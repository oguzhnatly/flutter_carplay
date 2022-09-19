enum CPBarButtonStyles {
  none,
  rounded,
}

class CPBarButtonStylesUtil {
  CPBarButtonStylesUtil._();

  static CPBarButtonStyles parseValue(String value) {
    switch (value) {
      case 'rounded':
        return CPBarButtonStyles.rounded;
      case 'none':
      default:
        return CPBarButtonStyles.none;
    }
  }
}

extension CPBarButtonStylesExtension on CPBarButtonStyles {
  String stringValue() {
    switch (this) {
      case CPBarButtonStyles.rounded:
        return 'rounded';
      case CPBarButtonStyles.none:
      default:
        return 'none';
    }
  }
}
