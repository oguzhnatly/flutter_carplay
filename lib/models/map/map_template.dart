import 'package:uuid/uuid.dart';

import '../../controllers/carplay_controller.dart';
import '../../flutter_carplay.dart';

/// A template object that displays map.
class CPMapTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  String title;
  List<CPMapButton> mapButtons;
  List<CPBarButton> leadingNavigationBarButtons;
  List<CPBarButton> trailingNavigationBarButtons;
  bool automaticallyHidesNavigationBar;
  bool hidesButtonsWithNavigationBar;

  /// Creates [CPMapTemplate]
  CPMapTemplate({
    this.title = '',
    this.mapButtons = const [],
    this.leadingNavigationBarButtons = const [],
    this.trailingNavigationBarButtons = const [],
    this.automaticallyHidesNavigationBar = false,
    this.hidesButtonsWithNavigationBar = false,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'mapButtons': mapButtons.map((e) => e.toJson()).toList(),
        'leadingNavigationBarButtons':
            leadingNavigationBarButtons.map((e) => e.toJson()).toList(),
        'trailingNavigationBarButtons':
            trailingNavigationBarButtons.map((e) => e.toJson()).toList(),
        'automaticallyHidesNavigationBar': automaticallyHidesNavigationBar,
        'hidesButtonsWithNavigationBar': hidesButtonsWithNavigationBar,
      };

  void updateTitle(String value) {
    title = value;
    FlutterCarPlayController.updateMapTemplate(_elementId, this);
  }

  void updateAutomaticallyHidesNavigationBar({required bool value}) {
    automaticallyHidesNavigationBar = value;
    FlutterCarPlayController.updateMapTemplate(_elementId, this);
  }

  void updateHidesButtonsWithNavigationBar({required bool value}) {
    hidesButtonsWithNavigationBar = value;
    FlutterCarPlayController.updateMapTemplate(_elementId, this);
  }

  void updateMapButtons(List<CPMapButton> buttons) {
    mapButtons = buttons;
    FlutterCarPlayController.updateMapTemplate(_elementId, this);
  }

  void updateLeadingNavigationBarButtons(List<CPBarButton> buttons) {
    leadingNavigationBarButtons = buttons;
    FlutterCarPlayController.updateMapTemplate(_elementId, this);
  }

  void updateTrailingNavigationBarButtons(List<CPBarButton> buttons) {
    trailingNavigationBarButtons = buttons;
    FlutterCarPlayController.updateMapTemplate(_elementId, this);
  }

  String get uniqueId {
    return _elementId;
  }
}
