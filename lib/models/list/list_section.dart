import 'package:uuid/uuid.dart';

import 'list_item.dart';

/// A section object of list items that appear in a list template.
class CPListSection {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// Header text of the section.
  final String? header;

  /// A list of items as [[CPListItem]] to include in the section.
  final List<CPListItem> items;

  /// Creates [CPListSection] that contains zero or more list items. You can configure
  /// a section to display a header, which CarPlay displays on the trailing edge of the screen.
  CPListSection({required this.items, this.header});

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'header': header,
        'items': items.map((e) => e.toJson()).toList(),
      };

  String get uniqueId {
    return _elementId;
  }
}
