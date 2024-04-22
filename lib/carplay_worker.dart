import 'dart:async';

import 'constants/private_constants.dart';
import 'controllers/carplay_controller.dart';
import 'flutter_carplay.dart';

// ignore_for_file: use_setters_to_change_properties

/// An object in order to integrate Apple CarPlay in navigation and
/// manage all user interface elements appearing on your screens displayed on
/// the CarPlay screen.
///
/// Using CarPlay, you can display content from your app on a customized user interface
/// that is generated and hosted by the system itself. Control over UI elements, such as
/// touch target size, font size and color, highlights, and so on.
///
/// **Useful Links:**
/// - [What is CarPlay?](https://developer.apple.com/carplay/)
/// - [Request CarPlay Framework](https://developer.apple.com/contact/carplay/)
/// - [Learn more about MFi Program](https://mfi.apple.com)
class FlutterCarplay {
  /// A main Flutter CarPlay Controller to manage the system.
  static final FlutterCarplayController _carPlayController =
      FlutterCarplayController();

  /// CarPlay main bridge as a listener from CarPlay and native side.
  late final StreamSubscription<dynamic>? _eventBroadcast;

  /// Current CarPlay and mobile app connection status.
  static String _connectionStatus = CPConnectionStatusTypes.unknown.name;

  /// A listener function, which will be triggered when CarPlay connection changes
  /// and will be transmitted to the main code, allowing the user to access
  /// the current connection status.
  Function(CPConnectionStatusTypes status)? _onCarplayConnectionChange;

  /// A listener function that will be triggered each time user's voice is recognized
  /// and transcripted by CarPlay voice control, allows users to access the speech
  /// recognition transcript.
  static Function(String transcript)? _onSpeechRecognitionTranscriptChange;

  /// A listener function that will be triggered when the voice control is cancelled.
  static Function()? _onCancelVoiceControl;

  /// A listener function that will be triggered when an information template is popped.
  static Function()? _onInformationTemplatePopped;

  /// A listener function that will be triggered when maneuver action text is requested.
  static Function(
    String action,
    String roadName,
    String nextRoadName, {
    bool isPrimary,
  })? _onManeuverActionTextRequested;

  /// A listener function that will be triggered when
  /// navigation is started from CarPlay.
  static Function(
    double sourceLatitude,
    double sourceLongitude,
    double destinationLatitude,
    double destinationLongitude,
  )? _onNavigationStartedFromCarplay;

  /// A listener function that will be triggered when
  /// navigation is failed from CarPlay.
  static Function(String message)? _onNavigationFailedFromCarplay;

  /// A listener function that will be triggered when
  /// navigation is completed from CarPlay.
  static Function()? _onNavigationCompletedFromCarplay;

