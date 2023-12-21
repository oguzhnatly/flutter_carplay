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
    static let updateListTemplate = "updateListTemplate"
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
    static let onMapButtonPressed = "onMapButtonPressed"
    static let onNavigationBarButtonPressed = "onNavigationBarButtonPressed"
    static let onTextButtonPressed = "onTextButtonPressed"
    static let popToRootTemplate = "popToRootTemplate"
    static let setVoiceControl = "setVoiceControl"
    static let activateVoiceControlState = "activateVoiceControlState"
    static let startVoiceControl = "startVoiceControl"
    static let stopVoiceControl = "stopVoiceControl"
    static let getActiveVoiceControlStateIdentifier = "getActiveVoiceControlStateIdentifier"
    static let onVoiceControlTranscriptChanged = "onVoiceControlTranscriptChanged"
    static let speak = "speak"
    static let onSpeechCompleted = "onSpeechCompleted"
    static let playAudio = "playAudio"
    static let getConfig = "getConfig"
}

enum FCPAlertActionTypes {
    case ACTION_SHEET
    case ALERT
}

enum FCPListTemplateTypes {
    case PART_OF_GRID_TEMPLATE
    case DEFAULT
}
