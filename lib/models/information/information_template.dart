import 'package:uuid/uuid.dart';

import '../button/text_button.dart';
import 'information_item.dart';

/// Enum defining different layouts of information templates.
enum CPInformationTemplateLayout {
  /// The default layout for an information template.
  leading,

  /// The layout for an information template that has two columns of information items and text buttons.
  twoColumn,
}

/// A template object that displays and manages information items and text buttons.
class CPInformationTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title will be shown in the navigation bar.
  final String title;

  /// The layout of the information template.
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
        'title': title,
        'layout': layout.name,
        '_elementId': _elementId,
        'actions': actions.map((e) => e.toJson()).toList(),
        'informationItems': informationItems.map((e) => e.toJson()).toList(),
      };

  String get uniqueId {
    return _elementId;
  }
}
