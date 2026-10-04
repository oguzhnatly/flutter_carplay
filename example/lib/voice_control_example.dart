import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Example speech composition. The template library remains provider agnostic.
class VoiceControlExample extends ChangeNotifier {
  VoiceControlExample({SpeechToText? speech, FlutterTts? tts})
    : _speech = speech ?? SpeechToText(),
      _tts = tts ?? FlutterTts();

  final SpeechToText _speech;
  final FlutterTts _tts;
  CPVoiceControlTemplate? _template;
  Future<bool> _cleanup = Future.value(true);
  Future<bool>? _audioCleanup;
  Future<void>? _cancellation;
  _VoicePlayback? _playback;
  int _presentation = 0;
  Timer? _finalResultTimer;
  Completer<void>? _listeningReady;
  int _session = 0;
  int? _cancellingSession;
  bool _disposed = false;
  bool _starting = false;
  bool _processing = false;
  bool busy = false;
  String status = 'Connect CarPlay, then tap the microphone to begin.';
  String transcript = '';
  String response = '';

  bool _current(int session) => !_disposed && session == _session;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  CPVoiceControlTemplate _makeTemplate({bool listening = false}) {
    final microphone = CPButton(
      image: 'images/voice_microphone.svg',
      title: 'Microphone',
      onPress: () => unawaited(start()),
    );
    final cancel = CPBarButton(
      title: 'Cancel',
      onPress: () => unawaited(cancelSession()),
    );
    CPVoiceControlState state(
      String id,
      String title, {
      bool canListen = false,
    }) => CPVoiceControlState(
      identifier: id,
      titleVariants: [title],
      image: id == 'listening' ? 'images/voice_microphone.svg' : null,
      actionButtons: canListen ? [microphone] : [],
    );
    final ready = state('ready', 'Tap the microphone', canListen: true);
    final input = state('listening', 'Listening');
    return CPVoiceControlTemplate(
      voiceControlStates: [
        if (listening) input else ready,
        if (listening) ready else input,
        state('processing', 'Processing'),
        state('speaking', 'Speaking'),
        state('error', 'Please try again', canListen: true),
      ],
      trailingNavigationBarButtons: [cancel],
      onDismiss: _dismissed,
    );
  }

  /// Used by the conversational entry point on CarPlay launch. Presentation
  /// alone never requests permission or starts recording.
  Future<void> present() async {
    final presentation = _presentation;
    await _cancellation;
    final audioStopped = await _cleanup;
    if (!audioStopped ||
        _disposed ||
        presentation != _presentation ||
        _template != null ||
        FlutterCarplay.connectionStatus !=
            ConnectionStatusTypes.connected.name) {
      return;
    }
    final session = _session;
    final template = _makeTemplate();
    _template = template;
    try {
      if (!await FlutterCarplay.showVoiceControl(template: template)) {
        if (identical(_template, template)) _template = null;
        if (_current(session)) {
          status =
              'Voice control could not open. Check the CarPlay connection and app category.';
        }
      }
    } on PlatformException catch (error) {
      if (identical(_template, template)) _template = null;
      if (_current(session)) {
        status = error.message ?? 'Voice control is unavailable.';
      }
    }
    _changed();
  }

