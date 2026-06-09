import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_carplay/constants/private_constants.dart';

import '../aa_models/alert/alert_action.dart';
import '../aa_models/alert/alert_template.dart';
import '../aa_models/grid/grid_button.dart';
import '../aa_models/list/list_item.dart';
import '../aa_models/list/list_section.dart';
import '../aa_models/list/list_template.dart';
import '../aa_models/pane/pane_action.dart';
import '../aa_models/template.dart';
import '../android_auto_worker.dart';
import '../helpers/auto_android_helper.dart';
import '../helpers/svg_rasterizer.dart';

/// [FlutterAndroidAutoController] is a root object used to control and
/// communicate with Android Auto native functions.
class FlutterAndroidAutoController {
  static final FlutterAutoAndroidHelper _androidAutoHelper =
      const FlutterAutoAndroidHelper();
  static final MethodChannel _methodChannel = MethodChannel(
    _androidAutoHelper.makeFAAChannelId(),
  );
  static final EventChannel _eventChannel = EventChannel(
    _androidAutoHelper.makeFAAChannelId(event: '/event'),
  );

  /// [AATabBarTemplate], [AAGridTemplate], [AAListTemplate], [AAPaneTemplate],
  /// [AAMessageTemplate], and [AALongMessageTemplate] in a list.
  static List<AATemplate> templateHistory = [];

  static AATemplate? get currentRootTemplate => templateHistory.firstOrNull;

  /// The currently presented modal, i.e. [AAAlertTemplate].
  static AATemplate? currentPresentTemplate;

  MethodChannel get methodChannel => _methodChannel;

  EventChannel get eventChannel => _eventChannel;

  Future<bool?> flutterToNativeModule(
    FAAChannelTypes type, [
    dynamic data,
  ]) async {
    return FlutterAndroidAutoController.flutterToNativeModuleStatic(type, data);
  }

  static Future<bool?> flutterToNativeModuleStatic(
    FAAChannelTypes type, [
    dynamic data,
  ]) async {
    await resolveSvgInPayload(data, size: FlutterAndroidAuto.svgRasterSize);
    final bool? value = await _methodChannel.invokeMethod<bool>(
      type.name,
      data,
    );
    return value;
  }

  static Future<void> updateAAListTemplateSections({
    required String elementId,
    required List<AAListSection> sections,
  }) async {
    final payload = <String, dynamic>{
      'elementId': elementId,
      'sections':
          sections.map((AAListSection section) => section.toJson()).toList(),
    };

    final bool? isCompleted = await flutterToNativeModuleStatic(
      FAAChannelTypes.updateListTemplateSections,
      payload,
    );

    if (isCompleted == true) {
      for (final template in templateHistory) {
        if (template is AAListTemplate && template.uniqueId == elementId) {
          template.updateSections(sections);
          return;
        }
      }
    }
  }

  Future<void> processFAAListItemSelectedChannel(String elementId) async {
    final AAListItem? item = _androidAutoHelper.findAAListItem(
      templates: templateHistory,
      elementId: elementId,
    );
    if (item == null) return;

    Future<void> complete() async {
      await flutterToNativeModule(
        FAAChannelTypes.onListItemSelectedComplete,
        item.uniqueId,
      );
    }

    try {
      await Future.sync(() => item.onPress?.call(complete, item));
    } catch (_) {
      await complete();
    }
  }

  Future<void> processFAAGridButtonPressed(String elementId) async {
    final AAGridButton? item = _androidAutoHelper.findAAGridButton(
      templates: templateHistory,
      elementId: elementId,
    );
    if (item == null) return;

    Future<void> complete() async {
      await flutterToNativeModule(
        FAAChannelTypes.onGridButtonSelectedComplete,
        item.uniqueId,
      );
    }

    try {
      await Future.sync(() => item.onPress?.call(complete, item));
    } catch (_) {
      await complete();
    }
  }

  void processFAAListSectionSelectedChannel(
    String elementId,
    int selectedIndex,
  ) {
    final AAListSection? listSection = _androidAutoHelper.findAAListSection(
      templates: templateHistory,
      elementId: elementId,
    );
    final selectedItem = listSection?.items.elementAtOrNull(selectedIndex);

    if (listSection != null && selectedItem != null) {
      listSection.selectedIndex = selectedIndex;
      listSection.onSelected?.call(selectedIndex, selectedItem);
    }
  }

  void processFAAToggleCheckedChangeChannel(String elementId, bool checked) {
    final AAListItem? listItem = _androidAutoHelper.findAAListItem(
      templates: templateHistory,
      elementId: elementId,
    );

    final toggle = listItem?.toggle;
    if (toggle != null) {
      toggle.isChecked = checked;
      toggle.onCheckedChange?.call(checked, listItem!);
    }
  }

  void processFAAPaneActionPressedChannel(String elementId) {
    final AAPaneAction? paneAction = _androidAutoHelper.findAAPaneAction(
      templates: templateHistory,
      elementId: elementId,
    );
    paneAction?.onPress?.call();
  }

  void processFAAAlertActionPressed(String elementId) {
    final template = currentPresentTemplate;
    if (template is! AAAlertTemplate) return;

    final AAAlertAction? action =
        template.actions.cast<AAAlertAction?>().firstWhere(
              (action) => action?.uniqueId == elementId,
              orElse: () => null,
            );
    action?.onPress();
  }

  void processFAAPresentStateChanged(String elementId, bool completed) {
    final template = currentPresentTemplate;
    if (template is AAAlertTemplate && template.onPresent != null) {
      template.onPresent!(completed);
    }
    if (!completed) currentPresentTemplate = null;
  }
}
