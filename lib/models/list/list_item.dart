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
  final String _elementId = const Uuid().v4();

  /// Text displayed in the list item cell.
  String text;

  /// Secondary text displayed below the primary text in the list item cell.
  String? detailText;

  /// An optional callback function that CarPlay invokes when the user selects the list item.
  final Function(VoidCallback complete, CPListItem item)? onPressed;

  /// Displays an image on the leading edge of the list item cell.
  String? image;

  /// Displays an dark image on the leading edge of the list item cell.
  String? darkImage;

  /// Playback progress status for the content that the list item represents.
  double? playbackProgress;

  /// Determines whether the list item displays its Now Playing indicator.
  bool? isPlaying;

  /// Determines whether the list item is enabled.
  bool? isEnabled;

  /// The location where the list item displays its Now Playing indicator.
  CPListItemPlayingIndicatorLocations? playingIndicatorLocation;

  /// An accessory that the list item displays in its trailing region.
  CPListItemAccessoryTypes? accessoryType;

  /// An accessory image that the list item displays in its trailing region.
  String? accessoryImage;

  /// An accessory dark image that the list item displays in its trailing region.
  String? accessoryDarkImage;

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
  });

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

  /// Updates the properties of the [CPListItem]
  void update({
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
  }) {
    // Updating the list item's primary text.
    if (text != null) this.text = text;

    // Updating the list item's secondary text.
    if (detailText != null) this.detailText = detailText;

    // Updating the image which will be displayed on the leading edge of the list item cell.
    // Image asset path in pubspec.yaml file.
    // For example: images/flutter_logo.png
    if (image != null) this.image = image;

    // Updating the list item's dark image.
    if (darkImage != null) this.darkImage = darkImage;

    // Updating the list item's playback status.
    if (isPlaying != null) this.isPlaying = isPlaying;

    // Updating the list item's enabled status.
    if (isEnabled != null) this.isEnabled = isEnabled;

    // Updating the list item's playing indicator location.
    if (accessoryType != null) this.accessoryType = accessoryType;

    // Updating the list item's accessory image.
    if (accessoryImage != null) this.accessoryImage = accessoryImage;

    // Updating the list item's dark accessory image.
    if (accessoryDarkImage != null) {
      this.accessoryDarkImage = accessoryDarkImage;
    }

    // Updating the list item's playing indicator location.
    if (playingIndicatorLocation != null) {
      this.playingIndicatorLocation = playingIndicatorLocation;
    }

    // Updating the list item's playback progress.
    // When the given value is not between 0.0 and 1.0, throws [RangeError]
    if (playbackProgress != null) {
      if (playbackProgress >= 0.0 && playbackProgress <= 1.0) {
        this.playbackProgress = playbackProgress;
        FlutterCarplayController.updateCPListItem(this);
      } else {
        throw RangeError('playbackProgress must be between 0.0 and 1.0');
      }
    }

    FlutterCarplayController.updateCPListItem(this);
  }

  String get uniqueId {
    return _elementId;
  }
}
