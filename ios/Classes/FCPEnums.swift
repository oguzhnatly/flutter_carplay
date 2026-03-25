//
//  FCPEnums.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

enum FCPConnectionTypes {
  static let connected = "CONNECTED"
  static let background = "BACKGROUND"
  static let disconnected = "DISCONNECTED"
}

enum FCPChannelTypes {
  static let onCarplayConnectionChange = "onCarplayConnectionChange"
  static let setRootTemplate = "setRootTemplate"
  static let forceUpdateRootTemplate = "forceUpdateRootTemplate"
  static let updateListTemplateSections = "updateListTemplateSections"
  static let updateTabBarTemplates = "updateTabBarTemplates"
  static let updateInformationTemplateItems = "updateInformationTemplateItems"
  static let updateInformationTemplateActions = "updateInformationTemplateActions"
  static let updateListItem = "updateListItem"
  static let updateListImageRowItem = "updateListImageRowItem"
  static let updateListImageRowItemElement = "updateListImageRowItemElement"
  static let onListItemSelected = "onFCPListItemSelected"
  static let onListItemSelectedComplete = "onFCPListItemSelectedComplete"
  static let onListImageRowItemSelected = "onFCPListImageRowItemSelected"
  static let onListImageRowItemSelectedComplete = "onFCPListImageRowItemSelectedComplete"
  static let onListImageRowItemElementSelected = "onFCPListImageRowItemElementSelected"
  static let onListImageRowItemElementSelectedComplete =
    "onFCPListImageRowItemElementSelectedComplete"
  static let onAlertActionPressed = "onFCPAlertActionPressed"
  static let setAlert = "setAlert"
  static let onPresentStateChanged = "onPresentStateChanged"
  static let popTemplate = "popTemplate"
  static let pushTemplate = "pushTemplate"
  static let showNowPlaying = "showNowPlaying"
  static let closePresent = "closePresent"
  static let onGridButtonPressed = "onGridButtonPressed"
  static let setActionSheet = "setActionSheet"
  static let onBarButtonPressed = "onBarButtonPressed"
  static let onTextButtonPressed = "onTextButtonPressed"
  static let popToRootTemplate = "popToRootTemplate"
  static let onScreenBackButtonPressed = "onScreenBackButtonPressed"
  static let getMaximumNumberOfGridImages = "getMaximumNumberOfGridImages"
  static let getMaximumSectionCount = "getMaximumSectionCount"
  static let getMaximumItemCount = "getMaximumItemCount"
}

enum FCPAlertActionTypes {
  case ACTION_SHEET
  case ALERT
}

func getAlertActionType(fromString: String?) -> FCPAlertActionTypes {
  guard let fromString = fromString else {
    return .ALERT
  }
  switch fromString {
  case "ACTION_SHEET":
    return .ACTION_SHEET
  case "ALERT":
    return .ALERT
  default:
    return .ALERT
  }
}
