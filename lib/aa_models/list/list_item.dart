import 'package:flutter_carplay/models/common/image_tint.dart';
import 'package:uuid/uuid.dart';

class AAToggle {
  bool isChecked;
  final bool? isEnabled;
  final Function(bool checked, AAListItem self)? onCheckedChange;

  AAToggle({this.isChecked = false, this.isEnabled, this.onCheckedChange});

  Map<String, dynamic> toJson() => {
    'isChecked': isChecked,
    'isEnabled': isEnabled,
    'onCheckedChange': onCheckedChange != null ? true : false,
  };
}

class AAListItem {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final String? subtitle;

  /// The image displayed for this row on Android Auto.
  ///
  /// Supports these formats:
  /// * Asset path: `images/flutter_logo.png` from pubspec.yaml assets
  /// * SVG asset: `images/icon.svg` rasterized to PNG before native display
  /// * File path: `file:///path/to/image.png` local file on device
  /// * Network URL: `https://example.com/image.png` remote image
  final String? imageUrl;
  final AutoImageTint? imageTint;

  /// The image displayed on the trailing side of this row when supported by the
  /// Android Auto host.
  ///
  /// Android Auto `Row` does not expose a dedicated arbitrary trailing image
  /// slot. This package renders [trailingImage] as a trailing row action icon,
  /// which is the closest supported affordance.
  final String? trailingImage;

  /// Optional tint applied to [trailingImage].
  final AutoImageTint? trailingImageTint;

  final bool? isBrowsable;
  final AAToggle? toggle;
  final Function(Function() complete, AAListItem self)? onPress;

  AAListItem({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.imageTint,
    this.trailingImage,
    this.trailingImageTint,
    this.isBrowsable,
    this.toggle,
    this.onPress,
    String? id,
  }) : assert(
         isBrowsable != true || toggle == null,
         'A browsable row must not have a toggle set.',
       ),
       assert(
         isBrowsable != true || onPress != null,
         'A browsable row must have an onClickListener set.',
       ),
       assert(
         toggle == null || onPress == null,
         'If a row contains a toggle, it must not have an onClickListener set.',
       ),
       _elementId = id ?? const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
    '_elementId': _elementId,
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'imageTint': imageTint?.toJson(),
    'trailingImage': trailingImage,
    'trailingImageTint': trailingImageTint?.toJson(),
    'isBrowsable': isBrowsable,
    'toggle': toggle?.toJson(),
    'onPress': onPress != null ? true : false,
  };
}
