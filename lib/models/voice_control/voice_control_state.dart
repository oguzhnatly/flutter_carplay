import 'package:uuid/uuid.dart';

/// A voice control state that contains title variants and images
/// that will be used by a voice control template.
class CPVoiceControlState {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A string that your app uses to identify the voice control state.
  final String identifier;

  /// The array of title variants for the voice control state.
  /// When the system displays the alert, it selects the title that best fits
  /// the available screen space, so arrange the titles from most to least preferred
  /// when creating an alert template. Also, localize each title for display to the user,
  /// and **be sure to include at least one title in the array.**
  final List<String> titleVariants;

  /// Image asset path in pubspec.yaml file.
  /// For example: images/flutter_logo.png
  ///
  /// **[!] For the animated images, the system enforces a minimum cycle
  /// duration of 0.3 seconds, and a maximum cycle duration of 5 seconds.**
  final String? image;

  /// A Boolean value that indicates whether the display of an **animated image**
  /// repeats the animation sequence indefinitely.
  ///
  /// The animation repeats when this property is true; otherwise, animation occurs only once.
  /// Default is false.
  final bool repeats;

  /// Creates [CPVoiceControlState]
  CPVoiceControlState({
    required this.titleVariants,
    required this.identifier,
    this.repeats = false,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'identifier': identifier,
        'titleVariants': titleVariants,
        'repeats': repeats,
        'image': image,
      };

  String get uniqueId {
    return _elementId;
  }
}
