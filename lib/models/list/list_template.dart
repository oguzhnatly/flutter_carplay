import 'package:uuid/uuid.dart';

import '../../controllers/carplay_controller.dart';
import '../button/bar_button.dart';
import 'list_section.dart';

/// A template object that displays and manages a list of items.
class CPListTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title displayed in the navigation bar.
  /// It will be displayed when only the list template is visible.
  final String? title;

  /// An array of list sections as [CPListSection], each can contain zero or more list items.
  List<CPListSection> sections;

  /// An optional array of title variants for the template’s empty view.
  /// Provide the strings as localized displayable content and order from most- to
  /// least- preferred. When there are no items in the list, the template displays
  /// an empty view with a title and a subtitle in place of the items. If you update
  /// the list and provide items, the template automatically removes the empty view.
  List<String> emptyViewTitleVariants;

  /// An optional array of subtitle variants for the template’s empty view.
  /// Provide the strings as localized displayable content and order from most- to
  /// least- preferred. When there are no items in the list, the template displays
  /// an empty view with a title and a subtitle in place of the items. If you update
  /// the list and provide items, the template automatically removes the empty view.
  List<String> emptyViewSubtitleVariants;

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
  final String? systemIcon;

  /// Back button object
  final CPBarButton? backButton;

  /// An array of bar buttons to be displayed on the leading side of the navigation bar.
  List<CPBarButton> leadingNavigationBarButtons;

  /// An array of bar buttons to be displayed on the trailing side of the navigation bar.
  List<CPBarButton> trailingNavigationBarButtons;

  /// Creates [CPListTemplate] to display a list of items, grouped into one or more sections.
  /// Each section contains an array of list items — objects that is [CPListItem]
  ///
  /// **Consider that some vehicles limit the number of items that [CPListTemplate] displays.**
  CPListTemplate({
    required this.sections,
    this.title,
    this.systemIcon,
    this.backButton,
    this.showsTabBadge = false,
    this.emptyViewTitleVariants = const [],
    this.emptyViewSubtitleVariants = const [],
    this.leadingNavigationBarButtons = const [],
    this.trailingNavigationBarButtons = const [],
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'sections': sections.map((e) => e.toJson()).toList(),
        'emptyViewTitleVariants': emptyViewTitleVariants,
        'emptyViewSubtitleVariants': emptyViewSubtitleVariants,
        'leadingNavigationBarButtons':
            leadingNavigationBarButtons.map((e) => e.toJson()).toList(),
        'trailingNavigationBarButtons':
            trailingNavigationBarButtons.map((e) => e.toJson()).toList(),
        'showsTabBadge': showsTabBadge,
        'systemIcon': systemIcon,
        'backButton': backButton?.toJson(),
      };

  /// Update the properties of the [CPListTemplate]
  void update({
    List<CPListSection>? sections,
    List<String>? emptyViewTitleVariants,
    List<String>? emptyViewSubtitleVariants,
    List<CPBarButton>? leadingNavigationBarButtons,
    List<CPBarButton>? trailingNavigationBarButtons,
  }) {
    // update sections
    if (sections != null) this.sections = sections;

    // update emptyViewTitleVariants
    if (emptyViewTitleVariants != null) {
      this.emptyViewTitleVariants = emptyViewTitleVariants;
    }

    // update emptyViewSubtitleVariants
    if (emptyViewSubtitleVariants != null) {
      this.emptyViewSubtitleVariants = emptyViewSubtitleVariants;
    }

    // update leadingNavigationBarButtons
    if (leadingNavigationBarButtons != null) {
      this.leadingNavigationBarButtons = leadingNavigationBarButtons;
    }

    // update trailingNavigationBarButtons
    if (trailingNavigationBarButtons != null) {
      this.trailingNavigationBarButtons = trailingNavigationBarButtons;
    }

    FlutterCarplayController.updateCPListTemplate(this);
  }

  String get uniqueId {
    return _elementId;
  }
}
