/// The position of the assistant cell in a list template.
/// iOS 15.0+ | iPadOS 15.0+ | Mac Catalyst 15.0+
enum CPAssistantCellPosition { top, bottom }

/// When the assistant cell is visible in a list template.
/// iOS 15.0+ | iPadOS 15.0+ | Mac Catalyst 15.0+
enum CPAssistantCellVisibility { off, whileLimitedUIActive, always }

/// The Siri action the assistant cell performs when selected.
/// Audio apps use [playMedia] and must handle `INPlayMediaIntent`;
/// communication apps use [startCall] and must handle `INStartCallIntent`.
/// iOS 15.0+ | iPadOS 15.0+ | Mac Catalyst 15.0+
enum CPAssistantCellActionType { playMedia, startCall }

/// The configuration of the assistant cell, a Siri row CarPlay draws in a
/// [CPListTemplate] for audio and communication apps. The app must ship an
/// Intents extension that handles the intent matching [action].
/// https://developer.apple.com/documentation/carplay/cpassistantcellconfiguration
/// iOS 15.0+ | iPadOS 15.0+ | Mac Catalyst 15.0+
class CPAssistantCellConfiguration {
  final CPAssistantCellPosition position;
  final CPAssistantCellVisibility visibility;
  final CPAssistantCellActionType action;

  const CPAssistantCellConfiguration({
    this.position = CPAssistantCellPosition.top,
    this.visibility = CPAssistantCellVisibility.always,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
    'position': position.name,
    'visibility': visibility.name,
    'action': action.name,
  };
}
