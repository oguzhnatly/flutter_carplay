enum CPAlertActionStyles {
  normal,
  cancel,
  destructive,
}

class CPAlertActionStylesUtil {
  CPAlertActionStylesUtil._();

  static CPAlertActionStyles parseValue(String value) {
    switch (value) {
      case 'normal':
        return CPAlertActionStyles.normal;
      case 'cancel':
        return CPAlertActionStyles.cancel;
      case 'destructive':
        return CPAlertActionStyles.destructive;
      default:
        throw ArgumentError('$value not supported');
    }
  }
}

extension CPAlertActionStylesExtension on CPAlertActionStyles {
  String stringValue() {
    switch (this) {
      case CPAlertActionStyles.normal:
        return 'normal';
      case CPAlertActionStyles.cancel:
        return 'cancel';
      case CPAlertActionStyles.destructive:
        return 'destructive';
      default:
        throw ArgumentError('$this not supported');
    }
  }
}
