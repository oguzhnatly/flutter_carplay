import 'package:uuid/uuid.dart';

/// Base class for all Now Playing buttons.
///
/// This is the abstract base class that all Now Playing button types extend.
/// Each button type provides specific functionality for the CarPlay Now Playing screen.
abstract class CPNowPlayingButton {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// Returns the unique identifier for this button.
  String get uniqueId => _elementId;

  /// Converts this button to a JSON representation for native communication.
  Map<String, dynamic> toJson();
}

/// A button that cycles through repeat modes on the Now Playing screen.
///
/// The repeat button automatically cycles through the available repeat modes:
/// off, one, and all. The system handles the visual state updates.
class CPNowPlayingRepeatButton extends CPNowPlayingButton {
  /// Callback fired when the repeat button is pressed.
  final Function()? onPress;

  /// Creates a [CPNowPlayingRepeatButton].
  ///
  /// The [onPress] callback is optional. When pressed, the button cycles
  /// through repeat modes (off -> one -> all -> off).
  CPNowPlayingRepeatButton({this.onPress});

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': uniqueId,
        'type': 'repeat',
      };
}

/// A button that toggles shuffle mode on the Now Playing screen.
///
/// The shuffle button toggles between shuffle on and off states.
/// The system handles the visual state updates.
class CPNowPlayingShuffleButton extends CPNowPlayingButton {
  /// Callback fired when the shuffle button is pressed.
  final Function()? onPress;

  /// Creates a [CPNowPlayingShuffleButton].
  ///
  /// The [onPress] callback is optional. When pressed, the button toggles
  /// the shuffle state.
  CPNowPlayingShuffleButton({this.onPress});

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': uniqueId,
        'type': 'shuffle',
      };
}

/// A button that adds the current item to the user's library.
///
/// This button is typically used for adding songs or podcasts to a library
/// or favorites list.
class CPNowPlayingAddToLibraryButton extends CPNowPlayingButton {
  /// Callback fired when the add to library button is pressed.
  final Function()? onPress;

  /// Creates a [CPNowPlayingAddToLibraryButton].
  ///
  /// The [onPress] callback is optional but should be provided to handle
  /// the add to library action in your app.
  CPNowPlayingAddToLibraryButton({this.onPress});

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': uniqueId,
        'type': 'addToLibrary',
      };
}

/// A button that triggers a "more" action, typically showing additional options.
///
/// This button is commonly used to display a menu with additional actions
/// for the currently playing item.
class CPNowPlayingMoreButton extends CPNowPlayingButton {
  /// Callback fired when the more button is pressed.
  final Function()? onPress;

  /// Creates a [CPNowPlayingMoreButton].
  ///
  /// The [onPress] callback is optional but should be provided to handle
  /// showing additional options when pressed.
  CPNowPlayingMoreButton({this.onPress});

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': uniqueId,
        'type': 'more',
      };
}

/// A button that cycles through playback rate options.
///
/// The playback rate button cycles through available playback speeds:
/// 0.5x, 1x, 1.5x, and 2x. The system handles the visual state updates.
class CPNowPlayingPlaybackRateButton extends CPNowPlayingButton {
  /// Callback fired when the playback rate button is pressed.
  final Function()? onPress;

  /// Creates a [CPNowPlayingPlaybackRateButton].
  ///
  /// The [onPress] callback is optional. When pressed, the button cycles
  /// through playback rate options (0.5x -> 1x -> 1.5x -> 2x -> 0.5x).
  CPNowPlayingPlaybackRateButton({this.onPress});

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': uniqueId,
        'type': 'playbackRate',
      };
}

/// A custom image button for the Now Playing screen.
///
/// This button allows you to display a custom image and handle tap events.
/// Use this for app specific actions like like/dislike, favorite, etc.
class CPNowPlayingImageButton extends CPNowPlayingButton {
  /// The image displayed on the button.
  ///
  /// Supports three formats:
  /// - **Asset path**: `images/heart.png` (from pubspec.yaml assets)
  /// - **File path**: `file:///path/to/image.png` (local file on device)
  /// - **Network URL**: `https://example.com/image.png` (remote image)
  ///
  /// **[!] The image should be a template image that can be tinted by the system.
  /// Use a simple, single color image for best results.**
  final String image;

  /// Callback fired when the button is pressed.
  final Function() onPress;

  /// Creates a [CPNowPlayingImageButton] with a custom image and handler.
  ///
  /// The [image] parameter specifies the button's icon.
  /// The [onPress] callback is required and will be invoked when the button is tapped.
  CPNowPlayingImageButton({
    required this.image,
    required this.onPress,
  });

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': uniqueId,
        'type': 'image',
        'image': image,
      };
}
