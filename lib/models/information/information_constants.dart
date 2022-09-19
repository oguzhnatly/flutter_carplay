enum CPInformationTemplateLayout {
  leading,
  twoColumn,
}

class CPInformationTemplateLayoutUtil {
  CPInformationTemplateLayoutUtil._();

  static CPInformationTemplateLayout parseValue(String value) {
    switch (value) {
      case 'leading':
        return CPInformationTemplateLayout.leading;
      case 'twoColumn':
        return CPInformationTemplateLayout.twoColumn;
      default:
        throw ArgumentError('$value is not supproted');
    }
  }
}

extension CPListItemPlayingIndicatorLocationsExtension on CPInformationTemplateLayout? {
  String stringValue() {
    switch (this) {
      case CPInformationTemplateLayout.leading:
        return 'leading';
      case CPInformationTemplateLayout.twoColumn:
        return 'twoColumn';
      default:
        throw ArgumentError('$this is not supported');
    }
  }
}