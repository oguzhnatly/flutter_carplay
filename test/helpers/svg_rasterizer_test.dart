import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

/// A valid asset path used throughout the tests.
const _svgAssetKey = 'test/fixtures/icon.svg';
const _svgFixtureKeys = <String>[
  _svgAssetKey,
  'test/fixtures/navigation.svg',
  'test/fixtures/media.svg',
  'test/fixtures/warning.svg',
];
const _invalidSvgAssetKey = 'test/fixtures/invalid.svg';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Registers a mock handler on the `flutter/assets` channel that serves the
  /// fixture SVG bytes and malformed bytes for [_invalidSvgAssetKey].
  void mockAssets() {
    final fixtureBytes = <String, Uint8List>{
      for (final key in _svgFixtureKeys) key: File(key).readAsBytesSync(),
    };
    final invalidBytes = Uint8List.fromList('<not-svg>'.codeUnits);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      final validBytes = fixtureBytes[key];
      if (validBytes != null) {
        return ByteData.view(validBytes.buffer);
      }
      if (key == _invalidSvgAssetKey) {
        return ByteData.view(invalidBytes.buffer);
      }
      // Unknown asset -> the real `flutter/assets` channel returns null for a
      // missing asset, which causes the asset bundle to report "not found".
      return null;
    });
  }

  setUp(() {
    mockAssets();
    clearSvgRasterCache();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('isSvgAsset', () {
    test('returns true for an asset SVG path', () {
      expect(isSvgAsset('images/icon.svg'), isTrue);
      expect(isSvgAsset('icon.svg'), isTrue);
      expect(isSvgAsset('assets/foo/bar.SVG'), isTrue);
      expect(isSvgAsset('  images/icon.svg  '), isTrue);
    });

    test('returns false for non-SVG assets', () {
      expect(isSvgAsset('icon.png'), isFalse);
      expect(isSvgAsset('images/icon.jpg'), isFalse);
      expect(isSvgAsset('icon'), isFalse);
    });

    test('returns false for remote URLs', () {
      expect(isSvgAsset('http://example.com/icon.svg'), isFalse);
      expect(isSvgAsset('https://example.com/icon.svg'), isFalse);
      expect(isSvgAsset('HTTPS://example.com/icon.svg'), isFalse);
    });

    test('returns false for empty and null values', () {
      expect(isSvgAsset(''), isFalse);
      expect(isSvgAsset('   '), isFalse);
      expect(isSvgAsset(null), isFalse);
    });
  });

  group('rasterizeSvgAsset', () {
    test('returns non-null PNG bytes for a valid asset SVG', () async {
      final bytes = await rasterizeSvgAsset(_svgAssetKey);
      expect(bytes, isNotNull);
      expect(bytes, isA<Uint8List>());
      expect(bytes!.isNotEmpty, isTrue);
      // PNG signature: 137 80 78 71 13 10 26 10
      expect(
        bytes.sublist(0, 8),
        equals(<int>[137, 80, 78, 71, 13, 10, 26, 10]),
      );
    });

    test('returns PNG bytes for every bundled SVG fixture', () async {
      for (final fixture in _svgFixtureKeys) {
        final bytes = await rasterizeSvgAsset(fixture);
        expect(bytes, isNotNull, reason: fixture);
        expect(
          bytes!.sublist(0, 8),
          equals(<int>[137, 80, 78, 71, 13, 10, 26, 10]),
        );
      }
    });

    test('returns the same cached instance on repeat calls', () async {
      final first = await rasterizeSvgAsset(_svgAssetKey);
      final second = await rasterizeSvgAsset(_svgAssetKey);
      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
    });

    test('caches separately per size', () async {
      final small = await rasterizeSvgAsset(_svgAssetKey, size: 48);
      final large = await rasterizeSvgAsset(_svgAssetKey, size: 64);
      expect(small, isNotNull);
      expect(large, isNotNull);
      expect(identical(small, large), isFalse);
    });

    test('shares a single in-flight operation for concurrent calls', () async {
      // Both calls are issued before either completes, so they must resolve to
      // the exact same bytes instance produced by one rasterization.
      final futures = await Future.wait([
        rasterizeSvgAsset(_svgAssetKey),
        rasterizeSvgAsset(_svgAssetKey),
        rasterizeSvgAsset(_svgAssetKey),
      ]);
      expect(futures[0], isNotNull);
      expect(identical(futures[0], futures[1]), isTrue);
      expect(identical(futures[1], futures[2]), isTrue);
    });

    test('returns null for an invalid SVG', () async {
      final bytes = await rasterizeSvgAsset(_invalidSvgAssetKey);
      expect(bytes, isNull);
    });

    test('returns null for a missing asset', () async {
      final bytes = await rasterizeSvgAsset('does/not/exist.svg');
      expect(bytes, isNull);
    });
  });

  group('resolveSvgInPayload', () {
    test('adds imageData next to an .svg image and preserves the original',
        () async {
      final payload = <String, dynamic>{'image': _svgAssetKey};
      await resolveSvgInPayload(payload);

      expect(payload['image'], _svgAssetKey);
      expect(payload['imageData'], isA<Uint8List>());
    });

    test('adds imageData next to an .svg imageUrl', () async {
      final payload = <String, dynamic>{'imageUrl': _svgAssetKey};
      await resolveSvgInPayload(payload);

      expect(payload['imageUrl'], _svgAssetKey);
      expect(payload['imageData'], isA<Uint8List>());
    });

    test('adds trailingImageData next to an .svg trailingImage', () async {
      final payload = <String, dynamic>{'trailingImage': _svgAssetKey};
      await resolveSvgInPayload(payload);

      expect(payload['trailingImage'], _svgAssetKey);
      expect(payload['trailingImageData'], isA<Uint8List>());
    });

    test('leaves non-SVG image untouched', () async {
      final payload = <String, dynamic>{'image': 'images/icon.png'};
      await resolveSvgInPayload(payload);

      expect(payload['image'], 'images/icon.png');
      expect(payload.containsKey('imageData'), isFalse);
    });

    test('leaves remote SVG image untouched', () async {
      final payload = <String, dynamic>{
        'image': 'https://example.com/icon.svg',
      };
      await resolveSvgInPayload(payload);
      expect(payload.containsKey('imageData'), isFalse);
    });

    test('skips systemIcon, imageTitles, and tint metadata', () async {
      final payload = <String, dynamic>{
        'systemIcon': 'something.svg',
        'imageTitles': <String>['a.svg', 'b.svg'],
        'trailingImageTint': <String, dynamic>{
          'color': 'not-an-image.svg',
        },
      };
      await resolveSvgInPayload(payload);

      expect(payload['systemIcon'], 'something.svg');
      expect(payload.containsKey('imageData'), isFalse);
      expect(payload.containsKey('imageTitlesData'), isFalse);
      expect(payload.containsKey('trailingImageTintData'), isFalse);
    });

    test('adds gridImageData with nulls for non-SVG entries', () async {
      final payload = <String, dynamic>{
        'gridImages': <String>[_svgAssetKey, 'icon.png', _svgAssetKey],
      };
      await resolveSvgInPayload(payload);

      final data = payload['gridImageData'] as List;
      expect(data.length, 3);
      expect(data[0], isA<Uint8List>());
      expect(data[1], isNull);
      expect(data[2], isA<Uint8List>());
      // Originals preserved.
      expect(payload['gridImages'], [_svgAssetKey, 'icon.png', _svgAssetKey]);
    });

    test('does not add gridImageData when no entry is an SVG', () async {
      final payload = <String, dynamic>{
        'gridImages': <String>['a.png', 'b.jpg'],
      };
      await resolveSvgInPayload(payload);
      expect(payload.containsKey('gridImageData'), isFalse);
    });

    test('recurses through deeply nested maps and lists', () async {
      // tabbar -> templates[] -> list -> sections[] -> items[] -> item
      final payload = <String, dynamic>{
        'templates': <dynamic>[
          <String, dynamic>{
            'sections': <dynamic>[
              <String, dynamic>{
                'items': <dynamic>[
                  <String, dynamic>{
                    'text': 'Item 1',
                    'image': _svgAssetKey,
                  },
                  <String, dynamic>{
                    'text': 'Item 2',
                    'image': 'icon.png',
                  },
                ],
              },
            ],
          },
        ],
      };

      await resolveSvgInPayload(payload);

      final items = ((payload['templates'] as List)[0] as Map)['sections'][0]
          ['items'] as List;
      expect((items[0] as Map)['imageData'], isA<Uint8List>());
      expect((items[1] as Map).containsKey('imageData'), isFalse);
    });

    test('resolves nested lists of lists', () async {
      final payload = <dynamic>[
        <dynamic>[
          <String, dynamic>{'image': _svgAssetKey},
        ],
      ];

      await resolveSvgInPayload(payload);

      final item = (payload[0] as List)[0] as Map;
      expect(item['imageData'], isA<Uint8List>());
    });

    test('returns the same node it was given', () async {
      final payload = <String, dynamic>{'image': _svgAssetKey};
      final result = await resolveSvgInPayload(payload);
      expect(identical(result, payload), isTrue);
    });

    test('honors a custom size', () async {
      final payloadSmall = <String, dynamic>{'image': _svgAssetKey};
      final payloadLarge = <String, dynamic>{'image': _svgAssetKey};

      await resolveSvgInPayload(payloadSmall, size: 48);
      await resolveSvgInPayload(payloadLarge, size: 64);

      final small = payloadSmall['imageData'] as Uint8List;
      final large = payloadLarge['imageData'] as Uint8List;
      // Different sizes produce distinct cached instances.
      expect(identical(small, large), isFalse);
    });
  });

  group('does not recurse into image byte data', () {
    test('skips a raw imageData byte payload', () async {
      final spy = _SpyList(<int>[1, 2, 3, 4]);
      final payload = <String, dynamic>{'imageData': spy};

      await resolveSvgInPayload(payload);

      expect(
        spy.iterationCount,
        0,
        reason: 'the walker must treat raw image bytes as an opaque leaf and '
            'never iterate over them',
      );
    });

    test('skips a gridImageData byte list and its entries', () async {
      final inner = _SpyList(<int>[1, 2, 3]);
      final spy = _SpyList(<Object?>[inner, null]);
      final payload = <String, dynamic>{'gridImageData': spy};

      await resolveSvgInPayload(payload);

      expect(spy.iterationCount, 0);
      expect(inner.iterationCount, 0);
    });

    test('skips imageData attached after rasterizing a real .svg image',
        () async {
      // Drive the real flow to attach `imageData`, then swap in a spy (with the
      // `image` key removed so a re-run does not regenerate it) to prove the
      // walker leaves the attached byte payload untouched.
      final payload = <String, dynamic>{'image': _svgAssetKey};
      await resolveSvgInPayload(payload);
      expect(payload['imageData'], isA<Uint8List>());

      final produced = payload['imageData'] as Uint8List;
      payload.remove('image');
      final spy = _SpyList(produced);
      payload['imageData'] = spy;

      await resolveSvgInPayload(payload);

      expect(spy.iterationCount, 0);
    });
  });

  group('configurable raster size', () {
    test('FlutterCarplay default is 120', () {
      expect(FlutterCarplay.svgRasterSize, defaultSvgRasterSize);
      expect(defaultSvgRasterSize, 120);
    });

    test('FlutterAndroidAuto default is 120', () {
      expect(FlutterAndroidAuto.svgRasterSize, defaultSvgRasterSize);
    });
  });
}

/// A [List] spy that records whether the SVG walker iterated over it.
///
/// The walker should treat raw image byte payloads (e.g. the `imageData` /
/// `gridImageData` it attaches) as opaque leaves and never descend into them.
/// Because byte payloads are lists, a walker that recurses into every list
/// value would iterate every entry; this spy makes that observable by counting
/// reads of [iterator].
class _SpyList extends ListBase<Object?> {
  _SpyList(this._delegate);

  final List<Object?> _delegate;

  /// Number of times something started iterating over this list.
  int iterationCount = 0;

  @override
  Iterator<Object?> get iterator {
    iterationCount++;
    return _delegate.iterator;
  }

  @override
  int get length => _delegate.length;

  @override
  set length(int newLength) => _delegate.length = newLength;

  @override
  Object? operator [](int index) => _delegate[index];

  @override
  void operator []=(int index, Object? value) => _delegate[index] = value;
}
