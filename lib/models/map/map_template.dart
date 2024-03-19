import 'package:uuid/uuid.dart';

import '../../controllers/carplay_controller.dart';
import '../../flutter_carplay.dart';

/// A template object that displays map.
class CPMapTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title will be shown in the navigation bar.
  String title;

  /// The array of map buttons as [CPMapButton] displayed on the template.
  List<CPMapButton> mapButtons;

  /// An array of bar buttons to be displayed on the leading side of the navigation bar.
  List<CPBarButton> leadingNavigationBarButtons;

  /// An array of bar buttons to be displayed on the trailing side of the navigation bar.
  List<CPBarButton> trailingNavigationBarButtons;

  /// Automatically hides the navigation bar when the map template is visible.
  bool automaticallyHidesNavigationBar;

  /// Hides the buttons in the navigation bar when the map template is visible.
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

  /// Update the properties of the [CPMapTemplate]
  void update({
    String? title,
    List<CPMapButton>? mapButtons,
    List<CPBarButton>? leadingNavigationBarButtons,
    List<CPBarButton>? trailingNavigationBarButtons,
    bool? automaticallyHidesNavigationBar,
    bool? hidesButtonsWithNavigationBar,
  }) {
    // update title
    if (title != null) this.title = title;

    // update mapButtons
    if (mapButtons != null) this.mapButtons = mapButtons;

    // update leadingNavigationBarButtons
    if (leadingNavigationBarButtons != null) {
      this.leadingNavigationBarButtons = leadingNavigationBarButtons;
    }

    // update trailingNavigationBarButtons
    if (trailingNavigationBarButtons != null) {
      this.trailingNavigationBarButtons = trailingNavigationBarButtons;
    }

    // update automaticallyHidesNavigationBar
    if (automaticallyHidesNavigationBar != null) {
      this.automaticallyHidesNavigationBar = automaticallyHidesNavigationBar;
    }

    // update hidesButtonsWithNavigationBar
    if (hidesButtonsWithNavigationBar != null) {
      this.hidesButtonsWithNavigationBar = hidesButtonsWithNavigationBar;
    }
    FlutterCarPlayController.updateCPMapTemplate(this);
  }

  /// Displays a trip preview on [CPMapTemplate]
  void showTripPreviews({
    List<CPTrip> trips = const [],
    CPTrip? selectedTrip,
    CPTripPreviewTextConfiguration? textConfiguration,
  }) {
    FlutterCarPlayController.showTripPreviews(
      uniqueId,
      trips,
      selectedTrip,
      textConfiguration,
    );
  }

  /// Hides the trip preview on [CPMapTemplate]
  void hideTripPreviews() {
    FlutterCarPlayController.hideTripPreviews(uniqueId);
  }

  /// Displays a banner on [CPMapTemplate]
  void showBanner({required String message, required int color}) {
    FlutterCarPlayController.showBanner(uniqueId, message, color);
  }

  /// Hides the banner on [CPMapTemplate]
  void hideBanner() {
    FlutterCarPlayController.hideBanner(uniqueId);
  }

  /// Displays a banner on [CPMapTemplate]
  void showToast({
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    FlutterCarPlayController.showToast(uniqueId, message, duration);
  }

  /// Displays an overlay card on [CPMapTemplate]
  void showOverlay({
    String? primaryTitle,
    String? secondaryTitle,
    String? subtitle,
  }) {
    FlutterCarPlayController.showOverlay(
      uniqueId,
      primaryTitle,
      secondaryTitle,
      subtitle,
    );
  }

  /// Hides the overlay on [CPMapTemplate]
  void hideOverlay() {
    FlutterCarPlayController.hideOverlay(uniqueId);
  }

  /// Starts a navigation.
  void startNavigation({
    required double destinationLat,
    required double destinationLong,
  }) {
    FlutterCarPlayController.startNavigation(
      uniqueId,
      destinationLat,
      destinationLong,
    );
  }

  /// Stops a navigation.
  void stopNavigation() {
    FlutterCarPlayController.stopNavigation(uniqueId);
  }

  String get uniqueId {
    return _elementId;
  }
}
