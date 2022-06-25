import 'package:flutter_carplay/constants/private_constants.dart';
import 'package:flutter_carplay/helpers/enum_utils.dart';
import 'package:flutter_carplay/models/alert/alert_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'CPEnumUtils - stringFromEnum method should return last character after .',
      () {
    final cancelString =
        CPEnumUtils.stringFromEnum(CPAlertActionStyles.cancel.toString());

    expect(cancelString, 'cancel');

    final carPlayString = CPEnumUtils.stringFromEnum('test.carPlay');

    expect(carPlayString, 'carPlay');
  });

  test(
      'CPEnumUtils - enumFromString method should return event from FCPChannelTypes enums',
      () {
    final setRootTemplateString =
        CPEnumUtils.enumFromString(FCPChannelTypes.values, 'setRootTemplate');

    expect(setRootTemplateString, FCPChannelTypes.setRootTemplate);

    final setAlertString =
        CPEnumUtils.enumFromString(FCPChannelTypes.values, 'setAlert');

    expect(setAlertString, FCPChannelTypes.setAlert);
  });
}
