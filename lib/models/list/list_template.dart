import 'package:flutter_carplay/models/button/bar_button.dart';
import 'package:flutter_carplay/models/list/list_section.dart';
import 'package:uuid/uuid.dart';

import '../template.dart';

/// A template that displays and manages a list of items.
/// https://developer.apple.com/documentation/carplay/CPListTemplate
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPListTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// The title that the navigation bar displays when the template is visible
  /// Notes:
  /// - [systemIcon] must be set in order for the title to be displayed in a tab bar.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final String? title;

  /// The sections that the list displays.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final List<CPListSection> sections;

  /// An array of title variants for the template’s empty view.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final List<String>? emptyViewTitleVariants;

  /// An array of subtitle variants for the template’s empty view.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final List<String>? emptyViewSubtitleVariants;

  /// A button to display as the Back button on the navigation bar.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final CPBarButton? backButton;

  /// Creates [CPListTemplate] to display a list of items, grouped into one or more sections.
  /// Each section contains an array of list items — objects that is [CPListItem]
  ///
  /// **Consider that some vehicles limit the number of items that [CPListTemplate] displays.**
  CPListTemplate({
    this.title,
    required this.sections,
    this.emptyViewTitleVariants,
    this.emptyViewSubtitleVariants,
    super.tabTitle,
    super.showsTabBadge = false,
    super.systemIcon,
    this.backButton,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'sections': sections.map((e) => e.toJson()).toList(),
        'emptyViewTitleVariants': emptyViewTitleVariants,
        'emptyViewSubtitleVariants': emptyViewSubtitleVariants,
        'tabTitle': tabTitle,
        'showsTabBadge': showsTabBadge,
        'systemIcon': systemIcon,
        'backButton': backButton?.toJson(),
        'runtimeType': 'FCPListTemplate',
      };

  @override
  String get uniqueId {
    return _elementId;
  }

  void updateSections(List<CPListSection> newSections) {
    final copy = List<CPListSection>.from(newSections);
    sections
      ..clear()
      ..addAll(copy);
  }
}
