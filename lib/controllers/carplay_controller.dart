import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

/// [FlutterCarPlayController] is an root object in order to control and communication
/// system with the Apple CarPlay and native functions.
class FlutterCarPlayController {
  static final FlutterCarplayHelper _carplayHelper =
      const FlutterCarplayHelper();
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

  static Future<bool?> flutterToNativeModule(
    FCPChannelTypes type, [
    dynamic data,
  ]) async {
    final value = await _methodChannel.invokeMethod<bool>(
      type.name,
      data,
    );
    return value;
  }

  static void updateCPListItem(
    CPListItem updatedListItem,
  ) {
    flutterToNativeModule(
      FCPChannelTypes.updateListItem,
      updatedListItem.toJson(),
    ).then(
      (value) {
        if (value != true) return;

        for (var h in templateHistory) {
          switch (h) {
            case CPTabBarTemplate _:
              for (var t in h.templates) {
                if (t is CPListTemplate) {
                  for (var s in t.sections) {
                    for (var i in s.items) {
                      if (i.uniqueId == updatedListItem.uniqueId &&
                          i is CPListItem) {
                        s.items[s.items.indexOf(i)] = updatedListItem;
                        return;
                      }
                    }
                  }
                }
              }
              break;
            case CPListTemplate _:
              for (var s in h.sections) {
                for (var i in s.items) {
                  if (i.uniqueId == updatedListItem.uniqueId &&
                      i is CPListItem) {
                    s.items[s.items.indexOf(i)] = updatedListItem;
                    return;
                  }
                }
              }
              break;
            default:
          }
        }
      },
    );
  }

  static void updateCPListImageRowItemElement(
    CPListImageRowItemElement updatedListImageRowItemElement,
  ) {
    flutterToNativeModule(
      FCPChannelTypes.updateListImageRowItemElement,
      updatedListImageRowItemElement.toJson(),
    ).then(
      (value) {
        if (value != true) return;

        for (var h in templateHistory) {
          switch (h) {
            case CPTabBarTemplate _:
              for (var t in h.templates) {
                if (t is CPListTemplate) {
                  for (var s in t.sections) {
                    for (var i in s.items) {
                      if (i is CPListImageRowItem) {
                        for (var e in i.elements ?? []) {
                          if (e.uniqueId ==
                              updatedListImageRowItemElement.uniqueId) {
                            i.elements![i.elements!.indexOf(e)] =
                                updatedListImageRowItemElement;
                            return;
                          }
                        }
                      }
                    }
                  }
                }
              }
              break;
            case CPListTemplate _:
              for (var s in h.sections) {
                for (var i in s.items) {
                  if (i is CPListImageRowItem) {
                    for (var e in i.elements ?? []) {
                      if (e.uniqueId ==
                          updatedListImageRowItemElement.uniqueId) {
                        i.elements![i.elements!.indexOf(e)] =
                            updatedListImageRowItemElement;
                        return;
                      }
                    }
                  }
                }
              }
              break;
            default:
          }
        }
      },
    );
  }

  static void updateCPListImageRowItem(
    CPListImageRowItem updatedListImageItem,
  ) {
    flutterToNativeModule(
      FCPChannelTypes.updateListImageRowItem,
      updatedListImageItem.toJson(),
    ).then(
      (value) {
        if (value != true) return;

        for (var h in templateHistory) {
          switch (h) {
            case CPTabBarTemplate _:
              for (var t in h.templates) {
                if (t is CPListTemplate) {
                  for (var s in t.sections) {
                    for (var i in s.items) {
                      if (i.uniqueId == updatedListImageItem.uniqueId &&
                          i is CPListImageRowItem) {
                        s.items[s.items.indexOf(i)] = updatedListImageItem;
                        return;
                      }
                    }
                  }
                }
              }
              break;
            case CPListTemplate _:
              for (var s in h.sections) {
                for (var i in s.items) {
                  if (i.uniqueId == updatedListImageItem.uniqueId &&
                      i is CPListImageRowItem) {
                    s.items[s.items.indexOf(i)] = updatedListImageItem;
                    return;
                  }
                }
              }
              break;
            default:
          }
        }
      },
    );
  }

  static Future<int?> getMaximumNumberOfGridImages() async {
    final value = await _methodChannel.invokeMethod<int>(
      FCPChannelTypes.getMaximumNumberOfGridImages.name,
    );
    return value;
  }

  static Future<int?> getMaximumSectionCount() async {
    final value = await _methodChannel.invokeMethod<int>(
      FCPChannelTypes.getMaximumSectionCount.name,
    );
    return value;
  }

  static Future<int?> getMaximumItemCount() async {
    final value = await _methodChannel.invokeMethod<int>(
      FCPChannelTypes.getMaximumItemCount.name,
    );
    return value;
  }

