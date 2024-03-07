import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// A button object for placement in a map.
class CPMapButton {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The enabled state of the map button.
  final bool isEnabled;

  /// The hidden state of the map button.
  final bool isHidden;

  /// The image displayed on the map button.
  final String? image;

  /// The image displayed on the focused map button.
  final String? focusedImage;

  /// Tint color of the button.
  final int? tintColor;

  /// Fired when the user taps a map button.
  final VoidCallback onPressed;

  /// Creates [CPMapButton]
  CPMapButton({
    required this.onPressed,
    this.isEnabled = true,
    this.isHidden = false,
    this.focusedImage,
    this.tintColor,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'focusedImage': focusedImage,
        '_elementId': _elementId,
        'isEnabled': isEnabled,
        'tintColor': tintColor,
        'isHidden': isHidden,
        'image': image,
      };

  String get uniqueId {
    return _elementId;
  }
}
