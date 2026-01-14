import 'package:flutter_carplay/flutter_carplay.dart';

class FlutterCarplayHelper {
  CPListItem? findCPListItem({
    required List<dynamic> templates,
    required String elementId,
  }) {
    CPListItem? listItem;
    l1:
    for (var t in templates) {
      final List<CPListTemplate> listTemplates = [];
      if (t is CPTabBarTemplate) {
        for (var template in t.templates) {
          if (template is CPListTemplate) {
            listTemplates.add(template);
          }
        }
      } else if (t is CPListTemplate) {
        listTemplates.add(t);
      }
      if (listTemplates.isNotEmpty) {
        for (var list in listTemplates) {
          for (var section in list.sections) {
            for (var item in section.items) {
              if (item.uniqueId == elementId) {
                listItem = item;
                break l1;
              }
            }
          }
        }
      }
    }
    return listItem;
  }

  String makeFCPChannelId({String? event = ''}) =>
      'com.oguzhnatly.flutter_carplay${event!}';
}
