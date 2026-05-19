import 'package:uuid/uuid.dart';

class AAListItem {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final String? subtitle;

  /// Image displayed on the left side of the item. Supports three formats:
  /// - **Asset** (pubspec.yaml): `'images/logo.png'`
  /// - **Local file**: `'file:///path/to/image.png'`
  /// - **Network URL**: `'https://example.com/image.png'`
  final String? image;

  /// Text displayed as the loading screen title while the item's [onPress]
  /// handler is executing (until [complete] is called). When null, no title
  /// is shown.
  final String? loadingMessage;

  final Future<void> Function(Function() complete, AAListItem self)? onPress;

  AAListItem({
    required this.title,
    this.subtitle,
    this.image,
    this.loadingMessage,
    this.onPress,
  }) : _elementId = const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'subtitle': subtitle,
        'image': image,
        'loadingMessage': loadingMessage,
        'onPress': onPress != null ? true : false,
      };
}
