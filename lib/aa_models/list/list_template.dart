import 'package:uuid/uuid.dart';

import '../template.dart';
import 'list_section.dart';

class AAListTemplate implements AATemplate {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final List<AAListSection> sections;

  /// An array of title variants displayed when the list is empty.
  ///
  /// Android Auto uses the first element as the message passed to
  /// `ItemList.Builder.setNoItemsMessage()`. When [sections] is empty and
  /// this list is null, the template falls back to a loading indicator.
  final List<String>? emptyViewTitleVariants;

  /// Label displayed on the tab bar item when this template is used as a tab
  /// inside an [AATabBarTemplate]. Falls back to [title] when not set.
  final String? tabTitle;

  /// SF Symbol / icon name used to resolve a [CarIcon] for the tab bar item.
  /// Common names such as "map", "house", "magnifyingglass" are mapped to
  /// Car App Library built-in icons. Unknown names fall back to a default.
  final String? systemIcon;

  /// URL of an image to use as the tab bar icon. Loaded asynchronously.
  /// Takes precedence over [systemIcon] when set.
  final String? iconUrl;

  AAListTemplate({
    required this.title,
    required this.sections,
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
        'sections':
            sections.map((AAListSection section) => section.toJson()).toList(),
        'emptyViewTitleVariants': emptyViewTitleVariants,
        'tabTitle': tabTitle,
        'systemIcon': systemIcon,
        'iconUrl': iconUrl,
      };
}
