import 'dart:async';
import 'package:flutter_carplay/constants/constants.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/models/speaker/carplay_speaker.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_carplay/helpers/enum_utils.dart';
import 'package:flutter_carplay/models/alert/alert_template.dart';
import 'package:flutter_carplay/models/grid/grid_template.dart';
import 'package:flutter_carplay/models/tabbar/tabbar_template.dart';
import 'package:flutter_carplay/constants/private_constants.dart';
import 'package:flutter_carplay/models/voice_control/voice_control_template.dart';

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
  static final FlutterCarPlayController _carPlayController =
      FlutterCarPlayController();

  /// CarPlay main bridge as a listener from CarPlay and native side.
  late final StreamSubscription<dynamic>? _eventBroadcast;

  /// Current CarPlay and mobile app connection status.
  static String _connectionStatus =
      CPEnumUtils.stringFromEnum(CPConnectionStatusTypes.unknown.toString());

  /// A listener function, which will be triggered when CarPlay connection changes
  /// and will be transmitted to the main code, allowing the user to access
  /// the current connection status.
  Function(CPConnectionStatusTypes status)? _onCarplayConnectionChange;

  /// A listener function that will be triggered each time user's voice is recognized
  /// and transcripted by CarPlay voice control, allows users to access the speech
  /// recognition transcript.
  static Function(String transcript)? _onSpeechRecognitionTranscriptChange;

  /// Creates an [FlutterCarplay] and starts the connection.
  FlutterCarplay() {
    _eventBroadcast = _carPlayController.eventChannel
        .receiveBroadcastStream()
        .listen((event) {
      final FCPChannelTypes receivedChannelType = CPEnumUtils.enumFromString(
        FCPChannelTypes.values,
        event["type"],
      );
      switch (receivedChannelType) {
        case FCPChannelTypes.onCarplayConnectionChange:
          final CPConnectionStatusTypes connectionStatus =
              CPEnumUtils.enumFromString(
            CPConnectionStatusTypes.values,
            event["data"]["status"],
          );
          _connectionStatus =
              CPEnumUtils.stringFromEnum(connectionStatus.toString());
          if (_onCarplayConnectionChange != null) {
            _onCarplayConnectionChange!(connectionStatus);
          }
          break;
        case FCPChannelTypes.onFCPListItemSelected:
          _carPlayController
              .processFCPListItemSelectedChannel(event["data"]["elementId"]);
          break;
        case FCPChannelTypes.onFCPAlertActionPressed:
          _carPlayController
              .processFCPAlertActionPressed(event["data"]["elementId"]);
          break;
        case FCPChannelTypes.onPresentStateChanged:
          _carPlayController
              .processFCPPresentTemplateCompleted(event["data"]["completed"]);
          break;
        case FCPChannelTypes.onGridButtonPressed:
          _carPlayController
              .processFCPGridButtonPressed(event["data"]["elementId"]);
          break;
        case FCPChannelTypes.onBarButtonPressed:
          _carPlayController
              .processFCPBarButtonPressed(event["data"]["elementId"]);
          break;
        case FCPChannelTypes.onVoiceControlTranscriptChanged:
          if (_onSpeechRecognitionTranscriptChange != null) {
            _onSpeechRecognitionTranscriptChange!(event["data"]["transcript"]);
          }
          break;
        case FCPChannelTypes.onSpeechCompleted:
          _carPlayController
              .processFCPSpeakerOnComplete(event["data"]["elementId"]);
          break;
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
  static void setRootTemplate({
    required dynamic rootTemplate,
    bool animated = true,
  }) {
    if (rootTemplate.runtimeType == CPTabBarTemplate ||
        rootTemplate.runtimeType == CPGridTemplate ||
        rootTemplate.runtimeType == CPListTemplate) {
      _carPlayController.methodChannel
          .invokeMethod('setRootTemplate', <String, dynamic>{
        'rootTemplate': rootTemplate.toJson(),
        'animated': animated,
        'runtimeType': "F" + rootTemplate.runtimeType.toString(),
      }).then((value) {
        if (value) {
          FlutterCarPlayController.currentRootTemplate = rootTemplate;
          _carPlayController.addTemplateToHistory(rootTemplate);
        }
      });
    }
  }

  /// It will set the current root template again.
  void forceUpdateRootTemplate() {
    _carPlayController.methodChannel.invokeMethod('forceUpdateRootTemplate');
  }

  /// Getter for current root template.
  /// Return one of type [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate]
  static dynamic get rootTemplate {
    return FlutterCarPlayController.currentRootTemplate;
  }

  /// It will present [CPAlertTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static void showAlert({
    required CPAlertTemplate template,
    bool animated = true,
  }) {
    _carPlayController.methodChannel.invokeMethod(
        CPEnumUtils.stringFromEnum(FCPChannelTypes.setAlert.toString()),
        <String, dynamic>{
          'rootTemplate': template.toJson(),
          'animated': animated,
          'onPresent': template.onPresent != null ? true : false,
        }).then((value) {
      if (value) {
        FlutterCarPlayController.currentPresentTemplate = template;
      }
    });
  }

  /// It will present [CPActionSheetTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static void showActionSheet({
    required CPActionSheetTemplate template,
    bool animated = true,
  }) {
    _carPlayController.methodChannel.invokeMethod(
        CPEnumUtils.stringFromEnum(FCPChannelTypes.setActionSheet.toString()),
        <String, dynamic>{
          'rootTemplate': template.toJson(),
          'animated': animated,
        }).then((value) {
      if (value) {
        FlutterCarPlayController.currentPresentTemplate = template;
      }
    });
  }

  /// It will present [CPVoiceControlTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static void showVoiceControl({
    required CPVoiceControlTemplate template,
    bool animated = true,
  }) {
    _carPlayController.methodChannel.invokeMethod(
      CPEnumUtils.stringFromEnum(FCPChannelTypes.setVoiceControl.toString()),
      <String, dynamic>{
        'rootTemplate': template.toJson(),
        'animated': animated,
      },
    ).then((value) {
      if (value) {
        FlutterCarPlayController.currentPresentTemplate = template;
      }
    });
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
      CPEnumUtils.stringFromEnum(FCPChannelTypes.activateVoiceControlState),
      identifier,
    );
    return value;
  }

  /// The identifier of the [CPVoiceControlTemplate]'s current voice control state.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<String> getActiveVoiceControlStateIdentifier() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      CPEnumUtils.stringFromEnum(
          FCPChannelTypes.getActiveVoiceControlStateIdentifier),
      null,
    );
    return value as String;
  }

  /// Starts recording for the voice recognition.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<bool> startVoiceControl() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      CPEnumUtils.stringFromEnum(FCPChannelTypes.startVoiceControl),
      null,
    );
    return value as bool;
  }

  /// Stops recording for the voice recognition.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<bool> stopVoiceControl() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      CPEnumUtils.stringFromEnum(FCPChannelTypes.stopVoiceControl),
      null,
    );
    return value as bool;
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

  /// Adds the specified [CPSpeaker] utterance to the queue of the speech synthesizer in CarPlay.
  static void speak(CPSpeaker speakerController) {
    if (speakerController.onComplete != null) {
      FlutterCarPlayController.callbackObjects.add(speakerController);
    }
    _carPlayController.methodChannel
        .invokeMethod(
            CPEnumUtils.stringFromEnum(FCPChannelTypes.speak.toString()),
            speakerController.toJson())
        .then((value) {
      if (value == false && speakerController.onComplete != null) {
        FlutterCarPlayController.callbackObjects
            .removeWhere((e) => e.uniqueId == speakerController.uniqueId);
      }
    });
  }

  /// Plays [CPAudio] data asynchronously.
  static void play(CPAudio audio) {
    _carPlayController.methodChannel.invokeMethod(
      CPEnumUtils.stringFromEnum(FCPChannelTypes.playAudio.toString()),
      audio.toJson(),
    );
  }

  /// Removes the top-most template from the navigation hierarchy.
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  /// - count represents how many times this function will occur.
  static Future<bool> pop({bool animated = true, int count = 1}) async {
    FlutterCarPlayController.templateHistory.removeLast();
    return await _carPlayController.reactToNativeModule(
      FCPChannelTypes.popTemplate,
      <String, dynamic>{
        "count": count,
        "animated": animated,
      },
    );
  }

  /// Removes all of the templates from the navigation hierarchy except the root template.
  /// If animated is true, CarPlay animates the presentation of the template.
  static Future<bool> popToRoot({bool animated = true}) async {
    FlutterCarPlayController.templateHistory = [
      FlutterCarPlayController.currentRootTemplate
    ];
    return await _carPlayController.reactToNativeModule(
      FCPChannelTypes.popToRootTemplate,
      animated,
    );
  }

  /// Removes a modal template. Since [CPAlertTemplate], [CPActionSheetTemplate], [CPVoiceControlTemplate] are
  /// modals, they can be removed. If animated is true, CarPlay animates the transition between templates.
  static Future<bool> popModal({bool animated = true}) async {
    FlutterCarPlayController.currentPresentTemplate = null;
    return await _carPlayController.reactToNativeModule(
      FCPChannelTypes.closePresent,
      animated,
    );
  }

  /// Adds a template to the navigation hierarchy and displays it.
  ///
  /// - template is to add to the navigation hierarchy. **Must be one of the type:**
  /// [CPGridTemplate] or [CPListTemplate] If not, it will throw an [TypeError]
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  static Future<bool> push({
    required dynamic template,
    bool animated = true,
  }) async {
    if (template.runtimeType == CPGridTemplate ||
        template.runtimeType == CPListTemplate) {
      bool isCompleted = await _carPlayController
          .reactToNativeModule(FCPChannelTypes.pushTemplate, <String, dynamic>{
        "template": template.toJson(),
        "animated": animated,
        "runtimeType": "F" + template.runtimeType.toString(),
      });
      if (isCompleted) {
        _carPlayController.addTemplateToHistory(template);
      }
      return isCompleted;
    } else {
      throw TypeError();
    }
  }
}
