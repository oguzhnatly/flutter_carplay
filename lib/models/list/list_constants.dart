enum CPListItemPlayingIndicatorLocations {
  trailing,
  leading,
}

class CPListItemPlayingIndicatorLocationsUtil {
  CPListItemPlayingIndicatorLocationsUtil._();

  static CPListItemPlayingIndicatorLocations parseValue(String value) {
    switch (value) {
      case 'trailing':
        return CPListItemPlayingIndicatorLocations.trailing;
      case 'leading':
        return CPListItemPlayingIndicatorLocations.leading;
      default:
        throw ArgumentError('$value is not supproted');
    }
  }
}

extension CPListItemPlayingIndicatorLocationsExtension on CPListItemPlayingIndicatorLocations? {
  String stringValue() {
    switch (this) {
      case CPListItemPlayingIndicatorLocations.trailing:
        return 'trailing';
      case CPListItemPlayingIndicatorLocations.leading:
        return 'leading';
      default:
        throw ArgumentError('$this is not supported');
    }
  }
}

enum CPListItemAccessoryTypes {
  none,
  cloud,
  disclosureIndicator,
}

class CPListItemAccessoryTypesUtil {
  CPListItemAccessoryTypesUtil._();

  static CPListItemAccessoryTypes parseValue(String value) {
    switch (value) {
      case 'cloud':
        return CPListItemAccessoryTypes.cloud;
      case 'disclosureIndicator':
        return CPListItemAccessoryTypes.disclosureIndicator;
      case 'none':
      default:
        return CPListItemAccessoryTypes.none;
    }
  }
}

extension CPListItemAccessoryTypesExtension on CPListItemAccessoryTypes? {
  String stringValue() {
    switch (this) {
      case CPListItemAccessoryTypes.cloud:
        return 'cloud';
      case CPListItemAccessoryTypes.disclosureIndicator:
        return 'disclosureIndicator';
      case CPListItemAccessoryTypes.none:
      default:
        return 'none';
    }
  }
}
