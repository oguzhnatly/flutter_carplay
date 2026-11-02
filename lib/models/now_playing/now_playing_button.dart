import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

abstract class CPNowPlayingButton {
  final String _elementId;

  final bool isEnabled;

  final bool isSelected;

  final VoidCallback onPress;

  CPNowPlayingButton({
    this.isEnabled = true,
    this.isSelected = false,
    required this.onPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    '_elementId': _elementId,
    'isEnabled': isEnabled,
    'isSelected': isSelected,
  };

  String get uniqueId {
    return _elementId;
  }
}
