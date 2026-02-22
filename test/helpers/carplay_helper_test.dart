import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterCarplayHelper', () {
    late FlutterCarplayHelper flutterCarplayHelper;

    final cpListItem = CPListItem(text: '<CPListItem>');

    final cpListTemplate = CPListTemplate(
      title: '<CPListTemplate>',
      sections: [
        CPListSection(items: [cpListItem]),
      ],
      systemIcon: '<CarIcon>',
    );

    final templates = [
      CPTabBarTemplate(
        tabTitle: '<CPTabBarTemplate>',
        templates: [cpListTemplate],
      ),
      cpListTemplate,
    ];

    setUp(() {
      flutterCarplayHelper = FlutterCarplayHelper();
    });

    test('find CPListItem from dynamic list item and element id', () {
      final CPListTemplateItem? item =
          flutterCarplayHelper.findCPListTemplateItem(
        templates: templates,
        elementId: cpListItem.uniqueId,
      );

      expect(item, cpListItem);

      final CPListTemplateItem? nullableItem =
          flutterCarplayHelper.findCPListTemplateItem(
        templates: templates,
        elementId: '',
      );

      expect(nullableItem, null);
    });

    test('make FCP channel id', () {
      final String channelId =
          flutterCarplayHelper.makeFCPChannelId(event: '/event');

      expect(channelId, 'com.oguzhnatly.flutter_carplay/event');
    });
  });
}
