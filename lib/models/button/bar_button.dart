import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Enum defining different styles of bar buttons in CarPlay.
enum CPBarButtonStyles {
  /// The default style for a bar button.
  none,

  /// The style for a bar button that has rounded corners.
  rounded,
}

/// A button object for placement in a navigation bar.
class CPBarButton {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The title displayed on the bar button.
  final String? title;

  /// The image displayed on the bar button.
  final String? image;

  /// The enabled state of the bar button.
  final bool isEnabled;

  /// The style to use when displaying the button.
  /// Default is [CPBarButtonStyles.rounded]
  final CPBarButtonStyles style;

  /// Fired when the user taps a bar button.
  final VoidCallback onPressed;

  /// Creates [CPBarButton]
  CPBarButton({
    required this.onPressed,
    this.style = CPBarButtonStyles.rounded,
    this.isEnabled = true,
    this.image,
    this.title,
  })  : assert(
          image != null || title != null,
          "Properties [image] and [title] both can't be null at the same time.",
        ),
        assert(
          image == null || title == null,
          "Properties [image] and [title] both can't be set at the same time.",
        );

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        '_elementId': _elementId,
        if (title != null) 'title': title,
        if (image != null) 'image': image,
        'style': style.name,
      };

  /// Creates a copy of this object but with the given fields replaced with new values.
  CPBarButton copyWith({
    String? title,
    String? image,
    bool? isEnabled,
    CPBarButtonStyles? style,
    VoidCallback? onPressed,
  }) {
    return CPBarButton(
      title: title ?? this.title,
      image: image ?? this.image,
      style: style ?? this.style,
      onPressed: onPressed ?? this.onPressed,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  String get uniqueId {
    return _elementId;
  }
}
