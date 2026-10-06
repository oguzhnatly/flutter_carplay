import 'package:flutter/services.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final controller = FlutterCarPlayController();
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    calls.clear();
    FlutterCarPlayController.templateHistory = [];
    messenger.setMockMethodCallHandler(controller.methodChannel, (call) async {
      calls.add(call);
      return true;
    });
  });
  tearDown(() {
    FlutterCarPlayController.templateHistory = [];
    messenger.setMockMethodCallHandler(controller.methodChannel, null);
  });

  test('rejects two competing callbacks', () {
    expect(
      () => CPGridButton(
        titleVariants: ['x'],
        image: 'x',
        onPress: () {},
        onPressWithCompletion: (complete, self) {},
      ),
      throwsArgumentError,
    );
  });

  test('completion callback owns loading after its future returns', () async {
    late Future<void> Function() finish;
    late CPGridButton button;
    button = CPGridButton(
      titleVariants: ['x'],
      image: 'x',
      onPressWithCompletion: (complete, self) async {
        expect(identical(self, button), isTrue);
        finish = complete;
      },
    );
    FlutterCarPlayController.templateHistory = [
      CPGridTemplate(title: 'x', buttons: [button]),
    ];
    await controller.processFCPGridButtonPressed(
      button.uniqueId,
      pressId: 'press-1',
    );
    expect(calls, isEmpty);
    await finish();
    await finish();
    expect(calls.length, 1);
    expect(calls.single.arguments, {
      'elementId': button.uniqueId,
      'pressId': 'press-1',
    });
  });

  test('handler NoSuchMethodError is not a second dispatch', () async {
    var presses = 0;
    final button = CPGridButton(
      titleVariants: ['x'],
      image: 'x',
      onPressWithCompletion: (complete, self) {
        presses++;
        throw NoSuchMethodError.withInvocation(
          Object(),
          Invocation.method(#missing, []),
        );
      },
    );
    FlutterCarPlayController.templateHistory = [
      CPGridTemplate(title: 'x', buttons: [button]),
    ];
    await controller.processFCPGridButtonPressed(button.uniqueId);
    expect(presses, 1);
    expect(calls.length, 1);
  });

  test('completion followed by an exception completes once', () async {
    final button = CPGridButton(
      titleVariants: ['x'],
      image: 'x',
      onPressWithCompletion: (complete, self) async {
        await complete();
        throw StateError('failed after completion');
      },
    );
    FlutterCarPlayController.templateHistory = [
      CPGridTemplate(title: 'x', buttons: [button]),
    ];
    await controller.processFCPGridButtonPressed(button.uniqueId);
    expect(calls.length, 1);
  });

  test('unknown event still completes the native interaction', () async {
    await controller.processFCPGridButtonPressed(
      'removed',
      pressId: 'old-press',
    );
    expect(calls.single.arguments, {
      'elementId': 'removed',
      'pressId': 'old-press',
    });
  });

  test('legacy zero argument callback runs in a tab bar grid', () async {
    var presses = 0;
    final button = CPGridButton(
      titleVariants: ['Legacy'],
      image: 'icon.png',
      onPress: () {
        presses++;
      },
    );
    FlutterCarPlayController.templateHistory = [
      CPTabBarTemplate(
        templates: [
          CPListTemplate(title: 'List', sections: []),
          CPGridTemplate(title: 'Grid', buttons: [button]),
        ],
      ),
    ];
    await controller.processFCPGridButtonPressed(button.uniqueId);
    expect(presses, 1);
  });
}
