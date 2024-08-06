import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../controllers/carplay_controller.dart';

/// Enum defining different locations of playing indicator.
enum CPListItemPlayingIndicatorLocations {
  /// The location of playing indicator on the trailing edge.
  trailing,

  /// The location of playing indicator on the leading edge.
  leading,
}

/// Enum defining different accessory types.
enum CPListItemAccessoryTypes {
  /// The default accessory type.
  none,

  /// The accessory type that displays an image of a cloud.
  cloud,

  /// The accessory type that displays an disclosure indicator.
  disclosureIndicator,
}

/// A selectable list item object that appears in a list template.
class CPListItem {
  /// Unique id of the object.
  final String _elementId;

  /// Text displayed in the list item cell.
  final String text;

  /// Secondary text displayed below the primary text in the list item cell.
  final String? detailText;

  /// An optional callback function that CarPlay invokes when the user selects the list item.
  final Function(VoidCallback complete, CPListItem item)? onPressed;

  /// Displays an image on the leading edge of the list item cell.
  final String? image;

  /// Displays an dark image on the leading edge of the list item cell.
  final String? darkImage;

  /// Playback progress status for the content that the list item represents.
  double? playbackProgress;

  /// Determines whether the list item displays its Now Playing indicator.
  bool? isPlaying;

  /// Determines whether the list item is enabled.
  bool? isEnabled;

  /// The location where the list item displays its Now Playing indicator.
  CPListItemPlayingIndicatorLocations? playingIndicatorLocation;

  /// An accessory that the list item displays in its trailing region.
  final CPListItemAccessoryTypes? accessoryType;

  /// An accessory image that the list item displays in its trailing region.
  final String? accessoryImage;

  /// An accessory dark image that the list item displays in its trailing region.
  final String? accessoryDarkImage;

  /// Creates [CPListItem] that manages the content of a single row in a [CPListTemplate].
  /// CarPlay manages the layout of a list item and may adjust its layout to allow for
  /// the display of auxiliary content, such as, an accessory or a Now Playing indicator.
  /// A list item can display primary text, secondary text, now playing indicators as playback progress,
  /// an accessory image and a trailing image.
  CPListItem({
    required this.text,
    this.detailText,
    this.onPressed,
    this.image,
    this.playbackProgress,
    this.isPlaying,
    this.playingIndicatorLocation,
    this.accessoryType,
    this.accessoryImage,
    this.isEnabled = true,
    this.darkImage,
    this.accessoryDarkImage,
  }) : _elementId = const Uuid().v4();

  CPListItem._internal(
    this._elementId, {
    required this.text,
    this.detailText,
    this.onPressed,
    this.image,
    this.playbackProgress,
    this.isPlaying,
    this.playingIndicatorLocation,
    this.accessoryType,
    this.accessoryImage,
    this.isEnabled = true,
    this.darkImage,
    this.accessoryDarkImage,
  });

  /// Creates a copy of the current [CPInformationTemplate] instance with updated properties.
  CPListItem _copyWith({
    String? text,
    String? detailText,
    Function(VoidCallback complete, CPListItem item)? onPressed,
    String? image,
    double? playbackProgress,
    CPListItemPlayingIndicatorLocations? playingIndicatorLocation,
    CPListItemAccessoryTypes? accessoryType,
    String? accessoryImage,
    bool? isPlaying,
    bool? isEnabled,
    String? darkImage,
    String? accessoryDarkImage,
  }) {
    return CPListItem._internal(
      _elementId,
      text: text ?? this.text,
      detailText: detailText ?? this.detailText,
      onPressed: onPressed ?? this.onPressed,
      image: image ?? this.image,
      playbackProgress: playbackProgress ?? this.playbackProgress,
      playingIndicatorLocation: playingIndicatorLocation ?? this.playingIndicatorLocation,
      accessoryType: accessoryType ?? this.accessoryType,
      accessoryImage: accessoryImage ?? this.accessoryImage,
      isPlaying: isPlaying ?? this.isPlaying,
      isEnabled: isEnabled ?? this.isEnabled,
      darkImage: darkImage ?? this.darkImage,
      accessoryDarkImage: accessoryDarkImage ?? this.accessoryDarkImage,
    );
  }

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'text': text,
        'detailText': detailText,
        'onPressed': onPressed != null,
        'image': image,
        'playbackProgress': playbackProgress,
        'isPlaying': isPlaying,
        'isEnabled': isEnabled,
        'accessoryImage': accessoryImage,
        'accessoryType': accessoryType?.name,
        'playingIndicatorLocation': playingIndicatorLocation?.name,
        'darkImage': darkImage,
        'accessoryDarkImage': accessoryDarkImage,
      };

  /// Updates the properties of the [CPListItem].
  ///
  /// Available only on Apple CarPlay and has no effect on Android Auto.
  Future<CPListItem> update({
    String? text,
    String? detailText,
    String? image,
    double? playbackProgress,
    CPListItemPlayingIndicatorLocations? playingIndicatorLocation,
    CPListItemAccessoryTypes? accessoryType,
    String? accessoryImage,
    bool? isPlaying,
    bool? isEnabled,
    String? darkImage,
    String? accessoryDarkImage,
  }) async {
    final updatedListItem = _copyWith(
      text: text ?? this.text,
      detailText: detailText ?? this.detailText,
      image: image ?? this.image,
      playbackProgress: playbackProgress ?? this.playbackProgress,
      playingIndicatorLocation: playingIndicatorLocation ?? this.playingIndicatorLocation,
      accessoryType: accessoryType ?? this.accessoryType,
      accessoryImage: accessoryImage ?? this.accessoryImage,
      isPlaying: isPlaying ?? this.isPlaying,
      isEnabled: isEnabled ?? this.isEnabled,
      darkImage: darkImage ?? this.darkImage,
      accessoryDarkImage: accessoryDarkImage ?? this.accessoryDarkImage,
    );

    // Updating the list item's playback progress.
    // When the given value is not between 0.0 and 1.0, throws [RangeError]
    if (playbackProgress != null) {
      if (playbackProgress >= 0.0 && playbackProgress <= 1.0) {
        this.playbackProgress = playbackProgress;
        return FlutterCarplayController.updateCPListItem(updatedListItem);
      } else {
        throw RangeError('playbackProgress must be between 0.0 and 1.0');
      }
    }
    try {
      // Updating the list item's properties.
      return FlutterCarplayController.updateCPListItem(updatedListItem);
    } catch (e) {
      return this;
    }
  }

  String get uniqueId {
    return _elementId;
  }
}
