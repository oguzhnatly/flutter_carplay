import 'dart:async';

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

  /// The currently presented modal, including voice control.
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
    bool Function()? isCurrent,
  ]) async {
    // Rasterize any Flutter asset SVGs referenced by image fields into PNG
    // bytes before sending the payload to the native side, which cannot render
    // SVG directly. Non-collection payloads pass through unchanged.
    await resolveSvgInPayload(data, size: FlutterCarplay.svgRasterSize);

    if (isCurrent != null && !isCurrent()) return false;
    final value = await _methodChannel.invokeMethod<bool>(type.name, data);
    return value;
  }

  static _ModalRequest? _modalRequest;

  static Future<bool> presentModal(
    CPTemplate template,
    FCPChannelTypes method,
    Map<String, dynamic> arguments,
  ) async {
    if (_modalRequest != null || currentPresentTemplate != null) return false;
    final request = _ModalRequest(template);
    _modalRequest = request;
    try {
      final completed = await Future.any<bool?>([
        flutterToNativeModule(method, arguments, () {
          if (!identical(_modalRequest, request)) return false;
          request.invoked = true;
          return true;
        }),
        request.cancelled.future,
      ]);
      if (!identical(_modalRequest, request)) return false;
      if (completed != true) {
        _modalRequest = null;
        return false;
      }
      currentPresentTemplate = template;
      return true;
    } catch (_) {
      if (identical(_modalRequest, request)) _modalRequest = null;
      rethrow;
    }
  }

  static void dismissCurrentModal({String? elementId}) {
    final template = _modalRequest?.template ?? currentPresentTemplate;
    if (template == null ||
        (elementId != null && template.uniqueId != elementId)) {
      return;
    }
    final request = _modalRequest;
    _modalRequest = null;
    currentPresentTemplate = null;
    if (request != null && !request.cancelled.isCompleted) {
      request.cancelled.complete(false);
    }
    if (template is CPVoiceControlTemplate) template.onDismiss?.call();
  }

  static Future<bool> dismissModal(bool animated) {
    final request = _modalRequest;
    if (request == null) return Future.value(false);
    if (!request.invoked) {
      dismissCurrentModal();
      return Future.value(true);
    }
    return request.dismissal ??= _dismissModalRequest(request, animated);
  }

  static Future<bool> _dismissModalRequest(
    _ModalRequest request,
    bool animated,
  ) async {
    try {
      final completed = await flutterToNativeModule(
        FCPChannelTypes.closePresent,
        animated,
        () => identical(_modalRequest, request),
      );
      if (completed == true && identical(_modalRequest, request)) {
        dismissCurrentModal();
      }
      return completed == true;
    } finally {
      request.dismissal = null;
    }
  }

  void processVoiceControlButtonPressed(String templateId, String elementId) {
    final template = currentPresentTemplate;
    if (template is! CPVoiceControlTemplate ||
        template.uniqueId != templateId) {
      return;
    }
    for (final state in template.voiceControlStates) {
      for (final button in state.actionButtons) {
        if (button.uniqueId == elementId) {
          if (button.isEnabled) button.onPress();
          return;
        }
      }
    }
    for (final button in [
      ...template.leadingNavigationBarButtons,
      ...template.trailingNavigationBarButtons,
    ]) {
      if (button.uniqueId == elementId) {
        button.onPress();
        return;
      }
    }
  }

  static void updateCPListItem(CPListItem updatedListItem) {
    flutterToNativeModule(
      FCPChannelTypes.updateListItem,
      updatedListItem.toJson(),
    ).then((value) {
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
                if (i.uniqueId == updatedListItem.uniqueId && i is CPListItem) {
                  s.items[s.items.indexOf(i)] = updatedListItem;
                  return;
                }
              }
            }
            break;
          default:
        }
      }
    });
  }

  static void updateCPListImageRowItemElement(
    CPListImageRowItemElement updatedListImageRowItemElement,
  ) {
    flutterToNativeModule(
      FCPChannelTypes.updateListImageRowItemElement,
      updatedListImageRowItemElement.toJson(),
    ).then((value) {
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
                    if (e.uniqueId == updatedListImageRowItemElement.uniqueId) {
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
    });
  }

  static void updateCPListImageRowItem(
    CPListImageRowItem updatedListImageItem,
  ) {
    flutterToNativeModule(
      FCPChannelTypes.updateListImageRowItem,
      updatedListImageItem.toJson(),
    ).then((value) {
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
    });
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

  Future<void> processFCPListItemSelectedChannel(String elementId) async {
    final item = _carplayHelper.findCPListTemplateItem(
      templates: templateHistory,
      elementId: elementId,
    );
    if (item is! CPListItem) return;

    Future<void> complete() async {
      await flutterToNativeModule(
        FCPChannelTypes.onFCPListItemSelectedComplete,
        item.uniqueId,
      );
    }

    try {
      await Future.sync(() => item.onPress?.call(complete, item));
    } catch (_) {
      await complete();
    }
  }

  Future<void> processFCPListImageRowItemSelectedChannel(
    String elementId,
  ) async {
    final item = _carplayHelper.findCPListTemplateItem(
      templates: templateHistory,
      elementId: elementId,
    );

    if (item is! CPListImageRowItem) return;

    Future<void> complete() async {
      await flutterToNativeModule(
        FCPChannelTypes.onFCPListImageRowItemSelectedComplete,
        item.uniqueId,
      );
    }

    try {
      await Future.sync(() => item.onPress?.call(complete, item));
    } catch (_) {
      await complete();
    }
  }

  Future<void> processFCPListImageRowItemElementSelectedChannel(
    String elementId,
    int index,
  ) async {
    final item = _carplayHelper.findCPListTemplateItem(
      templates: templateHistory,
      elementId: elementId,
    );

    if (item is! CPListImageRowItem) return;

    Future<void> complete() async {
      await flutterToNativeModule(
        FCPChannelTypes.onFCPListImageRowItemElementSelectedComplete,
        item.uniqueId,
      );
    }

    try {
      await Future.sync(() => item.onItemPress?.call(complete, item, index));
    } catch (_) {
      await complete();
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
    final template = _modalRequest?.template ?? currentPresentTemplate;
    if (template is CPAlertTemplate) template.onPresent?.call(completed);
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
        t.onUpdatedSearchText?.call(searchText, (List<CPListItem> results) {
          t.updateResults(results);
          final items = results.map((e) => e.toJson()).toList();
          FlutterCarPlayController.flutterToNativeModule(
            FCPChannelTypes.updateSearchResults,
            <String, dynamic>{'elementId': elementId, 'searchResults': items},
          );
        });
        return;
      }
    }
  }

  void processFCPSearchResultSelected(String elementId, String itemElementId) {
    for (var t in templateHistory) {
      if (t is CPSearchTemplate && t.uniqueId == elementId) {
        CPListItem? selectedItem;
        for (var item in t.currentResults) {
          if (item.uniqueId == itemElementId) {
            selectedItem = item;
            break;
          }
        }
        if (selectedItem != null) {
          t.onSelectedResult?.call(selectedItem, () {
            FlutterCarPlayController.flutterToNativeModule(
              FCPChannelTypes.onSearchResultSelectedComplete,
              <String, dynamic>{'elementId': elementId},
            );
          });
        }
        return;
      }
    }
  }

  void processFCPSearchButtonPressed(String elementId) {
    for (var t in templateHistory) {
      if (t is CPSearchTemplate && t.uniqueId == elementId) {
        t.onSearchTemplateSearchButtonPressed?.call();
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

class _ModalRequest {
  _ModalRequest(this.template);
  final CPTemplate template;
  final cancelled = Completer<bool>();
  Future<bool>? dismissal;
  bool invoked = false;
}