  Future<void> start() async {
    if (_disposed || busy || _starting || _cancellingSession != null) return;
    _starting = true;
    busy = true;
    _processing = false;
    final session = ++_session;
    transcript = '';
    response = '';
    status = 'Preparing voice input';
    _changed();
    try {
      final audioStopped = await _cleanup;
      if (!_current(session)) return;
      if (!audioStopped) {
        await _fail('Audio cleanup failed. Try again.', session);
        return;
      }
      // initialize retains the original callbacks after its first success.
      _speech.errorListener = (error) {
        if (_current(session) && busy && !_processing) {
          unawaited(_fail('Speech input failed: ${error.errorMsg}', session));
        }
      };
      _speech.statusListener = (value) {
        if (!_current(session)) return;
        if (value == SpeechToText.listeningStatus) _completeListeningSignal();
        if (value == SpeechToText.doneStatus && busy && !_processing) {
          final current = _session;
          _finalResultTimer?.cancel();
          _finalResultTimer = Timer(const Duration(seconds: 2), () {
            if (_current(current) && busy && !_processing) {
              unawaited(_fail('No speech was recognized. Try again.', current));
            }
          });
        }
      };
      final available = await _speech.initialize(
        onError: _speech.errorListener,
        onStatus: _speech.statusListener,
      );
      if (!_current(session)) return;
      if (!available) {
        await _fail(
          'Microphone or speech access is unavailable. Review permissions in iPhone Settings.',
          session,
        );
        return;
      }
      if (_template == null) {
        final template = _makeTemplate(listening: true);
        _template = template;
        final bool shown;
        try {
          shown = await FlutterCarplay.showVoiceControl(template: template);
        } catch (_) {
          if (identical(_template, template)) _template = null;
          rethrow;
        }
        if (!shown && identical(_template, template)) _template = null;
        if (!_current(session)) return;
        if (!shown) {
          await _fail(
            'Voice control could not open. Check the CarPlay connection and app category.',
            session,
          );
          return;
        }
      } else if (!await _activate('listening', session)) {
        await _fail(
          'CarPlay could not show voice input. Try again shortly.',
          session,
        );
        return;
      }
      if (!_current(session)) return;
      status = 'Listening';
      _changed();
      if (!_current(session)) return;
      final listeningReady = _listeningReady = Completer<void>();
      await _speech.listen(
        onResult: (result) => _onResult(result, session),
        // Keep automatic error cancellation off because _fail owns teardown.
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      if (!_current(session)) {
        await _speech.cancel();
        return;
      }
      await listeningReady.future.timeout(const Duration(seconds: 3));
    } catch (error) {
      await _fail('Voice input is unavailable: $error', session);
    } finally {
      _starting = false;
      _changed();
    }
  }

  void _onResult(SpeechRecognitionResult result, int session) {
    if (!_current(session) || !busy || _processing) return;
    // Recognition text stays on the phone. CarPlay receives generic states only.
    transcript = result.recognizedWords;
    _changed();
    if (result.finalResult) unawaited(_respond(session));
  }

  Future<void> _respond(int session) async {
    if (!_current(session) || _processing) return;
    _processing = true;
    _finalResultTimer?.cancel();
    try {
      await _speech.stop();
      if (!_current(session)) return;
      if (transcript.trim().isEmpty) {
        await _fail('No speech was recognized. Try again.', session);
        return;
      }
      status = 'Processing';
      _changed();
      if (!await _activate('processing', session)) {
        await _fail(
          'CarPlay could not show the processing state. Try again.',
          session,
        );
        return;
      }
      if (!_current(session)) return;
      response = replyTo(transcript, DateTime.now());
      if (!await _activate('speaking', session)) {
        await _fail(
          'CarPlay could not show the speaking state. Try again.',
          session,
        );
        return;
      }
      await _tts.awaitSpeakCompletion(false);
      if (!_current(session)) return;
      await _tts.autoStopSharedSession(true);
      if (!_current(session)) return;
      final configured = await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.duckOthers],
        IosTextToSpeechAudioMode.spokenAudio,
      );
      if (!_current(session)) return;
      if (configured != 1) {
        await _fail(
          'The speech audio session could not be configured. Try again.',
          session,
        );
        return;
      }
      status = 'Speaking';
      _changed();
      if (!_current(session)) return;
      final playback = _playback = _VoicePlayback();
      void ended([String? failure]) {
        if (identical(_playback, playback) && !playback.ended.isCompleted) {
          playback.ended.complete(failure);
        }
      }

      _tts.setCompletionHandler(ended);
      _tts.setCancelHandler(
        () => ended('Speech playback was interrupted. Try again.'),
      );
      _tts.setErrorHandler((error) => ended('Speech playback failed: $error'));
      // iOS cancellation does not settle an awaited speak result. Native
      // terminal events own playback; the method result only accepts the request.
      unawaited(
        _tts.speak(response).then<void>((accepted) {
          if (accepted != 1) {
            ended('Speech playback could not start. Try again.');
          }
        }, onError: (Object error) => ended('Speech playback failed: $error')),
      );
      final failure = await playback.ended.future;
      if (!_current(session)) return;
      _cleanup = _stopAudio();
      final released = await _cleanup;
      if (!_current(session)) return;
      if (!released) {
        await _fail('Audio cleanup failed. Try again.', session);
        return;
      }
      if (failure != null) {
        await _fail(failure, session);
        return;
      }
      if (!await _activate('ready', session)) {
        await _fail(
          'CarPlay could not show the ready state. Try again.',
          session,
        );
        return;
      }
      if (!_current(session)) return;
      busy = false;
      status = 'Ready for another question';
      _changed();
    } catch (error) {
      await _fail('Voice response failed: $error', session);
    }
  }

  /// A small local conversational service, without a remote account or backend.
  static String replyTo(String text, DateTime now) {
    final words = text.toLowerCase();
    if (words.contains('time')) {
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minute = now.minute.toString().padLeft(2, '0');
      return 'It is $hour:$minute ${now.hour < 12 ? 'AM' : 'PM'}.';
    }
    return 'I can tell you the time. Ask, what time is it?';
  }

  Future<bool> _activate(String identifier, int session) async {
    // The host can reject rapid changes. Retry briefly without claiming success.
    for (var attempt = 0; attempt < 3 && _current(session); attempt++) {
      final template = _template;
      if (template == null) return false;
      if (await template.activateState(identifier)) return _current(session);
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    return false;
  }

  void _completeListeningSignal() {
    final ready = _listeningReady;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  Future<void> _fail(String message, int session) async {
    if (!_current(session)) return;
    final errorSession = ++_session;
    _completeListeningSignal();
    busy = false;
    _finalResultTimer?.cancel();
    status = message;
    _cleanup = _stopAudio();
    _changed();
    final released = await _cleanup;
    if (!_current(errorSession)) return;
    if (!released) {
      status = '$message Audio cleanup failed. Try again.';
      _changed();
    }
    try {
      await _activate('error', errorSession);
    } on PlatformException {
      /* Phone status remains available. */
    }
  }

  Future<bool> _stopAudio() {
    return _audioCleanup ??= _stopOwnedAudio().whenComplete(() {
      _audioCleanup = null;
    });
  }

  Future<bool> _stopOwnedAudio() async {
    final playback = _playback;
    Future<void> stop(Future<dynamic> Function() operation) async {
      try {
        await operation();
      } catch (_) {
        /* The provider may already be stopped. */
      }
    }

    await Future.wait([stop(_speech.cancel), stop(_tts.stop)]);
    // stop() acknowledges the request before iOS delivers didCancel. Keep the
    // old handlers installed until its terminal event, before another session.
    if (playback != null) await playback.ended.future;
    try {
      return await _tts.setSharedInstance(false) == 1;
    } catch (_) {
      return false;
    } finally {
      if (identical(_playback, playback)) _playback = null;
    }
  }

  void _dismissed() {
    _session++;
    if (_cancellation == null) _presentation++;
    _completeListeningSignal();
    _template = null;
    busy = false;
    _finalResultTimer?.cancel();
    status = 'Voice session ended';
    _cleanup = _stopAudio();
    _changed();
  }

  Future<void> cancelSession() {
    _presentation++;
    return _cancellation ??= _cancelSession().whenComplete(() {
      _cancellation = null;
    });
  }

  Future<void> _cancelSession() async {
    final template = _template;
    final session = ++_session;
    _cancellingSession = session;
    _completeListeningSignal();
    busy = false;
    _finalResultTimer?.cancel();
    status = 'Stopping voice session';
    _cleanup = _stopAudio();
    _changed();
    bool isCurrent() => _session == session && identical(_template, template);
    try {
      final released = await _cleanup;
      if (!isCurrent()) return;
      if (!released) {
        status = 'Audio cleanup failed. Try again.';
        return;
      }
      if (template == null) {
        status = 'Voice session ended';
        return;
      }
      final dismissed = await FlutterCarplay.popModal();
      if (!isCurrent()) return;
      if (!dismissed) {
        status = 'Audio stopped. CarPlay could not dismiss the voice screen.';
      }
    } on PlatformException catch (error) {
      if (isCurrent()) {
        status =
            'Audio stopped. ${error.message ?? 'CarPlay dismissal failed.'}';
      }
    } finally {
      if (_cancellingSession == session) {
        _cancellingSession = null;
        _changed();
      }
    }
  }

  void connectionChanged(ConnectionStatusTypes status) {
    if (status == ConnectionStatusTypes.disconnected ||
        status == ConnectionStatusTypes.background) {
      unawaited(cancelSession());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(cancelSession());
    super.dispose();
  }
}

class _VoicePlayback {
  final ended = Completer<String?>();
}

class VoiceControlExamplePage extends StatelessWidget {
  const VoiceControlExamplePage({super.key, required this.example});
  final VoiceControlExample example;

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) unawaited(example.cancelSession());
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Voice control')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedBuilder(
            animation: example,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.status,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ask what time it is. Speech access is requested when you start. CarPlay must be connected with an approved conversational or navigation configuration. This example uses iOS 26.4 voice controls.',
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: example.busy ? null : example.start,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start listening'),
                    ),
                    OutlinedButton(
                      onPressed: example.cancelSession,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Transcript on iPhone only'),
                SelectableText(
                  example.transcript.isEmpty
                      ? 'No speech captured'
                      : example.transcript,
                ),
                const SizedBox(height: 16),
                const Text('Spoken response'),
                SelectableText(
                  example.response.isEmpty
                      ? 'No response yet'
                      : example.response,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
