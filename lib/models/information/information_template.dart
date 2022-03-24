import 'package:flutter_carplay/models/button/text_button.dart';
import 'package:flutter_carplay/helpers/enum_utils.dart';
import 'information_constants.dart';
import 'information_item.dart';


import 'package:uuid/uuid.dart';

/// A template object that displays and manages information items and text buttons.
class CPInformationTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title will be shown in the navigation bar.
  final String title;

  final CPInformationTemplateLayout layout;

  /// The array of actions as [CPTextButton] displayed on the template.
  final List<CPTextButton> actions;

  /// The array of information items  as [CPInformationItem] displayed on the template.

  final List<CPInformationItem> informationItems;


  /// Creates [CPInformationTemplate]
  CPInformationTemplate({
    required this.title,
    required this.layout,
    required this.actions,
    required this.informationItems,
  });

  Map<String, dynamic> toJson() => {
    "_elementId": _elementId,
    "layout": CPEnumUtils.stringFromEnum(layout.toString()),
    "title": title,
    "actions": actions.map((e) => e.toJson()).toList(),
    "informationItems": informationItems.map((e) => e.toJson()).toList(),
  };

  String get uniqueId {
    return _elementId;
  }
}
