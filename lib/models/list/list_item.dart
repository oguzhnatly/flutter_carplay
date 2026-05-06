import 'package:flutter_carplay/controllers/carplay_controller.dart';
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
  /// Supports three formats:
  /// - **Asset path**: `images/flutter_logo.png` (from pubspec.yaml assets)
  /// - **File path**: `file:///path/to/image.png` (local file on device)
  /// - **Network URL**: `https://example.com/image.png` (remote image)
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  String? image;

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
  final Future<void> Function(Function() complete, CPListItem self)? onPress;

  /// Maximum time in seconds the CarPlay loading indicator stays visible waiting
  /// for [onPress] to call [complete]. When null, no safety timeout is scheduled
  /// and the spinner persists until [complete] is called. Values below 1 are ignored.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final int? onPressTimeout;

  /// Creates [CPListItem] that manages the content of a single row in a [CPListTemplate].
  /// CarPlay manages the layout of a list item and may adjust its layout to allow for
  /// the display of auxiliary content, such as, an accessory or a Now Playing indicator.
  /// A list item can display primary text, secondary text, now playing indicators as playback progress,
  /// an accessory image and a trailing image.
  CPListItem({
    super.text,
    this.detailText,
    this.onPress,
    this.onPressTimeout,
    this.image,
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
        'onPressTimeout': onPressTimeout,
        'image': image,
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
  /// Supports three formats:
  /// - **Asset path**: `images/flutter_logo.png` (from pubspec.yaml assets)
  /// - **File path**: `file:///path/to/image.png` (local file on device)
  /// - **Network URL**: `https://example.com/image.png` (remote image)
  void setImage(String image) {
    this.image = image;
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
    double? playbackProgress,
    bool? isPlaying,
    CPListItemPlayingIndicatorLocation? playingIndicatorLocation,
    CPListItemAccessoryType? accessoryType,
  }) {
    if (text != null) this.text = text;
    if (detailText != null) this.detailText = detailText;
    if (image != null) this.image = image;
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
