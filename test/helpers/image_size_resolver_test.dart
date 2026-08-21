import 'dart:typed_data';

import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaultSize = AutoImageSize.medium();
  final defaultJson = defaultSize.toJson();

  group('applyDefaultImageSize', () {
    test('stamps the default onto an image that has none', () {
      final payload = <String, dynamic>{'image': 'images/icon.png'};

      applyDefaultImageSize(payload, defaultSize);

      expect(payload['imageSize'], defaultJson);
    });

    test('leaves a per-image size untouched', () {
      final explicit = const AutoImageSize.small().toJson();
      final payload = <String, dynamic>{
        'image': 'images/icon.png',
        'imageSize': explicit,
      };

      applyDefaultImageSize(payload, defaultSize);

      expect(payload['imageSize'], explicit);
    });

    test('does not invent a size when there is no image', () {
      final payload = <String, dynamic>{'text': 'no image here'};

      applyDefaultImageSize(payload, defaultSize);

      expect(payload.containsKey('imageSize'), isFalse);
    });

    test('ignores an empty image string', () {
      final payload = <String, dynamic>{'image': ''};

      applyDefaultImageSize(payload, defaultSize);

      expect(payload['imageSize'], isNull);
    });

    test('maps trailing and accessory images onto trailingImageSize', () {
      final trailing = <String, dynamic>{'trailingImage': 'images/check.svg'};
      final accessory = <String, dynamic>{'accessoryImage': 'images/check.svg'};

      applyDefaultImageSize(trailing, defaultSize);
      applyDefaultImageSize(accessory, defaultSize);

      expect(trailing['trailingImageSize'], defaultJson);
      expect(accessory['trailingImageSize'], defaultJson);
    });

    test('fills gridImageSizes index-aligned, keeping provided entries', () {
      final explicit = const AutoImageSize.max().toJson();
      final payload = <String, dynamic>{
        'gridImages': ['a.svg', 'b.svg', 'c.svg'],
        'gridImageSizes': [null, explicit],
      };

      applyDefaultImageSize(payload, defaultSize);

      expect(payload['gridImageSizes'], [defaultJson, explicit, defaultJson]);
    });

    test('reaches images nested deep inside a real template payload', () {
      final payload = CPTabBarTemplate(
        templates: [
          CPListTemplate(
            sections: [
              CPListSection(
                items: [
                  CPListItem(text: 'a', image: 'images/icon.svg'),
                ],
              ),
            ],
          ),
          CPGridTemplate(
            title: 'grid',
            buttons: [
              CPGridButton(titleVariants: ['x'], image: 'images/icon.svg'),
            ],
          ),
        ],
      ).toJson();

      applyDefaultImageSize(payload, defaultSize);

      final listItem =
          payload['templates'][0]['sections'][0]['items'][0] as Map;
      final gridButton = payload['templates'][1]['buttons'][0] as Map;
      expect(listItem['imageSize'], defaultJson);
      expect(gridButton['imageSize'], defaultJson);
    });

    test('does not descend into rasterized byte payloads', () {
      final payload = <String, dynamic>{
        'image': 'images/icon.svg',
        'imageData': Uint8List.fromList([1, 2, 3]),
      };

      applyDefaultImageSize(payload, defaultSize);

      expect(payload['imageData'], isA<Uint8List>());
      expect((payload['imageData'] as Uint8List).length, 3);
    });
  });

  group('size key coverage', () {
    /// Guards against the same drift the SVG walker test guards against: a model
    /// that gains an image key the resolver does not know about silently loses
    /// support for the global `FlutterCarplay.iconSize`.
    final knownImageKeys = <String>{
      ...autoImageSizeKeys.keys,
      ...autoImageSizeListKeys.keys,
    };

    test('every image key the SVG walker rasterizes also carries a size', () {
      expect(
        svgImageDataKeys.keys.toSet().difference(knownImageKeys),
        isEmpty,
        reason: 'An image key is rasterized but has no size mapping. Add it to '
            'autoImageSizeKeys or autoImageSizeListKeys in '
            'lib/helpers/image_size_resolver.dart.',
      );
    });

    test('size keys are registered as ignored by the SVG walker', () {
      final sizeKeys = <String>{
        ...autoImageSizeKeys.values,
        ...autoImageSizeListKeys.values,
      };
      expect(svgIgnoredKeys, containsAll(sizeKeys));
    });

    test('CPListItem emits both size keys', () {
      final json = CPListItem(
        text: 'a',
        image: 'images/icon.svg',
        trailingImage: 'images/check.svg',
      ).toJson();

      applyDefaultImageSize(json, defaultSize);

      expect(json['imageSize'], defaultJson);
      expect(json['trailingImageSize'], defaultJson);
    });

    test('CPGridButton honours a per-button size', () {
      final json = CPGridButton(
        titleVariants: ['a'],
        image: 'images/icon.svg',
        imageSize: const AutoImageSize.small(),
      ).toJson();

      applyDefaultImageSize(json, defaultSize);

      expect(json['imageSize'], const AutoImageSize.small().toJson());
    });

    test('CPListImageRowItem gets one size per grid image', () {
      final json = CPListImageRowItem(
        text: 'a',
        gridImages: const ['images/icon.svg', 'images/other.svg'],
      ).toJson();

      applyDefaultImageSize(json, defaultSize);

      expect(json['gridImageSizes'], [defaultJson, defaultJson]);
    });
  });

  group('AutoImageSize', () {
    test('presets are ordered small < medium < large < max', () {
      const sizes = [
        AutoImageSize.small(),
        AutoImageSize.medium(),
        AutoImageSize.large(),
        AutoImageSize.max(),
      ];
      for (var i = 1; i < sizes.length; i++) {
        expect(sizes[i].fraction, greaterThan(sizes[i - 1].fraction));
      }
      expect(sizes.last.fraction, 1.0);
    });

    test('serializes to a fraction', () {
      expect(const AutoImageSize.fraction(0.42).toJson(), {'fraction': 0.42});
    });

    test('compares by fraction', () {
      expect(const AutoImageSize.fraction(0.7), const AutoImageSize.medium());
    });
  });
}
