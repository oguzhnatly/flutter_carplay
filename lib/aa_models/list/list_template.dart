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
  /// [AATabBarTemplate]. Supports three formats:
  ///
  /// - System icon name (e.g., "star", "map") — mapped to a
  /// built-in [CarIcon] from the Car App Library.
  /// - Flutter asset (e.g., "images/logo.png") — loaded via the
  /// APK AssetManager.
  /// - Local file (e.g., "file:///path/to/icon.png") — read from disk.
  /// - Network URL (e.g., "https://example.com/icon.png") — downloaded asynchronously.
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
