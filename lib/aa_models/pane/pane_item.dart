import 'package:flutter_carplay/models/common/image_tint.dart';
import 'package:uuid/uuid.dart';

class AAPaneItem {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final String? detail;

  /// The image displayed for this informational row on Android Auto.
  ///
  /// Supports these formats:
  /// - **Asset path**: `images/flutter_logo.png` (from pubspec.yaml assets)
  /// - **SVG asset**: `images/icon.svg` (rasterized to PNG before being sent to
  ///   the native side; remote/`file://` SVGs are not supported)
  /// - **File path**: `file:///path/to/image.png` (local file on device)
  /// - **Network URL**: `https://example.com/image.png` (remote image)
  final String? imageUrl;
  final AutoImageTint? imageTint;

  AAPaneItem({
    required this.title,
    this.detail,
    this.imageUrl,
    this.imageTint,
    String? id,
  })  : assert(title.isNotEmpty, 'AAPaneItem.title cannot be empty'),
        _elementId = id ?? const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'detail': detail,
        'imageUrl': imageUrl,
        'imageTint': imageTint?.toJson(),
      };
}
