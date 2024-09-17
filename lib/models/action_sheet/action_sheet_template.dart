import 'package:uuid/uuid.dart';

import '../../flutter_carplay.dart';
import '../../helpers/carplay_helper.dart';

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

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'message': message,
        'actions': actions.map((e) => e.toJson()).toList(),
      };

  @override
  String get uniqueId {
    return _elementId;
  }

  @override
  bool hasSameValues(CPTemplate other) {
    return other is CPActionSheetTemplate && title == other.title &&
        message == other.message &&
        FlutterCarplayHelper().compareLists(actions, other.actions, (a, b) => a.hasSameValues(b));
  }
}
