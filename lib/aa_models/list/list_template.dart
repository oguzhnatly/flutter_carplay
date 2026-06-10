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

  /// Icon displayed in the tab when this template is used inside an
  /// [AATabBarTemplate]. Supports mapped system icon names, Flutter assets,
  /// local files, and network URLs.
  ///
  /// When [iconUrl] is also set, [iconUrl] takes precedence.
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
    String? id,
  })  : assert(
          _hasValidSelectableList(sections),
          'A selectable AAListSection must be the only section in an '
          'AAListTemplate and must not have a title.',
        ),
        _elementId = id ?? const Uuid().v4();

  @override
  String get uniqueId => _elementId;

  static bool _hasValidSelectableList(List<AAListSection> sections) {
    final selectableSections = sections.where(
      (AAListSection section) => section.isSelectable,
    );
    if (selectableSections.isEmpty) return true;

    return sections.length == 1 &&
        (selectableSections.single.title == null ||
            selectableSections.single.title!.isEmpty);
  }

  static void _validateSelectableList(List<AAListSection> sections) {
    assert(
      _hasValidSelectableList(sections),
      'A selectable AAListSection must be the only section in an '
      'AAListTemplate and must not have a title.',
    );
  }

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

  void updateSections(List<AAListSection> newSections) {
    _validateSelectableList(newSections);
    final copy = List<AAListSection>.from(newSections);
    sections
      ..clear()
      ..addAll(copy);
  }
}
