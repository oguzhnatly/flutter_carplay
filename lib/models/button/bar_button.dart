import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/enum_utils.dart';
import 'alert_constants.dart';

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
  final VoidCallback onPressed;

  /// Creates [CPBarButton] with a title, style and handler.
  CPBarButton({
    required this.title,
    this.style = CPBarButtonStyles.rounded,
    required this.onPressed,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'style': CPEnumUtils.stringFromEnum(style.toString()),
      };

  String get uniqueId {
    return _elementId;
  }
}
