import 'package:uuid/uuid.dart';

import '../../helpers/carplay_helper.dart';
import '../list/list_item.dart';
import '../template.dart';

/// A template object that displays search template.
class CPSearchTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// An array of search results as [CPListItem]
  List<CPListItem> searchResults = [];

  /// A callback function that CarPlay invokes when the user updates the search text.
  final void Function(String, void Function(List<CPListItem>)) onSearchTextUpdated;

  /// Creates [CPSearchTemplate]
  CPSearchTemplate({required this.onSearchTextUpdated});

  @override
  Map<String, dynamic> toJson() => {'_elementId': _elementId};

  @override
  String get uniqueId {
    return _elementId;
  }

  @override
  bool hasSameValues(CPTemplate other) {
    if (runtimeType != other.runtimeType) return false;
    other as CPSearchTemplate;

    return FlutterCarplayHelper().compareLists(searchResults, other.searchResults, (a, b) => a.hasSameValues(b));
  }
}
