import 'package:uuid/uuid.dart';

import '../template.dart';
import 'alert_action.dart';

/// A template that presents a modal alert on Android Auto.
///
/// Rendered as a full-screen [MessageTemplate] from the Car App Library.
/// Unlike CarPlay, Android Auto does not support true overlay modals, so the
/// alert occupies the entire screen and is pushed onto the navigation stack.
///
/// Use [FlutterAndroidAuto.showAlert] to present it and
/// [FlutterAndroidAuto.popModal] to dismiss it programmatically.
class AAAlertTemplate implements AATemplate {
  final String _elementId;

  /// Primary title shown at the top of the alert.
  final String title;

  /// Optional body message displayed below the title.
  final String? message;

  /// The action buttons available on the alert.
  final List<AAAlertAction> actions;

  /// Called when the alert finishes presenting.
  /// [completed] is true when the alert was shown successfully.
  final Function(bool completed)? onPresent;

  AAAlertTemplate({
    required this.title,
    this.message,
    required this.actions,
    this.onPresent,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  String get uniqueId => _elementId;

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'message': message,
        'actions': actions.map((e) => e.toJson()).toList(),
        'onPresent': onPresent != null,
      };
}
