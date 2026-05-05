import 'package:uuid/uuid.dart';

import '../list/list_item.dart';
import '../template.dart';

/// A template that provides the ability to search for a destination and see a list of search results.
/// https://developer.apple.com/documentation/carplay/cpsearchtemplate
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPSearchTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// Tells the delegate that the user updated the search criteria text.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final Function(String searchText, Function(List<CPListItem> results) update)?
      onUpdatedSearchText;

  /// Tells the delegate that the user selected an item from the search result.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final Function(CPListItem selectedItem, Function() complete)?
      onSelectedResult;

  /// Tells the delegate that the user tapped the keyboard's search button.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final Function()? onSearchTemplateSearchButtonPressed;

  final List<CPListItem> _currentResults = [];

  /// Creates [CPSearchTemplate] to display a CarPlay search interface.
  CPSearchTemplate({
    String? id,
    this.onUpdatedSearchText,
    this.onSelectedResult,
    this.onSearchTemplateSearchButtonPressed,
  })  : _elementId = id ?? const Uuid().v4(),
        super();

  @override
  Map<String, dynamic> toJson() => {
        'runtimeType': 'FCPSearchTemplate',
        '_elementId': _elementId,
        'onUpdatedSearchText': onUpdatedSearchText != null,
        'onSelectedResult': onSelectedResult != null,
        'onSearchTemplateSearchButtonPressed':
            onSearchTemplateSearchButtonPressed != null,
      };

  @override
  String get uniqueId => _elementId;

  List<CPListItem> get currentResults => _currentResults;

  void updateResults(List<CPListItem> results) {
    final copy = List<CPListItem>.from(results);
    _currentResults
      ..clear()
      ..addAll(copy);
  }
}
