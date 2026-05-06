import 'package:flutter/services.dart';
import 'package:flutter_carplay/constants/private_constants.dart';

import '../aa_models/alert/alert_action.dart';
import '../aa_models/alert/alert_template.dart';
import '../aa_models/grid/grid_button.dart';
import '../aa_models/list/list_item.dart';
import '../aa_models/tabbar/tabbar_template.dart';
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

  /// [AATabBarTemplate], [AAGridTemplate], [AAListTemplate] in a List
  static List<AATemplate> templateHistory = [];

  /// [AATabBarTemplate], [AAGridTemplate], [AAListTemplate]
  static AATemplate? get currentRootTemplate => templateHistory.firstOrNull;

  /// The currently presented modal, i.e. [AAAlertTemplate].
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

  // ─── Event processors ──────────────────────────────────────────────────────

  Future<void> processFAAListItemSelectedChannel(String elementId) async {
    final item = _androidAutoHelper.findAAListItem(
      templates: templateHistory,
      elementId: elementId,
    );
    if (item is! AAListItem) return;

    void complete() {
      flutterToNativeModule(
          FAAChannelTypes.onListItemSelectedComplete, item.uniqueId);
    }

    await item.onPress?.call(complete, item).catchError((_) => complete());
  }

  Future<void> processFAAGridButtonPressed(String elementId) async {
    final item = _androidAutoHelper.findAAGridButton(
      templates: templateHistory,
      elementId: elementId,
    );
    if (item is! AAGridButton) return;

    void complete() {
      flutterToNativeModule(
          FAAChannelTypes.onGridButtonSelectedComplete, item.uniqueId);
    }

    await item.onPress?.call(complete, item).catchError((_) => complete());
  }

  void processFAAAlertActionPressed(String elementId) {
    final template = currentPresentTemplate;
    if (template is! AAAlertTemplate) return;

    final AAAlertAction? action =
        template.actions.cast<AAAlertAction?>().firstWhere(
              (a) => a?.uniqueId == elementId,
              orElse: () => null,
            );
    action?.onPress();
  }

  void processFAAPresentStateChanged(String elementId, bool completed) {
    final template = currentPresentTemplate;
    if (template is AAAlertTemplate && template.onPresent != null) {
      template.onPresent!(completed);
    }
    if (!completed) {
      // Alert was dismissed (e.g. via back button) – clear the reference.
      currentPresentTemplate = null;
    }
  }
}
