import 'package:flutter_carplay/models/voice_control/voice_control_state.dart';
import 'package:uuid/uuid.dart';

/// A voice control template with a list of voice control states [CPVoiceControlState].
class CPVoiceControlTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The array of actions as [CPVoiceControlState] will be available on the alert.
  /// You can provide up to five states. If you provide more, the template **ignores**
  /// any states after the first five in the array.
  final List<CPVoiceControlState> voiceControlStates;

  /// Fired when the template presented to CarPlay. With this callback function, it can be
  /// determined whether an error was encountered while presenting, or if it was successfully opened,
  /// with the [bool] completed data in it.
  ///
  /// If completed is true, the template successfully presented. If not, you may want to show an error to the user.
  final Function(bool completed)? onPresent;

  /// Creates [CPVoiceControlTemplate] with a list of voice control states.
  ///
  /// When the voice control template is first presented, it defaults to the first state in
  /// the voiceControlStates array. After presenting the template, you may want to change
  /// the state by calling the `activateVoiceControlState()` function.
  CPVoiceControlTemplate({
    required this.voiceControlStates,
    this.onPresent,
  });

  Map<String, dynamic> toJson() => {
        "_elementId": _elementId,
        "voiceControlStates":
            voiceControlStates.map((e) => e.toJson()).toList(),
        "onPresent": onPresent != null ? true : false,
      };

  String get uniqueId {
    return _elementId;
  }
}
