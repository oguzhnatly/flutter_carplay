import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AAPaneTemplate', () {
    test('serializes informational rows and actions', () {
      final template = AAPaneTemplate(
        id: 'pane-1',
        title: 'Vehicle Info',
        imageUrl: 'images/icon.svg',
        imageTint: const AutoImageTint.platform(),
        items: [
          AAPaneItem(
            id: 'item-1',
            title: 'Battery',
            detail: '82%',
            imageUrl: 'images/battery.svg',
            imageTint: const AutoImageTint.green(),
          ),
        ],
        actions: [
          AAPaneAction(
            id: 'action-1',
            title: 'Refresh',
            imageUrl: 'images/refresh.svg',
            isPrimary: true,
            onPress: () {},
          ),
        ],
      );

      expect(template.toJson(), <String, dynamic>{
        '_elementId': 'pane-1',
        'title': 'Vehicle Info',
        'items': [
          <String, dynamic>{
            '_elementId': 'item-1',
            'title': 'Battery',
            'detail': '82%',
            'imageUrl': 'images/battery.svg',
            'imageTint': const AutoImageTint.green().toJson(),
          },
        ],
        'actions': [
          <String, dynamic>{
            '_elementId': 'action-1',
            'title': 'Refresh',
            'imageUrl': 'images/refresh.svg',
            'imageTint': null,
            'isPrimary': true,
            'onPress': true,
          },
        ],
        'imageUrl': 'images/icon.svg',
        'imageTint': const AutoImageTint.platform().toJson(),
        'isLoading': false,
      });
    });
  });
}
