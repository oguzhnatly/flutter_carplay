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

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPIInformationTemplate], [CPPointOfInterestTemplate] in a List
  static List<dynamic> templateHistory = [];

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPIInformationTemplate], [CPPointOfInterestTemplate]
  static dynamic currentRootTemplate;

  /// [CPAlertTemplate], [CPActionSheetTemplate], [CPVoiceControlTemplate]
  static dynamic currentPresentTemplate;

  /// Specific objects that are waiting to receive callback.
  static List<dynamic> callbackObjects = [];

  MethodChannel get methodChannel {
    return _methodChannel;
  }

  EventChannel get eventChannel {
    return _eventChannel;
  }

  Future<bool> reactToNativeModule(FCPChannelTypes type, dynamic data) async {
    final value = await _methodChannel.invokeMethod(
      CPEnumUtils.stringFromEnum(type.toString()),
      data,
    );
    return value;
  }

  static void updateListTemplate(
    String elementId,
    CPListTemplate updatedTemplate,
  ) {
    _methodChannel
        .invokeMethod('updateListTemplate', updatedTemplate.toJson())
        .then((value) {
      if (value) {
        l1:
        for (var template in templateHistory) {
          switch (template) {
            case final CPTabBarTemplate tabBarTemplate:
              for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
                if (tab.uniqueId == elementId) {
                  tabBarTemplate.templates[tabIndex] = updatedTemplate;
                  break l1;
                }
              }
            case final CPListTemplate listTemplate:
              if (listTemplate.uniqueId == elementId) {
                template = updatedTemplate;
                break l1;
              }
            default:
          }
        }
      }
    });
  }

  static void updateCPListItem(CPListItem updatedListItem) {
    _methodChannel
        .invokeMethod('updateListItem', updatedListItem.toJson())
        .then((value) {
      if (value) {
        l1:
        for (final template in templateHistory) {
          switch (template) {
            case final CPTabBarTemplate tabBarTemplate:
              for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
                for (final (sectionIndex, section) in tab.sections.indexed) {
                  for (final (itemIndex, item) in section.items.indexed) {
                    if (item.uniqueId == updatedListItem.uniqueId) {
                      tabBarTemplate.templates[tabIndex].sections[sectionIndex]
                          .items[itemIndex] = updatedListItem;
                      break l1;
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
                    break l1;
                  }
                }
              }
            default:
          }
        }
      }
    });
  }

  void addTemplateToHistory(dynamic template) {
    if (template.runtimeType == CPTabBarTemplate ||
        template.runtimeType == CPGridTemplate ||
        template.runtimeType == CPInformationTemplate ||
        template.runtimeType == CPMapTemplate ||
        template.runtimeType == CPPointOfInterestTemplate ||
        template.runtimeType == CPListTemplate) {
      templateHistory.add(template);
    } else {
      throw TypeError();
    }
  }

  void processFCPListItemSelectedChannel(String elementId) {
    final listItem = _carplayHelper.findCPListItem(
      templates: templateHistory,
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

  void processFCPAlertActionPressed(String elementId) {
    final CPAlertAction selectedAlertAction = currentPresentTemplate!.actions
        .firstWhere((e) => e.uniqueId == elementId);
    selectedAlertAction.onPressed();
  }

  void processFCPAlertTemplateCompleted({bool completed = false}) {
    if (currentPresentTemplate?.onPresent != null) {
      currentPresentTemplate!.onPresent!(completed);
    }
  }

  void processFCPGridButtonPressed(String elementId) {
    CPGridButton? gridButton;
    l1:
    for (final template in templateHistory) {
      if (template is CPGridTemplate) {
        for (final b in template.buttons) {
          if (b.uniqueId == elementId) {
            gridButton = b;
            break l1;
          }
        }
      }
    }
    if (gridButton != null) gridButton.onPressed();
  }

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

  void processFCPMapButtonPressed(String elementId) {
    l1:
    for (final template in templateHistory) {
      if (template is CPMapTemplate) {
        for (final button in template.mapButtons) {
          if (button.uniqueId == elementId) {
            button.onPressed();
            break l1;
          }
        }
      }
      break l1;
    }
  }

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

  void processFCPSpeakerOnComplete(String elementId) {
    callbackObjects.removeWhere((e) {
      if (e is CPSpeaker) {
        // e.uniqueId == elementId;
        e.onCompleted?.call();
        return true;
      }
      return false;
    });
  }
}
