import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/carplay_worker.dart';
import 'package:uuid/uuid.dart';

import '../button/bar_button.dart';
import '../template.dart';
import 'voice_control_state.dart';

/// A modal voice indicator for approved CarPlay app categories.
///
/// Use FlutterCarplay.showVoiceControl, never root, push or tab presentation.
/// The first state is displayed on presentation. This template does not record
/// audio, transcribe speech or activate Siri.
class CPVoiceControlTemplate extends CPTemplate {
  CPVoiceControlTemplate({
    required List<CPVoiceControlState> voiceControlStates,
    List<CPBarButton> leadingNavigationBarButtons = const [],
    List<CPBarButton> trailingNavigationBarButtons = const [],
    this.onDismiss,
    String? id,
  }) : uniqueId = id ?? const Uuid().v4(),
       voiceControlStates = List.unmodifiable(voiceControlStates),
       leadingNavigationBarButtons = List.unmodifiable(
         leadingNavigationBarButtons,
       ),
       trailingNavigationBarButtons = List.unmodifiable(
         trailingNavigationBarButtons,
       ) {
    if (uniqueId.trim().isEmpty) {
      throw ArgumentError('Template identifier must not be empty.');
    }
    if (voiceControlStates.isEmpty ||
        voiceControlStates.length > 5 ||
        voiceControlStates.map((s) => s.identifier).toSet().length !=
            voiceControlStates.length) {
      throw ArgumentError(
        'Provide one to five voice states with distinct identifiers.',
      );
    }
    final bars = [
      ...leadingNavigationBarButtons,
      ...trailingNavigationBarButtons,
    ];
    if (leadingNavigationBarButtons.length > 2 ||
        trailingNavigationBarButtons.length > 2 ||
        bars.any((b) => b.uniqueId.trim().isEmpty || b.title.trim().isEmpty) ||
        bars.map((b) => b.uniqueId).toSet().length != bars.length) {
      throw ArgumentError(
        'Provide up to two distinct, nonempty navigation buttons per side.',
      );
    }
    // A shared button may be reused in multiple states, but IDs must not name
    // different callbacks or collide with navigation buttons.
    final seen = <String, Object>{for (final b in bars) b.uniqueId: b};
    for (final state in voiceControlStates) {
      for (final button in state.actionButtons) {
        final previous = seen[button.uniqueId];
        if (previous != null && !identical(previous, button)) {
          throw ArgumentError(
            'Button identifiers must identify a single button.',
          );
        }
        seen[button.uniqueId] = button;
      }
    }
  }

  @override
  final String uniqueId;
  final List<CPVoiceControlState> voiceControlStates;

  /// Navigation buttons require iOS 26.4 and an SDK containing that API.
  final List<CPBarButton> leadingNavigationBarButtons;
  final List<CPBarButton> trailingNavigationBarButtons;

  /// Called once when dismissed, cancelled while presenting, or disconnected.
  /// Stop recording and speech playback here. A rejected presentation does not
  /// call this callback because the session never opened.
  final VoidCallback? onDismiss;

  /// Returns whether the host reports this identifier as active after the call.
  /// CarPlay can ignore rapid changes due to its state activation rate limit.
  Future<bool> activateState(String identifier) =>
      FlutterCarplay.activateVoiceControlState(
        elementId: uniqueId,
        identifier: identifier,
      );

  @override
  Map<String, dynamic> toJson() => {
    'runtimeType': 'FCPVoiceControlTemplate',
    '_elementId': uniqueId,
    'voiceControlStates': voiceControlStates.map((s) => s.toJson()).toList(),
    'leadingNavigationBarButtons': leadingNavigationBarButtons
        .map((b) => b.toJson())
        .toList(),
    'trailingNavigationBarButtons': trailingNavigationBarButtons
        .map((b) => b.toJson())
        .toList(),
  };
}
