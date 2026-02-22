import 'package:flutter/services.dart';
import 'package:flutter_carplay/constants/private_constants.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_carplay/helpers/carplay_helper.dart';

import '../models/template.dart';

/// [FlutterCarPlayController] is an root object in order to control and communication
/// system with the Apple CarPlay and native functions.
class FlutterCarPlayController {
  static final FlutterCarplayHelper _carplayHelper = FlutterCarplayHelper();
  static final MethodChannel _methodChannel = MethodChannel(
    _carplayHelper.makeFCPChannelId(),
  );
  static final EventChannel _eventChannel = EventChannel(
    _carplayHelper.makeFCPChannelId(event: '/event'),
  );

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPIInformationTemplate], [CPPointOfInterestTemplate] in a List
  static List<CPTemplate> templateHistory = [];

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPIInformationTemplate], [CPPointOfInterestTemplate]
  static CPTemplate? get currentRootTemplate => templateHistory.firstOrNull;

  /// [CPAlertTemplate], [CPActionSheetTemplate]
  static CPTemplate? currentPresentTemplate;

  MethodChannel get methodChannel {
    return _methodChannel;
  }

  EventChannel get eventChannel {
    return _eventChannel;
  }

  Future<bool?> flutterToNativeModule(
    FCPChannelTypes type,
    dynamic data,
  ) async {
    final value = await _methodChannel.invokeMethod<bool>(
      EnumUtils.stringFromEnum(type.toString()),
      data,
    );
    return value;
  }

  static void updateCPListItem(CPListItem updatedListItem) {
    _methodChannel.invokeMethod('updateListItem', <String, dynamic>{
      ...updatedListItem.toJson(),
    }).then((value) {
      if (value) {
        l1:
        for (var h in templateHistory) {
          switch (h) {
            case CPTabBarTemplate _:
              for (var t in h.templates) {
                if (t is CPListTemplate) {
                  for (var s in t.sections) {
                    for (var i in s.items) {
                      if (i.uniqueId == updatedListItem.uniqueId) {
                        s.items[s.items.indexOf(i)] = updatedListItem;
                        break l1;
                      }
                    }
                  }
                }
              }
              break;
            case CPListTemplate _:
              for (var s in h.sections) {
                for (var i in s.items) {
                  if (i.uniqueId == updatedListItem.uniqueId) {
                    s.items[s.items.indexOf(i)] = updatedListItem;
                    break l1;
                  }
                }
              }
              break;
            default:
          }
        }
      }
    });
  }

  void addTemplateToHistory(CPTemplate template) {
    if (template is CPTabBarTemplate ||
        template is CPGridTemplate ||
        template is CPInformationTemplate ||
        template is CPPointOfInterestTemplate ||
        template is CPListTemplate) {
      templateHistory.add(template);
    } else {
      throw TypeError();
    }
  }

  void processFCPListItemSelectedChannel(String elementId) {
    final CPListItem? listItem = _carplayHelper.findCPListItem(
      templates: templateHistory,
      elementId: elementId,
    );
    if (listItem != null) {
      listItem.onPress!(
        () => flutterToNativeModule(
          FCPChannelTypes.onFCPListItemSelectedComplete,
          listItem.uniqueId,
        ),
        listItem,
      );
    }
  }

  void processFCPAlertActionPressed(String elementId) {
    final CPAlertAction selectedAlertAction =
        (currentPresentTemplate as CPActionsTemplate)
            .actions
            .firstWhere((e) => e.uniqueId == elementId);
    selectedAlertAction.onPress();
  }

  void processFCPAlertTemplateCompleted(bool completed) {
    if (currentPresentTemplate is CPAlertTemplate) {
      (currentPresentTemplate as CPAlertTemplate).onPresent?.call(completed);
    }
  }

  void processFCPGridButtonPressed(String elementId) {
    CPGridButton? gridButton;
    l1:
    for (var t in templateHistory) {
      if (t is CPGridTemplate) {
        for (var b in t.buttons) {
          if (b.uniqueId == elementId) {
            gridButton = b;
            break l1;
          }
        }
      }
    }
    if (gridButton != null) gridButton.onPress();
  }

  void processFCPBarButtonPressed(String elementId) {
    CPBarButton? barButton;
    l1:
    for (var t in templateHistory) {
      if (t is CPListTemplate) {
        barButton = t.backButton;
        break l1;
      }
    }
    if (barButton != null) barButton.onPress();
  }

  void processFCPTextButtonPressed(String elementId) {
    l1:
    for (var t in templateHistory) {
      if (t is CPPointOfInterestTemplate) {
        for (CPPointOfInterest p in t.poi) {
          if (p.primaryButton != null &&
              p.primaryButton!.uniqueId == elementId) {
            p.primaryButton!.onPress();
            break l1;
          }
          if (p.secondaryButton != null &&
              p.secondaryButton!.uniqueId == elementId) {
            p.secondaryButton!.onPress();
            break l1;
          }
        }
      } else {
        if (t is CPInformationTemplate) {
          l2:
          for (CPTextButton b in t.actions) {
            if (b.uniqueId == elementId) {
              b.onPress();
              break l2;
            }
          }
        }
      }
    }
  }

  static T? getTemplateFromHistory<T extends CPTemplate>(String elementId) {
    for (final template in templateHistory) {
      if (template is T && template.uniqueId == elementId) return template;

      if (template is CPTabBarTemplate) {
        for (final t in template.templates) {
          if (t is T && t.uniqueId == elementId) return t;
        }
      }
    }
    return null;
  }
}
