import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CPEnumUtils', () {
    test('convert string into any type of enum', () {
      final cpListItemAccessoryType =
          CPEnumUtils.enumFromString(CPListItemAccessoryTypes.values, 'cloud');

      expect(cpListItemAccessoryType, CPListItemAccessoryTypes.cloud);

      final cpListItemPlayingIndicatorLocation = CPEnumUtils.enumFromString(
        CPListItemPlayingIndicatorLocations.values,
        'trailing',
      );

      expect(
        cpListItemPlayingIndicatorLocation,
        CPListItemPlayingIndicatorLocations.trailing,
      );
    });
  });
}
