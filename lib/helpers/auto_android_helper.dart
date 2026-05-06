import 'package:flutter_carplay/flutter_carplay.dart';

class FlutterAutoAndroidHelper {
  const FlutterAutoAndroidHelper();

  AAListItem? findAAListItem({
    required List<AATemplate> templates,
    required String elementId,
  }) {
    for (var t in templates) {
      final List<AAListTemplate> listTemplates = [];

      if (t is AATabBarTemplate) {
        for (var tab in t.tabs) {
          if (tab is AAListTemplate) listTemplates.add(tab);
        }
      } else if (t is AAListTemplate) {
        listTemplates.add(t);
      }

      for (var list in listTemplates) {
        for (var section in list.sections) {
          for (var item in section.items) {
            if (item.uniqueId == elementId) return item;
          }
        }
      }
    }
    return null;
  }

  /// Searches [templates] (including tabs inside an [AATabBarTemplate]) for an
  /// [AAGridButton] whose [uniqueId] matches [elementId].
  AAGridButton? findAAGridButton({
    required List<AATemplate> templates,
    required String elementId,
  }) {
    for (var t in templates) {
      final List<AAGridTemplate> gridTemplates = [];

      if (t is AATabBarTemplate) {
        for (var tab in t.tabs) {
          if (tab is AAGridTemplate) gridTemplates.add(tab);
        }
      } else if (t is AAGridTemplate) {
        gridTemplates.add(t);
      }

      for (var grid in gridTemplates) {
        for (var button in grid.buttons) {
          if (button.uniqueId == elementId) return button;
        }
      }
    }
    return null;
  }

  String makeFAAChannelId({String event = ''}) =>
      'com.oguzhnatly.flutter_android_auto$event';
}
