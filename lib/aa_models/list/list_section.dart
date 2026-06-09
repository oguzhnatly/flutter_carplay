import 'package:uuid/uuid.dart';

import 'list_item.dart';

class AAListSection {
  /// Unique id of the object.
  final String _elementId;

  /// Required only when multiple [AAListSection] are used in the same [AAListTemplate].
  final String? title;

  final List<AAListItem> items;
  int? selectedIndex;
  final Function(int selectedIndex, AAListItem selectedItem)? onSelected;

  AAListSection({
    this.title,
    required this.items,
    this.selectedIndex,
    this.onSelected,
    String? id,
  })  : assert(
          selectedIndex == null ||
              (selectedIndex >= 0 && selectedIndex < items.length),
          'selectedIndex must be within the list item range.',
        ),
        assert(
          (selectedIndex == null && onSelected == null) || items.isNotEmpty,
          'A selectable list must have at least one item.',
        ),
        assert(
          selectedIndex == null && onSelected == null ||
              items.every((AAListItem item) => item.onPress == null),
          'Selectable list items must not have an onClickListener set.',
        ),
        assert(
          selectedIndex == null && onSelected == null ||
              items.every((AAListItem item) => item.toggle == null),
          'Selectable list items must not have a toggle set.',
        ),
        _elementId = id ?? const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'items': items.map((AAListItem item) => item.toJson()).toList(),
        'selectedIndex': selectedIndex,
        'onSelected': onSelected != null ? true : false,
      };
}
