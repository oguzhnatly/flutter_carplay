import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

import 'controllers/android_auto_controller.dart';

/// An object in order to integrate Android auto in navigation and
/// manage all user interface elements appearing on your screens displayed on
/// the Android Auto screen.
///
/// Using Android auto, you can display content from your app on a customized user interface
/// that is generated and hosted by the system itself. Control over UI elements, such as
/// touch target size, font size and color, highlights, and so on.
///
/// **Useful Links:**
/// - [What is Android auto?](https://developer.android.com/training/cars?hl=fr#auto/)
class FlutterAndroidAuto {
  /// A main Flutter CarPlay Controller to manage the system.
  static final FlutterAndroidAutoController _androidAutoController =
      FlutterAndroidAutoController();

  /// CarPlay main bridge as a listener from Android Auto and native side.
  late final StreamSubscription<dynamic>? _eventBroadcast;

  /// Current Android Auto and mobile app connection status.
  static String _connectionStatus = ConnectionStatusTypes.unknown.name;

  /// A listener function, which will be triggered when CarPlay connection changes
  /// and will be transmitted to the main code, allowing the user to access
  /// the current connection status.
  Function(ConnectionStatusTypes status)? _onAndroidAutoConnectionChange;

  /// Creates an [FlutterAndroidAuto] and starts the connection.
  FlutterAndroidAuto() {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _eventBroadcast = _androidAutoController.eventChannel
        .receiveBroadcastStream()
        .listen((event) async {
      final FAAChannelTypes receivedChannelType =
          EnumUtils.enumFromString(FAAChannelTypes.values, event['type']);

      switch (receivedChannelType) {
        case FAAChannelTypes.onAndroidAutoConnectionChange:
          final ConnectionStatusTypes connectionStatus =
              EnumUtils.enumFromString(
            ConnectionStatusTypes.values,
            event['data']['status'],
          );
          _connectionStatus = connectionStatus.name;
          if (_onAndroidAutoConnectionChange != null) {
            _onAndroidAutoConnectionChange!(connectionStatus);
          }
          break;

        case FAAChannelTypes.onListItemSelected:
          await _androidAutoController.processFAAListItemSelectedChannel(
            event['data']['elementId'],
          );
          break;

        case FAAChannelTypes.onScreenBackButtonPressed:
          FlutterAndroidAutoController.templateHistory.removeWhere(
            (AATemplate item) => item.uniqueId == event['data']['elementId'],
          );
          break;

        case FAAChannelTypes.onAlertActionPressed:
          _androidAutoController.processFAAAlertActionPressed(
            event['data']['elementId'],
          );
          break;

        case FAAChannelTypes.onPresentStateChanged:
          final bool completed = event['data']['completed'] as bool? ?? false;
          _androidAutoController.processFAAPresentStateChanged(
            event['data']['elementId'],
            completed,
          );
          break;

        case FAAChannelTypes.onTabBarItemSelected:
          // Notifies Dart that the active tab changed. No Dart-side action
          // is strictly required; update the history if needed.
          break;

        case FAAChannelTypes.onGridButtonPressed:
          await _androidAutoController.processFAAGridButtonPressed(
            event['data']['elementId'],
          );
          break;

        default:
          break;
      }
    });
  }

  /// A function that will disconnect all event listeners from Android Auto. The action
  /// will be irrevocable, and a new [FlutterAndroidAuto] controller must be created after this,
  /// otherwise Android Auto will be unusable.
  ///
  /// [!] It is not recommended to use this function if you do not know what you are doing.
  void closeConnection() {
    _eventBroadcast!.cancel();
  }

  /// A function that will resume the paused all event listeners from Android Auto.
  void resumeConnection() {
    _eventBroadcast!.resume();
  }

  /// A function that will pause the all active event listeners from Android Auto.
  void pauseConnection() {
    _eventBroadcast!.pause();
  }