  /// Creates an [FlutterCarplay] and starts the connection.
  FlutterCarplay() {
    _eventBroadcast = _carPlayController.eventChannel
        .receiveBroadcastStream()
        .listen((event) {
      final receivedChannelType = CPEnumUtils.enumFromString(
        FCPChannelTypes.values,
        event['type'],
      );
      switch (receivedChannelType) {
        case FCPChannelTypes.onCarplayConnectionChange:
          final connectionStatus = CPEnumUtils.enumFromString(
            CPConnectionStatusTypes.values,
            event['data']['status'],
          );
          _connectionStatus = connectionStatus.name;
          _onCarplayConnectionChange?.call(connectionStatus);
        case FCPChannelTypes.onSearchTextUpdated:
          _carPlayController.processFCPSearchTextUpdatedChannel(
            event['data']['elementId'],
            event['data']['query'],
          );
        case FCPChannelTypes.onSearchResultSelected:
          _carPlayController.processFCPSearchResultSelectedChannel(
            event['data']['elementId'],
            event['data']['itemElementId'],
          );
        case FCPChannelTypes.onSearchCancelled:
          _carPlayController.processFCPSearchCancelledChannel(
            event['data']['elementId'],
          );
        case FCPChannelTypes.onInformationTemplatePopped:
          _onInformationTemplatePopped?.call();
          _carPlayController.processFCPInformationTemplatePoppedChannel(
            event['data']['elementId'],
          );
        case FCPChannelTypes.onFCPListItemSelected:
          _carPlayController
              .processFCPListItemSelectedChannel(event['data']['elementId']);
        case FCPChannelTypes.onFCPAlertActionPressed:
          _carPlayController
              .processFCPAlertActionPressed(event['data']['elementId']);
        case FCPChannelTypes.onPresentStateChanged:
          _carPlayController.processFCPAlertTemplateCompleted(
            completed: event['data']['completed'],
          );
        case FCPChannelTypes.onGridButtonPressed:
          _carPlayController
              .processFCPGridButtonPressed(event['data']['elementId']);
        case FCPChannelTypes.onBarButtonPressed:
          _carPlayController
              .processFCPBarButtonPressed(event['data']['elementId']);
        case FCPChannelTypes.onMapButtonPressed:
          _carPlayController
              .processFCPMapButtonPressed(event['data']['elementId']);
        case FCPChannelTypes.onDashboardButtonPressed:
          _carPlayController
              .processFCPDashboardButtonPressed(event['data']['elementId']);
        case FCPChannelTypes.onTextButtonPressed:
          _carPlayController
              .processFCPTextButtonPressed(event['data']['elementId']);
        case FCPChannelTypes.onVoiceControlTranscriptChanged:
          _onSpeechRecognitionTranscriptChange
              ?.call(event['data']['transcript']);
        case FCPChannelTypes.onVoiceControlTemplatePopped:
          _onCancelVoiceControl?.call();
          _carPlayController.proessFCPVoiceControlTemplatePoppedChannel(
            event['data']['elementId'],
          );
        case FCPChannelTypes.onSpeechCompleted:
          _carPlayController
              .processFCPSpeakerOnComplete(event['data']['elementId']);
        case FCPChannelTypes.onManeuverActionTextRequested:
          final data = event['data'];
          _onManeuverActionTextRequested?.call(
            data['action'],
            data['roadName'],
            data['nextRoadName'],
            isPrimary: data['isPrimary'],
          );
        case FCPChannelTypes.onNavigationStartedFromCarplay:
          final data = event['data'];
          _onNavigationStartedFromCarplay?.call(
            data['sourceLatitude'],
            data['sourceLongitude'],
            data['destinationLatitude'],
            data['destinationLongitude'],
          );
        case FCPChannelTypes.onNavigationFailedFromCarplay:
          _onNavigationFailedFromCarplay?.call(event['data']['message']);
        case FCPChannelTypes.onNavigationCompletedFromCarplay:
          _onNavigationCompletedFromCarplay?.call();
        default:
          break;
      }
    });
  }

  /// A function that will disconnect all event listeners from CarPlay. The action
  /// will be irrevocable, and a new [FlutterCarplay] controller must be created after this,
  /// otherwise CarPlay will be unusable.
  ///
  /// [!] It is not recommended to use this function if you do not know what you are doing.
  void closeConnection() {
    _eventBroadcast!.cancel();
  }

  /// A function that will resume the paused all event listeners from CarPlay.
  void resumeConnection() {
    _eventBroadcast!.resume();
  }

  /// A function that will pause the all active event listeners from CarPlay.
  void pauseConnection() {
    _eventBroadcast!.pause();
  }

