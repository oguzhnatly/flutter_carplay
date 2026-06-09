import 'package:uuid/uuid.dart';

import '../../../controllers/carplay_controller.dart';
import '../../common/image_tint.dart';
import 'list_image_row_item_element.dart';

/// https://developer.apple.com/documentation/carplay/cplistimagerowitemgridelement
/// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
class CPListImageRowItemGridElement implements CPListImageRowItemElement {
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

  /// Creates [CPListImageRowItemGridElement]
  CPListImageRowItemGridElement({
    required this.image,
    this.imageTint,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'image': image,
        'imageTint': imageTint?.toJson(),
        'runtimeType': 'FCPListImageRowItemGridElement',
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

  void update({
    String? image,
    AutoImageTint? imageTint,
  }) {
    if (image != null) this.image = image;
    if (imageTint != null) this.imageTint = imageTint;

    FlutterCarPlayController.updateCPListImageRowItemElement(this);
  }

  @override
  String get uniqueId {
    return _elementId;
  }
}
