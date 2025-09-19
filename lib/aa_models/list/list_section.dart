import 'package:uuid/uuid.dart';

import 'list_item.dart';

class AAListSection {
  /// Unique id of the object.
  final String _elementId;

  /// Required only when multiple [AAListSection] are used in the same [AAListTemplate].
  final String? title;

  final List<AAListItem> items;

  AAListSection({
    this.title,
    required this.items,
  }) : _elementId = const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'items': items.map((AAListItem item) => item.toJson()).toList(),
      };
}
