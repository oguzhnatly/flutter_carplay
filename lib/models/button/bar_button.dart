import 'package:car_play/helpers/enum_utils.dart';
import 'package:car_play/models/button/alert_constants.dart';
import 'package:uuid/uuid.dart';

/// A button object for placement in a navigation bar.
class CPBarButton {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The title displayed on the bar button.
  final String title;

  /// The style to use when displaying the button.
  /// Default is [CPBarButtonStyles.rounded]
  final CPBarButtonStyles style;

  /// Fired when the user taps a bar button.
  final Function() onPress;

  /// Creates [CPBarButton] with a title, style and handler.
  CPBarButton({
    required this.title,
    this.style = CPBarButtonStyles.rounded,
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
