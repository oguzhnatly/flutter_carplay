import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_carplay_example/voice_control_example.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

const speechChannel = MethodChannel('plugin.csdcorp.com/speech_to_text');
const ttsChannel = MethodChannel('flutter_tts');
const carChannel = MethodChannel('com.oguzhnatly.flutter_carplay');
const eventChannel = MethodChannel('com.oguzhnatly.flutter_carplay/event');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late VoiceControlExample voice;
  late SpeechToText speech;
  late _IosAudioTts tts;
  late FlutterCarplay carplay;
  late List<String> audioCalls;
  late List<MethodCall> carCalls;

  Future<void> speechEvent(String method, Object arguments) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
      speechChannel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) => done.complete(),
    );
    await done.future;
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> connection(String status) async {
    messenger.handlePlatformMessage(
      eventChannel.name,
      const StandardMethodCodec().encodeSuccessEnvelope({
        'type': 'onCarplayConnectionChange',
        'data': {'status': status},
      }),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> ttsEvent(String method, [Object? arguments]) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
      ttsChannel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) => done.complete(),
    );
    await done.future;
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> recognize() => speechEvent(
    'textRecognition',
    jsonEncode({
      'alternates': [
        {'recognizedWords': 'what time is it', 'confidence': 1.0},
      ],
      'resultType': 2,
    }),
  );

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    audioCalls = [];
    carCalls = [];
    messenger.setMockMethodCallHandler(speechChannel, (call) async {
      audioCalls.add('speech.${call.method}');
      if (call.method == 'listen') {
        await speechEvent('notifyStatus', 'listening');
      }
      return true;
    });
    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
      audioCalls.add('tts.${call.method}');
      if (call.method == 'speak') await ttsEvent('speak.onComplete');
      return 1;
    });
    messenger.setMockMethodCallHandler(carChannel, (call) async {
      carCalls.add(call);
      return true;
    });
    messenger.setMockMethodCallHandler(eventChannel, (_) async => null);
    carplay = FlutterCarplay();
    await Future<void>.delayed(Duration.zero);
    await connection('DISCONNECTED');
    await connection('CONNECTED');
    speech = SpeechToText.withMethodChannel();
    tts = _IosAudioTts();
    voice = VoiceControlExample(speech: speech, tts: tts);
    carplay.addListenerOnConnectionChange(voice.connectionChanged);
  });

  tearDown(() async {
    await voice.cancelSession();
    voice.dispose();
    await Future<void>.delayed(Duration.zero);
    await connection('DISCONNECTED');
    carplay.closeConnection();
    await Future<void>.delayed(Duration.zero);
    for (final channel in [
      speechChannel,
      ttsChannel,
      carChannel,
      eventChannel,
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('presenting on launch does not authorize or start recording', () async {
    await voice.present();
    expect(carCalls.single.method, 'setVoiceControlTemplate');
    expect(audioCalls, isEmpty);
    expect(voice.busy, isFalse);
  });

  test('permission denial leaves the microphone stopped', () async {
    messenger.setMockMethodCallHandler(speechChannel, (call) async {
      audioCalls.add('speech.${call.method}');
      return false;
    });
    await voice.start();
    expect(voice.status, contains('permissions'));
    expect(voice.busy, isFalse);
    expect(audioCalls, isNot(contains('speech.listen')));
    expect(carCalls, isEmpty);
  });

  test('presentation rejection prevents recording', () async {
    messenger.setMockMethodCallHandler(carChannel, (_) async => false);
    await voice.start();
    expect(voice.status, contains('could not open'));
    expect(audioCalls, isNot(contains('speech.listen')));
  });

  test(
    'unsupported presentation can be retried without stale template state',
    () async {
      messenger.setMockMethodCallHandler(
        carChannel,
        (_) async => throw PlatformException(code: 'unsupported_version'),
      );
      await voice.start();
      expect(audioCalls, isNot(contains('speech.listen')));
      messenger.setMockMethodCallHandler(carChannel, (call) async {
        carCalls.add(call);
        return true;
      });
      await voice.start();
      expect(audioCalls, contains('speech.listen'));
    },
  );

  test(
    'microphone startup failure leaves the example ready to retry',
    () async {
      messenger.setMockMethodCallHandler(speechChannel, (call) async {
        audioCalls.add('speech.${call.method}');
        return call.method != 'listen';
      });
      await voice.start();
      expect(voice.busy, isFalse);
      expect(voice.status, contains('Voice input is unavailable'));
    },
  );

  test('permission completion after cancel cannot start a session', () async {
    final permission = Completer<bool>();
    messenger.setMockMethodCallHandler(speechChannel, (call) async {
      audioCalls.add('speech.${call.method}');
      if (call.method == 'initialize') return permission.future;
      return true;
    });
    final start = voice.start();
    await Future<void>.delayed(Duration.zero);
    await voice.cancelSession();
    permission.complete(true);
    await start;
    expect(audioCalls, isNot(contains('speech.listen')));
    expect(carCalls, isEmpty);
  });

  test(
    'recognition goes through processing and speech without a CarPlay transcript',
    () async {
      await voice.start();
      expect(audioCalls, contains('speech.listen'));
      await speechEvent(
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'what time is it', 'confidence': 1.0},
          ],
          'resultType': 2,
        }),
      );
      for (var i = 0; i < 20 && voice.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(voice.transcript, 'what time is it');
      expect(voice.response, startsWith('It is '));
      expect(audioCalls, containsAllInOrder(['speech.stop', 'tts.speak']));
      expect(voice.busy, isFalse);
      final transitions = carCalls
          .where((c) => c.method == 'activateVoiceControlState')
          .map((c) => c.arguments['identifier']);
      expect(
        transitions,
        containsAllInOrder(['processing', 'speaking', 'ready']),
      );
      expect(
        jsonEncode(carCalls.map((c) => c.arguments).toList()),
        isNot(contains('what time is it')),
      );
    },
  );

  test(
    'disconnect stops both audio providers and rejects late recognition',
    () async {
      await voice.start();
      await connection('DISCONNECTED');
      await speechEvent(
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'what time is it', 'confidence': 1.0},
          ],
          'resultType': 2,
        }),
      );
      expect(audioCalls, contains('speech.cancel'));
      expect(audioCalls, contains('tts.stop'));
      expect(audioCalls, isNot(contains('tts.speak')));
      expect(voice.busy, isFalse);
    },
  );

  test('native dismissal stops audio promptly', () async {
    await voice.start();
    final template = FlutterCarPlayController.currentPresentTemplate!;
    messenger.handlePlatformMessage(
      eventChannel.name,
      const StandardMethodCodec().encodeSuccessEnvelope({
        'type': 'onVoiceControlDismissed',
        'data': {'elementId': template.uniqueId},
      }),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
    expect(audioCalls, contains('speech.cancel'));
    expect(audioCalls, contains('tts.stop'));
    expect(voice.busy, isFalse);
  });

  for (final throwsOnClose in [false, true]) {
    test(
      'Cancel retries after ${throwsOnClose ? 'an exception' : 'a rejected dismissal'}',
      () async {
        await voice.start();
        final original = FlutterCarPlayController.currentPresentTemplate;
        var attempts = 0;
        messenger.setMockMethodCallHandler(carChannel, (call) async {
          carCalls.add(call);
          if (call.method == 'closePresent' && ++attempts == 1) {
            if (throwsOnClose) throw PlatformException(code: 'dismiss_failed');
            return false;
          }
          return true;
        });
        await voice.cancelSession();
        expect(audioCalls, containsAll(['speech.cancel', 'tts.stop']));
        expect(voice.busy, isFalse);
        expect(FlutterCarPlayController.currentPresentTemplate, same(original));
        await voice.cancelSession();
        expect(attempts, 2);
        expect(FlutterCarPlayController.currentPresentTemplate, isNull);
        expect(voice.status, 'Voice session ended');
      },
    );
  }

  test(
    'Cancel starts both audio stops before either teardown finishes',
    () async {
      await voice.start();
      final stopping = Completer<bool>();
      messenger.setMockMethodCallHandler(speechChannel, (call) async {
        audioCalls.add('speech.${call.method}');
        return call.method == 'cancel' ? stopping.future : true;
      });
      audioCalls.clear();
      final cancelling = voice.cancelSession();
      await Future<void>.delayed(Duration.zero);
      final stoppedTogether = List<String>.of(audioCalls);
      stopping.complete(true);
      await cancelling;
      expect(stoppedTogether, containsAll(['speech.cancel', 'tts.stop']));
    },
  );

  test(
    'concurrent Cancel attempts share a close and retain ownership for retry',
    () async {
      await voice.present();
      final closing = Completer<bool>();
      messenger.setMockMethodCallHandler(carChannel, (call) async {
        carCalls.add(call);
        return call.method == 'closePresent' ? closing.future : true;
      });
      final first = voice.cancelSession();
      await Future<void>.delayed(Duration.zero);
      final second = voice.cancelSession();
      await Future<void>.delayed(Duration.zero);
      closing.complete(false);
      await Future.wait([first, second]);
      expect(
        carCalls.where((call) => call.method == 'closePresent'),
        hasLength(1),
      );
      messenger.setMockMethodCallHandler(carChannel, (call) async {
        carCalls.add(call);
        return true;
      });
      await voice.cancelSession();
      expect(
        carCalls.where((call) => call.method == 'closePresent'),
        hasLength(2),
      );
    },
  );

  for (final outcome in ['true', 'false', 'exception']) {
    test(
      'old cancellation $outcome completion cannot change a reconnected session',
      () async {
        await voice.present();
        final closing = Completer<bool>();
        messenger.setMockMethodCallHandler(carChannel, (call) async {
          carCalls.add(call);
          return call.method == 'closePresent' ? closing.future : true;
        });
        final cancelling = voice.cancelSession();
        await Future<void>.delayed(Duration.zero);
        await connection('DISCONNECTED');
        await connection('CONNECTED');
        final presenting = voice.present();
        await Future<void>.delayed(Duration.zero);
        expect(FlutterCarPlayController.currentPresentTemplate, isNull);
        if (outcome == 'exception') {
          closing.completeError(PlatformException(code: 'dismiss_failed'));
        } else {
          closing.complete(outcome == 'true');
        }
        await cancelling;
        await presenting;
        expect(FlutterCarPlayController.currentPresentTemplate, isNotNull);
        messenger.setMockMethodCallHandler(carChannel, (call) async {
          carCalls.add(call);
          return true;
        });
        await voice.cancelSession();
        expect(FlutterCarPlayController.currentPresentTemplate, isNull);
      },
    );
  }

  test(
    'start waits for an invoked cancellation and can reuse the retained modal after failure',
    () async {
      await voice.present();
      final closing = Completer<bool>();
      messenger.setMockMethodCallHandler(carChannel, (call) async {
        carCalls.add(call);
        return call.method == 'closePresent' ? closing.future : true;
      });
      final cancelling = voice.cancelSession();
      await Future<void>.delayed(Duration.zero);
      await voice.start();
      expect(audioCalls, isNot(contains('speech.listen')));
      closing.complete(false);
      await cancelling;
      await voice.start();
      expect(audioCalls, contains('speech.listen'));
      expect(
        carCalls.where((call) => call.method == 'setVoiceControlTemplate'),
        hasLength(1),
      );
    },
  );

  for (final launch in ['present', 'start']) {
    for (final failsWithError in [false, true]) {
      test(
        '$launch releases a rejected pending presentation after Cancel fails, error: $failsWithError',
        () async {
          final pending = Completer<bool>();
          final invoked = Completer<void>();
          messenger.setMockMethodCallHandler(carChannel, (call) async {
            carCalls.add(call);
            if (call.method == 'setVoiceControlTemplate') {
              invoked.complete();
              return pending.future;
            }
            return false;
          });
          final presenting = launch == 'present'
              ? voice.present()
              : voice.start();
          await invoked.future;
          await voice.cancelSession();
          if (failsWithError) {
            pending.completeError(PlatformException(code: 'present_failed'));
          } else {
            pending.complete(false);
          }
          await presenting;
          messenger.setMockMethodCallHandler(carChannel, (call) async {
            carCalls.add(call);
            return true;
          });
          await voice.start();
          expect(audioCalls, contains('speech.listen'));
          expect(
            carCalls.where((call) => call.method == 'setVoiceControlTemplate'),
            hasLength(2),
          );
        },
      );
    }
  }

  test(
    'failed Cancel invalidates late recognition and TTS completion',
    () async {
      final speaking = Completer<int>();
      final invoked = Completer<void>();
      messenger.setMockMethodCallHandler(ttsChannel, (call) async {
        audioCalls.add('tts.${call.method}');
        if (call.method == 'speak') {
          invoked.complete();
          return speaking.future;
        }
        if (call.method == 'stop') await ttsEvent('speak.onCancel');
        return 1;
      });
      await voice.start();
      final recognition = jsonEncode({
        'alternates': [
          {'recognizedWords': 'what time is it', 'confidence': 1.0},
        ],
        'resultType': 2,
      });
      await speechEvent('textRecognition', recognition);
      await invoked.future;
      messenger.setMockMethodCallHandler(carChannel, (call) async {
        carCalls.add(call);
        return false;
      });
      await voice.cancelSession();
      final status = voice.status;
      final callCount = carCalls.length;
      speaking.complete(1);
      await speechEvent(
        'textRecognition',
        recognition.replaceAll('what time is it', 'stale result'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(voice.status, status);
      expect(voice.transcript, 'what time is it');
      expect(voice.busy, isFalse);
      expect(carCalls, hasLength(callCount));
      messenger.setMockMethodCallHandler(carChannel, (_) async => true);
    },
  );

  test('regression reused speech provider binds the current owner', () async {
    await voice.start();
    await voice.cancelSession();
    voice.dispose();
    await Future<void>.delayed(Duration.zero);
    voice = VoiceControlExample(speech: speech);
    await voice.start();
    expect(voice.status, 'Listening');
  });

  test('regression completion releases the shared audio session', () async {
    final invoked = Completer<void>();
    final speaking = Completer<int>();
    var released = false;
    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
      audioCalls.add('tts.${call.method}');
      if (call.method == 'speak') {
        invoked.complete();
        return speaking.future;
      }
      if (call.method == 'setSharedInstance' && call.arguments == false) {
        released = true;
      }
      return 1;
    });
    await voice.start();
    await recognize();
    await invoked.future;
    speaking.complete(1);
    await ttsEvent('speak.onComplete');
    await Future<void>.delayed(Duration.zero);
    expect(released, isTrue);
    expect(voice.status, 'Ready for another question');
    expect(voice.busy, isFalse);
  });

  for (final event in ['speak.onCancel', 'speak.onError']) {
    test('regression $event recovers without a speak result', () async {
      final invoked = Completer<void>();
      final speaking = Completer<int>();
      var released = false;
      messenger.setMockMethodCallHandler(ttsChannel, (call) async {
        audioCalls.add('tts.${call.method}');
        if (call.method == 'speak') {
          invoked.complete();
          return speaking.future;
        }
        if (call.method == 'setSharedInstance' && call.arguments == false) {
          released = true;
        }
        return 1;
      });
      await voice.start();
      await recognize();
      await invoked.future;
      await ttsEvent(event, event == 'speak.onError' ? 'native failure' : null);
      await Future<void>.delayed(Duration.zero);
      expect(voice.busy, isFalse);
      expect(voice.status, isNot('Ready for another question'));
      expect(released, isTrue);
      expect(carCalls.last.arguments['identifier'], 'error');
      final status = voice.status;
      speaking.complete(1);
      await Future<void>.delayed(Duration.zero);
      expect(voice.status, status);
    });
  }

  for (final state in ['processing', 'ready']) {
    test(
      'regression rejected $state activation recovers with a microphone',
      () async {
        messenger.setMockMethodCallHandler(carChannel, (call) async {
          carCalls.add(call);
          return call.method != 'activateVoiceControlState' ||
              call.arguments['identifier'] != state;
        });
        await voice.start();
        await recognize();
        await Future<void>.delayed(const Duration(milliseconds: 2300));
        expect(voice.status, contains('could not show'));
        expect(voice.busy, isFalse);
        expect(carCalls.last.arguments['identifier'], 'error');
        if (state == 'processing') {
          expect(audioCalls, isNot(contains('tts.speak')));
        }
        final template =
            FlutterCarPlayController.currentPresentTemplate
                as CPVoiceControlTemplate;
        expect(
          template.voiceControlStates
              .singleWhere((state) => state.identifier == 'error')
              .actionButtons,
          isNotEmpty,
        );
      },
    );
  }

  test(
    'cleanup owns delayed native cancellation before another session',
    () async {
      final spoken = Completer<void>();
      final oldAcceptance = Completer<int>();
      var released = false;
      messenger.setMockMethodCallHandler(ttsChannel, (call) async {
        if (call.method == 'speak') {
          spoken.complete();
          return oldAcceptance.future;
        }
        if (call.method == 'setSharedInstance' && call.arguments == false) {
          released = true;
        }
        return 1;
      });
      await voice.start();
      await recognize();
      await spoken.future;
      final oldComplete = tts.completionHandler!;
      final oldCancel = tts.cancelHandler!;
      final oldError = tts.errorHandler!;
      final cancelling = voice.cancelSession();
      var cancelled = false;
      unawaited(cancelling.then((_) => cancelled = true));
      await Future<void>.delayed(Duration.zero);
      await voice.start();
      expect(audioCalls.where((call) => call == 'speech.listen'), hasLength(1));
      expect(cancelled, isFalse);
      expect(released, isFalse);
      await ttsEvent('speak.onCancel');
      await cancelling;
      expect(released, isTrue);
      await voice.start();
      final newSpoken = Completer<void>();
      messenger.setMockMethodCallHandler(ttsChannel, (call) async {
        if (call.method == 'speak') newSpoken.complete();
        return 1;
      });
      await recognize();
      await newSpoken.future;
      oldComplete();
      oldCancel();
      oldError('old failure');
      oldAcceptance.completeError(PlatformException(code: 'old_request'));
      await Future<void>.delayed(Duration.zero);
      expect(voice.busy, isTrue);
      expect(voice.status, 'Speaking');
      await ttsEvent('speak.onComplete');
      expect(voice.status, 'Ready for another question');
    },
  );

  test('native method acceptance is not speech completion', () async {
    final spoken = Completer<void>();
    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
      if (call.method == 'speak') spoken.complete();
      return 1;
    });
    await voice.start();
    await recognize();
    await spoken.future;
    await Future<void>.delayed(Duration.zero);
    expect(voice.busy, isTrue);
    expect(voice.status, 'Speaking');
    await ttsEvent('speak.onComplete');
    expect(voice.busy, isFalse);
  });

  for (final failure in ['rejected', 'exception']) {
    test('speech request $failure releases audio and allows retry', () async {
      var released = false;
      messenger.setMockMethodCallHandler(ttsChannel, (call) async {
        if (call.method == 'speak') {
          if (failure == 'exception') {
            throw PlatformException(code: 'tts_error');
          }
          return 0;
        }
        if (call.method == 'setSharedInstance' && call.arguments == false) {
          released = true;
        }
        return 1;
      });
      await voice.start();
      await recognize();
      await Future<void>.delayed(Duration.zero);
      expect(voice.busy, isFalse);
      expect(released, isTrue);
      expect(carCalls.last.arguments['identifier'], 'error');
      await voice.start();
      expect(voice.status, 'Listening');
    });
  }

  test('audio release rejection never announces readiness', () async {
    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
      if (call.method == 'speak') await ttsEvent('speak.onComplete');
      if (call.method == 'setSharedInstance') return 0;
      return 1;
    });
    await voice.start();
    await recognize();
    await Future<void>.delayed(Duration.zero);
    expect(voice.status, contains('Audio cleanup failed'));
    expect(voice.busy, isFalse);
    await voice.start();
    expect(audioCalls.where((call) => call == 'speech.listen'), hasLength(1));
  });

  test('regression speech errors have one cancellation owner', () async {
    await voice.start();
    final stopping = Completer<bool>();
    var cancellations = 0;
    messenger.setMockMethodCallHandler(speechChannel, (call) async {
      if (call.method == 'cancel') {
        cancellations++;
        return stopping.future;
      }
      return true;
    });
    final error = speechEvent(
      'notifyError',
      jsonEncode({'errorMsg': 'error_audio', 'permanent': true}),
    );
    await Future<void>.delayed(Duration.zero);
    final observed = cancellations;
    stopping.complete(true);
    await error;
    expect(observed, 1);
  });

  test('regression immediate retry waits for error cleanup', () async {
    await voice.start();
    final stopping = Completer<bool>();
    Future<void>? retry;
    voice.addListener(() {
      if (!voice.busy &&
          retry == null &&
          voice.status.contains('Speech input failed')) {
        retry = voice.start();
      }
    });
    messenger.setMockMethodCallHandler(speechChannel, (call) async {
      audioCalls.add('speech.${call.method}');
      if (call.method == 'cancel') return stopping.future;
      if (call.method == 'listen') {
        await speechEvent('notifyStatus', 'listening');
      }
      return true;
    });
    await speechEvent(
      'notifyError',
      jsonEncode({'errorMsg': 'error_audio', 'permanent': false}),
    );
    final listenCount = audioCalls
        .where((call) => call == 'speech.listen')
        .length;
    stopping.complete(true);
    await retry;
    expect(listenCount, 1);
    expect(voice.status, 'Listening');
  });

  for (final state in ['Listening', 'Speaking']) {
    test(
      'regression cancellation during $state notification prevents audio',
      () async {
        Future<void>? cancelling;
        voice.addListener(() {
          if (voice.status == state) cancelling = voice.cancelSession();
        });
        await voice.start();
        if (state == 'Speaking') await recognize();
        await cancelling;
        await Future<void>.delayed(Duration.zero);
        expect(
          audioCalls,
          isNot(contains(state == 'Listening' ? 'speech.listen' : 'tts.speak')),
        );
      },
    );
  }

  for (final result in [0, null]) {
    test(
      'regression rejected audio category $result prevents playback',
      () async {
        tts.categoryResult = result;
        await voice.start();
        await recognize();
        await Future<void>.delayed(Duration.zero);
        expect(audioCalls, isNot(contains('tts.speak')));
        expect(voice.status, contains('audio session'));
        expect(voice.busy, isFalse);
      },
    );
  }

  test('local conversational response supports time and help', () {
    expect(
      VoiceControlExample.replyTo(
        'What time is it?',
        DateTime(2026, 1, 1, 13, 7),
      ),
      'It is 1:07 PM.',
    );
    expect(
      VoiceControlExample.replyTo('help', DateTime(2026)),
      contains('Ask, what time is it?'),
    );
  });

  testWidgets('phone view makes capture explicit and labels private text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: VoiceControlExamplePage(example: voice)),
    );
    expect(find.text('Start listening'), findsOneWidget);
    expect(find.text('Transcript on iPhone only'), findsOneWidget);
    expect(audioCalls, isEmpty);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}

// The pinned provider skips this method on macOS even with Flutter's iOS test
// override. All other provider methods and callbacks still use the real channel.
class _IosAudioTts extends FlutterTts {
  Object? categoryResult = 1;

  @override
  Future<dynamic> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, [
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  ]) async {
    expect(category, IosTextToSpeechAudioCategory.playback);
    expect(options, contains(IosTextToSpeechAudioCategoryOptions.duckOthers));
    expect(mode, IosTextToSpeechAudioMode.spokenAudio);
    return categoryResult;
  }
}
