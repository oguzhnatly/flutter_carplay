import 'package:flutter_carplay/models/button/bar_button.dart';
import 'package:flutter_carplay/models/list/list_section.dart';
import 'package:uuid/uuid.dart';

/// A template object that displays and manages a list of items.
class CPListTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title displayed in the navigation bar.
  /// It will be displayed when only the list template is visible.
  final String? title;

  /// An array of list sections as [CPListSection], each can contain zero or more list items.
  final List<CPListSection> sections;

  /// An optional array of title variants for the template’s empty view.
  /// Provide the strings as localized displayable content and order from most- to
  /// least- preferred. When there are no items in the list, the template displays
  /// an empty view with a title and a subtitle in place of the items. If you update
  /// the list and provide items, the template automatically removes the empty view.
  final List<String>? emptyViewTitleVariants;

  /// An optional array of subtitle variants for the template’s empty view.
  /// Provide the strings as localized displayable content and order from most- to
  /// least- preferred. When there are no items in the list, the template displays
  /// an empty view with a title and a subtitle in place of the items. If you update
  /// the list and provide items, the template automatically removes the empty view.
  final List<String>? emptyViewSubtitleVariants;

  /// An indicator you use to call attention to the tab. When it is true, a small
  /// red indicator will be displayed on the tab in order to show user that it requires
  /// an action or you received an notification e.g.
  ///
  /// CarPlay only displays the red indicator when the template is a root-template
  /// of a tab bar, otherwise setting this property has no effect.
  final bool showsTabBadge;

  /// A system icon which will be used in a image that represents the content of the tab.
  ///
  /// SF Symbols provides a set of over 3,100 consistent, highly configurable symbols you can
  /// use in your app. Apple designed SF Symbols to integrate seamlessly with the San Francisco
  /// system font, so the symbols automatically align with text in all weights and sizes.
  ///
  /// **See**:
  /// - [SF Symbols Apple Website](https://developer.apple.com/sf-symbols/)
  /// - [SF Symbols - Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/)
  ///
  /// **IMPORTANT:**
  /// All SF Symbols shall be considered to be system-provided images as defined in the Xcode and Apple SDKs
  /// license agreements and are subject to the terms and conditions set forth therein. You may not use SF
  /// Symbols—or glyphs that are substantially or confusingly similar—in your app icons, logos, or any other
  /// trademark-related use. Apple reserves the right to review and, in its sole discretion, require modification
  /// or discontinuance of use of any Symbol used in violation of the foregoing restrictions, and you agree to
  /// promptly comply with any such request.
  final String systemIcon;

  /// Back button object
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
    this.showsTabBadge = false,
    required this.systemIcon,
    this.backButton,
  });

  Map<String, dynamic> toJson() => {
        "_elementId": _elementId,
        "title": title,
        "sections": sections.map((e) => e.toJson()).toList(),
        "emptyViewTitleVariants": emptyViewTitleVariants,
        "emptyViewSubtitleVariants": emptyViewSubtitleVariants,
        "showsTabBadge": showsTabBadge,
        "systemIcon": systemIcon,
        "backButton": backButton?.toJson(),
      };

  String get uniqueId {
    return _elementId;
  }
}
