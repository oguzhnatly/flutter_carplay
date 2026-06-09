import 'package:flutter_carplay/models/common/image_tint.dart';
import 'package:uuid/uuid.dart';

class AAPaneAction {
  /// Unique id of the object.
  final String _elementId;

  final String title;

  /// Optional icon displayed with this pane action on Android Auto.
  ///
  /// Supports the same formats as [AAPaneItem.imageUrl], including Flutter
  /// asset SVGs rasterized before the payload is sent to native Android.
  final String? imageUrl;
  final AutoImageTint? imageTint;
  final bool isPrimary;
  final Function()? onPress;

  AAPaneAction({
    required this.title,
    this.imageUrl,
    this.imageTint,
    this.isPrimary = false,
    this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'imageUrl': imageUrl,
        'imageTint': imageTint?.toJson(),
        'isPrimary': isPrimary,
        'onPress': onPress != null,
      };
}
