enum FCPChannelTypes {
  onCarplayConnectionChange,
  setRootTemplate,
  forceUpdateRootTemplate,
  updateListItem,
  onFCPListItemSelected,
  onFCPListItemSelectedComplete,
  onFCPAlertActionPressed,
  setAlert,
  onPresentStateChanged,
  popTemplate,
  closePresent,
  pushTemplate,
  showNowPlaying,
  onGridButtonPressed,
  setActionSheet,
  onBarButtonPressed,
  onTextButtonPressed,
  popToRootTemplate,
}

class FCPChannelTypesUtil {
  FCPChannelTypesUtil._();

  static FCPChannelTypes parseValue(String value) {
    switch (value) {
      case 'onCarplayConnectionChange':
        return FCPChannelTypes.onCarplayConnectionChange;
      case 'setRootTemplate':
        return FCPChannelTypes.setRootTemplate;
      case 'forceUpdateRootTemplate':
        return FCPChannelTypes.forceUpdateRootTemplate;
      case 'updateListItem':
        return FCPChannelTypes.updateListItem;
      case 'onFCPListItemSelected':
        return FCPChannelTypes.onFCPListItemSelected;
      case 'onFCPListItemSelectedComplete':
        return FCPChannelTypes.onFCPListItemSelectedComplete;
      case 'onFCPAlertActionPressed':
        return FCPChannelTypes.onFCPAlertActionPressed;
      case 'setAlert':
        return FCPChannelTypes.setAlert;
      case 'onPresentStateChanged':
        return FCPChannelTypes.onPresentStateChanged;
      case 'popTemplate':
        return FCPChannelTypes.popTemplate;
      case 'closePresent':
        return FCPChannelTypes.closePresent;
      case 'pushTemplate':
        return FCPChannelTypes.pushTemplate;
      case 'showNowPlaying':
        return FCPChannelTypes.showNowPlaying;
      case 'onGridButtonPressed':
        return FCPChannelTypes.onGridButtonPressed;
      case 'setActionSheet':
        return FCPChannelTypes.setActionSheet;
      case 'onBarButtonPressed':
        return FCPChannelTypes.onBarButtonPressed;
      case 'onTextButtonPressed':
        return FCPChannelTypes.onTextButtonPressed;
      case 'popToRootTemplate':
        return FCPChannelTypes.popToRootTemplate;
      default:
        throw ArgumentError('$value not supported');
    }
  }
}

extension FCPChannelTypesExtension on FCPChannelTypes {
  String stringValue() {
    switch (this) {
      case FCPChannelTypes.onCarplayConnectionChange:
        return 'onCarplayConnectionChange';
      case FCPChannelTypes.setRootTemplate:
        return 'setRootTemplate';
      case FCPChannelTypes.forceUpdateRootTemplate:
        return 'forceUpdateRootTemplate';
      case FCPChannelTypes.updateListItem:
        return 'updateListItem';
      case FCPChannelTypes.onFCPListItemSelected:
        return 'onFCPListItemSelected';
      case FCPChannelTypes.onFCPListItemSelectedComplete:
        return 'onFCPListItemSelectedComplete';
      case FCPChannelTypes.onFCPAlertActionPressed:
        return 'onFCPAlertActionPressed';
      case FCPChannelTypes.setAlert:
        return 'setAlert';
      case FCPChannelTypes.onPresentStateChanged:
        return 'onPresentStateChanged';
      case FCPChannelTypes.popTemplate:
        return 'popTemplate';
      case FCPChannelTypes.closePresent:
        return 'closePresent';
      case FCPChannelTypes.pushTemplate:
        return 'pushTemplate';
      case FCPChannelTypes.showNowPlaying:
        return 'showNowPlaying';
      case FCPChannelTypes.onGridButtonPressed:
        return 'onGridButtonPressed';
      case FCPChannelTypes.setActionSheet:
        return 'setActionSheet';
      case FCPChannelTypes.onBarButtonPressed:
        return 'onBarButtonPressed';
      case FCPChannelTypes.onTextButtonPressed:
        return 'onTextButtonPressed';
      case FCPChannelTypes.popToRootTemplate:
        return 'popToRootTemplate';
    }
  }
}
