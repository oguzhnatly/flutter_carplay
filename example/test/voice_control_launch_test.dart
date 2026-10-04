import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay_example/voice_control_main.dart';
import 'package:flutter_carplay_example/voice_control_example.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.oguzhnatly.flutter_carplay');
  const events = MethodChannel('com.oguzhnatly.flutter_carplay/event');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Completer<bool> refresh;
  late Completer<void> shown;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls = [];
    refresh = Completer<bool>();
    shown = Completer<void>();
    FlutterCarPlayController.templateHistory.clear();
    messenger.setMockMethodCallHandler(events, (_) async => null);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      // CarPlay can omit completion for a redundant root replacement.
      if (call.method == 'forceUpdateRootTemplate') return refresh.future;
      if (call.method == 'setVoiceControlTemplate' && !shown.isCompleted) {
        shown.complete();
      }
      return true;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (_) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugin.csdcorp.com/speech_to_text'),
      (_) async => true,
    );
  });

  tearDown(() {
    if (!refresh.isCompleted) refresh.complete(false);
    debugDefaultTargetPlatformOverride = null;
    for (final name in [
      channel.name,
      events.name,
      'flutter_tts',
      'plugin.csdcorp.com/speech_to_text',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
  });

  testWidgets(
    'CarPlay launch presents voice without replacing its root twice',
    (tester) async {
      await tester.pumpWidget(const ConversationalApp());
      await tester.pump();
      messenger.handlePlatformMessage(
        events.name,
        const StandardMethodCodec().encodeSuccessEnvelope({
          'type': 'onCarplayConnectionChange',
          'data': {'status': 'CONNECTED'},
        }),
        (_) {},
      );
      await tester.pump();
      await tester.pump();
      for (var attempt = 0; attempt < 20 && !shown.isCompleted; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(calls.where((c) => c.method == 'setRootTemplate'), hasLength(1));
      expect(
        calls.where((c) => c.method == 'setVoiceControlTemplate'),
        hasLength(1),
      );
      expect(
        calls.where((c) => c.method == 'forceUpdateRootTemplate'),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    },
  );
  for (final ending in ['foreground', 'disconnect', 'dispose']) {
    testWidgets('regression foreground waits for cancellation then $ending', (
      tester,
    ) async {
      const speech = MethodChannel('plugin.csdcorp.com/speech_to_text');
      final stopping = Completer<bool>();
      final cancelling = Completer<void>();
      Future<void> connection(String status) async {
        messenger.handlePlatformMessage(
          events.name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'type': 'onCarplayConnectionChange',
            'data': {'status': status},
          }),
          (_) {},
        );
        await tester.pump();
      }

      Future<void> drain() async {
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
      }

      messenger.setMockMethodCallHandler(speech, (call) async {
        if (call.method == 'listen') {
          messenger.handlePlatformMessage(
            speech.name,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('notifyStatus', 'listening'),
            ),
            (_) {},
          );
        }
        if (call.method == 'cancel') {
          if (!cancelling.isCompleted) cancelling.complete();
          return stopping.future;
        }
        return true;
      });
      await tester.pumpWidget(const ConversationalApp());
      await connection('CONNECTED');
      await drain();
      final voice = tester
          .widget<VoiceControlExamplePage>(find.byType(VoiceControlExamplePage))
          .example;
      await tester.runAsync(voice.start);
      await connection('BACKGROUND');
      expect(cancelling.isCompleted, isTrue);
      await connection('CONNECTED');
      expect(
        calls.where((c) => c.method == 'setVoiceControlTemplate'),
        hasLength(1),
      );
      if (ending == 'disconnect') await connection('DISCONNECTED');
      if (ending == 'dispose') await tester.pumpWidget(const SizedBox());
      stopping.complete(true);
      await drain();
      expect(
        calls.where((c) => c.method == 'setVoiceControlTemplate'),
        hasLength(ending == 'foreground' ? 2 : 1),
      );
      if (ending == 'foreground') {
        expect(FlutterCarPlayController.currentPresentTemplate, isNotNull);
      } else {
        expect(FlutterCarPlayController.currentPresentTemplate, isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
