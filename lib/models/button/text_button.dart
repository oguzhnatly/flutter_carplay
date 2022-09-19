import 'package:uuid/uuid.dart';

enum CPTextButtonStyles {
  normal,
  cancel,
  confirm,
}

class CPTextButtonStylesUtil {
  CPTextButtonStylesUtil._();

  static CPTextButtonStyles parseValue(String value) {
    switch (value) {
      case 'normal':
        return CPTextButtonStyles.normal;
      case 'cancel':
        return CPTextButtonStyles.cancel;
      case 'confirm':
        return CPTextButtonStyles.confirm;
      default:
        throw ArgumentError('$value is not supported');
    }
  }
}

extension CPTextButtonStylesExtension on CPTextButtonStyles {
  String stringValue() {
    switch (this) {
      case CPTextButtonStyles.normal:
        return 'normal';
      case CPTextButtonStyles.cancel:
        return 'cancel';
      case CPTextButtonStyles.confirm:
        return 'confirm';
      default:
        throw ArgumentError('$this is not supported');
    }
  }
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
        "style": style.stringValue(),
      };

  String get uniqueId {
    return _elementId;
  }
}
