import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';

import '../constants/private_constants.dart';
import '../flutter_carplay.dart';
import '../helpers/carplay_helper.dart';

/// [FlutterCarPlayController] is an root object in order to control and communication
/// system with the Apple CarPlay and native functions.
class FlutterCarPlayController {
  static final FlutterCarplayHelper _carplayHelper = FlutterCarplayHelper();
  static final MethodChannel _methodChannel =
      MethodChannel(_carplayHelper.makeFCPChannelId());
  static final EventChannel _eventChannel =
      EventChannel(_carplayHelper.makeFCPChannelId(event: '/event'));

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPInformationTemplate], [CPPointOfInterestTemplate], [CPMapTemplate], [CPSearchTemplate] in a List
  static List<dynamic> templateHistory = [];

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPInformationTemplate], [CPPointOfInterestTemplate], [CPMapTemplate]
  static dynamic currentRootTemplate;

  /// [CPAlertTemplate], [CPActionSheetTemplate], [CPVoiceControlTemplate]
  static CPPresentTemplate? currentPresentTemplate;

  /// Specific objects that are waiting to receive callback.
  static List<dynamic> callbackObjects = [];

  MethodChannel get methodChannel => _methodChannel;

  EventChannel get eventChannel => _eventChannel;

  /// Invokes the method channel with the specified [type] and [data]
  Future<bool> reactToNativeModule(FCPChannelTypes type, dynamic data) async {
    final value = await _methodChannel.invokeMethod(type.name, data);
    return value;
  }

  /// Displays a banner on [CPMapTemplate]
  static void showBanner(String elementId, String message, int color) {
    _methodChannel.invokeMethod(FCPChannelTypes.showBanner.name, {
      '_elementId': elementId,
      'message': message,
      'color': color,
    });
  }

  /// Hides the banner on [CPMapTemplate]
  static void hideBanner(String elementId) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.hideBanner.name,
      {'_elementId': elementId},
    );
  }

  /// Displays a toast on [CPMapTemplate]
  static void showToast(String elementId, String message, Duration duration) {
    _methodChannel.invokeMethod(FCPChannelTypes.showToast.name, {
      '_elementId': elementId,
      'message': message,
      'duration': duration.inSeconds.toDouble(),
    });
  }

  /// Displays an overlay card on [CPMapTemplate]
  static void showOverlay(
    String elementId,
    String? primaryTitle,
    String? secondaryTitle,
    String? subtitle,
  ) {
    _methodChannel.invokeMethod(FCPChannelTypes.showOverlay.name, {
      '_elementId': elementId,
      'primaryTitle': primaryTitle,
      'secondaryTitle': secondaryTitle,
      'subtitle': subtitle,
    });
  }

  /// Show trip previews on the [CPMapTemplate]
  static void showTripPreviews(
    String elementId,
    List<CPTrip> trips,
    CPTrip? selectedTrip,
    CPTripPreviewTextConfiguration? textConfiguration,
  ) {
    _methodChannel.invokeMethod(FCPChannelTypes.showTripPreviews.name, {
      '_elementId': elementId,
      'trips': trips.map((e) => e.toJson()).toList(),
      'selectedTrip': selectedTrip?.toJson(),
      'textConfiguration': textConfiguration?.toJson(),
    });
  }

  /// Hides the trip previews from the [CPMapTemplate]
  static void hideTripPreviews(String elementId) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.hideTripPreviews.name,
      {'_elementId': elementId},
    );
  }

  /// Show panning interface on the [CPMapTemplate]
  static void showPanningInterface(String elementId, {bool animated = true}) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.showPanningInterface.name,
      {
        '_elementId': elementId,
        'animated': animated,
      },
    );
  }

  /// Dismiss panning interface on the [CPMapTemplate]
  static void dismissPanningInterface(
    String elementId, {
    bool animated = true,
  }) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.dismissPanningInterface.name,
      {
        '_elementId': elementId,
        'animated': animated,
      },
    );
  }

  /// Starts a navigation.
  static void startNavigation(
    String elementId,
    CPTrip trip,
  ) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.startNavigation.name,
      {
        '_elementId': elementId,
        'trip': trip.toJson(),
      },
    );
  }

  /// Stops a navigation.
  static void stopNavigation(String elementId) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.stopNavigation.name,
      {'_elementId': elementId},
    );
  }

  /// Sends back the action text for the next maneuver.
  static void onManeuverActionTextRequestComplete(
    String actionText, {
    bool isPrimary = false,
  }) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.onManeuverActionTextRequestComplete.name,
      {
        'actionText': actionText,
        'isPrimary': isPrimary,
      },
    );
  }

  /// Toggles offline mode.
  static void toggleOfflineMode({bool isOffline = false}) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.toggleOfflineMode.name,
      {'isOffline': isOffline},
    );
  }

  /// Mutes or un-mutes voice instructions.
  static void toggleVoiceInstructions({bool isMuted = false}) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.toggleVoiceInstructions.name,
      {'isMuted': isMuted},
    );
  }

  /// Toggles the satellite view on the [CPMapTemplate].
  static void toggleSatelliteView({bool showSatelliteView = false}) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.toggleSatelliteView.name,
      {'showSatelliteView': showSatelliteView},
    );
  }

  /// Toggles the traffic view on the [CPMapTemplate].
  static void toggleTrafficView({bool showTrafficView = false}) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.toggleTrafficView.name,
      {'showTrafficView': showTrafficView},
    );
  }

  /// Re-centers the map view on the [CPMapTemplate].
  static void recenterMapView(String recenterMapPosition) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.recenterMapView.name,
      {'recenterMapPosition': recenterMapPosition},
    );
  }

  /// Updates the map coordinates on the [CPMapTemplate].
  static void updateMapCoordinates(
    GeoCoordinates? stationAddressCoordinates,
    GeoCoordinates? incidentAddressCoordinates,
    GeoCoordinates? destinationAddressCoordinates,
  ) {
    _methodChannel.invokeMethod(FCPChannelTypes.updateMapCoordinates.name, {
      'stationAddressLatitude': stationAddressCoordinates?.latitude,
      'stationAddressLongitude': stationAddressCoordinates?.longitude,
      'incidentAddressLatitude': incidentAddressCoordinates?.latitude,
      'incidentAddressLongitude': incidentAddressCoordinates?.longitude,
      'destinationAddressLatitude': destinationAddressCoordinates?.latitude,
      'destinationAddressLongitude': destinationAddressCoordinates?.longitude,
    });
  }

  /// Hides the overlay card on [CPMapTemplate]
  static void hideOverlay(String elementId) {
    _methodChannel.invokeMethod(
      FCPChannelTypes.hideOverlay.name,
      {'_elementId': elementId},
    );
  }

  /// Updates the [CPInformationTemplate]
  static void updateCPInformationTemplate(
    CPInformationTemplate updatedTemplate,
  ) {
    final elementId = updatedTemplate.uniqueId;
    _methodChannel
        .invokeMethod(
      FCPChannelTypes.updateInformationTemplate.name,
      updatedTemplate.toJson(),
    )
        .then((value) {
      if (value) {
        for (var template in templateHistory) {
          switch (template) {
            // case final CPTabBarTemplate tabBarTemplate:
            //   for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
            //     if (tab.uniqueId == elementId) {
            //       tabBarTemplate.templates[tabIndex] = updatedTemplate;
            //       return;
            //     }
            //   }
            case final CPInformationTemplate informationTemplate:
              if (informationTemplate.uniqueId == elementId) {
                template = updatedTemplate;
                return;
              }
            default:
          }
        }
      }
    });
  }

  /// Updates the [CPMapTemplate]
  static void updateCPMapTemplate(CPMapTemplate updatedTemplate) {
    final elementId = updatedTemplate.uniqueId;
    _methodChannel
        .invokeMethod(
      FCPChannelTypes.updateMapTemplate.name,
      updatedTemplate.toJson(),
    )
        .then((value) {
      if (value) {
        for (var template in templateHistory) {
          switch (template) {
            // case final CPTabBarTemplate tabBarTemplate:
            //   for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
            //     if (tab.uniqueId == elementId) {
            //       tabBarTemplate.templates[tabIndex] = updatedTemplate;
            //       return;
            //     }
            //   }
            case final CPMapTemplate mapTemplate:
              if (mapTemplate.uniqueId == elementId) {
                template = updatedTemplate;
                return;
              }
            default:
          }
        }
      }
    });
  }

  /// Updates the [CPListTemplate]
  static void updateCPListTemplate(CPListTemplate updatedTemplate) {
    final elementId = updatedTemplate.uniqueId;
    _methodChannel
        .invokeMethod(
      FCPChannelTypes.updateListTemplate.name,
      updatedTemplate.toJson(),
    )
        .then((value) {
      if (value) {
        for (var template in templateHistory) {
          switch (template) {
            case final CPTabBarTemplate tabBarTemplate:
              for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
                if (tab.uniqueId == elementId) {
                  tabBarTemplate.templates[tabIndex] = updatedTemplate;
                  return;
                }
              }
            case final CPListTemplate listTemplate:
              if (listTemplate.uniqueId == elementId) {
                template = updatedTemplate;
                return;
              }
            default:
          }
        }
      }
    });
  }

  /// Updates the [CPListItem]
  static void updateCPListItem(CPListItem updatedListItem) {
    _methodChannel
        .invokeMethod(
      FCPChannelTypes.updateListItem.name,
      updatedListItem.toJson(),
    )
        .then((value) {
      if (value) {
        for (final template in templateHistory) {
          switch (template) {
            case final CPTabBarTemplate tabBarTemplate:
              for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
                for (final (sectionIndex, section) in tab.sections.indexed) {
                  for (final (itemIndex, item) in section.items.indexed) {
                    if (item.uniqueId == updatedListItem.uniqueId) {
                      tabBarTemplate.templates[tabIndex].sections[sectionIndex]
                          .items[itemIndex] = updatedListItem;
                      return;
                    }
                  }
                }
              }
            case final CPListTemplate listTemplate:
              for (final (sectionIndex, section)
                  in listTemplate.sections.indexed) {
                for (final (itemIndex, item) in section.items.indexed) {
                  if (item.uniqueId == updatedListItem.uniqueId) {
                    listTemplate.sections[sectionIndex].items[itemIndex] =
                        updatedListItem;
                    return;
                  }
                }
              }
            default:
          }
        }
      }
    });
  }

  /// Adds the pushed [template] to the [templateHistory]
  void addTemplateToHistory(dynamic template) {
    if (template is CPMapTemplate ||
        template is CPListTemplate ||
        template is CPGridTemplate ||
        template is CPSearchTemplate ||
        template is CPTabBarTemplate ||
        template is CPInformationTemplate ||
        template is CPPointOfInterestTemplate) {
      templateHistory.add(template);
    } else {
      throw TypeError();
    }
  }

  /// Processes the FCPSearchTextUpdatedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPSearchTemplate]
  /// - query: The search query
  void processFCPSearchTextUpdatedChannel(String elementId, String query) {
    for (final template in templateHistory) {
      if (template is CPSearchTemplate && template.uniqueId == elementId) {
        template.onSearchTextUpdated(
          query,
          (searchResults) {
            template.searchResults = searchResults;
            reactToNativeModule(
              FCPChannelTypes.onSearchTextUpdatedComplete,
              {
                '_elementId': elementId,
                'searchResults': searchResults.map((e) => e.toJson()).toList(),
              },
            );
          },
        );
        return;
      }
    }
  }

  /// Processes the FCPSearchResultSelectedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPSearchTemplate]
  /// - itemElementId: The id of the [CPListItem]
  void processFCPSearchResultSelectedChannel(
    String elementId,
    String itemElementId,
  ) {
    for (final template in templateHistory) {
      if (template is CPSearchTemplate && template.uniqueId == elementId) {
        final selectedItem = template.searchResults.singleWhereOrNull(
          (result) => result.uniqueId == itemElementId,
        );
        if (selectedItem != null) {
          selectedItem.onPressed?.call(
            () {},
            selectedItem,
          );
        }
        return;
      }
    }
  }

  /// Processes the FCPSearchCancelledChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPSearchTemplate]
  void processFCPSearchCancelledChannel(String elementId) {
    final topTemplate = templateHistory.lastOrNull;
    if (topTemplate is CPSearchTemplate && topTemplate.uniqueId == elementId) {
      templateHistory.removeLast();
    }
  }

  /// Processes the FCPInformationTemplatePoppedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPInformationTemplate]
  void processFCPInformationTemplatePoppedChannel(String elementId) {
    final topTemplate = templateHistory.lastOrNull;
    if (topTemplate is CPInformationTemplate &&
        topTemplate.uniqueId == elementId) {
      templateHistory.removeLast();
    }
  }

  /// Processes the FCPVoiceControlTemplatePoppedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPVoiceControlTemplate]
  Future<void> proessFCPVoiceControlTemplatePoppedChannel(
    String elementId,
  ) async {
    final topTemplate = FlutterCarPlayController.currentPresentTemplate;
    if (topTemplate is CPVoiceControlTemplate &&
        topTemplate.uniqueId == elementId) {
      await FlutterCarplay.stopVoiceControl();
      FlutterCarplay.removeListenerOnSpeechRecognitionTranscriptChange();
      FlutterCarPlayController.currentPresentTemplate = null;
    }
  }

  /// Processes the FCPListItemSelectedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPListItem]
  void processFCPListItemSelectedChannel(String elementId) {
    final listItem = _carplayHelper.findCPListItem(
      templateHistory: templateHistory,
      elementId: elementId,
    );
    if (listItem != null) {
      listItem.onPressed!(
        () {
          reactToNativeModule(
            FCPChannelTypes.onFCPListItemSelectedComplete,
            listItem.uniqueId,
          );
        },
        listItem,
      );
    }
  }

  /// Processes the FCPAlertActionPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPAlertAction]
  void processFCPAlertActionPressed(String elementId) {
    if (currentPresentTemplate is! CPActionSheetTemplate &&
        currentPresentTemplate is! CPAlertTemplate) return;

    final selectedAlertAction = switch (currentPresentTemplate) {
      final CPAlertTemplate template =>
        template.actions.singleWhereOrNull((e) => e.uniqueId == elementId),
      final CPActionSheetTemplate template =>
        template.actions.singleWhereOrNull((e) => e.uniqueId == elementId),
      _ => null,
    };

    selectedAlertAction?.onPressed();
  }

  /// Processes the FCPAlertTemplateCompletedChannel
  ///
  /// Parameters:
  /// - completed: Whether the alert was successfully presented
  void processFCPAlertTemplateCompleted({bool completed = false}) {
    if (currentPresentTemplate is! CPAlertTemplate) return;
    (currentPresentTemplate as CPAlertTemplate).onPresent?.call(completed);
  }

  /// Processes the FCPGridButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPGridButton]
  void processFCPGridButtonPressed(String elementId) {
    for (final template in templateHistory) {
      if (template is CPGridTemplate) {
        final button = template.buttons.singleWhereOrNull(
          (e) => e.uniqueId == elementId,
        );
        if (button != null) {
          button.onPressed();
          return;
        }
      }
    }
  }

  /// Processes the FCPBarButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPBarButton]
  void processFCPBarButtonPressed(String elementId) {
    for (final template in templateHistory) {
      if (template is CPListTemplate) {
        final backButton = template.backButton;
        if (backButton != null && backButton.uniqueId == elementId) {
          backButton.onPressed();
          return;
        }

        final button = template.leadingNavigationBarButtons.singleWhereOrNull(
              (e) => e.uniqueId == elementId,
            ) ??
            template.trailingNavigationBarButtons.singleWhereOrNull(
              (e) => e.uniqueId == elementId,
            );
        if (button != null) {
          button.onPressed();
          return;
        }
      } else if (template is CPInformationTemplate) {
        final backButton = template.backButton;
        if (backButton != null && backButton.uniqueId == elementId) {
          backButton.onPressed();
          return;
        }

        final button = template.leadingNavigationBarButtons.singleWhereOrNull(
              (e) => e.uniqueId == elementId,
            ) ??
            template.trailingNavigationBarButtons.singleWhereOrNull(
              (e) => e.uniqueId == elementId,
            );
        if (button != null) {
          button.onPressed();
          return;
        }
      } else if (template is CPMapTemplate) {
        final button = template.leadingNavigationBarButtons.singleWhereOrNull(
              (e) => e.uniqueId == elementId,
            ) ??
            template.trailingNavigationBarButtons.singleWhereOrNull(
              (e) => e.uniqueId == elementId,
            );
        if (button != null) {
          button.onPressed();
          return;
        }
      }
    }
  }

  /// Processes the FCPMapButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPMapButton]
  void processFCPMapButtonPressed(String elementId) {
    for (final template in templateHistory) {
      if (template is CPMapTemplate) {
        final button = template.mapButtons.singleWhereOrNull(
          (e) => e.uniqueId == elementId,
        );
        if (button != null) {
          button.onPressed();
          return;
        }
      }
    }
  }

  /// Processes the FCPDashboardButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPMapButton]
  void processFCPDashboardButtonPressed(String elementId) {
    for (final template in templateHistory) {
      if (template is CPMapTemplate) {
        final button = template.dashboardButtons.singleWhereOrNull(
          (e) => e.uniqueId == elementId,
        );
        if (button != null) {
          button.onPressed();
          return;
        }
      }
    }
  }

  /// Processes the FCPTextButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPTextButton]
  void processFCPTextButtonPressed(String elementId) {
    l1:
    for (final template in templateHistory) {
      if (template is CPPointOfInterestTemplate) {
        for (final p in template.poi) {
          if (p.primaryButton != null &&
              p.primaryButton!.uniqueId == elementId) {
            p.primaryButton!.onPressed();
            break l1;
          }
          if (p.secondaryButton != null &&
              p.secondaryButton!.uniqueId == elementId) {
            p.secondaryButton!.onPressed();
            break l1;
          }
        }
      } else {
        if (template is CPInformationTemplate) {
          l2:
          for (final b in template.actions) {
            if (b.uniqueId == elementId) {
              b.onPressed();
              break l2;
            }
          }
        }
      }
    }
  }

  /// Processes the FCPPointOfInterestTemplateCompletedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPPointOfInterestTemplate]
  void processFCPSpeakerOnComplete(String elementId) {
    callbackObjects.removeWhere((e) {
      if (e is CPSpeaker) {
        e.onCompleted?.call();
        return true;
      }
      return false;
    });
  }
}
