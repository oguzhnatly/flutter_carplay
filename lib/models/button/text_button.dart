import 'package:flutter_carplay/helpers/enum_utils.dart';
import 'package:uuid/uuid.dart';


enum CPTextButtonStyles {
  normal,
  cancel,
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
  final Function() onPress;

  /// Creates [CPTextButton] with a title, style and handler.
  CPTextButton({
    required this.title,
    this.style = CPTextButtonStyles.normal,
    required this.onPress,
  });

  Map<String, dynamic> toJson() => {
    "_elementId": _elementId,
    "title": title,
    "style": CPEnumUtils.stringFromEnum(style.toString()),
  };

  String get uniqueId {
    return _elementId;
  }
}
