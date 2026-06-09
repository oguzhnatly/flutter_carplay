import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UIColor', () {
    test('serializes RGB as clamped byte channels', () {
      expect(
        const UIColor(red: -1, green: 128, blue: 300).toJson(),
        <String, dynamic>{
          'red': 0,
          'green': 128,
          'blue': 255,
          'alpha': 1.0,
        },
      );
    });
  });

  group('AutoImageTint', () {
    test('serializes custom light and dark RGB byte colors', () {
      final json = const AutoImageTint.custom(
        color: UIColor(red: 129, green: 83, blue: 255),
        darkColor: UIColor(red: 196, green: 181, blue: 253),
      ).toJson();

      expect(json['type'], 'custom');
      expect(json['color'], <String, dynamic>{
        'red': 129,
        'green': 83,
        'blue': 255,
        'alpha': 1.0,
      });
      expect(json['darkColor'], <String, dynamic>{
        'red': 196,
        'green': 181,
        'blue': 253,
        'alpha': 1.0,
      });
    });

    test('withDarkColor adds a dark custom color', () {
      final tint = const AutoImageTint.custom(
        color: UIColor(red: 10, green: 20, blue: 30),
      ).withDarkColor(const UIColor(red: 200, green: 210, blue: 220));

      expect(tint.toJson(), <String, dynamic>{
        'type': 'custom',
        'color': <String, dynamic>{
          'red': 10,
          'green': 20,
          'blue': 30,
          'alpha': 1.0,
        },
        'darkColor': <String, dynamic>{
          'red': 200,
          'green': 210,
          'blue': 220,
          'alpha': 1.0,
        },
        'selectedSafe': true,
      });
    });
  });
}
