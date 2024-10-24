/// Enum defining different types of CarPlay channel events.
enum FCPChannelTypes {
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

  /// Event to update the content of an information template in CarPlay.
  updateInformationTemplate,

  /// Event triggered when the search text is updated in CarPlay.
  onSearchTextUpdated,

  /// Event triggered when the search text update is complete in CarPlay.
  onSearchTextUpdatedComplete,

  /// Event triggered when a search result is selected in CarPlay.
  onSearchResultSelected,

  /// Event triggered when a template disappears in CarPlay.
  onTemplatePopped,

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

  /// Event for opening an url.
  openUrl,
}
