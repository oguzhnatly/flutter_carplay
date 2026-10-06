import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingListItem extends CPListItem {
  _CountingListItem() : super(image: 'icon.png');
  int sizeWrites = 0;

  @override
  set imageSize(AutoImageSize? value) {
    sizeWrites++;
    super.imageSize = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.oguzhnatly.flutter_carplay');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Completer<MethodCall> received;

  setUp(() {
    received = Completer<MethodCall>();
    FlutterCarplay.iconSize = const AutoImageSize.small();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (!received.isCompleted) received.complete(call);
      return true;
    });
  });

  tearDown(() {
    FlutterCarplay.iconSize = const AutoImageSize.medium();
    messenger.setMockMethodCallHandler(channel, null);
    FlutterCarPlayController.templateHistory.clear();
  });

  test(
    'update persists primary size before sending the channel payload',
    () async {
      final item = CPListItem(
        image: 'icon.png',
        imageSize: const AutoImageSize.small(),
        trailingImage: 'check.png',
      );
      item.update(
        imageSize: const AutoImageSize.max(),
        trailingImageSize: const AutoImageSize.large(),
      );
      final call = await received.future;
      expect(call.method, 'updateListItem');
      expect(item.imageSize, const AutoImageSize.max());
      expect(call.arguments['imageSize'], {'fraction': 1.0});
      expect(call.arguments['trailingImageSize'], {'fraction': 0.85});
    },
  );

  test(
    'size setters reset primary and trailing images to the global size',
    () async {
      final item = CPListItem(image: 'icon.png', trailingImage: 'check.png');
      item.setImageSize(const AutoImageSize.max());
      expect((await received.future).arguments['imageSize'], {'fraction': 1.0});
      received = Completer<MethodCall>();
      item.setImageSize(null);
      expect((await received.future).arguments['imageSize'], {'fraction': 0.5});
      received = Completer<MethodCall>();
      item.setTrailingImage('new.png', imageSize: const AutoImageSize.large());
      expect((await received.future).arguments['trailingImageSize'], {
        'fraction': 0.85,
      });
      received = Completer<MethodCall>();
      item.setTrailingImageSize(null);
      expect((await received.future).arguments['trailingImageSize'], {
        'fraction': 0.5,
      });
      expect(item.imageSize, isNull);
      expect(item.trailingImageSize, isNull);
    },
  );

  test(
    'all image row element setters send overrides and global resets',
    () async {
      final elements = <CPListImageRowItemElement>[
        CPListImageRowItemCardElement(image: 'icon.png'),
        CPListImageRowItemCondensedElement(image: 'icon.png', title: 'a'),
        CPListImageRowItemGridElement(image: 'icon.png'),
        CPListImageRowItemImageGridElement(image: 'icon.png', title: 'a'),
        CPListImageRowItemRowElement(image: 'icon.png'),
      ];
      for (final element in elements) {
        received = Completer<MethodCall>();
        element.setImage('new.png', imageSize: const AutoImageSize.max());
        final update = await received.future;
        expect(update.method, 'updateListImageRowItemElement');
        expect(update.arguments['imageSize'], {'fraction': 1.0});
        received = Completer<MethodCall>();
        element.setImageSize(null);
        expect((await received.future).arguments['imageSize'], {
          'fraction': 0.5,
        });
        expect(element.imageSize, isNull);
      }
    },
  );

  test(
    'channel serialization applies global sizes to nested image rows',
    () async {
      final row = CPListImageRowItem(
        gridImages: ['first.png', 'second.png', 'third.png'],
        gridImageSizes: [null, const AutoImageSize.max()],
      );
      await FlutterCarPlayController.flutterToNativeModule(
        FCPChannelTypes.setRootTemplate,
        {
          'rootTemplate': CPListTemplate(
            sections: [
              CPListSection(items: [row]),
            ],
          ).toJson(),
        },
      );
      final call = await received.future;
      expect(
        call.arguments['rootTemplate']['sections'][0]['items'][0]['gridImageSizes'],
        [
          {'fraction': 0.5},
          {'fraction': 1.0},
          {'fraction': 0.5},
        ],
      );
    },
  );

  test('setImage writes its size once', () async {
    final item = _CountingListItem();
    item.setImage('new.png', imageSize: const AutoImageSize.max());
    await received.future;
    expect(item.sizeWrites, 1);
  });
}
