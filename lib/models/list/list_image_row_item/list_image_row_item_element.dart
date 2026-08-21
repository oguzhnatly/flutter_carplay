import '../../common/image_size.dart';
import '../../common/image_tint.dart';

/// Abstract superclass for a a row item element object.
/// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
/// https://developer.apple.com/documentation/carplay/cplistimagerowitemelement
abstract interface class CPListImageRowItemElement {
  /// The image associated with this element.
  ///
  /// Accepts an asset path, an SVG Flutter asset (`.svg`, rasterized to PNG
  /// before reaching the native side), a `file://` path, or a network URL.
  /// Remote/`file://` SVGs are not supported.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  String? get image;

  /// Optional tint applied to [image].
  AutoImageTint? get imageTint;

  /// How much of the slot CarPlay reserves for [image] the artwork fills.
  ///
  /// Defaults to `FlutterCarplay.iconSize` when omitted.
  AutoImageSize? get imageSize;

  Map<String, dynamic> toJson();

  String get uniqueId;

  /// Updates the element's image. See [image] for supported formats (including
  /// `.svg` Flutter assets).
  void setImage(String image, {AutoImageTint? imageTint, AutoImageSize? imageSize});

  /// Updates the tint applied to [image]. Pass `null` to remove the tint.
  void setImageTint(AutoImageTint? imageTint);

  /// Updates how much of its reserved slot [image] fills. Pass `null` to fall
  /// back to `FlutterCarplay.iconSize`.
  void setImageSize(AutoImageSize? imageSize);
}
