import '../button/button.dart';

/// Visual feedback for one stage of voice interaction, without audio capture.
class CPVoiceControlState {
  CPVoiceControlState({
    required this.identifier,
    List<String>? titleVariants,
    this.image,
    this.repeats = false,
    List<CPButton> actionButtons = const [],
  }) : titleVariants = titleVariants == null
           ? null
           : List.unmodifiable(titleVariants),
       actionButtons = List.unmodifiable(actionButtons) {
    if (identifier.trim().isEmpty) {
      throw ArgumentError.value(identifier, 'identifier', 'Must not be empty.');
    }
    if (titleVariants != null &&
        (titleVariants.isEmpty || titleVariants.any((s) => s.trim().isEmpty))) {
      throw ArgumentError.value(
        titleVariants,
        'titleVariants',
        'Provide nonempty titles or omit them.',
      );
    }
    if (image != null && image!.trim().isEmpty) {
      throw ArgumentError.value(image, 'image', 'Must not be empty.');
    }
    if (actionButtons.length > 2 ||
        actionButtons.map((b) => b.uniqueId).toSet().length !=
            actionButtons.length) {
      throw ArgumentError(
        'A voice state supports up to two distinct action buttons.',
      );
    }
  }

  final String identifier;
  final List<String>? titleVariants;

  /// An optional image asset, file URL or remote URL, at most 150 by 150 points.
  /// Asset SVGs are rasterized before crossing the platform channel.
  final String? image;

  /// Repeats an animated native image. Does not animate a static image or SVG.
  final bool repeats;

  /// Requires iOS 26.4. Older systems reject templates that include buttons.
  final List<CPButton> actionButtons;

  Map<String, dynamic> toJson() => {
    'runtimeType': 'FCPVoiceControlState',
    'identifier': identifier,
    'titleVariants': titleVariants?.toList(),
    'image': image,
    'repeats': repeats,
    'actionButtons': actionButtons.map((b) => b.toJson()).toList(),
  };
}
