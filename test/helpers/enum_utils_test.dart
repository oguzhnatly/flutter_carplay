import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnumUtils', () {
    test('convert string into any type of enum', () {
      final cpListItemAccessoryType = EnumUtils.enumFromString(
        CPListItemAccessoryTypes.values,
        'cloud',
      );

      expect(cpListItemAccessoryType, CPListItemAccessoryTypes.cloud);

      final cpListItemPlayingIndicatorLocation = EnumUtils.enumFromString(
        CPListItemPlayingIndicatorLocations.values,
        'trailing',
      );

      expect(
        cpListItemPlayingIndicatorLocation,
        CPListItemPlayingIndicatorLocations.trailing,
      );
    });

    test('convert dynamic type into string after the `.`', () {
      final cpAlertActionStylesString = EnumUtils.stringFromEnum(
        CPAlertActionStyles.normal.toString(),
      );

      expect(cpAlertActionStylesString, 'normal');

      final fcpChannelTypesString = EnumUtils.stringFromEnum('car.setAlert');

      expect(fcpChannelTypesString, 'setAlert');
    });
  });
}
