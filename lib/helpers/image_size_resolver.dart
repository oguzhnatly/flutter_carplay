import 'package:flutter/foundation.dart';

import 'package:flutter_carplay/models/common/image_size.dart';

/// Image keys paired with the sibling key carrying their [AutoImageSize].
///
/// Mirrors the structure of `svgImageDataKeys` in `svg_rasterizer.dart`. When a
/// model gains a new image-bearing `toJson()` key, register it here too, or it
/// silently loses support for the global `FlutterCarplay.iconSize` default.
const autoImageSizeKeys = <String, String>{
  'image': 'imageSize',
  'imageUrl': 'imageSize',
  'accessoryImage': 'trailingImageSize',
  'trailingImage': 'trailingImageSize',
};

/// Image keys whose values are lists, paired with their sibling size-list key.
const autoImageSizeListKeys = <String, String>{
  'gridImages': 'gridImageSizes',
};

/// The sibling keys this resolver writes. Never recursed into.
final _sizeKeys = <String>{
  ...autoImageSizeKeys.values,
  ...autoImageSizeListKeys.values,
};

/// Fills in the global icon size for any image that did not specify one.
///
/// Native code defaults a missing size to 0.7, so this walker exists purely to
/// let `FlutterCarplay.iconSize` override that default without every model
/// having to reach for global state at construction time. Per-image
/// [AutoImageSize] values already present are left untouched.
///
/// The [node] is mutated in place and also returned for convenience.
dynamic applyDefaultImageSize(dynamic node, AutoImageSize defaultSize) {
  if (node is Map) {
    for (final entry in autoImageSizeKeys.entries) {
      final image = node[entry.key];
      if (image is! String || image.isEmpty) continue;
      if (node[entry.value] == null) {
        node[entry.value] = defaultSize.toJson();
      }
    }

    for (final entry in autoImageSizeListKeys.entries) {
      final images = node[entry.key];
      if (images is! List) continue;
      final existing = node[entry.value];
      final sizes = <Map<String, dynamic>?>[];
      for (var i = 0; i < images.length; i++) {
        final provided =
            existing is List && i < existing.length ? existing[i] : null;
        sizes.add(
          provided is Map<String, dynamic> ? provided : defaultSize.toJson(),
        );
      }
      node[entry.value] = sizes;
    }

    for (final key in node.keys.toList()) {
      if (_sizeKeys.contains(key)) continue;
      final value = node[key];
      // Rasterized SVG bytes are themselves a List<int>; descending into them
      // would walk every individual byte.
      if (value is Uint8List) continue;
      applyDefaultImageSize(value, defaultSize);
    }
  } else if (node is List) {
    for (final item in node) {
      if (item is Uint8List) continue;
      applyDefaultImageSize(item, defaultSize);
    }
  }

  return node;
}
