import 'package:flutter/services.dart';
import 'package:flutter_carplay/constants/private_constants.dart';

import '../aa_models/list/list_item.dart';
import '../aa_models/template.dart';
import '../helpers/auto_android_helper.dart';

/// [FlutterAndroidAutoController] is an root object in order to control and communication
/// system with the Android Auto and native functions.
class FlutterAndroidAutoController {
  static final FlutterAutoAndroidHelper _androidAutoHelper =
      const FlutterAutoAndroidHelper();
  static final MethodChannel _methodChannel = MethodChannel(
    _androidAutoHelper.makeFAAChannelId(),
  );
  static final EventChannel _eventChannel = EventChannel(
    _androidAutoHelper.makeFAAChannelId(event: '/event'),
  );

  /// [AATabBarTemplate], [AAGridTemplate], [AAListTemplate], [AAIInformationTemplate], [AAPointOfInterestTemplate] in a List
  static List<AATemplate> templateHistory = [];

  /// [AATabBarTemplate], [AAGridTemplate], [AAListTemplate], [AAIInformationTemplate], [AAPointOfInterestTemplate]
  static AATemplate? get currentRootTemplate => templateHistory.firstOrNull;

  /// [AAAlertTemplate], [AAActionSheetTemplate]
  static AATemplate? currentPresentTemplate;

  MethodChannel get methodChannel => _methodChannel;

  EventChannel get eventChannel => _eventChannel;

  Future<bool?> flutterToNativeModule(
    FAAChannelTypes type, [
    dynamic data,
  ]) async {
    final bool? value = await _methodChannel.invokeMethod<bool>(
      type.name,
      data,
    );
    return value;
  }

  /* static void updateCPListItem(CPListItem updatedListItem) {
    _methodChannel.invokeMethod('updateListItem', <String, dynamic>{
      ...updatedListItem.toJson(),
    }).then((value) {
      if (value) {
        l1:
        for (var h in templateHistory) {
          switch (h.runtimeType) {
            case CPTabBarTemplate _:
              for (var t in (h as CPTabBarTemplate).templates) {
                for (var s in t.sections) {
                  for (var i in s.items) {
                    if (i.uniqueId == updatedListItem.uniqueId) {
                      currentRootTemplate!
                          .templates[currentRootTemplate!.templates.indexOf(t)]
                          .sections[t.sections.indexOf(s)]
                          .items[s.items.indexOf(i)] = updatedListItem;
                      break l1;
                    }
                  }
                }
              }
              break;
            case CPListTemplate _:
              for (var s in (h as CPListTemplate).sections) {
                for (var i in s.items) {
                  if (i.uniqueId == updatedListItem.uniqueId) {
                    currentRootTemplate!
                        .sections[currentRootTemplate!.sections.indexOf(
                      s,
                    )]
                        .items[s.items.indexOf(i)] = updatedListItem;
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
  }*/

  void processFAAListItemSelectedChannel(String elementId) {
    final AAListItem? listItem = _androidAutoHelper.findAAListItem(
      templates: templateHistory,
      elementId: elementId,
    );
    if (listItem != null) {
      listItem.onPress!(
        () => flutterToNativeModule(
          FAAChannelTypes.onListItemSelectedComplete,
          listItem.uniqueId,
        ),
        listItem,
      );
    }
  }

/*void processFAAAlertActionPressed(String elementId) {
    CAAAlertAction selectedAlertAction = currentPresentTemplate!.actions
        .firstWhere((e) => e.uniqueId == elementId);
    selectedAlertAction.onPress();
  }*/

/*void processFCPAlertTemplateCompleted(bool completed) {
    if (currentPresentTemplate?.onPresent != null) {
      currentPresentTemplate!.onPresent!(completed);
    }
  }*/

/*void processFCPGridButtonPressed(String elementId) {
    CPGridButton? gridButton;
    l1:
    for (var t in templateHistory) {
      if (t.runtimeType.toString() == "CPGridTemplate") {
        for (var b in t.buttons) {
          if (b.uniqueId == elementId) {
            gridButton = b;
            break l1;
          }
        }
      }
    }
    if (gridButton != null) gridButton.onPress();
  }*/

/*void processFCPBarButtonPressed(String elementId) {
    CPBarButton? barButton;
    l1:
    for (var t in templateHistory) {
      if (t.runtimeType.toString() == "CPListTemplate") {
        barButton = t.backButton;
        break l1;
      }
    }
    if (barButton != null) barButton.onPress();
  }*/

/*void processFCPTextButtonPressed(String elementId) {
    l1:
    for (var t in templateHistory) {
      if (t.runtimeType.toString() == "CPPointOfInterestTemplate") {
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
        if (t.runtimeType.toString() == "CPInformationTemplate") {
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
  }*/
}
