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

  test('rejects CPSearchTemplate as a root template before native call',
      () async {
    var invokedNative = false;
    messenger.setMockMethodCallHandler(_carplayChannel, (call) async {
      invokedNative = true;
      return true;
    });

    await expectLater(
      FlutterCarplay.setRootTemplate(rootTemplate: CPSearchTemplate()),
      throwsA(isA<TypeError>()),
    );

    expect(invokedNative, isFalse);
  });
}
