import 'now_playing_button.dart';

class CPNowPlayingPlaybackRateButton extends CPNowPlayingButton {
  CPNowPlayingPlaybackRateButton({
    super.isEnabled,
    super.isSelected,
    required super.onPress,
    super.id,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'runtimeType': 'FCPNowPlayingPlaybackRateButton',
  };
}