  /// Callback function will be fired when CarPlay connection status is changed.
  /// For example, when CarPlay is connected to the device, in the background state,
  /// or completely disconnected.
  ///
  /// See also: [CPConnectionStatusTypes]
  void addListenerOnConnectionChange(
    Function(CPConnectionStatusTypes status) onCarplayConnectionChange,
  ) {
    _onCarplayConnectionChange = onCarplayConnectionChange;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on CarPlay connection status changed.
  void removeListenerOnConnectionChange() {
    _onCarplayConnectionChange = null;
  }

  /// Current CarPlay connection status. It will return one of [CPConnectionStatusTypes] as String.
  static String get connectionStatus {
    return _connectionStatus;
  }

  /// Sets the root template of the navigation hierarchy. If a navigation
  /// hierarchy already exists, CarPlay replaces the entire hierarchy.
  ///
  /// - rootTemplate is a template to use as the root of a new navigation hierarchy. If one exists,
  /// it will replace the current rootTemplate. **Must be one of the type:**
  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate] If not, it will throw an [TypeError]
  ///
  /// - If animated is true, CarPlay animates the presentation of the template, but will be ignored
  /// this flag when there isn’t an existing navigation hierarchy to replace.
  ///
  /// [!] CarPlay cannot have more than 5 templates on one screen.
  static Future<void> setRootTemplate({
    required dynamic rootTemplate,
    bool animated = true,
  }) async {
    if (rootTemplate is CPMapTemplate ||
        rootTemplate is CPGridTemplate ||
        rootTemplate is CPListTemplate ||
        rootTemplate is CPTabBarTemplate ||
        rootTemplate is CPInformationTemplate ||
        rootTemplate is CPPointOfInterestTemplate) {
      final isSuccess = await _carPlayController.methodChannel
          .invokeMethod('setRootTemplate', <String, dynamic>{
        'animated': animated,
        'rootTemplate': rootTemplate.toJson(),
        'runtimeType': 'F${rootTemplate.runtimeType}',
      });

      if (isSuccess) {
        FlutterCarplayController.currentRootTemplate = rootTemplate;
        _carPlayController.addTemplateToHistory(rootTemplate);
      }
    }
  }

  /// It will set the current root template again.
  Future<void> forceUpdateRootTemplate() async {
    await _carPlayController.methodChannel.invokeMethod(
      'forceUpdateRootTemplate',
    );
  }

  /// Getter for current root template.
  /// Return one of type [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate]
  static dynamic get rootTemplate {
    return FlutterCarplayController.currentRootTemplate;
  }

