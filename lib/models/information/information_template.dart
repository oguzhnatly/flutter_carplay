import 'package:uuid/uuid.dart';

import '../../controllers/carplay_controller.dart';
import '../button/bar_button.dart';
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
  List<CPTextButton> actions;

  /// The array of information items  as [CPInformationItem] displayed on the template.
  List<CPInformationItem> informationItems;

  /// Back button object.
  final CPBarButton? backButton;

  /// An array of bar buttons to be displayed on the leading side of the navigation bar.
  List<CPBarButton> leadingNavigationBarButtons;

  /// An array of bar buttons to be displayed on the trailing side of the navigation bar.
  List<CPBarButton> trailingNavigationBarButtons;

  /// Creates [CPInformationTemplate]
  CPInformationTemplate({
    required this.title,
    required this.layout,
    required this.actions,
    required this.informationItems,
    this.leadingNavigationBarButtons = const [],
    this.trailingNavigationBarButtons = const [],
    this.backButton,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'layout': layout.name,
        '_elementId': _elementId,
        'backButton': backButton?.toJson(),
        'actions': actions.map((e) => e.toJson()).toList(),
        'informationItems': informationItems.map((e) => e.toJson()).toList(),
        'leadingNavigationBarButtons':
            leadingNavigationBarButtons.map((e) => e.toJson()).toList(),
        'trailingNavigationBarButtons':
            trailingNavigationBarButtons.map((e) => e.toJson()).toList(),
      };

  /// Update the properties of the [CPInformationTemplate]
  void update({
    List<CPTextButton>? actions,
    List<CPInformationItem>? items,
    List<CPBarButton>? leadingNavigationBarButtons,
    List<CPBarButton>? trailingNavigationBarButtons,
  }) {
    // update items
    if (items != null) informationItems = items;

    // update actions
    if (actions != null) this.actions = actions;

    // update leadingNavigationBarButtons
    if (leadingNavigationBarButtons != null) {
      this.leadingNavigationBarButtons = leadingNavigationBarButtons;
    }

    // update trailingNavigationBarButtons
    if (trailingNavigationBarButtons != null) {
      this.trailingNavigationBarButtons = trailingNavigationBarButtons;
    }

    FlutterCarplayController.updateCPInformationTemplate(this);
  }

  String get uniqueId {
    return _elementId;
  }
}
