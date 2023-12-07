import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// A controller of a text to speech. It includes the text for speech synthesis as
/// well as the factors that affect the speech.
class CPSpeaker {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A text string for the speech synthesizer to speak.
  final String text;

  /// A BCP 47 code that identifies the language and locale for a voice
  /// by defining [Locale](https://api.flutter.dev/flutter/dart-ui/Locale-class.html).
  ///
  /// Default is `Locale('en', 'US')`.
  ///
  /// For a complete list of supported languages, see
  /// [languages supported by VoiceOver](https://support.apple.com/en-us/HT206175).
  final Locale language;

  /// Will be fired when the text is finished being voiced/speech in CarPlay.
  final VoidCallback? onCompleted;

  /// Creates [CPSpeaker] with the primary factors that distinguish
  /// a voice in speech synthesis such as language, locale, and quality.
  ///
  /// For a complete list of supported languages, see
  /// [languages supported by VoiceOver](https://support.apple.com/en-us/HT206175).
  CPSpeaker({
    required this.text,
    this.language = const Locale('en', 'US'),
    this.onCompleted,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        '_elementId': _elementId,
        'language': language.toLanguageTag(),
        'onCompleted': onCompleted != null,
      };

  String get uniqueId {
    return _elementId;
  }
}
