import 'package:uuid/uuid.dart';

import '../../../controllers/carplay_controller.dart';
import '../../common/image_tint.dart';
import 'list_image_row_item_constants.dart';
import 'list_image_row_item_element.dart';

/// https://developer.apple.com/documentation/carplay/cplistimagerowitemcondensedelement
/// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
class CPListImageRowItemCondensedElement implements CPListImageRowItemElement {
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
  String title;

  /// The subtitle associated with this element.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  String? subtitle;

  /// The name of the system symbol image to use as accessory.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  String? accessorySymbolName;

  /// Shape used to draw the image of the element.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  final CPListImageRowItemCondensedElementShape imageShape;

  /// Creates [CPListImageRowItemCondensedElement]
  CPListImageRowItemCondensedElement({
    required this.image,
    required this.title,
    this.imageTint,
    this.subtitle,
    this.accessorySymbolName,
    this.imageShape = CPListImageRowItemCondensedElementShape.roundedRectangle,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'image': image,
        'imageTint': imageTint?.toJson(),
        'title': title,
        'subtitle': subtitle,
        'accessorySymbolName': accessorySymbolName,
        'imageShape': imageShape.name,
        'runtimeType': 'FCPListImageRowItemCondensedElement',
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

  void setAccessorySymbolName(String accessorySymbolName) {
    this.accessorySymbolName = accessorySymbolName;
    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  void update({
    String? image,
    AutoImageTint? imageTint,
    String? title,
    String? subtitle,
    String? accessorySymbolName,
  }) {
    if (image != null) this.image = image;
    if (imageTint != null) this.imageTint = imageTint;
    if (title != null) this.title = title;
    if (subtitle != null) this.subtitle = subtitle;
    if (accessorySymbolName != null) {
      this.accessorySymbolName = accessorySymbolName;
    }

    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  @override
  String get uniqueId {
    return _elementId;
  }
}
