import 'package:uuid/uuid.dart';

import '../../../controllers/carplay_controller.dart';
import '../../common/image_tint.dart';
import '../../common/ui_color.dart';
import 'list_image_row_item_element.dart';

/// https://developer.apple.com/documentation/carplay/cplistimagerowitemcardelement
/// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
class CPListImageRowItemCardElement implements CPListImageRowItemElement {
  /// Unique id of the object.
  final String _elementId;

  /// The image to display in the card.
  ///
  /// Accepts an asset path, an SVG Flutter asset (`.svg`, rasterized to PNG
  /// before reaching the native side), a `file://` path, or a network URL.
  /// Remote/`file://` SVGs are not supported.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  @override
  String image;

  @override
  AutoImageTint? imageTint;

  /// The title associated with this element.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  String? title;

  /// The subtitle associated with this element.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  String? subtitle;

  /// A UIColor used to tint the element. When @c showsImageFullHeight is true,
  /// the tint color is applied behind the labels at the bottom of the card.
  /// Otherwise, this color is part of the gradient color at the bottom of the card.
  UIColor? tintColor;

  /// A Boolean value indicating whether the element should be fill with the image.
  /// iOS 14.0–26.0 | iPadOS 14.0–26.0 | Mac Catalyst 14.0–26.0
  final bool showsImageFullHeight;

  /// Creates [CPListImageRowItemCardElement]
  CPListImageRowItemCardElement({
    required this.image,
    this.imageTint,
    this.title,
    this.subtitle,
    this.showsImageFullHeight = true,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'image': image,
        'imageTint': imageTint?.toJson(),
        'title': title,
        'subtitle': subtitle,
        'tintColor': tintColor?.toJson(),
        'showsImageFullHeight': showsImageFullHeight,
        'runtimeType': 'FCPListImageRowItemCardElement',
      };

  @override
  void setImage(String image, {AutoImageTint? imageTint}) {
    this.image = image;
    if (imageTint != null) this.imageTint = imageTint;
    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  @override
  void setImageTint(AutoImageTint? imageTint) {
    this.imageTint = imageTint;
    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  void setTitle(String title) {
    this.title = title;
    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  void setSubtitle(String subtitle) {
    this.subtitle = subtitle;
    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  void setTintColor(UIColor tintColor) {
    this.tintColor = tintColor;
    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  void update({
    String? image,
    AutoImageTint? imageTint,
    String? title,
    String? subtitle,
    UIColor? tintColor,
    bool? showsImageFullHeight,
  }) {
    if (image != null) this.image = image;
    if (imageTint != null) this.imageTint = imageTint;
    if (title != null) this.title = title;
    if (subtitle != null) this.subtitle = subtitle;
    if (tintColor != null) this.tintColor = tintColor;

    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  @override
  String get uniqueId {
    return _elementId;
  }
}
