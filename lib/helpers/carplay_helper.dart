import '../flutter_carplay.dart';

class FlutterCarplayHelper {
  CPListItem? findCPListItem({
    required List<dynamic> templates,
    required String elementId,
  }) {
    CPListItem? listItem;
    l1:
    for (final t in templates) {
      final listTemplates = <CPListTemplate>[];
      if (t.runtimeType.toString() == (CPTabBarTemplate).toString()) {
        for (final template in t.templates) {
          listTemplates.add(template);
        }
      } else if (t.runtimeType.toString() == (CPListTemplate).toString()) {
        listTemplates.add(t);
      }
      if (listTemplates.isNotEmpty) {
        for (final list in listTemplates) {
          for (final section in list.sections) {
            for (final item in section.items) {
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
