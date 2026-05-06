import 'package:uuid/uuid.dart';

import '../template.dart';
import 'grid_button.dart';

/// A template that displays a grid of tappable cells on Android Auto.
///
/// Rendered as [GridTemplate] from the Car App Library. Android Auto
/// recommends a maximum of 8 buttons per grid.
///
/// When used as a tab inside an [AATabBarTemplate], the tab label is taken
/// from [tabTitle] (falling back to [title]). An optional tab icon can be
/// provided via [systemIcon] or [iconUrl].
class AAGridTemplate implements AATemplate {
  /// Unique id of the object.
  final String _elementId;

  /// Title displayed in the header of the template.
  final String title;

  /// The grid cells. Android Auto recommends a maximum of 8 items.
  final List<AAGridButton> buttons;

  /// Messages displayed when [buttons] is empty.
  ///
  /// Android Auto uses the first element as the text passed to
  /// `ItemList.Builder.setNoItemsMessage()`. When [buttons] is empty and
  /// this list is null or empty, the template shows a loading indicator.
  final List<String>? emptyViewTitleVariants;

  /// Label displayed on the tab bar item when this template is used as a tab
  /// inside an [AATabBarTemplate]. Falls back to [title] when not set.
  final String? tabTitle;

  /// SF Symbol / icon name used to resolve a [CarIcon] for the tab bar item.
  /// Common names such as "map", "house", "star" are mapped to Car App
  /// Library built-in icons. Unknown names fall back to a default.
  final String? systemIcon;

  /// URL of an image to use as the tab bar icon. Loaded asynchronously.
  /// Takes precedence over [systemIcon] when both are set.
  final String? iconUrl;

  AAGridTemplate({
    required this.title,
    required this.buttons,
    this.emptyViewTitleVariants,
    this.tabTitle,
    this.systemIcon,
    this.iconUrl,
  }) : _elementId = const Uuid().v4();

  @override
  String get uniqueId => _elementId;

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'buttons': buttons.map((b) => b.toJson()).toList(),
        'emptyViewTitleVariants': emptyViewTitleVariants,
        'tabTitle': tabTitle,
        'systemIcon': systemIcon,
        'iconUrl': iconUrl,
      };
}
