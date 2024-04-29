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
    static let updateListItem = "updateListItem"
    static let onListItemSelected = "onFCPListItemSelected"
    static let onListItemSelectedComplete = "onFCPListItemSelectedComplete"
    static let onAlertActionPressed = "onFCPAlertActionPressed"
    static let setAlert = "setAlert"
    static let onPresentStateChanged = "onPresentStateChanged"
    static let popTemplate = "popTemplate"
    static let pushTemplate = "pushTemplate"
    static let closePresent = "closePresent"
    static let onGridButtonPressed = "onGridButtonPressed"
    static let setActionSheet = "setActionSheet"
    static let onBarButtonPressed = "onBarButtonPressed"
    static let onTextButtonPressed = "onTextButtonPressed"
    static let onSearchTextUpdated = "onSearchTextUpdated"
    static let onSearchTextUpdatedComplete = "onSearchTextUpdatedComplete"
    static let onSearchResultSelected = "onSearchResultSelected"
    static let onSearchButtonPressed = "onSearchButtonPressed"
    static let onSearchCancelled = "onSearchCancelled"
    static let popToRootTemplate = "popToRootTemplate"
}

enum FCPAlertActionTypes {
    case ACTION_SHEET
    case ALERT
}

enum FCPListTemplateTypes {
    case PART_OF_GRID_TEMPLATE
    case DEFAULT
}
