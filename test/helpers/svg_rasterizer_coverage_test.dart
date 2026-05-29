import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards against silent drift between the models and the SVG walker.
///
/// The walker ([resolveSvgInPayload]) only knows about image keys declared in
/// [svgImageKeys] (rasterized) or [svgIgnoredKeys] (deliberately skipped). If a
/// model gains a new image-bearing `toJson()` key that isn't registered in
/// either, SVG support would silently break for it. This test serializes real
/// model instances and asserts every image-like key they emit is accounted for.
void main() {
  /// Keys known to the walker (rasterized or deliberately ignored).
  final knownKeys = <String>{
    ...svgImageKeys.map((k) => k.key),
    ...svgIgnoredKeys,
  };

  /// All sibling data keys the walker can write, which must never be flagged as
  /// unhandled image keys themselves.
  final dataKeys = svgImageKeys.map((k) => k.dataKey).toSet();

  /// Heuristic: a key is "image-like" if it references an image/icon asset.
  /// Excludes booleans/enums/shape descriptors that merely contain "image".
  bool isImageLikeKey(String key) {
    if (dataKeys.contains(key)) return false;
    const nonAssetImageKeys = <String>{
      'imageShape', // enum name, not an asset
      'showsImageFullHeight', // bool
    };
    if (nonAssetImageKeys.contains(key)) return false;
    final lower = key.toLowerCase();
    return lower.contains('image') || lower.contains('icon');
  }

  /// Recursively collects every map key found in [node].
  Set<String> collectKeys(dynamic node) {
    final keys = <String>{};
    if (node is Map) {
      for (final entry in node.entries) {
        keys.add(entry.key.toString());
        keys.addAll(collectKeys(entry.value));
      }
    } else if (node is List) {
      for (final item in node) {
        keys.addAll(collectKeys(item));
      }
    }
    return keys;
  }

  /// Asserts that every image-like key emitted by [json] is known to the walker.
  void expectAllImageKeysHandled(String label, Map<String, dynamic> json) {
    final imageKeys = collectKeys(json).where(isImageLikeKey).toSet();
    final unhandled = imageKeys.difference(knownKeys);
    expect(
      unhandled,
      isEmpty,
      reason: '$label emits image key(s) $unhandled that the SVG walker does '
          'not handle. Add them to svgImageKeys or svgIgnoredKeys in '
          'lib/helpers/svg_rasterizer.dart.',
    );
  }

  group('SVG walker key coverage', () {
    test('svgImageKeys and svgIgnoredKeys do not overlap', () {
      final imageKeySet = svgImageKeys.map((k) => k.key).toSet();
      expect(imageKeySet.intersection(svgIgnoredKeys), isEmpty);
    });

    test('CPListItem image key is handled', () {
      expectAllImageKeysHandled(
        'CPListItem',
        CPListItem(text: 'a', image: 'images/icon.svg').toJson(),
      );
    });

    test('CPGridButton image key is handled', () {
      expectAllImageKeysHandled(
        'CPGridButton',
        CPGridButton(
          titleVariants: ['a'],
          image: 'images/icon.svg',
        ).toJson(),
      );
    });

    test('CPPointOfInterest image key is handled', () {
      expectAllImageKeysHandled(
        'CPPointOfInterest',
        CPPointOfInterest(
          latitude: 0,
          longitude: 0,
          title: 'a',
          image: 'images/icon.svg',
        ).toJson(),
      );
    });

    test('CPListImageRowItem image keys are handled', () {
      expectAllImageKeysHandled(
        'CPListImageRowItem',
        CPListImageRowItem(
          text: 'a',
          gridImages: const ['images/icon.svg'],
        ).toJson(),
      );
    });

    test('AAListItem imageUrl key is handled', () {
      expectAllImageKeysHandled(
        'AAListItem',
        AAListItem(title: 'a', imageUrl: 'images/icon.svg').toJson(),
      );
    });

    test('a full nested CarPlay tab bar payload is fully handled', () {
      final tabBar = CPTabBarTemplate(
        templates: [
          CPListTemplate(
            sections: [
              CPListSection(
                items: [
                  CPListItem(text: 'a', image: 'images/icon.svg'),
                  CPListImageRowItem(
                    text: 'b',
                    gridImages: const ['images/icon.svg'],
                  ),
                ],
              ),
            ],
          ),
          CPGridTemplate(
            title: 'grid',
            buttons: [
              CPGridButton(
                titleVariants: ['x'],
                image: 'images/icon.svg',
              ),
            ],
          ),
        ],
      );

      expectAllImageKeysHandled('CPTabBarTemplate', tabBar.toJson());
    });

    test('systemIcon is registered as ignored, not rasterized', () {
      expect(svgIgnoredKeys, contains('systemIcon'));
      final imageKeyNames = svgImageKeys.map((k) => k.key).toSet();
      expect(imageKeyNames, isNot(contains('systemIcon')));
    });

    test('imageTitles is registered as ignored, not rasterized', () {
      expect(svgIgnoredKeys, contains('imageTitles'));
    });
  });
}
