import 'package:flutter_carplay/aa_models/template.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

class FlutterAutoAndroidHelper {
  const FlutterAutoAndroidHelper();

  AAListItem? findAAListItem({
    required List<AATemplate> templates,
    required String elementId,
  }) {
    for (var t in templates) {
      final List<AAListTemplate> listTemplates = [];

      /*if (t.runtimeType.toString() == (AATabBarTemplate).toString()) {
        for (var template in t.templates) {
          listTemplates.add(template);
        }
      } else*/
      if (t is AAListTemplate) {
        listTemplates.add(t);
      }

      for (var list in listTemplates) {
        for (var section in list.sections) {
          for (var item in section.items) {
            if (item.uniqueId == elementId) {
              return item;
            }
          }
        }
      }
    }
    return null;
  }

  String makeFAAChannelId({String event = ''}) =>
      'com.oguzhnatly.flutter_android_auto$event';
}
