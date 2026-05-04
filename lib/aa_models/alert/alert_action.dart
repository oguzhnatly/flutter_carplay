import 'package:uuid/uuid.dart';

/// Display styles for an alert action button on Android Auto.
enum AAAlertActionStyle { normal, cancel, destructive }

/// An action that can be performed from an [AAAlertTemplate] on Android Auto.
class AAAlertAction {
  final String _elementId;

  /// The button label.
  final String title;

  /// Visual style hint for the button.
  final AAAlertActionStyle style;

  /// Called when the user taps this action.
  final Function() onPress;

  AAAlertAction({
    required this.title,
    this.style = AAAlertActionStyle.normal,
    required this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'style': style.name,
      };
}
