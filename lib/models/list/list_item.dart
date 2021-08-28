import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/helpers/enum_utils.dart';
import 'package:flutter_carplay/models/list/list_constants.dart';
import 'package:uuid/uuid.dart';

/// A selectable list item object that appears in a list template.
class CPListItem {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// Text displayed in the list item cell.
  String text;

  /// Secondary text displayed below the primary text in the list item cell.
  String? detailText;

  /// An optional callback function that CarPlay invokes when the user selects the list item.
  final Function(Function() complete, CPListItem self)? onPress;

  /// Displays an image on the leading edge of the list item cell.
  /// Image asset path in pubspec.yaml file.
  /// For example: images/flutter_logo.png
  String? image;

  /// Playback progress status for the content that the list item represents.
  double? playbackProgress;

  /// Determines whether the list item displays its Now Playing indicator.
  bool? isPlaying;

  /// The location where the list item displays its Now Playing indicator.
  CPListItemPlayingIndicatorLocations? playingIndicatorLocation;

  /// An accessory that the list item displays in its trailing region.
  CPListItemAccessoryTypes? accessoryType;

  /// Creates [CPListItem] that manages the content of a single row in a [CPListTemplate].
  /// CarPlay manages the layout of a list item and may adjust its layout to allow for
  /// the display of auxiliary content, such as, an accessory or a Now Playing indicator.
  /// A list item can display primary text, secondary text, now playing indicators as playback progress,
  /// an accessory image and a trailing image.
  CPListItem({
    required this.text,
    this.detailText,
    this.onPress,
    this.image,
    this.playbackProgress,
    this.isPlaying,
    this.playingIndicatorLocation,
    this.accessoryType,
  });

  Map<String, dynamic> toJson() => {
        "_elementId": _elementId,
        "text": text,
        "detailText": detailText,
        "onPress": onPress != null ? true : false,
        "image": image,
        "playbackProgress": playbackProgress,
        "isPlaying": isPlaying,
        "playingIndicatorLocation":
            CPEnumUtils.stringFromEnum(playingIndicatorLocation.toString()),
        "accessoryType": CPEnumUtils.stringFromEnum(accessoryType.toString()),
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

  /// Updating the list item's both the primary and detail text at the same time.
  void updateTexts({String? text, String? detailText}) {
    this.text = text ?? this.text;
    this.detailText = detailText ?? this.detailText;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Updating the image which will be displayed on the leading edge of the list item cell.
  /// Image asset path in pubspec.yaml file.
  /// For example: images/flutter_logo.png
  set updateImage(String image) {
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
      CPListItemPlayingIndicatorLocations playingIndicatorLocation) {
    this.playingIndicatorLocation = playingIndicatorLocation;
    FlutterCarPlayController.updateCPListItem(this);
  }

  /// Setter for accessoryType
  void setAccessoryType(CPListItemAccessoryTypes accessoryType) {
    this.accessoryType = accessoryType;
    FlutterCarPlayController.updateCPListItem(this);
  }

  String get uniqueId {
    return _elementId;
  }
}
