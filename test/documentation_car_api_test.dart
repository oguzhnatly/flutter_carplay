import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('media example and setup guide require Car App API level 8', () {
    final readme = File('README.md').readAsStringSync();
    final mediaConfigurations = [
      File(
        'example/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync(),
      ...RegExp(r'```xml\n([\s\S]*?)\n```')
          .allMatches(readme)
          .map((match) => match.group(1)!)
          .where((xml) => xml.contains('androidx.car.app.category.MEDIA')),
    ];
    expect(mediaConfigurations.length, greaterThanOrEqualTo(2));
    for (final xml in mediaConfigurations) {
      expect(xml, contains('androidx.car.app.category.MEDIA'));
      final metadata = RegExp(r'<meta-data\b[^>]*>')
          .allMatches(xml)
          .map((match) => match.group(0)!)
          .singleWhere(
            (tag) => tag.contains('androidx.car.app.minCarApiLevel'),
          );
      final minimum = RegExp(r'android:value="(\d+)"').firstMatch(metadata);
      expect(minimum, isNotNull);
      expect(int.parse(minimum!.group(1)!), greaterThanOrEqualTo(8));
    }
  });
}
