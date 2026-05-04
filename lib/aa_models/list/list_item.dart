import 'package:uuid/uuid.dart';

class AAListItem {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final String? subtitle;
  final String? imageUrl;

  /// Text displayed as the header of the loading screen while the item's
  /// [onPress] handler is executing (until [complete] is called).
  ///
  /// When null the loading screen shows no title.
  final String? loadingMessage;

  final Function(Function() complete, AAListItem self)? onPress;

  AAListItem({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.loadingMessage,
    this.onPress,
  }) : _elementId = const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'loadingMessage': loadingMessage,
        'onPress': onPress != null ? true : false,
      };
}
