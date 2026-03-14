import 'package:flutter_carplay/models/alert/alert_action.dart';
import 'package:uuid/uuid.dart';

import '../template.dart';

/// A template that displays a modal alert.
/// https://developer.apple.com/documentation/carplay/cpalerttemplate
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPAlertTemplate extends CPTemplate implements CPActionsTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// The array of title variants.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final List<String> titleVariants;

  /// The array of actions available on the alert.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  @override
  final List<CPAlertAction> actions;

  /// The closure that CarPlay invokes after the user taps the action button.
  /// Notes:
  /// - If completed is true, the alert successfully presented. If not, you may want to show an error to the user.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final Function(bool completed)? onPresent;

  /// Creates [CPAlertTemplate]
  CPAlertTemplate({
    required this.titleVariants,
    required this.actions,
    this.onPresent,
    super.tabTitle,
    super.showsTabBadge = false,
    super.systemIcon,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'titleVariants': titleVariants,
        'actions': actions.map((e) => e.toJson()).toList(),
        'onPresent': onPresent != null ? true : false,
        'tabTitle': tabTitle,
        'showsTabBadge': showsTabBadge,
        'systemIcon': systemIcon,
        'runtimeType': 'FCPAlertTemplate',
      };

  @override
  String get uniqueId {
    return _elementId;
  }
}
