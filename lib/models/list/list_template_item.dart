/// A description of the common properties of all list item types.
/// https://developer.apple.com/documentation/carplay/cplisttemplateitem
/// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
abstract class CPListTemplateItem {
  CPListTemplateItem({
    this.text,
  });

  /// The item’s primary text.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  String? text;

  Map<String, dynamic> toJson();

  String get uniqueId;
}
