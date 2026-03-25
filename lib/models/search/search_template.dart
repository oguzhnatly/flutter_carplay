import 'package:uuid/uuid.dart';

import '../template.dart';

class CPSearchTemplate extends CPTemplate {
  final String _elementId = const Uuid().v4();

  final Function(String searchText, Function(List<dynamic> results) update)?
      onSearchTextUpdated;

  final Function(dynamic selectedItem, Function() complete)?
      onSearchResultSelected;

  final Function()? onSearchButtonPressed;

  List<dynamic> _currentResults = [];

  CPSearchTemplate({
    this.onSearchTextUpdated,
    this.onSearchResultSelected,
    this.onSearchButtonPressed,
  }) : super();

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
    _currentResults = List.from(results);
  }
}
