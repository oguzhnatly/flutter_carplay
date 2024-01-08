import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Enum defining different styles of alert actions in CarPlay.
enum CPAlertActionStyles {
  /// The default style for an alert action.
  normal,

  /// The style for an alert action that cancels an alert.
  cancel,

  /// The style for an alert action that indicates a destructive action.
  destructive,
}

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
  final VoidCallback onPressed;

  /// Creates [CPAlertAction]
  CPAlertAction({
    required this.title,
    required this.onPressed,
    this.style = CPAlertActionStyles.normal,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'style': style.name,
      };

  String get uniqueId {
    return _elementId;
  }
}