  /// Callback function will be fired when Android Auto connection status is changed.
  /// For example, when Android Auto is connected to the device, in the background state,
  /// or completely disconnected.
  ///
  /// See also: [ConnectionStatusTypes]
  void addListenerOnConnectionChange(
    Function(ConnectionStatusTypes status) onAndroidAutoConnectionChange,
  ) {
    _onAndroidAutoConnectionChange = onAndroidAutoConnectionChange;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on Android Auto connection status changed.
  void removeListenerOnConnectionChange() {
    _onAndroidAutoConnectionChange = null;
  }

  /// Current CarPlay connection status. It will return one of [ConnectionStatusTypes] as String.
  static String get connectionStatus {
    return _connectionStatus;
  }

  static Future<void> setRootTemplate({
    required AATemplate template,
  }) async {
    final bool? isCompleted = await _androidAutoController
        .flutterToNativeModule(FAAChannelTypes.setRootTemplate, {
      'template': template.toJson(),
      'runtimeType': _getAARuntimeTypeString(template),
    });

    if (isCompleted == true) {
      if (FlutterAndroidAutoController.templateHistory.isEmpty) {
        FlutterAndroidAutoController.templateHistory.add(template);
      } else {
        FlutterAndroidAutoController.templateHistory[0] = template;
      }
    }
  }

  /// It will set the current root template again.
  Future<void> forceUpdateRootTemplate() {
    return _androidAutoController.flutterToNativeModule(
      FAAChannelTypes.forceUpdateRootTemplate,
    );
  }

  /// Getter for current root template.
  static dynamic get rootTemplate {
    return FlutterAndroidAutoController.currentRootTemplate;
  }

  /// Presents an [AAAlertTemplate] modally on Android Auto.
  ///
  /// Because Android Auto does not support true overlay modals, the alert is
  /// pushed onto the navigation stack as a full-screen [MessageTemplate].
  /// Use [popModal] to dismiss it programmatically.
  ///
  /// [!] Only one modal can be presented at a time.
  static Future<void> showAlert({
    required AAAlertTemplate template,
  }) async {
    final bool? isCompleted = await _androidAutoController
        .flutterToNativeModule(FAAChannelTypes.setAlert, {
      'template': template.toJson(),
    });

    if (isCompleted == true) {
      FlutterAndroidAutoController.currentPresentTemplate = template;
    }
  }

  /// Dismisses the currently presented modal ([AAAlertTemplate]).
  static Future<bool> popModal() async {
    FlutterAndroidAutoController.currentPresentTemplate = null;
    final bool? isCompleted = await _androidAutoController
        .flutterToNativeModule(FAAChannelTypes.closePresent);
    return isCompleted ?? false;
  }

  /// Updates the tabs of the currently displayed [AATabBarTemplate].
  ///
  /// [template] must be the same instance (or have the same [uniqueId]) as the
  /// one currently set as root, with its [AATabBarTemplate.tabs] already updated.
  static Future<void> updateTabBarTemplates({
    required AATabBarTemplate template,
  }) async {
    await _androidAutoController
        .flutterToNativeModule(FAAChannelTypes.updateTabBarTemplates, {
      'template': template.toJson(),
    });

    // Keep Dart-side history in sync
    final index = FlutterAndroidAutoController.templateHistory
        .indexWhere((t) => t.uniqueId == template.uniqueId);
    if (index >= 0) {
      FlutterAndroidAutoController.templateHistory[index] = template;
    }
  }

  /// Removes the top-most template from the navigation hierarchy.
  ///
  /// The history will be updated accordingly to the screen lifecycle.
  static Future<bool> pop() async {
    final bool? isCompleted =
        await _androidAutoController.flutterToNativeModule(
      FAAChannelTypes.popTemplate,
    );

    return isCompleted ?? false;
  }

  /// Removes all of the templates from the navigation hierarchy except the root template.
  ///
  /// The history will be updated accordingly to the screen lifecycle.
  static Future<bool> popToRoot() async {
    final bool? isCompleted =
        await _androidAutoController.flutterToNativeModule(
      FAAChannelTypes.popToRootTemplate,
    );
    return isCompleted ?? false;
  }

  /// Adds a template to the navigation hierarchy and displays it.
  ///
  /// - template is to add to the navigation hierarchy. **Must be one of the type:**
  /// [AAListTemplate] or [AATabBarTemplate]
  ///
  /// Be aware of the restrictions : https://developer.android.com/training/cars/apps#template-restrictions
  /// - Max 5 templates in the navigation stack.
  static Future<bool> push({
    required AATemplate template,
  }) async {
    final bool? isCompleted = await _androidAutoController
        .flutterToNativeModule(FAAChannelTypes.pushTemplate, <String, dynamic>{
      'template': template.toJson(),
      'runtimeType': _getAARuntimeTypeString(template),
    });
    if (isCompleted == true) {
      FlutterAndroidAutoController.templateHistory.add(template);
    }
    return isCompleted ?? false;
  }

  /// Didn't exist on Android Auto. If the player can be displayed, a button will
  /// be shown on the bottom right of the Android Auto screen.
  static Future<bool> showSharedNowPlaying() async => false;

  /// Returns the runtime type string for native communication.
  /// Uses explicit type checks to ensure compatibility with Dart obfuscation.
  static String _getAARuntimeTypeString(AATemplate template) {
    if (template is AAListTemplate) return 'FAAListTemplate';
    if (template is AAGridTemplate) return 'FAAGridTemplate';
    if (template is AATabBarTemplate) return 'FAATabBarTemplate';
    if (template is AAAlertTemplate) return 'FAAAlertTemplate';
    return 'FAA${template.runtimeType}';
  }
}
