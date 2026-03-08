import 'package:flutter_carplay/models/alert/alert_action.dart';
import 'package:uuid/uuid.dart';

import '../template.dart';

/// A template that displays a modal action sheet.
/// https://developer.apple.com/documentation/carplay/cpactionsheettemplate
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPActionSheetTemplate extends CPTemplate implements CPActionsTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// The title of the action sheet.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final String? title;

  /// The descriptive message providing details about the reason for displaying the action sheet.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final String? message;

  /// The list of actions available on the action sheet.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  @override
  final List<CPAlertAction> actions;

  /// Creates [CPActionSheetTemplate]
  CPActionSheetTemplate({
    this.title,
    this.message,
    required this.actions,
    super.tabTitle,
    super.showsTabBadge = false,
    super.systemIcon,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'message': message,
        'actions': actions.map((e) => e.toJson()).toList(),
        'tabTitle': tabTitle,
        'showsTabBadge': showsTabBadge,
        'systemIcon': systemIcon,
        'runtimeType': 'FCPActionSheetTemplate',
      };

  @override
  String get uniqueId {
    return _elementId;
  }
}
