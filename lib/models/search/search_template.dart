import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:uuid/uuid.dart';

/// A template object that displays and manages a search query.
class CPSearchTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// An array of search results as [CPListItem].
  List<CPListItem> searchResults = [];

  /// A duration in seconds that the search query is debounced.
  final double debounceDuration;

  /// Whether the search should be performed as the user types or
  /// when the search button is pressed.
  final bool shouldSearchAsType;

  /// A callback function that CarPlay invokes when the user updates the search text.
  final void Function(String, void Function(List<CPListItem>))
      onSearchTextUpdated;

  /// Creates [CPSearchTemplate].
  CPSearchTemplate({
    required this.onSearchTextUpdated,
    this.shouldSearchAsType = true,
    this.debounceDuration = 0.5,
  });

  /// Creates json from [CPSearchTemplate].
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'shouldSearchAsType': shouldSearchAsType,
        'debounceDuration': debounceDuration,
      };

  /// Unique id of the object.
  String get uniqueId {
    return _elementId;
  }
}
