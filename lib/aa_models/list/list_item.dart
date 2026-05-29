import 'package:uuid/uuid.dart';

class AAListItem {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final String? subtitle;

  /// The image displayed for this row on Android Auto.
  ///
  /// Supports these formats:
  /// - **Asset path**: `images/flutter_logo.png` (from pubspec.yaml assets)
  /// - **SVG asset**: `images/icon.svg` (rasterized to PNG before being sent to
  ///   the native side; remote/`file://` SVGs are not supported)
  /// - **File path**: `file:///path/to/image.png` (local file on device)
  /// - **Network URL**: `https://example.com/image.png` (remote image)
  final String? imageUrl;
  final Function(Function() complete, AAListItem self)? onPress;

  AAListItem({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'onPress': onPress != null ? true : false,
      };
}
