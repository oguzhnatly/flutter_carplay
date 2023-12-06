import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:uuid/uuid.dart';

/// A template object that displays map.
class CPMapTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  final String title;
  final List<CPMapButton> mapButtons;
  final List<CPBarButton> leadingNavigationBarButtons;
  final List<CPBarButton> trailingNavigationBarButtons;
  final bool automaticallyHidesNavigationBar;
  final bool hidesButtonsWithNavigationBar;

  /// Creates [CPMapTemplate]
  CPMapTemplate({
    required this.title,
    required this.mapButtons,
    required this.leadingNavigationBarButtons,
    required this.trailingNavigationBarButtons,
    this.automaticallyHidesNavigationBar = false,
    this.hidesButtonsWithNavigationBar = false,
  });

  Map<String, dynamic> toJson() => {
        "_elementId": _elementId,
        "title": title,
        "mapButtons": mapButtons.map((e) => e.toJson()).toList(),
        "leadingNavigationBarButtons":
            leadingNavigationBarButtons.map((e) => e.toJson()).toList(),
        "trailingNavigationBarButtons":
            trailingNavigationBarButtons.map((e) => e.toJson()).toList(),
        "automaticallyHidesNavigationBar": automaticallyHidesNavigationBar,
        "hidesButtonsWithNavigationBar": hidesButtonsWithNavigationBar,
      };

  String get uniqueId {
    return _elementId;
  }
}
