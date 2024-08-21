import 'package:uuid/uuid.dart';

import '../../controllers/carplay_controller.dart';
import '../../flutter_carplay.dart';
import '../../helpers/carplay_helper.dart';

/// A template object that displays and manages a list of items.
class CPListTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId;

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
  final List<String> emptyViewTitleVariants;

  /// An optional array of subtitle variants for the template’s empty view.
  /// Provide the strings as localized displayable content and order from most- to
  /// least- preferred. When there are no items in the list, the template displays
  /// an empty view with a title and a subtitle in place of the items. If you update
  /// the list and provide items, the template automatically removes the empty view.
  final List<String> emptyViewSubtitleVariants;

  /// An indicator you use to call attention to the tab. When it is true, a small
  /// red indicator will be displayed on the tab in order to show user that it requires
  /// an action or you received an notification e.g.
  ///
  /// CarPlay only displays the red indicator when the template is a root-template
  /// of a tab bar, otherwise setting this property has no effect.
  final bool showsTabBadge;

  /// A Boolean value that indicates whether the template is currently loading.
  ///
  /// Available only for Android Auto.
  final bool isLoading;

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
  final List<CPBarButton> leadingNavigationBarButtons;

  /// An array of bar buttons to be displayed on the trailing side of the navigation bar.
  final List<CPBarButton> trailingNavigationBarButtons;

  /// Creates [CPListTemplate] to display a list of items, grouped into one or more sections.
  /// Each section contains an array of list items — objects that is [CPListItem]
  ///
  /// **Consider that some vehicles limit the number of items that [CPListTemplate] displays.**
  CPListTemplate({
    this.sections = const [],
    this.title,
    this.systemIcon,
    this.backButton,
    this.isLoading = false,
    this.showsTabBadge = false,
    this.emptyViewTitleVariants = const [],
    this.emptyViewSubtitleVariants = const [],
    this.leadingNavigationBarButtons = const [],
    this.trailingNavigationBarButtons = const [],
  }) : _elementId = const Uuid().v4();

  /// Private named constructor used internally for copying instances.
  CPListTemplate._internal(
    this._elementId, {
    this.title,
    this.sections = const [],
    this.systemIcon,
    this.backButton,
    this.isLoading = false,
    this.showsTabBadge = false,
    this.emptyViewTitleVariants = const [],
    this.emptyViewSubtitleVariants = const [],
    this.leadingNavigationBarButtons = const [],
    this.trailingNavigationBarButtons = const [],
  });

  /// Creates a copy of the current [CPListTemplate] instance with updated properties.
  CPListTemplate copyWith({
    String? title,
    List<CPListSection>? sections,
    List<String>? emptyViewTitleVariants,
    List<String>? emptyViewSubtitleVariants,
    List<CPBarButton>? leadingNavigationBarButtons,
    List<CPBarButton>? trailingNavigationBarButtons,
    bool? showsTabBadge,
    bool? isLoading,
    String? systemIcon,
    CPBarButton? backButton,
  }) {
    return CPListTemplate._internal(
      _elementId,
      title: title ?? this.title,
      sections: sections ?? this.sections,
      emptyViewTitleVariants: emptyViewTitleVariants ?? this.emptyViewTitleVariants,
      emptyViewSubtitleVariants: emptyViewSubtitleVariants ?? this.emptyViewSubtitleVariants,
      leadingNavigationBarButtons: leadingNavigationBarButtons ?? this.leadingNavigationBarButtons,
      trailingNavigationBarButtons: trailingNavigationBarButtons ?? this.trailingNavigationBarButtons,
      showsTabBadge: showsTabBadge ?? this.showsTabBadge,
      isLoading: isLoading ?? this.isLoading,
      systemIcon: systemIcon ?? this.systemIcon,
      backButton: backButton ?? this.backButton,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'sections': sections.map((e) => e.toJson()).toList(),
        'emptyViewTitleVariants': emptyViewTitleVariants,
        'emptyViewSubtitleVariants': emptyViewSubtitleVariants,
        'leadingNavigationBarButtons': leadingNavigationBarButtons.map((e) => e.toJson()).toList(),
        'trailingNavigationBarButtons': trailingNavigationBarButtons.map((e) => e.toJson()).toList(),
        'showsTabBadge': showsTabBadge,
        'isLoading': isLoading,
        'systemIcon': systemIcon,
        'backButton': backButton?.toJson(),
      };


  @override
  String get uniqueId {
    return _elementId;
  }

  @override
  bool hasSameValues(CPTemplate other) {
    if (runtimeType != other.runtimeType) return false;
    other as CPListTemplate;

    return title == other.title &&
        FlutterCarplayHelper().compareLists(other.sections, sections, (a, b) => a.hasSameValues(b)) &&
        FlutterCarplayHelper().compareLists(other.emptyViewTitleVariants, emptyViewTitleVariants, (a, b) => a == b) &&
        FlutterCarplayHelper()
            .compareLists(other.emptyViewSubtitleVariants, emptyViewSubtitleVariants, (a, b) => a == b) &&
        showsTabBadge == other.showsTabBadge &&
        isLoading == other.isLoading &&
        systemIcon == other.systemIcon &&
        _compareButton(backButton, other.backButton) &&
        FlutterCarplayHelper().compareLists(
            other.leadingNavigationBarButtons, leadingNavigationBarButtons, (a, b) => a.hasSameValues(b)) &&
        FlutterCarplayHelper().compareLists(
            other.trailingNavigationBarButtons, trailingNavigationBarButtons, (a, b) => a.hasSameValues(b));
  }

  bool _compareButton(CPBarButton? button, CPBarButton? otherButton) {
    if (otherButton == null && button == null) return true;
    if (otherButton == null || button == null) return false;

    return otherButton.hasSameValues(button);
  }
}
