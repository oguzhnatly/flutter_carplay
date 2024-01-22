import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

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
  static dynamic currentPresentTemplate;

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
    _methodChannel.invokeMethod('showBanner', {
      '_elementId': elementId,
      'message': message,
      'color': color,
    });
  }

  /// Hides the banner on [CPMapTemplate]
  static void hideBanner(String elementId) {
    _methodChannel.invokeMethod('hideBanner', {'_elementId': elementId});
  }

  /// Displays a toast on [CPMapTemplate]
  static void showToast(String elementId, String message) {
    _methodChannel.invokeMethod('showToast', {
      '_elementId': elementId,
      'message': message,
    });
  }

  /// Displays an overlay card on [CPMapTemplate]
  static void showOverlay(
    String elementId,
    String? primaryTitle,
    String? secondaryTitle,
    String? subtitle,
  ) {
    _methodChannel.invokeMethod('showOverlay', {
      '_elementId': elementId,
      'primaryTitle': primaryTitle,
      'secondaryTitle': secondaryTitle,
      'subtitle': subtitle,
    });
  }

  /// Hides the overlay card on [CPMapTemplate]
  static void hideOverlay(String elementId) {
    _methodChannel.invokeMethod('hideOverlay', {'_elementId': elementId});
  }

  /// Updates the [CPMapTemplate]
  static void updateCPMapTemplate(CPMapTemplate updatedTemplate) {
    final elementId = updatedTemplate.uniqueId;
    _methodChannel
        .invokeMethod('updateMapTemplate', updatedTemplate.toJson())
        .then((value) {
      if (value) {
        l1:
        for (var template in templateHistory) {
          switch (template) {
            // case final CPTabBarTemplate tabBarTemplate:
            //   for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
            //     if (tab.uniqueId == elementId) {
            //       tabBarTemplate.templates[tabIndex] = updatedTemplate;
            //       break l1;
            //     }
            //   }
            case final CPMapTemplate mapTemplate:
              if (mapTemplate.uniqueId == elementId) {
                template = updatedTemplate;
                break l1;
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
        .invokeMethod('updateListTemplate', updatedTemplate.toJson())
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
        .invokeMethod('updateListItem', updatedListItem.toJson())
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
    final CPAlertAction selectedAlertAction = currentPresentTemplate!.actions
        .firstWhere((e) => e.uniqueId == elementId);
    selectedAlertAction.onPressed();
  }

  /// Processes the FCPAlertTemplateCompletedChannel
  ///
  /// Parameters:
  /// - completed: Whether the alert was successfully presented
  void processFCPAlertTemplateCompleted({bool completed = false}) {
    if (currentPresentTemplate?.onPresent != null) {
      currentPresentTemplate!.onPresent!(completed);
    }
  }

  /// Processes the FCPGridButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPGridButton]
  void processFCPGridButtonPressed(String elementId) {
    for (final template in templateHistory) {
      if (template is CPGridTemplate) {
        for (final button in template.buttons) {
          if (button.uniqueId == elementId) {
            button.onPressed();
            return;
          }
        }
      }
    }
  }

  /// Processes the FCPBarButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPBarButton]
  void processFCPBarButtonPressed(String elementId) {
    l1:
    for (final template in templateHistory) {
      if (template is CPListTemplate) {
        final backButton = template.backButton;
        if (backButton != null && backButton.uniqueId == elementId) {
          backButton.onPressed();
          break l1;
        }
        for (final button in template.trailingNavigationBarButtons) {
          if (button.uniqueId == elementId) {
            button.onPressed();
            break l1;
          }
        }
        for (final button in template.leadingNavigationBarButtons) {
          if (button.uniqueId == elementId) {
            button.onPressed();
            break l1;
          }
        }
      } else {
        l2:
        if (template is CPMapTemplate) {
          for (final button in template.trailingNavigationBarButtons) {
            if (button.uniqueId == elementId) {
              button.onPressed();
              break l2;
            }
          }
          for (final button in template.leadingNavigationBarButtons) {
            if (button.uniqueId == elementId) {
              button.onPressed();
              break l2;
            }
          }
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
        for (final button in template.mapButtons) {
          if (button.uniqueId == elementId) {
            button.onPressed();
            return;
          }
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
