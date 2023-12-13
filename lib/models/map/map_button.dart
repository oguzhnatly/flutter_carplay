import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// A button object for placement in a map.
class CPMapButton {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  final bool isEnabled;
  final bool isHidden;
  final String? image;
  final String? focusedImage;

  /// Fired when the user taps a map button.
  final VoidCallback onPressed;

  /// Creates [CPMapButton] with a title, style and handler.
  CPMapButton({
    required this.onPressed,
    this.isEnabled = true,
    this.isHidden = false,
    this.focusedImage,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'isEnabled': isEnabled,
        'isHidden': isHidden,
        'image': image,
        'focusedImage': focusedImage,
      };

  String get uniqueId {
    return _elementId;
  }
}
