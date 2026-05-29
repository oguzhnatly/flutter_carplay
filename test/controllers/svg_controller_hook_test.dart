import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_carplay/controllers/android_auto_controller.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

const _svgAssetKey = 'test/fixtures/icon.svg';

const _carplayChannel = MethodChannel('com.oguzhnatly.flutter_carplay');
const _androidAutoChannel =
    MethodChannel('com.oguzhnatly.flutter_android_auto');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Serves the fixture SVG bytes for [_svgAssetKey], null otherwise.
  void mockAssets() {
    final validBytes = File('test/fixtures/icon.svg').readAsBytesSync();
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == _svgAssetKey) {
        return ByteData.view(Uint8List.fromList(validBytes).buffer);
      }
      return null;
    });
  }

  /// Mocks [channel] and records the last `data` argument passed to it,
  /// returning `true` so callers treat the call as successful.
  Map<String, dynamic> capturePayload(MethodChannel channel) {
    final captured = <String, dynamic>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      captured['method'] = call.method;
      captured['arguments'] = call.arguments;
      return true;
    });
    return captured;
  }

  setUp(() {
    mockAssets();
    clearSvgRasterCache();
    FlutterCarplay.svgRasterSize = defaultSvgRasterSize;
    FlutterAndroidAuto.svgRasterSize = defaultSvgRasterSize;
  });

  tearDown(() {
    messenger.setMockMessageHandler('flutter/assets', null);
    messenger.setMockMethodCallHandler(_carplayChannel, null);
    messenger.setMockMethodCallHandler(_androidAutoChannel, null);
  });

  group('carplay_controller flutterToNativeModule', () {
    test('attaches imageData for an .svg image before invokeMethod', () async {
      final captured = capturePayload(_carplayChannel);

      await FlutterCarPlayController.flutterToNativeModule(
        FCPChannelTypes.setRootTemplate,
        <String, dynamic>{
          'rootTemplate': <String, dynamic>{
            'sections': <dynamic>[
              <String, dynamic>{
                'items': <dynamic>[
                  <String, dynamic>{'text': 'a', 'image': _svgAssetKey},
                ],
              },
            ],
          },
        },
      );

      final args = captured['arguments'] as Map;
      final item = (((args['rootTemplate'] as Map)['sections'] as List)[0]
          as Map)['items'][0] as Map;
      expect(item['image'], _svgAssetKey);
      expect(item['imageData'], isA<Uint8List>());
    });

    test('leaves payload unchanged for a non-SVG image', () async {
      final captured = capturePayload(_carplayChannel);

      await FlutterCarPlayController.flutterToNativeModule(
        FCPChannelTypes.updateListItem,
        <String, dynamic>{'text': 'a', 'image': 'images/icon.png'},
      );

      final args = captured['arguments'] as Map;
      expect(args['image'], 'images/icon.png');
      expect(args.containsKey('imageData'), isFalse);
    });

    test('passes through non-collection payloads (e.g. bool)', () async {
      final captured = capturePayload(_carplayChannel);

      await FlutterCarPlayController.flutterToNativeModule(
        FCPChannelTypes.popToRootTemplate,
        true,
      );

      expect(captured['arguments'], isTrue);
    });

    test('uses the global FlutterCarplay.svgRasterSize for the walker',
        () async {
      // Bytes produced at the default size vs. a custom global size must differ,
      // proving the controller forwards the global setting to the walker.
      final defaultBytes = await rasterizeSvgAsset(_svgAssetKey);

      const customSize = 48;
      expect(customSize, isNot(defaultSvgRasterSize));
      FlutterCarplay.svgRasterSize = customSize;

      final captured = capturePayload(_carplayChannel);
      await FlutterCarPlayController.flutterToNativeModule(
        FCPChannelTypes.updateListItem,
        <String, dynamic>{'text': 'a', 'image': _svgAssetKey},
      );

      final args = captured['arguments'] as Map;
      final emitted = args['imageData'] as Uint8List;

      final expected = await rasterizeSvgAsset(_svgAssetKey, size: customSize);
      expect(emitted, equals(expected));
      expect(emitted, isNot(equals(defaultBytes)));
    });
  });

  group('android_auto_controller flutterToNativeModule', () {
    final controller = FlutterAndroidAutoController();

    test('attaches imageData for an .svg imageUrl before invokeMethod',
        () async {
      final captured = capturePayload(_androidAutoChannel);

      await controller.flutterToNativeModule(
        FAAChannelTypes.setRootTemplate,
        <String, dynamic>{
          'template': <String, dynamic>{
            'sections': <dynamic>[
              <String, dynamic>{
                'items': <dynamic>[
                  <String, dynamic>{'title': 'a', 'imageUrl': _svgAssetKey},
                ],
              },
            ],
          },
        },
      );

      final args = captured['arguments'] as Map;
      final item = (((args['template'] as Map)['sections'] as List)[0]
          as Map)['items'][0] as Map;
      expect(item['imageUrl'], _svgAssetKey);
      expect(item['imageData'], isA<Uint8List>());
    });

    test('leaves payload unchanged for a non-SVG imageUrl', () async {
      final captured = capturePayload(_androidAutoChannel);

      await controller.flutterToNativeModule(
        FAAChannelTypes.pushTemplate,
        <String, dynamic>{'title': 'a', 'imageUrl': 'https://x/icon.png'},
      );

      final args = captured['arguments'] as Map;
      expect(args['imageUrl'], 'https://x/icon.png');
      expect(args.containsKey('imageData'), isFalse);
    });

    test('uses the global FlutterAndroidAuto.svgRasterSize for the walker',
        () async {
      final defaultBytes = await rasterizeSvgAsset(_svgAssetKey);

      const customSize = 64;
      expect(customSize, isNot(defaultSvgRasterSize));
      FlutterAndroidAuto.svgRasterSize = customSize;

      final captured = capturePayload(_androidAutoChannel);
      await controller.flutterToNativeModule(
        FAAChannelTypes.pushTemplate,
        <String, dynamic>{'title': 'a', 'imageUrl': _svgAssetKey},
      );

      final args = captured['arguments'] as Map;
      final emitted = args['imageData'] as Uint8List;

      final expected = await rasterizeSvgAsset(_svgAssetKey, size: customSize);
      expect(emitted, equals(expected));
      expect(emitted, isNot(equals(defaultBytes)));
    });
  });
}
