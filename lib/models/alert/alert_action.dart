import 'package:flutter_carplay/models/alert/alert_constants.dart';
import 'package:uuid/uuid.dart';

/// An object that encapsulates an action the user can perform on an action sheet or alert.
/// https://developer.apple.com/documentation/carplay/cpalertaction
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPAlertAction {
  /// Unique id of the object.
  final String _elementId;

  /// The action button’s title.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final String title;

  /// The display style for the action button.
  /// Default is [CPAlertActionStyle.normal]
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final CPAlertActionStyle style;

  /// The closure that CarPlay invokes after the user taps the action button.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final Function() onPress;

  /// Creates [CPAlertAction]
  CPAlertAction({
    required this.title,
    this.style = CPAlertActionStyle.normal,
    required this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'style': style.name,
      };

  String get uniqueId {
    return _elementId;
  }
}
