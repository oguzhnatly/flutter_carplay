import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/models/common/image_tint.dart';
import 'package:flutter_carplay/models/list/list_constants.dart';
import 'package:uuid/uuid.dart';

import 'list_template_item.dart';

/// A selectable row in a list template.
/// https://developer.apple.com/documentation/carplay/cplistitem
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPListItem extends CPListTemplateItem {
  /// Unique id of the object.
  final String _elementId;

  /// The list item’s secondary text.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  String? detailText;

  /// The image that the list item displays in its leading region.
  ///
  /// Supports these formats:
  /// * Asset path: `images/flutter_logo.png` from pubspec.yaml assets
  /// * SVG asset: `images/icon.svg` rasterized to PNG before native display
  /// * File path: `file:///path/to/image.png` local file on device
  /// * Network URL: `https://example.com/image.png` remote image
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  String? image;

  /// Optional tint applied to [image]. Use [AutoImageTint.platform] when the
  /// host should choose a selected or focused row safe color.
  AutoImageTint? imageTint;

  /// Backward compatible trailing accessory image.
  ///
  /// New code should prefer [trailingImage], which also supports SVG assets and
  /// tint metadata.
  String? accessoryImage;

  /// The image that the list item displays in its trailing region.
  ///
  /// This maps to CarPlay's `accessoryImage` and takes precedence over
  /// [accessoryImage] and [accessoryType]. Use it for state indicators while
  /// keeping [image] for the leading user selected icon.
  String? trailingImage;

  /// Optional tint applied to [trailingImage].
  AutoImageTint? trailingImageTint;

  /// The playback progress status for the content that the list item represents.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  double? playbackProgress;

  /// A Boolean value that determines whether the list item displays its Now Playing indicator.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  bool? isPlaying;

  /// The location where the list item displays its Now Playing indicator.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  CPListItemPlayingIndicatorLocation? playingIndicatorLocation;

  /// The accessory that the list item displays in its trailing region.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  CPListItemAccessoryType? accessoryType;

  /// An optional closure that CarPlay invokes when the user selects the list item.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final Function(Function() complete, CPListItem self)? onPress;

  /// Creates [CPListItem] that manages the content of a single row in a [CPListTemplate].
  /// CarPlay manages the layout of a list item and may adjust its layout to allow for
  /// the display of auxiliary content, such as, an accessory or a Now Playing indicator.
  /// A list item can display primary text, secondary text, now playing indicators as playback progress,
  /// an accessory image and a trailing image.
  CPListItem({
    super.text,
    this.detailText,
    this.onPress,
    this.image,
    this.imageTint,
    this.accessoryImage,
    this.trailingImage,
    this.trailingImageTint,
    this.playbackProgress,
    this.isPlaying,
    this.playingIndicatorLocation,
    this.accessoryType,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'text': text,
        'detailText': detailText,
        'onPress': onPress != null ? true : false,
        'image': image,
        'imageTint': imageTint?.toJson(),
        'accessoryImage': accessoryImage,
        'trailingImage': trailingImage,
        'trailingImageTint': trailingImageTint?.toJson(),
        'playbackProgress': playbackProgress,
        'isPlaying': isPlaying,
        'playingIndicatorLocation': playingIndicatorLocation?.name,
        'accessoryType': accessoryType?.name,
        'runtimeType': 'FCPListItem',
      };

  /// Updating the list item's primary text.
  void setText(String text) {
    this.text = text;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Updating the list item's secondary text.
  void setDetailText(String detailText) {
    this.detailText = detailText;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Updating the image which will be displayed on the leading edge of the list item cell.
  ///
  /// Supports these formats:
  /// * Asset path: `images/flutter_logo.png` from pubspec.yaml assets
  /// * SVG asset: `images/icon.svg` rasterized to PNG before native display
  /// * File path: `file:///path/to/image.png` local file on device
  /// * Network URL: `https://example.com/image.png` remote image
  void setImage(String image, {AutoImageTint? imageTint}) {
    this.image = image;
    if (imageTint != null) this.imageTint = imageTint;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Updates the tint applied to [image]. Pass `null` to remove the tint.
  void setImageTint(AutoImageTint? imageTint) {
    this.imageTint = imageTint;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Updating the image displayed on the trailing edge of the list item cell.
  ///
  /// See [trailingImage] for supported formats, including SVG Flutter assets.
  void setTrailingImage(String trailingImage, {AutoImageTint? imageTint}) {
    this.trailingImage = trailingImage;
    if (imageTint != null) trailingImageTint = imageTint;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Updates the tint applied to [trailingImage]. Pass `null` to remove it.
  void setTrailingImageTint(AutoImageTint? imageTint) {
    trailingImageTint = imageTint;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Updating the image displayed in the trailing region of the list item cell.
  ///
  /// Supports the same asset path, file path, and network URL formats as [image].
  void setAccessoryImage(String? accessoryImage) {
    this.accessoryImage = accessoryImage;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Setter for playbackProgress
  /// When the given value is not between 0.0 and 1.0, throws [RangeError]
  void setPlaybackProgress(double playbackProgress) {
    if (playbackProgress >= 0.0 && playbackProgress <= 1.0) {
      this.playbackProgress = playbackProgress;
      FlutterCarPlayController.updateCPListItem(this);
    } else {
      throw RangeError('playbackProgress must be between 0.0 and 1.0');
    }
  }

  /// Setter for isPlaying
  void setIsPlaying(bool isPlaying) {
    this.isPlaying = isPlaying;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Setter for playingIndicatorLocation
  void setPlayingIndicatorLocation(
    CPListItemPlayingIndicatorLocation playingIndicatorLocation,
  ) {
    this.playingIndicatorLocation = playingIndicatorLocation;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Setter for accessoryType
  void setAccessoryType(CPListItemAccessoryType accessoryType) {
    this.accessoryType = accessoryType;
    FlutterCarPlayController.updateCPListItem(this);
  }

  void update({
    String? text,
    String? detailText,
    String? image,
    AutoImageTint? imageTint,
    String? accessoryImage,
    String? trailingImage,
    AutoImageTint? trailingImageTint,
    double? playbackProgress,
    bool? isPlaying,
    CPListItemPlayingIndicatorLocation? playingIndicatorLocation,
    CPListItemAccessoryType? accessoryType,
  }) {
    if (text != null) this.text = text;
    if (detailText != null) this.detailText = detailText;
    if (image != null) this.image = image;
    if (imageTint != null) this.imageTint = imageTint;
    if (accessoryImage != null) this.accessoryImage = accessoryImage;
    if (trailingImage != null) this.trailingImage = trailingImage;
    if (trailingImageTint != null) this.trailingImageTint = trailingImageTint;
    if (playbackProgress != null) {
      if (playbackProgress >= 0.0 && playbackProgress <= 1.0) {
        this.playbackProgress = playbackProgress;
      } else {
        throw RangeError('playbackProgress must be between 0.0 and 1.0');
      }
    }
    if (isPlaying != null) this.isPlaying = isPlaying;
    if (playingIndicatorLocation != null) {
      this.playingIndicatorLocation = playingIndicatorLocation;
    }
    if (accessoryType != null) this.accessoryType = accessoryType;

    FlutterCarPlayController.updateCPListItem(this);
  }

  @override
  String get uniqueId {
    return _elementId;
  }
}
