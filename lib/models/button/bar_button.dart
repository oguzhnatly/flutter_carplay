import 'package:uuid/uuid.dart';

import 'button_constants.dart';

/// A button for placement in a navigation bar.
/// https://developer.apple.com/documentation/carplay/cpbarbutton
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPBarButton {
  /// Unique id of the object.
  final String _elementId;

  /// The title displayed on the bar button.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final String title;

  /// The style to use when displaying the button.
  /// Default is [CPBarButtonStyle.rounded]
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final CPBarButtonStyle buttonStyle;

  /// A block that CarPlay calls when the user taps a bar button.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final Function() onPress;

  /// Creates [CPBarButton]
  CPBarButton({
    required this.title,
    this.buttonStyle = CPBarButtonStyle.rounded,
    required this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'buttonStyle': buttonStyle.name,
      };

  String get uniqueId {
    return _elementId;
  }
}
