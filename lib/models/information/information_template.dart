import 'package:uuid/uuid.dart';

import '../../helpers/carplay_helper.dart';
import '../button/bar_button.dart';
import '../button/text_button.dart';
import '../template.dart';
import 'information_item.dart';

/// Enum defining different layouts of information templates.
enum CPInformationTemplateLayout {
  /// The default layout for an information template.
  leading,

  /// The layout for an information template that has two columns of information items and text buttons.
  twoColumn,
}

/// A template object that displays and manages information items and text buttons.
class CPInformationTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// A title will be shown in the navigation bar.
  final String title;

  /// The layout of the information template.
  final CPInformationTemplateLayout layout;

  /// The array of actions as [CPTextButton] displayed on the template.
  final List<CPTextButton> actions;

  /// The array of information items  as [CPInformationItem] displayed on the template.
  final List<CPInformationItem> informationItems;

  /// Back button object.
  final CPBarButton? backButton;

  /// An array of bar buttons to be displayed on the leading side of the navigation bar.
  final List<CPBarButton> leadingNavigationBarButtons;

  /// An array of bar buttons to be displayed on the trailing side of the navigation bar.
  final List<CPBarButton> trailingNavigationBarButtons;

  /// Creates [CPInformationTemplate]
  CPInformationTemplate({
    required this.title,
    this.layout = CPInformationTemplateLayout.leading,
    this.informationItems = const [],
    this.actions = const [],
    this.leadingNavigationBarButtons = const [],
    this.trailingNavigationBarButtons = const [],
    this.backButton,
  }) : _elementId = const Uuid().v4();

  CPInformationTemplate._internal(
    this._elementId, {
    required this.title,
    required this.layout,
    required this.informationItems,
    required this.actions,
    required this.leadingNavigationBarButtons,
    required this.trailingNavigationBarButtons,
    required this.backButton,
  });

  /// Creates a copy of the current [CPInformationTemplate] instance with updated properties.
  CPInformationTemplate copyWith({
    String? title,
    CPInformationTemplateLayout? layout,
    List<CPTextButton>? actions,
    List<CPInformationItem>? informationItems,
    List<CPBarButton>? leadingNavigationBarButtons,
    List<CPBarButton>? trailingNavigationBarButtons,
    CPBarButton? backButton,
  }) {
    return CPInformationTemplate._internal(
      _elementId,
      title: title ?? this.title,
      layout: layout ?? this.layout,
      informationItems: informationItems ?? this.informationItems,
      actions: actions ?? this.actions,
      leadingNavigationBarButtons: leadingNavigationBarButtons ?? this.leadingNavigationBarButtons,
      trailingNavigationBarButtons: trailingNavigationBarButtons ?? this.trailingNavigationBarButtons,
      backButton: backButton ?? this.backButton,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'layout': layout.name,
        '_elementId': _elementId,
        'backButton': backButton?.toJson(),
        'actions': actions.map((e) => e.toJson()).toList(),
        'informationItems': informationItems.map((e) => e.toJson()).toList(),
        'leadingNavigationBarButtons': leadingNavigationBarButtons.map((e) => e.toJson()).toList(),
        'trailingNavigationBarButtons': trailingNavigationBarButtons.map((e) => e.toJson()).toList(),
      };

  @override
  String get uniqueId {
    return _elementId;
  }

  @override
  bool hasSameValues(CPTemplate other) {
    if (runtimeType != other.runtimeType) return false;
    other as CPInformationTemplate;

    return title == other.title &&
        layout == other.layout &&
        FlutterCarplayHelper().compareLists(informationItems, other.informationItems, (a, b) => a.hasSameValues(b)) &&
        FlutterCarplayHelper().compareLists(actions, other.actions, (a, b) => a.hasSameValues(b)) &&
        _compareButton(backButton, other.backButton) &&
        FlutterCarplayHelper().compareLists(
          other.leadingNavigationBarButtons,
          leadingNavigationBarButtons,
          (a, b) => a.hasSameValues(b),
        ) &&
        FlutterCarplayHelper().compareLists(
          other.trailingNavigationBarButtons,
          trailingNavigationBarButtons,
          (a, b) => a.hasSameValues(b),
        );
  }

  bool _compareButton(CPBarButton? button, CPBarButton? otherButton) {
    if (otherButton == null && button == null) return true;
    if (otherButton == null || button == null) return false;

    return otherButton.hasSameValues(button);
  }
}
