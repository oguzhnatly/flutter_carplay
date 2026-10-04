import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// An image button backed by CarPlay's CPButton, distinct from CPTextButton.
/// Voice state action buttons require iOS 26.4 and an SDK containing that API.
class CPButton {
  CPButton({
    required this.image,
    required this.onPress,
    this.title,
    this.isEnabled = true,
    String? id,
  }) : uniqueId = id ?? const Uuid().v4() {
    if (uniqueId.trim().isEmpty ||
        image.trim().isEmpty ||
        (title != null && title!.trim().isEmpty)) {
      throw ArgumentError(
        'Button identifiers, images and supplied titles must not be empty.',
      );
    }
  }

  final String uniqueId;

  /// A Flutter image asset, file URL or remote image URL. Asset SVGs are rasterized.
  final String image;
  final String? title;
  final bool isEnabled;
  final VoidCallback onPress;

  Map<String, dynamic> toJson() => {
    'runtimeType': 'FCPButton',
    '_elementId': uniqueId,
    'image': image,
    'title': title,
    'isEnabled': isEnabled,
  };
}
