import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/carplay_helper.dart';

/// A grid button object displayed on a grid template.
class CPGridButton {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// An array of title variants for the button.
  /// When the system displays the button, it selects the title that best fits the available
  /// screen space, so arrange the titles from most to least preferred when creating a grid button.
  /// Also, localize each title for display to the user, and **be sure to include at least
  /// one title in the array.**
  final List<String> titleVariants;

  /// Image asset path in pubspec.yaml file.
  /// For example: images/flutter_logo.png
  ///
  /// **[!] When creating a grid button, do NOT provide an animated image. If you do, the button
  /// uses the first image in the animation sequence.**
  final String image;

  /// Fired after the user taps the button.
  final VoidCallback onPressed;

  /// Creates [CPGridButton]
  CPGridButton({
    required this.titleVariants,
    required this.onPressed,
    required this.image,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'titleVariants': titleVariants,
        'image': image,
      };

  String get uniqueId {
    return _elementId;
  }

  bool hasSameValues(CPGridButton other) {
    return FlutterCarplayHelper().compareLists(titleVariants, other.titleVariants, (a, b) => a == b) &&
        image == other.image;
  }
}
