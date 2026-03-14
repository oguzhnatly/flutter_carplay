import 'package:uuid/uuid.dart';

import 'button_constants.dart';

/// A button that displays a stylized title.
/// https://developer.apple.com/documentation/carplay/CPTextButton
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPTextButton {
  /// Unique id of the object.
  final String _elementId;

  /// The text the button displays.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final String title;

  /// The text style the button applies to its title.
  /// Default is [CPTextButtonStyle.normal]
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final CPTextButtonStyle textstyle;

  /// A closure that CarPlay invokes when the user taps the button.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final Function() onPress;

  /// Creates [CPTextButton]
  CPTextButton({
    required this.title,
    this.textstyle = CPTextButtonStyle.normal,
    required this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'textstyle': textstyle.name,
        'runtimeType': 'FCPTextButton',
      };

  String get uniqueId {
    return _elementId;
  }
}
