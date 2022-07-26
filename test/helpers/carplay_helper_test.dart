import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_carplay/helpers/carplay_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterCarplayHelper', () {
    late FlutterCarplayHelper flutterCarplayHelper;

    final cpListItem=CPListItem(text: '<CPListItem>');

    final cpListTemplate = CPListTemplate(
        title: '<CPListTemplate>',
        sections: [
          CPListSection(items: [cpListItem])
        ],
        systemIcon: '<CarIcon>');

    final templates = [
      CPTabBarTemplate(title: '<CPTabBarTemplate>', templates: [cpListTemplate]),
      cpListTemplate
    ];

    setUp(() {
      flutterCarplayHelper = FlutterCarplayHelper();
    });

    test('find CPListItem from dynamic list item and element id', () {
      CPListItem? item = flutterCarplayHelper.findCPListItem(templates: templates, elementId: cpListItem.uniqueId);

      expect(item, cpListItem);

      CPListItem? nullableItem = flutterCarplayHelper.findCPListItem(
          templates: templates, elementId: '');

      expect(nullableItem, null);
    });

    test('make FCP channel id', () {
      String channelId = flutterCarplayHelper.makeFCPChannelId(event: '/event');

      expect(channelId, 'com.oguzhnatly.flutter_carplay/event');
    });
  });
}
