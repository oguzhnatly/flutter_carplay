import 'now_playing_button.dart';

class CPNowPlayingImageButton extends CPNowPlayingButton {
  final String image;

  CPNowPlayingImageButton({
    required this.image,
    super.isEnabled,
    super.isSelected,
    required super.onPress,
    super.id,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'runtimeType': 'FCPNowPlayingImageButton',
    'image': image,
  };
}
