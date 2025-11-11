import 'package:flutter_carplay/helpers/enum_utils.dart';
import 'package:flutter_carplay/models/button/text_button.dart';
import 'package:uuid/uuid.dart';

import '../template.dart';
import 'information_constants.dart';
import 'information_item.dart';

/// A template object that displays and manages information items and text buttons.
class CPInformationTemplate implements CPTemplate {
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

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'layout': EnumUtils.stringFromEnum(layout.toString()),
        'title': title,
        'actions': actions.map((e) => e.toJson()).toList(),
        'informationItems': informationItems.map((e) => e.toJson()).toList(),
      };

  @override
  String get uniqueId {
    return _elementId;
  }
}
