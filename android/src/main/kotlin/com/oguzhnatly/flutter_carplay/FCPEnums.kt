@file:Suppress("EnumEntryName")

package com.oguzhnatly.flutter_carplay

/** Enum defining different types of Android Auto channel events. */
enum class FCPChannelTypes {
    /// Event triggered when the Android Auto connection state changes.
    onCarplayConnectionChange,

    /// Event for setting the root template in Android Auto.
    setRootTemplate,

    /// Event to force an update to the root template in Android Auto.
    forceUpdateRootTemplate,

    /// Event to update a specific list item in Android Auto.
    updateListItem,

    /// Event to update the content of a list template in Android Auto.
    updateListTemplate,

    /// Event to update the content of an information template in Android Auto.
    updateInformationTemplate,

    /// Event triggered when the search text is updated in Android Auto.
    onSearchTextUpdated,

    /// Event triggered when the search text update is complete in Android Auto.
    onSearchTextUpdatedComplete,

    /// Event triggered when a search result is selected in Android Auto.
    onSearchResultSelected,

    /// Event triggered when the search is cancelled in Android Auto.
    onSearchCancelled,

    /// Event triggered when a template is popped in Android Auto.
    onTemplatePopped,

    /// Event triggered when a list item is selected in Android Auto.
    onFCPListItemSelected,

    /// Event triggered when a list item selection is complete in Android Auto.
    onFCPListItemSelectedComplete,

    /// Event triggered when an alert action is pressed in Android Auto.
    onFCPAlertActionPressed,

    /// Event for setting an alert template in Android Auto.
    setAlert,

    /// Event triggered when the presentation state changes in Android Auto.
    onPresentStateChanged,

    /// Event for popping a template in Android Auto.
    popTemplate,

    /// Event for pushing a template in Android Auto.
    pushTemplate,

    /// Event for closing the current presentation in Android Auto.
    closePresent,

    /// Event triggered when a grid button is pressed in Android Auto.
    onGridButtonPressed,

    /// Event for setting an action sheet template in Android Auto.
    setActionSheet,

    /// Event triggered when a bar button is pressed in Android Auto.
    onBarButtonPressed,

    /// Event triggered when a dashboard button is pressed in Android Auto.
    onDashboardButtonPressed,

    /// Event triggered when a text button is pressed in Android Auto.
    onTextButtonPressed,

    /// Event for popping to the root template in Android Auto.
    popToRootTemplate,

    /// Event for setting a voice control template in Android Auto.
    setVoiceControl,

    /// Event for activating a specific voice control state in Android Auto.
    activateVoiceControlState,

    /// Event for starting the voice control in Android Auto.
    startVoiceControl,

    /// Event for stopping the voice control in Android Auto.
    stopVoiceControl,

    /// Event for getting the active voice control state identifier in Android Auto.
    getActiveVoiceControlStateIdentifier,

    /// Event triggered when the voice control transcript changes in Android Auto.
    onVoiceControlTranscriptChanged,

    /// Event for speaking text in Android Auto.
    speak,

    /// Event triggered when speech is completed in Android Auto.
    onSpeechCompleted,

    /// Event for playing audio in Android Auto.
    playAudio,

    /// Event for getting Android Auto configuration information.
    getConfig,

    /// Event for showing a banner in Android Auto.
    showBanner,

    /// Event for hiding a banner in Android Auto.
    hideBanner,

    /// Event for showing a toast in Android Auto.
    showToast,

    /// Event for showing an overlay in Android Auto.
    showOverlay,

    /// Event for hiding an overlay in Android Auto.
    hideOverlay,
}

/** Enum defining different accessory types. */
enum class CPListItemAccessoryType {
    /// The default accessory type.
    none,

    /// The accessory type that displays an image of a cloud.
    cloud,

    /// The accessory type that displays an disclosure indicator.
    disclosureIndicator,
}

/** Enum defining different styles of bar buttons in Android Auto. */
enum class CPBarButtonStyle {
    /// The default style for a bar button.
    none,

    /// The style for a bar button that has rounded corners.
    rounded,
}

/** Enum defining different styles of alert actions in Android Auto. */
enum class CPAlertActionStyle {
    /// The default style for an alert action.
    normal,

    /// The style for an alert action that cancels an alert.
    cancel,

    /// The style for an alert action that indicates a destructive action.
    destructive,
}

/** Enum defining different styles of text buttons in Android Auto. */
enum class CPTextButtonStyle {
    /// The default style for a text button.
    normal,

    /// The style for a text button that indicates a cancel action.
    cancel,

    /// The style for a text button that indicates a confirm action.
    confirm
}

/** Enum defining different types of Android Auto connection states. */
enum class FCPConnectionTypes {
    /// Represents a connected state to Android Auto.
    CONNECTED,

    /// Represents a background state in Android Auto.
    BACKGROUND,

    /// Represents a foreground state in Android Auto.
    FOREGROUND,

    /// Represents a disconnected state from Android Auto.
    DISCONNECTED,
}

/** Enum defining different types of alert actions in Android Auto. */
enum class FCPAlertActionTypes {
    /// Represents an action sheet type of alert action.
    ACTION_SHEET,

    /// Represents a default type of alert action.
    ALERT,
}


/** Enum defining different types of list template in Android Auto. */
enum class FCPListTemplateTypes {
    /// Represents a part of a grid template in Android Auto.
    PART_OF_GRID_TEMPLATE,

    /// Represents a default type of list template in Android Auto.
    DEFAULT,
}

/** Enum defining different types of map marker in Android Auto. */
enum class MapMarkerType {
    /// Represents either the current location or the home station location marker in Android Auto.
    INITIAL,

    /// Represents an incident address marker in Android Auto.
    INCIDENT_ADDRESS,

    /// Represents a destination address marker in Android Auto.
    DESTINATION_ADDRESS,
}
