import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// Default raster size (in logical pixels, square) used when an SVG asset is
/// rasterized to PNG bytes for native consumption.
///
/// This can be overridden globally via [FlutterCarplay.svgRasterSize] /
/// [FlutterAndroidAuto.svgRasterSize], which are forwarded to
/// [resolveSvgInPayload].
const defaultSvgRasterSize = 120;

/// In-memory cache of rasterized SVG assets keyed by `assetPath|size`.
final _svgRasterCache = <String, Uint8List>{};

/// In-flight rasterization operations keyed by `assetPath|size`. Concurrent
/// requests for the same asset/size share a single operation instead of
/// rasterizing the same SVG multiple times.
final _svgRasterInflight = <String, Future<Uint8List?>>{};

/// Clears the in-memory rasterized SVG cache.
///
/// Primarily intended for tests, but safe to call at any time.
@visibleForTesting
void clearSvgRasterCache() => _svgRasterCache.clear();

/// Returns `true` when [value] points to a Flutter asset SVG.
///
/// Two conditions must hold: the value ends with `.svg` (case-insensitive) and
/// it is not a remote (`http`/`https`) URL.
bool isSvgAsset(String? value) {
  final lower = value?.trim().toLowerCase();
  if (lower == null) return false;
  return lower.endsWith('.svg') && !lower.startsWith('http');
}

/// Rasterizes the Flutter asset SVG at [assetPath] into PNG bytes.
///
/// The output is a square image of [size] x [size] logical pixels. Results are
/// cached in-memory keyed by `assetPath|size`, so repeated calls return the
/// same [Uint8List] instance. Concurrent calls for the same asset/size share a
/// single in-flight operation.
///
/// Returns `null` when the asset cannot be loaded or rasterized (e.g. invalid
/// SVG, missing asset).
Future<Uint8List?> rasterizeSvgAsset(
  String assetPath, {
  int size = defaultSvgRasterSize,
}) {
  final cacheKey = '$assetPath|$size';

  final cached = _svgRasterCache[cacheKey];
  if (cached != null) return Future.value(cached);

  final inflight = _svgRasterInflight[cacheKey];
  if (inflight != null) return inflight;

  final operation = _rasterize(assetPath, size, cacheKey);
  _svgRasterInflight[cacheKey] = operation;
  return operation.whenComplete(() => _svgRasterInflight.remove(cacheKey));
}

/// Performs the actual rasterization for [rasterizeSvgAsset].
Future<Uint8List?> _rasterize(
  String assetPath,
  int size,
  String cacheKey,
) async {
  try {
    // Load the asset bytes ourselves (rather than via [SvgAssetLoader]) so that
    // a missing asset surfaces here as a catchable error instead of going
    // through flutter_svg's asset cache.
    final assetData = await rootBundle.load(assetPath);
    final svgString = utf8.decode(assetData.buffer.asUint8List());

    final loader = SvgStringLoader(svgString);
    final pictureInfo = await vg.loadPicture(loader, null);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final pictureSize = pictureInfo.size;
      final sourceWidth = pictureSize.width.isFinite && pictureSize.width > 0
          ? pictureSize.width
          : size.toDouble();
      final sourceHeight = pictureSize.height.isFinite && pictureSize.height > 0
          ? pictureSize.height
          : size.toDouble();

      // Scale uniformly to fit within the target square while preserving the
      // aspect ratio, then center within the [size] x [size] canvas.
      final scale = (size / sourceWidth) < (size / sourceHeight)
          ? size / sourceWidth
          : size / sourceHeight;
      final dx = (size - sourceWidth * scale) / 2;
      final dy = (size - sourceHeight * scale) / 2;

      canvas.translate(dx, dy);
      canvas.scale(scale);
      canvas.drawPicture(pictureInfo.picture);

      final rendered = recorder.endRecording();
      final image = await rendered.toImage(size, size);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return null;
        final bytes = byteData.buffer.asUint8List();
        _svgRasterCache[cacheKey] = bytes;
        return bytes;
      } finally {
        image.dispose();
        rendered.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  } catch (error, stackTrace) {
    debugPrint('flutter_carplay: failed to rasterize SVG "$assetPath": $error');
    debugPrintStack(stackTrace: stackTrace);
    return null;
  }
}

/// Default suffix appended to an image key to form the sibling key that carries
/// the rasterized PNG bytes (e.g. `image` -> `imageData`).
const _dataKeySuffix = 'Data';

/// Describes a single payload key that may hold an SVG asset reference.
///
/// Each descriptor maps a model's `toJson()` key (the value emitted by a model)
/// to how its rasterized bytes should be attached. Keeping these as explicit,
/// documented descriptors avoids the previous stringly-typed maps and makes the
/// model -> walker relationship auditable (see the coverage test).
@immutable
class SvgImageKey {
  const SvgImageKey(this.key, {required this.isList, String? dataKey})
      : _dataKey = dataKey;

  /// A descriptor for a key holding a single image asset string.
  ///
  /// [dataKey] defaults to `<key>Data`.
  const SvgImageKey.single(String key, {String? dataKey})
      : this(key, isList: false, dataKey: dataKey);

