import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AAListTemplate', () {
    test('allows a single selectable section', () {
      final template = AAListTemplate(
        title: 'Audio source',
        sections: [
          AAListSection(
            selectedIndex: 0,
            onSelected: (_, __) {},
            items: [
              AAListItem(title: 'Radio option 1'),
              AAListItem(title: 'Radio option 2'),
            ],
          ),
        ],
      );

      expect(template.sections.single.selectedIndex, 0);
    });

    test('rejects selectable sections mixed with other sections', () {
      expect(
        () => AAListTemplate(
          title: 'Home',
          sections: [
            AAListSection(
              title: 'Pages',
              items: [AAListItem(title: 'Page 1')],
            ),
            AAListSection(
              title: 'Radio options',
              selectedIndex: 0,
              onSelected: (_, __) {},
              items: [
                AAListItem(title: 'Radio option 1'),
                AAListItem(title: 'Radio option 2'),
              ],
            ),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
