import 'package:uuid/uuid.dart';

/// A menu item button displayed on a grid template.
/// https://developer.apple.com/documentation/carplay/cpgridbutton
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPGridButton {
  /// Unique id of the object.
  final String _elementId;

  /// An array of title variants for the button.
  /// When the system displays the button, it selects the title that best fits the available
  /// screen space, so arrange the titles from most to least preferred when creating a grid button.
  /// Also, localize each title for display to the user, and **be sure to include at least
  /// one title in the array.**
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final List<String> titleVariants;

  /// The image displayed on the button.
  ///
  /// Supports three formats:
  /// - **Asset path**: `images/flutter_logo.png` (from pubspec.yaml assets)
  /// - **File path**: `file:///path/to/image.png` (local file on device)
  /// - **Network URL**: `https://example.com/image.png` (remote image)
  ///
  /// **[!] When creating a grid button, do NOT provide an animated image. If you do, the button
  /// uses the first image in the animation sequence.**
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final String image;

  /// The block invoked after the user taps the button.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final Function()? onPress;

  /// Creates [CPGridButton]
  CPGridButton({
    required this.titleVariants,
    required this.image,
    this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'titleVariants': titleVariants,
        'image': image,
        'onPress': onPress != null ? true : false,
      };

  String get uniqueId {
    return _elementId;
  }
}
