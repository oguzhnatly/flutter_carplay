import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class CPNowPlayingImageButton {
  final String _elementId;

  final String image;

  final bool isEnabled;

  final bool isSelected;

  final VoidCallback onPress;

  CPNowPlayingImageButton({
    required this.image,
    this.isEnabled = true,
    this.isSelected = false,
    required this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    '_elementId': _elementId,
    'image': image,
    'isEnabled': isEnabled,
    'isSelected': isSelected,
  };

  String get uniqueId {
    return _elementId;
  }
}
