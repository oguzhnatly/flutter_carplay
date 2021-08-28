import 'package:flutter_carplay/flutter_carplay.dart';

class FlutterCarplayHelper {
  CPListItem? findCPListItem({
    required List<dynamic> templates,
    required String elementId,
  }) {
    CPListItem? listItem;
    l1:
    for (var t in templates) {
      List<CPListTemplate> listTemplates = [];
      if (t.runtimeType.toString() == (CPTabBarTemplate).toString()) {
        for (var template in t.templates) {
          listTemplates.add(template);
        }
      } else if (t.runtimeType.toString() == (CPListTemplate).toString()) {
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

  String makeFCPChannelId({String? event = ""}) =>
      'com.oguzhnatly.flutter_carplay' + event!;
}
