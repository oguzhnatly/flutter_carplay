import 'dart:async';

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
  /// Supports asset paths, SVG assets, file paths, and network URLs.
  final String? imageUrl;
  final AutoImageTint? imageTint;

  /// The image displayed on the trailing side of this row when supported by the
  /// Android Auto host.
  final String? trailingImage;

  /// Optional tint applied to [trailingImage].
  final AutoImageTint? trailingImageTint;

  /// Text displayed as the loading screen title while [onPress] is executing
  /// until [complete] is called. When null, no title is shown.
  final String? loadingMessage;

  final bool? isBrowsable;
  final AAToggle? toggle;
  final FutureOr<void> Function(Function() complete, AAListItem self)? onPress;

  AAListItem({
    required this.title,
    this.subtitle,
    String? image,
    String? imageUrl,
    this.imageTint,
    this.trailingImage,
    this.trailingImageTint,
    this.loadingMessage,
    this.isBrowsable,
    this.toggle,
    this.onPress,
    String? id,
  })  : imageUrl = imageUrl ?? image,
        assert(
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
        'loadingMessage': loadingMessage,
        'isBrowsable': isBrowsable,
        'toggle': toggle?.toJson(),
        'onPress': onPress != null ? true : false,
      };
}
