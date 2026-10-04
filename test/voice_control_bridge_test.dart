import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

const channel = MethodChannel('com.oguzhnatly.flutter_carplay');
const events = MethodChannel('com.oguzhnatly.flutter_carplay/event');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late FlutterCarplay carplay;
  late List<MethodCall> calls;

  Future<void> event(String type, Map<String, dynamic> data) async {
    messenger.handlePlatformMessage(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope({
        'type': type,
        'data': data,
      }),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  CPVoiceControlTemplate voice({
    String id = 'voice',
    VoidCallback? onDismiss,
    List<CPButton> buttons = const [],
  }) => CPVoiceControlTemplate(
    id: id,
    voiceControlStates: [
      CPVoiceControlState(
        identifier: 'listening',
        titleVariants: ['Listening'],
        actionButtons: buttons,
      ),
      CPVoiceControlState(
        identifier: 'processing',
        titleVariants: ['Processing'],
      ),
    ],
    onDismiss: onDismiss,
  );

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls = [];
    messenger.setMockMethodCallHandler(events, (_) async => null);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    FlutterCarPlayController.templateHistory.clear();
    carplay = FlutterCarplay();
    await Future<void>.delayed(Duration.zero);
    await event('onCarplayConnectionChange', {'status': 'DISCONNECTED'});
    await event('onCarplayConnectionChange', {'status': 'CONNECTED'});
  });

  tearDown(() async {
    await event('onCarplayConnectionChange', {'status': 'DISCONNECTED'});
    carplay.closeConnection();
    await Future<void>.delayed(Duration.zero);
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(events, null);
    messenger.setMockMessageHandler('flutter/assets', null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('presents only modally and activates matching current state', () async {
    final template = voice();
    expect(
      await FlutterCarplay.showVoiceControl(
        template: template,
        animated: false,
      ),
      isTrue,
    );
    expect(calls.last.method, 'setVoiceControlTemplate');
    expect(calls.last.arguments['animated'], isFalse);
    expect(calls.last.arguments['template']['_elementId'], 'voice');
    expect(FlutterCarPlayController.templateHistory, isEmpty);
    expect(await template.activateState('processing'), isTrue);
    expect(calls.last.method, 'activateVoiceControlState');
    expect(calls.last.arguments, {
      'elementId': 'voice',
      'identifier': 'processing',
    });
    final count = calls.length;
    expect(await template.activateState('missing'), isFalse);
    expect(
      await FlutterCarplay.activateVoiceControlState(
        elementId: 'wrong',
        identifier: 'listening',
      ),
      isFalse,
    );
    expect(calls, hasLength(count));
    expect(
      () => FlutterCarplay.push(template: template),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => FlutterCarplay.setRootTemplate(rootTemplate: template),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => CPTabBarTemplate(templates: [template]).toJson(),
      throwsArgumentError,
    );
  });

  test('propagates rejected presentation and activation', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    final template = voice();
    expect(await FlutterCarplay.showVoiceControl(template: template), isFalse);
    expect(await template.activateState('processing'), isFalse);
    expect(FlutterCarPlayController.currentPresentTemplate, isNull);
    messenger.setMockMethodCallHandler(
      channel,
      (c) async => c.method != 'activateVoiceControlState',
    );
    expect(await FlutterCarplay.showVoiceControl(template: template), isTrue);
    expect(await template.activateState('processing'), isFalse);
  });

  test('platform errors release the presentation reservation', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'unsupported_template'),
    );
    await expectLater(
      FlutterCarplay.showVoiceControl(template: voice()),
      throwsA(isA<PlatformException>()),
    );
    messenger.setMockMethodCallHandler(channel, (_) async => true);
    expect(await FlutterCarplay.showVoiceControl(template: voice()), isTrue);
  });

  test(
    'dismissal result keeps or clears state and delivers callback once',
    () async {
      var dismissed = 0;
      final template = voice(onDismiss: () => dismissed++);
      await FlutterCarplay.showVoiceControl(template: template);
      messenger.setMockMethodCallHandler(channel, (_) async => false);
      expect(await FlutterCarplay.popModal(), isFalse);
      expect(FlutterCarPlayController.currentPresentTemplate, same(template));
      expect(dismissed, 0);
      messenger.setMockMethodCallHandler(channel, (_) async => true);
      expect(await FlutterCarplay.popModal(), isTrue);
      await event('onVoiceControlDismissed', {'elementId': 'voice'});
      expect(dismissed, 1);
      expect(await template.activateState('listening'), isFalse);
    },
  );

  test(
    'native dismissal and disconnect invalidate pending and active requests',
    () async {
      var dismissed = 0;
      final template = voice(onDismiss: () => dismissed++);
      await FlutterCarplay.showVoiceControl(template: template);
      await event('onVoiceControlDismissed', {'elementId': 'other'});
      expect(dismissed, 0);
      await event('onVoiceControlDismissed', {'elementId': 'voice'});
      expect(dismissed, 1);
      final pending = Completer<bool>();
      messenger.setMockMethodCallHandler(channel, (_) => pending.future);
      final showing = FlutterCarplay.showVoiceControl(template: template);
      await Future<void>.delayed(Duration.zero);
      await event('onCarplayConnectionChange', {'status': 'DISCONNECTED'});
      await event('onCarplayConnectionChange', {'status': 'CONNECTED'});
      pending.complete(true);
      expect(await showing, isFalse);
      expect(FlutterCarPlayController.currentPresentTemplate, isNull);
      expect(dismissed, 2);
    },
  );

  test(
    'native dismissal before presentation reply cannot resurrect template',
    () async {
      final pending = Completer<bool>();
      messenger.setMockMethodCallHandler(channel, (_) => pending.future);
      final showing = FlutterCarplay.showVoiceControl(template: voice());
      await Future<void>.delayed(Duration.zero);
      await event('onVoiceControlDismissed', {'elementId': 'voice'});
      pending.complete(true);
      expect(await showing, isFalse);
      expect(FlutterCarPlayController.currentPresentTemplate, isNull);
    },
  );

  test('disconnected calls and competing modals are rejected', () async {
    await event('onCarplayConnectionChange', {'status': 'DISCONNECTED'});
    expect(await FlutterCarplay.showVoiceControl(template: voice()), isFalse);
    await event('onCarplayConnectionChange', {'status': 'CONNECTED'});
    final pending = Completer<bool>();
    messenger.setMockMethodCallHandler(channel, (c) {
      calls.add(c);
      return pending.future;
    });
    final showing = FlutterCarplay.showVoiceControl(template: voice());
    await Future<void>.delayed(Duration.zero);
    expect(
      await FlutterCarplay.showVoiceControl(template: voice(id: 'second')),
      isFalse,
    );
    await FlutterCarplay.showAlert(
      template: CPAlertTemplate(titleVariants: ['Busy'], actions: []),
    );
    expect(calls, hasLength(1));
    pending.complete(true);
    expect(await showing, isTrue);
  });

  test(
    'cancellation before SVG loading finishes never invokes presentation',
    () async {
      final image = Completer<ByteData?>();
      clearSvgRasterCache();
      messenger.setMockMessageHandler('flutter/assets', (_) => image.future);
      var dismissed = 0;
      final template = CPVoiceControlTemplate(
        onDismiss: () => dismissed++,
        voiceControlStates: [
          CPVoiceControlState(identifier: 'listening', image: 'delayed.svg'),
        ],
      );
      final showing = FlutterCarplay.showVoiceControl(template: template);
      await Future<void>.delayed(Duration.zero);
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return false;
      });
      expect(await FlutterCarplay.popModal(), isTrue);
      expect(await showing.timeout(const Duration(seconds: 1)), isFalse);
      expect(dismissed, 1);
      image.complete(
        ByteData.sublistView(File('test/fixtures/icon.svg').readAsBytesSync()),
      );
      expect(await showing, isFalse);
      expect(calls, isEmpty);
      expect(dismissed, 1);
    },
  );

  for (final throwsOnClose in [false, true]) {
    test(
      'pending cancellation retains ownership after ${throwsOnClose ? 'an exception' : 'failure'} and can retry',
      () async {
        var dismissed = 0;
        var pressed = 0;
        final template = voice(
          onDismiss: () => dismissed++,
          buttons: [
            CPButton(id: 'retry', image: 'mic.png', onPress: () => pressed++),
          ],
        );
        final pending = Completer<bool>();
        var closeSucceeds = false;
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setVoiceControlTemplate') return pending.future;
          if (call.method == 'closePresent' && !closeSucceeds) {
            if (throwsOnClose) throw PlatformException(code: 'dismiss_failed');
            return false;
          }
          return true;
        });
        final showing = FlutterCarplay.showVoiceControl(template: template);
        await Future<void>.delayed(Duration.zero);
        if (throwsOnClose) {
          await expectLater(
            FlutterCarplay.popModal(),
            throwsA(isA<PlatformException>()),
          );
        } else {
          expect(await FlutterCarplay.popModal(), isFalse);
        }
        expect(dismissed, 0);
        pending.complete(true);
        expect(await showing, isTrue);
        expect(FlutterCarPlayController.currentPresentTemplate, same(template));
        await event('onVoiceControlButtonPressed', {
          'templateId': 'voice',
          'elementId': 'retry',
        });
        expect(pressed, 1);
        expect(await template.activateState('processing'), isTrue);
        expect(
          await FlutterCarplay.showVoiceControl(template: voice(id: 'other')),
          isFalse,
        );
        closeSucceeds = true;
        expect(await FlutterCarplay.popModal(), isTrue);
        await event('onVoiceControlDismissed', {'elementId': 'voice'});
        expect(dismissed, 1);
        expect(
          calls.where((call) => call.method == 'closePresent'),
          hasLength(2),
        );
      },
    );
  }

  test(
    'successful pending cancellation and concurrent closes complete once',
    () async {
      var dismissed = 0;
      final pending = Completer<bool>();
      final closing = Completer<bool>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'setVoiceControlTemplate'
            ? pending.future
            : closing.future;
      });
      final showing = FlutterCarplay.showVoiceControl(
        template: voice(onDismiss: () => dismissed++),
      );
      await Future<void>.delayed(Duration.zero);
      final first = FlutterCarplay.popModal();
      final second = FlutterCarplay.popModal();
      await Future<void>.delayed(Duration.zero);
      expect(dismissed, 0);
      await event('onVoiceControlDismissed', {'elementId': 'voice'});
      closing.complete(true);
      pending.complete(false);
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(await showing, isFalse);
      expect(dismissed, 1);
      expect(
        calls.where((call) => call.method == 'closePresent'),
        hasLength(1),
      );
    },
  );

  test(
    'disconnect and stale close completion preserve a replacement modal',
    () async {
      var dismissed = 0;
      await FlutterCarplay.showVoiceControl(
        template: voice(onDismiss: () => dismissed++),
      );
      final closing = Completer<bool>();
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'closePresent' ? closing.future : true,
      );
      final first = FlutterCarplay.popModal();
      final second = FlutterCarplay.popModal();
      await Future<void>.delayed(Duration.zero);
      await event('onCarplayConnectionChange', {'status': 'DISCONNECTED'});
      await event('onCarplayConnectionChange', {'status': 'CONNECTED'});
      final next = voice(id: 'next');
      expect(await FlutterCarplay.showVoiceControl(template: next), isTrue);
      closing.complete(false);
      expect(await first, isFalse);
      expect(await second, isFalse);
      await event('onVoiceControlDismissed', {'elementId': 'voice'});
      expect(FlutterCarPlayController.currentPresentTemplate, same(next));
      expect(dismissed, 1);
    },
  );

  test(
    'activation completion after disconnect cannot report success',
    () async {
      final template = voice();
      await FlutterCarplay.showVoiceControl(template: template);
      final pending = Completer<bool>();
      messenger.setMockMethodCallHandler(channel, (_) => pending.future);
      final activation = template.activateState('processing');
      await Future<void>.delayed(Duration.zero);
      await event('onCarplayConnectionChange', {'status': 'DISCONNECTED'});
      pending.complete(true);
      expect(await activation, isFalse);
    },
  );

  test('voice template cannot enter tabs through updates', () async {
    await expectLater(
      carplay.updateTabBarTemplates(elementId: 'tabs', templates: [voice()]),
      throwsArgumentError,
    );
    expect(calls, isEmpty);
  });

  test('buttons dispatch only to the current voice template', () async {
    var pressed = 0;
    final button = CPButton(
      id: 'mic',
      image: 'mic.png',
      onPress: () => pressed++,
    );
    await FlutterCarplay.showVoiceControl(template: voice(buttons: [button]));
    await event('onVoiceControlButtonPressed', {
      'templateId': 'other',
      'elementId': 'mic',
    });
    await event('onVoiceControlButtonPressed', {
      'templateId': 'voice',
      'elementId': 'missing',
    });
    expect(pressed, 0);
    await event('onVoiceControlButtonPressed', {
      'templateId': 'voice',
      'elementId': 'mic',
    });
    expect(pressed, 1);
    await FlutterCarplay.popModal();
    await event('onVoiceControlButtonPressed', {
      'templateId': 'voice',
      'elementId': 'mic',
    });
    expect(pressed, 1);
  });

  test('SVG rasterization reaches state and action button images', () async {
    clearSvgRasterCache();
    final bytes = File('test/fixtures/icon.svg').readAsBytesSync();
    messenger.setMockMessageHandler(
      'flutter/assets',
      (message) async =>
          utf8.decode(message!.buffer.asUint8List()) == 'test/fixtures/icon.svg'
          ? ByteData.sublistView(bytes)
          : null,
    );
    await FlutterCarplay.showVoiceControl(
      template: CPVoiceControlTemplate(
        voiceControlStates: [
          CPVoiceControlState(
            identifier: 'listening',
            image: 'test/fixtures/icon.svg',
            actionButtons: [
              CPButton(image: 'test/fixtures/icon.svg', onPress: () {}),
            ],
          ),
        ],
      ),
    );
    final state = calls.single.arguments['template']['voiceControlStates'][0];
    expect(state['imageData'], isA<Uint8List>());
    expect(state['actionButtons'][0]['imageData'], isA<Uint8List>());
  });
}
