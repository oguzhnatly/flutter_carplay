import '../flutter_carplay.dart';

/// Provides helper methods for [FlutterCarplay]
class FlutterCarplayHelper {
  /// Finds a CarPlay list item by element ID from the template history.
  ///
  /// - Parameters:
  ///   - templateHistory: The template history of the CarPlay.
  ///   - elementId: The element ID of the list item.
  CPListItem? findCPListItem({
    required List<dynamic> templateHistory,
    required String elementId,
  }) {
    for (final template in templateHistory) {
      final listTemplates = <CPListTemplate>[];
      if (template is CPTabBarTemplate) {
        listTemplates.addAll(template.templates);
      } else if (template is CPListTemplate) {
        listTemplates.add(template);
      }
      if (listTemplates.isNotEmpty) {
        for (final list in listTemplates) {
          for (final section in list.sections) {
            for (final item in section.items) {
              if (item.uniqueId == elementId) return item;
            }
          }
        }
      }
    }
    return null;
  }

  /// Generates a Flutter CarPlay (FCP) channel ID based on the specified event.
  /// - Parameter event: The event associated with the channel.
  /// - Returns: The FCP channel ID combining the base identifier and the provided event.
  String makeFCPChannelId({String? event = ''}) => 'com.oguzhnatly.flutter_carplay${event ?? ''}';

  /// Compares two lists with a compare function.
  bool compareLists<T>(List<T> list1, List<T> list2, bool Function(T, T) compareFunction) {
    if (list1.length != list2.length) return false;

    for (var i = 0; i < list1.length; i++) {
      if (!compareFunction(list1[i], list2[i])) {
        return false;
      }
    }
    return true;
  }
}
