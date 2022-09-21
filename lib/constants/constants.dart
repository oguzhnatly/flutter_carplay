enum CPConnectionStatusTypes {
  connected,
  background,
  disconnected,
  unknown,
}

class CPConnectionStatusTypesUtil {
  CPConnectionStatusTypesUtil._();
  static CPConnectionStatusTypes parseValue(String value) {
    switch (value) {
      case 'background':
        return CPConnectionStatusTypes.background;
      case 'connected':
        return CPConnectionStatusTypes.connected;
      case 'disconnected':
        return CPConnectionStatusTypes.disconnected;
      case 'unknown':
        return CPConnectionStatusTypes.unknown;
      default:
        return CPConnectionStatusTypes.unknown;
    }
  }
}

extension CPConnectionStatusTypeExtension on CPConnectionStatusTypes {
  String stringValue() {
    switch (this) {
      case CPConnectionStatusTypes.background:
        return 'background';
      case CPConnectionStatusTypes.connected:
        return 'connected';
      case CPConnectionStatusTypes.disconnected:
        return 'disconnected';
      case CPConnectionStatusTypes.unknown:
        return 'unknown';
    }
  }
}
