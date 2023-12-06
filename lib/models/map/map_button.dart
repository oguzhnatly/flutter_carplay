import 'package:uuid/uuid.dart';

/// A button object for placement in a map.
class CPMapButton {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The title displayed on the bar button.
  final String title;
  final bool isEnabled;
  final bool isHidden;
  final String? image;
  final String? focusedImage;

  /// Fired when the user taps a map button.
  final Function() onPress;

  /// Creates [CPMapButton] with a title, style and handler.
  CPMapButton({
    required this.title,
    required this.onPress,
    this.isEnabled = true,
    this.isHidden = false,
    this.image,
    this.focusedImage,
  });

  Map<String, dynamic> toJson() => {
        "_elementId": _elementId,
        "title": title,
        "isEnabled": isEnabled,
        "isHidden": isHidden,
        "image": image,
        "focusedImage": focusedImage,
      };

  String get uniqueId {
    return _elementId;
  }
}