  /// A descriptor for a key holding a `List<String>` of image asset strings.
  ///
  /// [dataKey] defaults to `<key>Data`.
  const SvgImageKey.list(String key, {String? dataKey})
      : this(key, isList: true, dataKey: dataKey);

  /// The payload key emitted by a model's `toJson()`.
  final String key;

  /// Whether [key] holds a list of asset strings (vs. a single string).
  final bool isList;

  /// Explicit sibling-key override, or `null` to use `<key>Data`.
  final String? _dataKey;

  /// The sibling key that receives the rasterized bytes.
  String get dataKey => _dataKey ?? '$key$_dataKeySuffix';
}

/// Every payload key that may reference a Flutter asset SVG, paired with how the
/// rasterized bytes are attached.
///
/// This is the single source of truth for the walker. When a model gains a new
/// image-bearing `toJson()` key, add it here. The coverage test
/// (`test/helpers/svg_rasterizer_coverage_test.dart`) asserts that every model
/// image key is represented here so new keys cannot silently slip through.
///
/// Models emitting these keys:
/// - `image`     -> CPListItem, CPGridButton, CPPointOfInterest, and all
///                  CPListImageRowItem*Element subtypes. Bytes are attached
///                  under `imageData`.
/// - `imageUrl`  -> AAListItem (Android Auto). The native contract expects the
///                  bytes under `imageData`.
/// - `gridImages`-> CPListImageRowItem (legacy iOS grid images); the native
///                  contract expects the bytes under `gridImageData`.
@visibleForTesting
const svgImageKeys = <SvgImageKey>[
  SvgImageKey.single('image'),
  SvgImageKey.single('imageUrl', dataKey: 'imageData'),
  SvgImageKey.list('gridImages', dataKey: 'gridImageData'),
];

/// Keys that look image-related but must never be rasterized.
///
/// - `systemIcon`  -> CPTemplate tab image (resolved natively as an SF Symbol /
///                    tab image, not an asset SVG we rasterize).
/// - `imageTitles` -> CPListImageRowItem labels (text, not images).
@visibleForTesting
const svgIgnoredKeys = <String>{'systemIcon', 'imageTitles'};

/// The sibling keys under which the walker attaches rasterized bytes (e.g.
/// `imageData`, `gridImageData`). These hold raw byte payloads, so the walker
/// must never recurse into them.
final _svgDataKeys = <String>{for (final k in svgImageKeys) k.dataKey};

/// Recursively walks a method-channel [node] (maps/lists), rasterizing any
/// Flutter asset SVG referenced by an image-bearing key (see [svgImageKeys])
/// and attaching the PNG bytes to a sibling `<key>Data` key.
///
/// Behavior:
/// - A single-image key (e.g. `image`, `imageUrl`) whose value is an SVG asset
///   -> sibling `<key>Data` ([Uint8List]).
/// - A list-image key (e.g. `gridImages`) -> sibling `<key>Data`
///   (`List<Uint8List?>`, `null` for non-SVG entries).
/// - Keys in [svgIgnoredKeys] are skipped entirely (never rasterized, never
///   recursed into).
/// - Original image strings are preserved for native fallback / back-compat.
///
/// The [node] is mutated in place and also returned for convenience.
Future<dynamic> resolveSvgInPayload(
  dynamic node, {
  int size = defaultSvgRasterSize,
}) async {
  if (node is Map) {
    for (final imageKey in svgImageKeys) {
      final value = node[imageKey.key];
      if (imageKey.isList) {
        if (value is! List) continue;
        var hasSvg = false;
        final data = <Uint8List?>[];
        for (final item in value) {
          final bytes = await _rasterizeIfSvg(item, size);
          data.add(bytes);
          if (bytes != null) hasSvg = true;
        }
        if (hasSvg) node[imageKey.dataKey] = data;
      } else {
        final bytes = await _rasterizeIfSvg(value, size);
        if (bytes != null) node[imageKey.dataKey] = bytes;
      }
    }

    // Recurse into all values, skipping ignored keys and the byte payloads we
    // just attached. The latter are raster bytes ([Uint8List], which is itself
    // a `List<int>`) or lists of them; descending into those would needlessly
    // walk every individual byte.
    for (final key in node.keys.toList()) {
      if (svgIgnoredKeys.contains(key)) continue;
      if (_svgDataKeys.contains(key)) continue;
      final value = node[key];
      if (value is Uint8List) continue;
      await resolveSvgInPayload(value, size: size);
    }
  } else if (node is List) {
    for (final item in node) {
      if (item is Uint8List) continue;
      await resolveSvgInPayload(item, size: size);
    }
  }

  return node;
}

/// Returns rasterized PNG bytes when [value] is a Flutter asset SVG string,
/// otherwise `null`.
Future<Uint8List?> _rasterizeIfSvg(dynamic value, int size) {
  if (value is String && isSvgAsset(value)) {
    return rasterizeSvgAsset(value, size: size);
  }
  return Future.value();
}
