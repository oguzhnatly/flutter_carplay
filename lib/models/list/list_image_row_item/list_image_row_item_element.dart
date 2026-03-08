/// Abstract superclass for a a row item element object.
/// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
/// https://developer.apple.com/documentation/carplay/cplistimagerowitemelement
abstract interface class CPListImageRowItemElement {
  /// The image associated with this element.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  String? get image;

  Map<String, dynamic> toJson();

  String get uniqueId;
}
