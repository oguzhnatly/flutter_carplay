import 'dart:async';

import 'package:uuid/uuid.dart';

import '../common/image_tint.dart';
import '../common/image_size.dart';

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
  /// Supports these formats:
  /// - **Asset path**: `images/flutter_logo.png` (from pubspec.yaml assets)
  /// - **SVG asset**: `images/icon.svg` (rasterized to PNG before being sent to
  ///   the native side; remote/`file://` SVGs are not supported)
  /// - **File path**: `file:///path/to/image.png` (local file on device)
  /// - **Network URL**: `https://example.com/image.png` (remote image)
  ///
  /// **[!] When creating a grid button, do NOT provide an animated image. If you do, the button
  /// uses the first image in the animation sequence.**
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final String image;

  /// Optional tint applied to [image].
  final AutoImageTint? imageTint;

  final AutoImageSize? imageSize;

  /// Optional image swapped in while the button is in its loading state
  /// (after the user taps and before [onPressWithCompletion]'s `complete` is called).
  ///
  /// While loading, this image rotates clockwise on the CarPlay display.
  /// When omitted, the button rotates its normal [image] instead.
  ///
  /// Accepts the same formats as [image] (asset path, SVG asset, `file://`
  /// path, or network URL). **In-place image updates require iOS 26.0+** —
  /// on earlier systems the loading rotation is skipped natively.
  final String? loadingImage;

  /// Optional tint applied to [loadingImage] while it is displayed.
  final AutoImageTint? loadingImageTint;

  /// The block invoked after the user taps the button.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final Function()? onPress;

  /// A loading-aware alternative to [onPress]. Call `complete()` to stop loading.
  /// Returning from this handler does not complete the interaction; throwing
  /// completes it automatically. The completion is idempotent and awaitable.
  /// Specify only one callback. Loading image rotation requires iOS 26 or later.
  final FutureOr<void> Function(
    Future<void> Function() complete,
    CPGridButton self,
  )?
  onPressWithCompletion;

  /// Creates [CPGridButton]
  CPGridButton({
    required this.titleVariants,
    required this.image,
    this.imageTint,
    this.imageSize,
    this.loadingImage,
    this.loadingImageTint,
    this.onPress,
    this.onPressWithCompletion,
    String? id,
  }) : _elementId = id ?? const Uuid().v4() {
    if (onPress != null && onPressWithCompletion != null) {
      throw ArgumentError('Specify onPress or onPressWithCompletion, not both');
    }
  }

  Map<String, dynamic> toJson() => {
    '_elementId': _elementId,
    'titleVariants': titleVariants,
    'image': image,
    'imageTint': imageTint?.toJson(),
    'imageSize': imageSize?.toJson(),
    if (loadingImage != null) 'loadingImage': loadingImage,
    if (loadingImageTint != null)
      'loadingImageTint': loadingImageTint!.toJson(),
    'onPress': onPress != null || onPressWithCompletion != null,
    'usesLoading': onPressWithCompletion != null,
    'runtimeType': 'FCPGridButton',
  };

  String get uniqueId {
    return _elementId;
  }
}
