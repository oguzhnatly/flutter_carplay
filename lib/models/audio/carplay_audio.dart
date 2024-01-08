import 'package:uuid/uuid.dart';

/// An object that contains audio data in order to play.
class CPAudio {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A resource path as imported in pubspec.yaml that
  /// identifies the local audio file to play.
  final String soundPath;

  /// Audio player’s volume relative to other audio output.
  ///
  /// This property supports values ranging from 0.0 for
  /// silence to 1.0 for full volume. Default is 1.0.
  final double volume;

  /// Creates [CPAudio]
  CPAudio({required this.soundPath, this.volume = 1.0});

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'soundPath': soundPath,
        'volume': volume,
      };

  String get uniqueId {
    return _elementId;
  }
}
