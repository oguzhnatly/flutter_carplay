import 'package:uuid/uuid.dart';

import '../../flutter_carplay.dart';
import '../../helpers/carplay_helper.dart';

/// A template object that displays a modal alert.
class CPAlertTemplate extends CPPresentTemplate {
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

  /// Creates [CPAlertTemplate]
  CPAlertTemplate({
    required this.titleVariants,
    required this.actions,
    super.isDismissible,
    super.routeName,
    super.onPresent,
    super.onPop,
  });

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'onPresent': onPresent != null,
        'onPop': onPop != null,
        'titleVariants': titleVariants,
        'actions': actions.map((e) => e.toJson()).toList(),
      };

  @override
  String get uniqueId {
    return _elementId;
  }

  @override
  bool hasSameValues(CPTemplate other) {
    return other is CPAlertTemplate &&
        FlutterCarplayHelper().compareLists(
          titleVariants,
          other.titleVariants,
          (a, b) => a == b,
        ) &&
        FlutterCarplayHelper().compareLists(actions, other.actions, (a, b) => a.hasSameValues(b));
  }
}
