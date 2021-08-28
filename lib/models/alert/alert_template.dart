import 'package:flutter_carplay/models/alert/alert_action.dart';
import 'package:uuid/uuid.dart';

/// A template object that displays a modal alert.
class CPAlertTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The array of title variants.
  /// When the system displays the alert, it selects the title that best fits
  /// the available screen space, so arrange the titles from most to least preferred
  /// when creating an alert template. Also, localize each title for display to the user,
  /// and **be sure to include at least one title in the array.**
  final List<String> titleVariants;

  /// The array of actions as [CPAlertAction] will be available on the alert.
  final List<CPAlertAction> actions;

  /// Fired when the alert presented to CarPlay. With this callback function, it can be
  /// determined whether an error was encountered while presenting, or if it was successfully opened,
  /// with the [bool] completed data in it.
  ///
  /// If completed is true, the alert successfully presented. If not, you may want to show an error to the user.
  final Function(bool completed)? onPresent;

  /// Creates [CPAlertTemplate]
  CPAlertTemplate({
    required this.titleVariants,
    required this.actions,
    this.onPresent,
  });

  Map<String, dynamic> toJson() => {
        "_elementId": _elementId,
        "titleVariants": titleVariants,
        "actions": actions.map((e) => e.toJson()).toList(),
        "onPresent": onPresent != null ? true : false,
      };

  String get uniqueId {
    return _elementId;
  }
}
