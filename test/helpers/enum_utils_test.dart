import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnumUtils', () {
    test('convert string into any type of enum', () {
      final cpListItemAccessoryType = EnumUtils.enumFromString(
        CPListItemAccessoryType.values,
        'cloud',
      );

      expect(cpListItemAccessoryType, CPListItemAccessoryType.cloud);

      final cpListItemPlayingIndicatorLocation = EnumUtils.enumFromString(
        CPListItemPlayingIndicatorLocation.values,
        'trailing',
      );

      expect(
        cpListItemPlayingIndicatorLocation,
        CPListItemPlayingIndicatorLocation.trailing,
      );
    });
  });
}
