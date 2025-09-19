import 'package:uuid/uuid.dart';

class AAListItem {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Function(Function() complete, AAListItem self)? onPress;

  AAListItem({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onPress,
  }) : _elementId = const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'onPress': onPress != null ? true : false,
      };
}
