import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../flutter_carplay.dart';
import '../../helpers/carplay_helper.dart';

/// A voice control template with a list of voice control states [CPVoiceControlState].
class CPVoiceControlTemplate extends CPPresentTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The array of actions as [CPVoiceControlState] will be available on the alert.
  /// You can provide up to five states. If you provide more, the template **ignores**
  /// any states after the first five in the array.
  final List<CPVoiceControlState> voiceControlStates;

  /// A BCP 47 code that identifies the language and locale for a voice
  /// by defining [Locale](https://api.flutter.dev/flutter/dart-ui/Locale-class.html).
  ///
  /// Default is `Locale('en', 'US')`.
  ///
  /// For a complete list of supported languages, see
  /// [languages supported by VoiceOver](https://support.apple.com/en-us/HT206175).
  final Locale locale;

  /// Creates [CPVoiceControlTemplate] with a list of voice control states.
  ///
  /// When the voice control template is first presented, it defaults to the first state in
  /// the voiceControlStates array. After presenting the template, you may want to change
  /// the state by calling the `activateVoiceControlState()` function.
  CPVoiceControlTemplate({
    required this.voiceControlStates,
    super.isDismissible,
    super.routeName,
    this.locale = const Locale('en', 'US'),
    super.onPresent,
    super.onPop,
  });

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'onPresent': onPresent != null,
        'onPop': onPop != null,
        'locale': locale.toLanguageTag(),
        'voiceControlStates': voiceControlStates.map((e) => e.toJson()).toList(),
      };

  @override
  String get uniqueId {
    return _elementId;
  }

  @override
  bool hasSameValues(CPTemplate other) {
    return other is CPVoiceControlTemplate &&
        locale == other.locale &&
        FlutterCarplayHelper().compareLists(
          voiceControlStates,
          other.voiceControlStates,
          (a, b) => a.hasSameValues(b),
        );
  }
}
