import 'package:uuid/uuid.dart';

import '../button/text_button.dart';
import '../template.dart';
import 'information_constants.dart';
import 'information_item.dart';

/// A template object that displays and manages information items and text buttons.
/// https://developer.apple.com/documentation/carplay/cpinformationtemplate
/// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
class CPInformationTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// The template’s title.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final String title;

  /// The layout that the template uses to arrange its items.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final CPInformationTemplateLayout layout;

  /// The actions that the template displays.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final List<CPTextButton> actions;

  /// An array of information items that the template displays.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final List<CPInformationItem> informationItems;

  /// Creates [CPInformationTemplate]
  CPInformationTemplate({
    required this.title,
    required this.layout,
    required this.actions,
    required this.informationItems,
    super.tabTitle,
    super.showsTabBadge = false,
    super.systemIcon,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'layout': layout.name,
        'title': title,
        'actions': actions.map((e) => e.toJson()).toList(),
        'informationItems': informationItems.map((e) => e.toJson()).toList(),
        'tabTitle': tabTitle,
        'showsTabBadge': showsTabBadge,
        'systemIcon': systemIcon,
        'runtimeType': 'FCPInformationTemplate',
      };

  @override
  String get uniqueId {
    return _elementId;
  }

  void updateInformationItems(List<CPInformationItem> newItems) {
    final copy = List<CPInformationItem>.from(newItems);
    informationItems
      ..clear()
      ..addAll(copy);
  }

  void updateActions(List<CPTextButton> newActions) {
    final copy = List<CPTextButton>.from(newActions);
    actions
      ..clear()
      ..addAll(copy);
  }
}