  /// It will present [CPAlertTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static Future<void> showAlert({
    required CPAlertTemplate template,
    bool animated = true,
  }) async {
    final isSuccess = await _carPlayController.methodChannel
        .invokeMethod(FCPChannelTypes.setAlert.name, <String, dynamic>{
      'animated': animated,
      'rootTemplate': template.toJson(),
      'onPresent': template.onPresent != null,
    });

    if (isSuccess) FlutterCarplayController.currentPresentTemplate = template;
  }

  /// It will present [CPActionSheetTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static Future<void> showActionSheet({
    required CPActionSheetTemplate template,
    bool animated = true,
  }) async {
    final isSuccess = await _carPlayController.methodChannel
        .invokeMethod(FCPChannelTypes.setActionSheet.name, <String, dynamic>{
      'rootTemplate': template.toJson(),
      'animated': animated,
    });

    if (isSuccess) FlutterCarplayController.currentPresentTemplate = template;
  }

  /// It will present [CPVoiceControlTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static Future<void> showVoiceControl({
    required CPVoiceControlTemplate template,
    bool animated = true,
  }) async {
    final isSuccess = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.setVoiceControl.name,
      <String, dynamic>{
        'rootTemplate': template.toJson(),
        'animated': animated,
      },
    );

    if (isSuccess) FlutterCarplayController.currentPresentTemplate = template;
  }

  /// Changes the [CPVoiceControlTemplate]'s state to the one matching the specified
  /// identifier in [CPVoiceControlState].
  ///
  /// - identifier is a corresponding to one of the voiceControlStates associated with [CPVoiceControlTemplate].
  ///
  /// **[!] The [CPVoiceControlTemplate] applies a rate limit for voice control states, ignoring state changes
  /// occurring too rapidly or frequently in a short period of time.**
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<bool> activateVoiceControlState({
    required String identifier,
  }) async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.activateVoiceControlState.name,
      identifier,
    );
    return value;
  }

  /// The identifier of the [CPVoiceControlTemplate]'s current voice control state.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<String?> getActiveVoiceControlStateIdentifier() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.getActiveVoiceControlStateIdentifier.name,
      null,
    );
    return value as String?;
  }

  /// Starts recording for the voice recognition.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<bool> startVoiceControl() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.startVoiceControl.name,
      null,
    );
    return value as bool? ?? false;
  }

  /// Stops recording for the voice recognition.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<bool> stopVoiceControl() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.stopVoiceControl.name,
      null,
    );
    return value as bool? ?? false;
  }

  /// Callback function will be fired when CarPlay recognized and transcripted user's voice each time.
  static void addListenerOnSpeechRecognitionTranscriptChange({
    Function(String transcript)? onSpeechRecognitionTranscriptChange,
  }) {
    _onSpeechRecognitionTranscriptChange = onSpeechRecognitionTranscriptChange;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on CarPlay speech recognition transcript changes.
  static void removeListenerOnSpeechRecognitionTranscriptChange() {
    _onSpeechRecognitionTranscriptChange = null;
  }

  /// Callback function will be fired when user cancels voice control.
  static void addListenerOnCancelVoiceControl({
    Function()? onCancelVoiceControl,
  }) {
    _onCancelVoiceControl = onCancelVoiceControl;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on user cancels voice control.
  static void removeListenerOnCancelVoiceControl() {
    _onCancelVoiceControl = null;
  }

  /// Callback function will be fired when user pops information template.
  static void addListenerOnInformationTemplatePopped({
    Function()? onInformationTemplatePopped,
  }) {
    _onInformationTemplatePopped = onInformationTemplatePopped;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on user pops information template.
  static void removeListenerOnInformationTemplatePopped() {
    _onInformationTemplatePopped = null;
  }

  /// Callback function will be fired when maneuver action text is requested.
  static void addListenerOnManeuverActionTextRequested({
    Function(
      String action,
      String roadName,
      String nextRoadName, {
      bool isPrimary,
    })? onManeuverActionTextRequested,
  }) {
    _onManeuverActionTextRequested = onManeuverActionTextRequested;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on maneuver action text requests.
  static void removeListenerOnManeuverActionTextRequested() {
    _onManeuverActionTextRequested = null;
  }

  /// Callback function will be fired when navigation started from CarPlay.
  static void addListenerOnNavigationStartedFromCarplay({
    Function(
      double sourceLatitude,
      double sourceLongitude,
      double destinationLatitude,
      double destinationLongitude,
    )? onNavigationStartedFromCarplay,
  }) {
    _onNavigationStartedFromCarplay = onNavigationStartedFromCarplay;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on navigation started from CarPlay.
  static void removeListenerOnNavigationStartedFromCarplay() {
    _onNavigationStartedFromCarplay = null;
  }

  /// Callback function will be fired when navigation failed from CarPlay.
  static void addListenerOnNavigationFailedFromCarplay({
    Function(String message)? onNavigationFailedFromCarplay,
  }) {
    _onNavigationFailedFromCarplay = onNavigationFailedFromCarplay;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on navigation failed from CarPlay.
  static void removeListenerOnNavigationFailedFromCarplay() {
    _onNavigationFailedFromCarplay = null;
  }

  /// Callback function will be fired when navigation completed from CarPlay.
  static void addListenerOnNavigationCompletedFromCarplay({
    Function()? onNavigationCompletedFromCarplay,
  }) {
    _onNavigationCompletedFromCarplay = onNavigationCompletedFromCarplay;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on navigation completed from CarPlay.
  static void removeListenerOnNavigationCompletedFromCarplay() {
    _onNavigationCompletedFromCarplay = null;
  }

  /// Adds the specified [CPSpeaker] utterance to the queue of the speech synthesizer in CarPlay.
  static void speak(CPSpeaker speakerController) {
    if (speakerController.onCompleted != null) {
      FlutterCarplayController.callbackObjects.add(speakerController);
    }
    _carPlayController.methodChannel
        .invokeMethod(
      FCPChannelTypes.speak.name,
      speakerController.toJson(),
    )
        .then((value) {
      if (value == false && speakerController.onCompleted != null) {
        FlutterCarplayController.callbackObjects
            .removeWhere((e) => e.uniqueId == speakerController.uniqueId);
      }
    });
  }

  /// Plays [CPAudio] data asynchronously.
  static void play(CPAudio audio) {
    _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.playAudio.name,
      audio.toJson(),
    );
  }

  /// Removes the top-most template from the navigation hierarchy.
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  /// - count represents how many times this function will occur.
  static Future<bool> pop({bool animated = true, int count = 1}) async {
    final isSuccess = await _carPlayController.reactToNativeModule(
      FCPChannelTypes.popTemplate,
      <String, dynamic>{
        'count': count,
        'animated': animated,
      },
    );

    if (isSuccess) {
      final templateHistory = FlutterCarplayController.templateHistory;
      for (final _ in Iterable<int>.generate(count)) {
        if (templateHistory.isNotEmpty) {
          templateHistory.removeLast();
        } else {
          break;
        }
      }
    }
    return isSuccess;
  }

  /// Removes all of the templates from the navigation hierarchy except the root template.
  /// If animated is true, CarPlay animates the presentation of the template.
  static Future<bool> popToRoot({bool animated = true}) async {
    await FlutterCarplay.popModal(forcePop: true);

    if (FlutterCarplayController.templateHistory.length <= 1) return false;

    final isSuccess = await _carPlayController.reactToNativeModule(
      FCPChannelTypes.popToRootTemplate,
      animated,
    );

    if (isSuccess) {
      if (FlutterCarplayController.currentRootTemplate != null) {
        FlutterCarplayController.templateHistory = [
          FlutterCarplayController.currentRootTemplate,
        ];
      }
    }

    return isSuccess;
  }

  /// Removes a modal template. Since [CPAlertTemplate] and [CPActionSheetTemplate] are both
  /// modals, they can be removed. If animated is true, CarPlay animates the transition between templates.
  static Future<bool> popModal({
    bool animated = true,
    bool forcePop = false,
  }) async {
    final cpTemplate = FlutterCarplayController.currentPresentTemplate;

    if (cpTemplate == null) return false;

    // Ignore pop when [forcePop] and [isDismissible] both are false
    if (!forcePop && !cpTemplate.isDismissible) {
      return false;
    }

    final isSuccess = await _carPlayController.reactToNativeModule(
      FCPChannelTypes.closePresent,
      animated,
    );

    if (isSuccess) FlutterCarplayController.currentPresentTemplate = null;
    return isSuccess;
  }

  /// Adds a template to the navigation hierarchy and displays it.
  ///
  /// - template is to add to the navigation hierarchy. **Must be one of the type:**
  /// [CPGridTemplate] or [CPListTemplate] [CPInformationTemplate] [CPMapTemplate] [CPPointOfInterestTemplate] If not, it will throw an [TypeError]
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  static Future<bool> push({
    required dynamic template,
    bool animated = true,
  }) async {
    if (template is CPMapTemplate ||
        template is CPGridTemplate ||
        template is CPListTemplate ||
        template is CPSearchTemplate ||
        template is CPInformationTemplate ||
        template is CPPointOfInterestTemplate) {
      final isSuccess = await _carPlayController
          .reactToNativeModule(FCPChannelTypes.pushTemplate, <String, dynamic>{
        'template': template.toJson(),
        'animated': animated,
        'runtimeType': 'F${template.runtimeType}',
      });
      if (isSuccess) _carPlayController.addTemplateToHistory(template);

      return isSuccess;
    } else {
      throw TypeError();
    }
  }

  /// Gets the current configuration of the CarPlay.
  static Future<Map<String, dynamic>> getConfig() async {
    final config = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.getConfig.name,
    );
    return {
      'maximumItemCount': config['maximumItemCount'],
      'maximumSectionCount': config['maximumSectionCount'],
    };
  }
}
