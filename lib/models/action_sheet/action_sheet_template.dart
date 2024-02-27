import 'package:uuid/uuid.dart';

import '../alert/alert_action.dart';
import '../present_template.dart';

/// A template object that displays a modal action sheet.
class CPActionSheetTemplate extends CPPresentTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The title of the action sheet.
  final String? title;

  /// The descriptive message providing details about the reason for displaying the action sheet.
  final String? message;

  /// The list of actions as [CPAlertAction] available on the action sheet.
  final List<CPAlertAction> actions;

  /// Creates [CPActionSheetTemplate]
  CPActionSheetTemplate({
    required this.actions,
    super.isDismissible,
    super.routeName,
    this.message,
    this.title,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'message': message,
        'actions': actions.map((e) => e.toJson()).toList(),
      };

  String get uniqueId {
    return _elementId;
  }
}
