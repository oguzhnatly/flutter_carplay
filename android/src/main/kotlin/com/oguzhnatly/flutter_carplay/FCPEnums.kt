@file:Suppress("EnumEntryName")

/** Enum defining different types of CarPlay channel events. */
enum class FCPChannelTypes {
    /// Event triggered when the CarPlay connection state changes.
    onCarplayConnectionChange,

    /// Event for setting the root template in CarPlay.
    setRootTemplate,

    /// Event to force an update to the root template in CarPlay.
    forceUpdateRootTemplate,

    /// Event to update a specific list item in CarPlay.
    updateListItem,

    /// Event to update the content of a list template in CarPlay.
    updateListTemplate,

    /// Event to update the content of a map template in CarPlay.
    updateMapTemplate,

    /// Event to update the content of an information template in CarPlay.
    updateInformationTemplate,

    /// Event triggered when the search text is updated in CarPlay.
    onSearchTextUpdated,

    /// Event triggered when the search text update is complete in CarPlay.
    onSearchTextUpdatedComplete,

    /// Event triggered when a search result is selected in CarPlay.
    onSearchResultSelected,

    /// Event triggered when the search is cancelled in CarPlay.
    onSearchCancelled,

    /// Event triggered when the information template is popped in CarPlay.
    onInformationTemplatePopped,

    /// Event triggered when a list item is selected in CarPlay.
    onFCPListItemSelected,

    /// Event triggered when a list item selection is complete in CarPlay.
    onFCPListItemSelectedComplete,

    /// Event triggered when an alert action is pressed in CarPlay.
    onFCPAlertActionPressed,

    /// Event for setting an alert template in CarPlay.
    setAlert,

    /// Event triggered when the presentation state changes in CarPlay.
    onPresentStateChanged,

    /// Event for popping a template in CarPlay.
    popTemplate,

    /// Event for pushing a template in CarPlay.
    pushTemplate,

    /// Event for closing the current presentation in CarPlay.
    closePresent,

    /// Event triggered when a grid button is pressed in CarPlay.
    onGridButtonPressed,

    /// Event for setting an action sheet template in CarPlay.
    setActionSheet,

    /// Event triggered when a bar button is pressed in CarPlay.
    onBarButtonPressed,

    /// Event triggered when a map button is pressed in CarPlay.
    onMapButtonPressed,

    /// Event triggered when a dashboard button is pressed in CarPlay.
    onDashboardButtonPressed,

    /// Event triggered when a text button is pressed in CarPlay.
    onTextButtonPressed,

    /// Event for popping to the root template in CarPlay.
    popToRootTemplate,

    /// Event for setting a voice control template in CarPlay.
    setVoiceControl,

    /// Event for activating a specific voice control state in CarPlay.
    activateVoiceControlState,

    /// Event for starting the voice control in CarPlay.
    startVoiceControl,

    /// Event for stopping the voice control in CarPlay.
    stopVoiceControl,

    /// Event for getting the active voice control state identifier in CarPlay.
    getActiveVoiceControlStateIdentifier,

    /// Event triggered when the voice control transcript changes in CarPlay.
    onVoiceControlTranscriptChanged,

    // Event triggered when the voice control template is popped in CarPlay.
    onVoiceControlTemplatePopped,

    /// Event for speaking text in CarPlay.
    speak,

    /// Event triggered when speech is completed in CarPlay.
    onSpeechCompleted,

    /// Event for playing audio in CarPlay.
    playAudio,

    /// Event for getting CarPlay configuration information.
    getConfig,

    /// Event for showing a banner in CarPlay.
    showBanner,

    /// Event for hiding a banner in CarPlay.
    hideBanner,

    /// Event for showing a toast in CarPlay.
    showToast,

    /// Event for showing an overlay in CarPlay.
    showOverlay,

    /// Event for hiding an overlay in CarPlay.
    hideOverlay,

    /// Event for showing a trip preview in CarPlay.
    showTripPreviews,

    /// Event for hiding a trip preview in CarPlay.
    hideTripPreviews,

    /// Event for showing the panning interface in CarPlay.
    showPanningInterface,

    /// Event for dismissing the panning interface in CarPlay.
    dismissPanningInterface,

    /// Event for starting a navigation in CarPlay.
    startNavigation,

    /// Event for stopping a navigation in CarPlay.
    stopNavigation,

    /// Event for updating the map coordinates in CarPlay.
    updateMapCoordinates,

    /// Event for requesting a maneuver action text in CarPlay.
    onManeuverActionTextRequested,

    /// Event triggered when the maneuver action text request is complete in CarPlay.
    onManeuverActionTextRequestComplete,

    /// Event for toggling offline mode in CarPlay.
    toggleOfflineMode,

    /// Event for toggling a voice instruction in CarPlay.
    toggleVoiceInstructions,

    /// Event for toggling satellite view in CarPlay.
    toggleSatelliteView,

    /// Event for recentering the map view in CarPlay.
    recenterMapView,

    /// Event for starting the navigation from CarPlay.
    onNavigationStartedFromCarplay,

    /// Event for failed the navigation from CarPlay.
    onNavigationFailedFromCarplay,

    /// Event for completed navigation from CarPlay.
    onNavigationCompletedFromCarplay,

    /// Event for zooming in the map view in CarPlay.
    zoomInMapView,

    /// Event for zooming out the map view in CarPlay.
    zoomOutMapView,
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

/** Enum defining different styles of bar buttons in CarPlay. */
enum class CPBarButtonStyle {
    /// The default style for a bar button.
    none,

    /// The style for a bar button that has rounded corners.
    rounded,
}

/** Enum defining different types of CarPlay connection states. */
enum class FCPConnectionTypes {
    /// Represents a connected state to CarPlay.
    CONNECTED,

    /// Represents a background state in CarPlay.
    BACKGROUND,

    /// Represents a disconnected state from CarPlay.
    DISCONNECTED,
}

/** Enum defining different types of alert actions in CarPlay. */
enum class FCPAlertActionTypes {
    /// Represents an action sheet type of alert action.
    ACTION_SHEET,

    /// Represents a default type of alert action.
    ALERT,
}


/** Enum defining different types of list template in CarPlay. */
enum class FCPListTemplateTypes {
    /// Represents a part of a grid template in CarPlay.
    PART_OF_GRID_TEMPLATE,

    /// Represents a default type of list template in CarPlay.
    DEFAULT,
}

/** Enum defining different types of map marker in CarPlay. */
enum class MapMarkerType {
    /// Represents either the current location or the home station location marker in CarPlay.
    INITIAL,

    /// Represents an incident address marker in CarPlay.
    INCIDENT_ADDRESS,

    /// Represents a destination address marker in CarPlay.
    DESTINATION_ADDRESS,
}
