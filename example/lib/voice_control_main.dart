import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

import 'voice_control_example.dart';

/// Select Runner/Conversational.entitlements when building this entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConversationalApp());
}

class ConversationalApp extends StatefulWidget {
  const ConversationalApp({super.key});

  @override
  State<ConversationalApp> createState() => _ConversationalAppState();
}

class _ConversationalAppState extends State<ConversationalApp> {
  VoiceControlExample? _voice;
  FlutterCarplay? _carplay;
  Future<void>? _rootReady;
  int _presentation = 0;
  String? _launchError;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final voice = _voice = VoiceControlExample();
    final carplay = _carplay = FlutterCarplay();
    carplay.addListenerOnConnectionChange((status) {
      _presentation++;
      voice.connectionChanged(status);
      if (status == ConnectionStatusTypes.connected) unawaited(_present());
    });
    _rootReady = FlutterCarplay.setRootTemplate(
      rootTemplate: CPListTemplate(
        title: 'Voice conversation',
        sections: [
          CPListSection(
            items: [
              CPListItem(
                text: 'Talk',
                detailText: 'Open voice control',
                onPress: (complete, _) async {
                  await complete();
                  await voice.present();
                },
              ),
            ],
          ),
        ],
      ),
    );
    unawaited(_present());
  }

  Future<void> _present() async {
    final presentation = _presentation;
    try {
      await _rootReady;
      if (!mounted ||
          presentation != _presentation ||
          FlutterCarplay.connectionStatus !=
              ConnectionStatusTypes.connected.name) {
        return;
      }
      // The root is installed by setRootTemplate and the native connect hook.
      // Replacing it again can leave the host completion pending indefinitely.
      if (!mounted) return;
      // Voice is the primary CarPlay interface on launch. The microphone action
      // is the explicit consent to begin capture after permissions are granted.
      await _voice?.present();
      if (mounted) setState(() => _launchError = null);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _launchError = error.message ?? 'CarPlay could not open.',
        );
      }
    }
  }

  @override
  void dispose() {
    _voice?.dispose();
    _carplay?.removeListenerOnConnectionChange();
    _carplay?.closeConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: _launchError != null
        ? Scaffold(
            body: SafeArea(child: Center(child: Text(_launchError!))),
          )
        : _voice == null
        ? const Scaffold(
            body: Center(child: Text('This voice example requires iOS.')),
          )
        : VoiceControlExamplePage(example: _voice!),
  );
}
