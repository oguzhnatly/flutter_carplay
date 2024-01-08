import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Enum defining different styles of text buttons in CarPlay.
enum CPTextButtonStyles {
  /// The default style for a text button.
  normal,

  /// The style for a text button that indicates a cancel action.
  cancel,

  /// The style for a text button that indicates a confirm action.
  confirm,
}

/// A button object for placement in a point of interest or information template.
class CPTextButton {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The title displayed on the bar button.
  final String title;

  /// The style to use when displaying the button.
  /// Default is [CPTextButtonStyles.normal]
  final CPTextButtonStyles style;

  /// Fired when the user taps a text button.
  final VoidCallback onPressed;

  /// Creates [CPTextButton]
  CPTextButton({
    required this.title,
    required this.onPressed,
    this.style = CPTextButtonStyles.normal,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'style': style.name,
      };

  String get uniqueId {
    return _elementId;
  }
}