  void addTemplateToHistory(CPTemplate template) {
    if (template is CPTabBarTemplate ||
        template is CPGridTemplate ||
        template is CPInformationTemplate ||
        template is CPPointOfInterestTemplate ||
        template is CPListTemplate ||
        template is CPSearchTemplate) {
      templateHistory.add(template);
    } else {
      throw TypeError();
    }
  }

  void processFCPListItemSelectedChannel(String elementId) {
    final item = _carplayHelper.findCPListTemplateItem(
      templates: templateHistory,
      elementId: elementId,
    );

    if (item is CPListItem) {
      item.onPress?.call(
        () => flutterToNativeModule(
          FCPChannelTypes.onFCPListItemSelectedComplete,
          item.uniqueId,
        ),
        item,
      );
    }
  }

  void processFCPListImageRowItemSelectedChannel(String elementId) {
    final item = _carplayHelper.findCPListTemplateItem(
      templates: templateHistory,
      elementId: elementId,
    );

    if (item is CPListImageRowItem) {
      item.onPress?.call(
        () => flutterToNativeModule(
          FCPChannelTypes.onFCPListImageRowItemSelectedComplete,
          item.uniqueId,
        ),
        item,
      );
    }
  }

  void processFCPListImageRowItemElementSelectedChannel(
    String elementId,
    int index,
  ) {
    final item = _carplayHelper.findCPListTemplateItem(
      templates: templateHistory,
      elementId: elementId,
    );

    if (item is CPListImageRowItem) {
      item.onItemPress?.call(
        () => flutterToNativeModule(
          FCPChannelTypes.onFCPListImageRowItemElementSelectedComplete,
          item.uniqueId,
        ),
        item,
        index,
      );
    }
  }

  void processFCPAlertActionPressed(String elementId) {
    if (currentPresentTemplate is! CPActionsTemplate) return;

    final actions = (currentPresentTemplate as CPActionsTemplate).actions;
    for (var action in actions) {
      if (action.uniqueId == elementId) {
        action.onPress();
        return;
      }
    }
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
    gridButton?.onPress?.call();
  }

  void processFCPBarButtonPressed(String elementId) {
    for (var t in templateHistory) {
      final List<CPListTemplate> listTemplates = [];
      if (t is CPTabBarTemplate) {
        for (var template in t.templates) {
          if (template is CPListTemplate) listTemplates.add(template);
        }
      } else if (t is CPListTemplate) {
        listTemplates.add(t);
      }
      for (var list in listTemplates) {
        if (list.backButton?.uniqueId == elementId) {
          list.backButton?.onPress();
          return;
        }
      }
    }
  }

  void processFCPTextButtonPressed(String elementId) {
    for (var t in templateHistory) {
      if (t is CPPointOfInterestTemplate) {
        for (CPPointOfInterest p in t.poi) {
          if (p.primaryButton != null &&
              p.primaryButton!.uniqueId == elementId) {
            p.primaryButton!.onPress();
            return;
          }
          if (p.secondaryButton != null &&
              p.secondaryButton!.uniqueId == elementId) {
            p.secondaryButton!.onPress();
            return;
          }
        }
      } else {
        if (t is CPInformationTemplate) {
          for (CPTextButton b in t.actions) {
            if (b.uniqueId == elementId) {
              b.onPress();
              return;
            }
          }
        }
      }
    }
  }

  void processFCPSearchTextUpdated(String elementId, String searchText) {
    for (var t in templateHistory) {
      if (t is CPSearchTemplate && t.uniqueId == elementId) {
        t.onSearchTextUpdated?.call(
          searchText,
          (List<dynamic> results) {
            t.updateResults(results);
            final items = results
                .whereType<CPListItem>()
                .map((e) => e.toJson())
                .toList();
            _methodChannel.invokeMethod('updateSearchResults', <String, dynamic>{
              'elementId': elementId,
              'searchResults': items,
            });
          },
        );
        return;
      }
    }
  }

  void processFCPSearchResultSelected(String elementId, String itemElementId) {
    for (var t in templateHistory) {
      if (t is CPSearchTemplate && t.uniqueId == elementId) {
        CPListItem? selectedItem;
        for (var item in t.currentResults) {
          if (item is CPListItem && item.uniqueId == itemElementId) {
            selectedItem = item;
            break;
          }
        }
        if (selectedItem != null) {
          t.onSearchResultSelected?.call(
            selectedItem,
            () {
              _methodChannel.invokeMethod(
                  'onSearchResultSelectedComplete', <String, dynamic>{
                'elementId': elementId,
              });
            },
          );
        }
        return;
      }
    }
  }

  void processFCPSearchButtonPressed(String elementId) {
    for (var t in templateHistory) {
      if (t is CPSearchTemplate && t.uniqueId == elementId) {
        t.onSearchButtonPressed?.call();
        return;
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
