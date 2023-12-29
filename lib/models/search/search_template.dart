import 'package:uuid/uuid.dart';

import '../list/list_item.dart';

/// A template object that displays search template.
class CPSearchTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  List<CPListItem> searchResults = [];

  final Function(String, Function(List<CPListItem>)) onSearchTextUpdated;

  /// Creates [CPSearchTemplate]
  CPSearchTemplate({required this.onSearchTextUpdated});

  Map<String, dynamic> toJson() => {'_elementId': _elementId};

  String get uniqueId {
    return _elementId;
  }
}
