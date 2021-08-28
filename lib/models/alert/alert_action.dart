import 'package:flutter_carplay/helpers/enum_utils.dart';
import 'package:flutter_carplay/models/alert/alert_constants.dart';
import 'package:uuid/uuid.dart';

/// An object that encapsulates an action the user can take on [CPActionSheetTemplate] or [CPAlertTemplate].
class CPAlertAction {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The action button's title.
  final String title;

  /// The display style for the action button.
  /// Default is [CPAlertActionStyles.normal]
  final CPAlertActionStyles style;

  /// A callback function that CarPlay invokes after the user taps the action button.
  final Function() onPress;

  /// Creates [CPAlertAction] with a title, style, and action handler.
  CPAlertAction({
    required this.title,
    this.style = CPAlertActionStyles.normal,
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
