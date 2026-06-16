import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

const _carplayChannel = MethodChannel('com.oguzhnatly.flutter_carplay');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(_carplayChannel, null);
  });

  test('allows CPSearchTemplate as a root template', () async {
    MethodCall? capturedCall;
    messenger.setMockMethodCallHandler(_carplayChannel, (call) async {
      capturedCall = call;
      return true;
    });

    await FlutterCarplay.setRootTemplate(rootTemplate: CPSearchTemplate());

    expect(capturedCall, isNotNull);
    expect(capturedCall!.method, 'setRootTemplate');
    final args = capturedCall!.arguments as Map<Object?, Object?>;
    final rootTemplate = args['rootTemplate'] as Map<Object?, Object?>;
    expect(rootTemplate['runtimeType'], 'FCPSearchTemplate');
  });
}
