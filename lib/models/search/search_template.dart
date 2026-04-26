import 'package:uuid/uuid.dart';

import '../template.dart';

/// A template that displays a search interface.
/// https://developer.apple.com/documentation/carplay/cpsearchtemplate
/// iOS 14.0+
class CPSearchTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// Called when the user updates the search text.
  /// Provides the current search text and a callback to update the displayed results.
  /// iOS 14.0+
  final Function(String searchText, Function(List<dynamic> results) update)?
      onSearchTextUpdated;

  /// Called when the user selects a search result.
  /// Provides the selected item and a completion callback to dismiss the search interface.
  /// iOS 14.0+
  final Function(dynamic selectedItem, Function() complete)?
      onSearchResultSelected;

  /// Called when the user taps the search button on the keyboard.
  /// iOS 14.0+
  final Function()? onSearchButtonPressed;

  List<dynamic> _currentResults = [];

  /// Creates [CPSearchTemplate] to display a CarPlay search interface.
  CPSearchTemplate({
    String? id,
    this.onSearchTextUpdated,
    this.onSearchResultSelected,
    this.onSearchButtonPressed,
  })  : _elementId = id ?? const Uuid().v4(),
        super();

  @override
  Map<String, dynamic> toJson() => {
        'runtimeType': 'FCPSearchTemplate',
        '_elementId': _elementId,
        'onSearchTextUpdated': onSearchTextUpdated != null,
        'onSearchResultSelected': onSearchResultSelected != null,
        'onSearchButtonPressed': onSearchButtonPressed != null,
      };

  @override
  String get uniqueId => _elementId;

  List<dynamic> get currentResults => _currentResults;

  void updateResults(List<dynamic> results) {
    final copy = List<dynamic>.from(results);
    _currentResults
      ..clear()
      ..addAll(copy);
  }
}
