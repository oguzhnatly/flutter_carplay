//
//  SwiftFlutterCarplayPlugin.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Flutter
import heresdk

/// A Swift Flutter plugin for CarPlay integration.
///
/// This plugin provides a bridge between Flutter and CarPlay, allowing developers to create CarPlay-enabled Flutter apps.

@available(iOS 14.0, *)
public class SwiftFlutterCarplayPlugin: NSObject, FlutterPlugin {
    /// The stream handler for CarPlay communication.
    private static var streamHandler: FCPStreamHandlerPlugin?

    /// The Flutter plugin registrar.
    private(set) static var registrar: FlutterPluginRegistrar?

    /// The root template to be displayed on CarPlay.
    private static var _fcpRootTemplate: FCPRootTemplate?

    /// The root view controller for CarPlay.
    private static var _rootViewController: UIViewController?

    /// The root template for CarPlay.
    private static var _rootTemplate: CPTemplate?

    /// Indicates whether animations should be used.
    public static var animated: Bool = false

    /// The present template object for CarPlay modals.
    private var fcpPresentTemplate: FCPPresentTemplate?

    /// The root template to be displayed on CarPlay.
    public static var rootTemplate: CPTemplate? {
        get {
            return _rootTemplate
        }
        set(template) {
            _rootTemplate = template
        }
    }

    /// The root template to be displayed on CarPlay.
    static var fcpRootTemplate: FCPRootTemplate? {
        get {
            return _fcpRootTemplate
        }
        set(template) {
            _fcpRootTemplate = template
        }
    }

    /// The root view controller for CarPlay.
    public static var rootViewController: UIViewController? {
        get {
            return _rootViewController
        }
        set(viewController) {
            _rootViewController = viewController
        }
    }

    /// The CPTemplate history for CarPlay.
    public static var cpTemplateHistory: [CPTemplate] {
        return FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.templates ?? []
    }

    /// Registers the plugin with the Flutter engine.
    ///
    /// This method is called when the Flutter engine initializes the plugin.
    ///
    /// - Parameter registrar: The Flutter plugin registrar.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: makeFCPChannelId(event: ""),
                                           binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterCarplayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        self.registrar = registrar

        streamHandler = FCPStreamHandlerPlugin(registrar: registrar)
    }

    /// Handles a Flutter method call and provides a result callback.
    ///
    /// This method is responsible for processing Flutter method calls and producing a result
    /// through the provided `FlutterResult` callback. It is typically used as part of a Flutter
    /// plugin implementation.
    ///
    /// - Parameters:
    ///   - call: The `FlutterMethodCall` representing the invoked method.
    ///   - result: The callback to provide the result of the method call to Flutter.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        MemoryLogger.shared.appendEvent("FlutterMethodCall received : \(call.method)")

        switch call.method {
        case FCPChannelTypes.setRootTemplate:

            guard let args = call.arguments as? [String: Any],
                  let runtimeType = args["runtimeType"] as? String,
                  let rootTemplate = createRootTemplate(from: args, runtimeType: runtimeType)
            else {
                result(false)
                return
            }

            setRootTemplate(rootTemplate, args: args, result: result)
        case FCPChannelTypes.forceUpdateRootTemplate:
            FlutterCarPlaySceneDelegate.forceUpdateRootTemplate(completion: { completed, _ in
                result(completed)
            })
        case FCPChannelTypes.updateInformationTemplate:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String
            else {
                result(false)
                return
            }

            updateInformationTemplate(elementId: elementId, args: args)
            result(true)
        case FCPChannelTypes.updateMapTemplate:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String
            else {
                result(false)
                return
            }

            updateMapTemplate(elementId: elementId, args: args)
            result(true)
        case FCPChannelTypes.updateListTemplate:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String,
                  let sections = args["sections"] as? [[String: Any]]
            else {
                result(false)
                return
            }

            updateListTemplate(elementId: elementId, sections: sections, args: args)
            result(true)
        case FCPChannelTypes.updateListItem:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String
            else {
                result(false)
                return
            }
            updateListItem(elementId: elementId, args: args)
            result(true)
        case FCPChannelTypes.onListItemSelectedComplete:
            guard let args = call.arguments as? String else {
                result(false)
                return
            }
            SwiftFlutterCarplayPlugin.findListItem(elementId: args, actionWhenFound: { item in
                item.stopHandler()
            })
            result(true)
        case FCPChannelTypes.onSearchTextUpdatedComplete:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String
            else {
                result(false)
                return
            }

            let searchResults = (args["searchResults"] as? [[String: Any]] ?? []).map {
                FCPListItem(obj: $0)
            }

            SwiftFlutterCarplayPlugin.findSearchTemplate(elementId: elementId, actionWhenFound: { template in
                template.searchPerformed(searchResults)
            })
            result(true)
        case FCPChannelTypes.setAlert:
            guard let args = call.arguments as? [String: Any],
                  let animated = args["animated"] as? Bool,
                  let rootTemplateArgs = args["rootTemplate"] as? [String: Any]
            else {
                result(false)
                return
            }

            if fcpPresentTemplate != nil {
                fcpPresentTemplate = nil
                FlutterCarPlaySceneDelegate.closePresent(animated: animated, completion: { _, _ in
                    showAlertTemplate()
                })
            } else {
                showAlertTemplate()
            }
            func showAlertTemplate() {
                let alertTemplate = FCPAlertTemplate(obj: rootTemplateArgs)
                fcpPresentTemplate = alertTemplate
                FlutterCarPlaySceneDelegate
                    .presentTemplate(template: alertTemplate.get, animated: animated, completion: { completed, _ in
                        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                                         data: ["completed": completed])
                        result(completed)
                    })
            }
        case FCPChannelTypes.setActionSheet:
            guard let args = call.arguments as? [String: Any],
                  let animated = args["animated"] as? Bool,
                  let rootTemplateArgs = args["rootTemplate"] as? [String: Any]
            else {
                result(false)
                return
            }

            if fcpPresentTemplate != nil {
                fcpPresentTemplate = nil
                FlutterCarPlaySceneDelegate.closePresent(animated: animated, completion: { _, _ in
                    showActionSheet()
                })
            } else {
                showActionSheet()
            }

            func showActionSheet() {
                let actionSheetTemplate = FCPActionSheetTemplate(obj: rootTemplateArgs)
                fcpPresentTemplate = actionSheetTemplate
                FlutterCarPlaySceneDelegate.presentTemplate(template: actionSheetTemplate.get, animated: animated, completion: { completed, _ in
                    result(completed)
                })
            }

        case FCPChannelTypes.popTemplate:
            guard let args = call.arguments as? [String: Any],
                  let count = args["count"] as? Int,
                  let animated = args["animated"] as? Bool
            else {
                result(false)
                return
            }
            for _ in 1 ... count {
                FlutterCarPlaySceneDelegate.pop(animated: animated, completion: { _, _ in
                })
            }
            result(true)
        case FCPChannelTypes.closePresent:
            guard let animated = call.arguments as? Bool else {
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.closePresent(animated: animated, completion: { completed, _ in
                result(completed)
            })
            fcpPresentTemplate = nil
        case FCPChannelTypes.pushTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            pushTemplate(args: args, result: result)
        case FCPChannelTypes.popToRootTemplate:
            guard let animated = call.arguments as? Bool else {
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.popToRootTemplate(animated: animated, completion: { completed, _ in
                result(completed)
            })
            fcpPresentTemplate = nil
        case FCPChannelTypes.setVoiceControl:
            guard let args = call.arguments as? [String: Any],
                  let animated = args["animated"] as? Bool,
                  let rootTemplateArgs = args["rootTemplate"] as? [String: Any]
            else {
                result(false)
                return
            }

            if fcpPresentTemplate != nil {
                fcpPresentTemplate = nil
                FlutterCarPlaySceneDelegate.closePresent(animated: animated, completion: { _, _ in
                    showVoiceTemplate()
                })
            } else {
                showVoiceTemplate()
            }

            func showVoiceTemplate() {
                let voiceControlTemplate = FCPVoiceControlTemplate(obj: rootTemplateArgs)
                fcpPresentTemplate = voiceControlTemplate
                FlutterCarPlaySceneDelegate.presentTemplate(template: voiceControlTemplate.get, animated: animated, completion: { completed, _ in
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                                     data: ["completed": completed])
                    result(completed)
                })
            }
        case FCPChannelTypes.activateVoiceControlState:
            guard fcpPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To activate a voice control state, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            guard let args = call.arguments as? String else {
                result(false)
                return
            }

            if let voiceControlTemplate = fcpPresentTemplate as? FCPVoiceControlTemplate {
                voiceControlTemplate.activateVoiceControlState(identifier: args)
                result(true)
            } else {
                result(false)
            }
        case FCPChannelTypes.getActiveVoiceControlStateIdentifier:
            guard fcpPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To get the active voice control state identifier, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }

            if let voiceControlTemplate = fcpPresentTemplate as? FCPVoiceControlTemplate {
                let identifier = voiceControlTemplate.getActiveVoiceControlStateIdentifier()
                result(identifier)
            } else {
                result(nil)
            }
        case FCPChannelTypes.startVoiceControl:
            guard fcpPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To start the voice control, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            if let voiceControlTemplate = fcpPresentTemplate as? FCPVoiceControlTemplate {
                voiceControlTemplate.start()
                result(true)
            } else {
                result(false)
            }
        case FCPChannelTypes.stopVoiceControl:
            guard fcpPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To stop the voice control, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            if let voiceControlTemplate = fcpPresentTemplate as? FCPVoiceControlTemplate {
                voiceControlTemplate.stop()
                result(true)
            } else {
                result(false)
            }
        case FCPChannelTypes.speak:
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String,
                  let language = args["language"] as? String,
                  let elementId = args["_elementId"] as? String,
                  let onCompleted = args["onCompleted"] as? Bool
            else {
                result(false)
                return
            }
            FCPSpeaker.shared.speak(text, language: language) {
                if onCompleted {
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSpeechCompleted,
                                                     data: ["elementId": elementId])
                }
            }
            result(true)
        case FCPChannelTypes.playAudio:
            guard let args = call.arguments as? [String: Any],
                  let soundPath = args["soundPath"] as? String,
                  let volume = args["volume"] as? NSNumber
            else {
                result(false)
                return
            }
            FCPSoundEffects.shared.prepare(sound: soundPath, volume: volume.floatValue)
            FCPSoundEffects.shared.play()
            result(true)
        case FCPChannelTypes.getConfig:
            let config = [
                "maximumItemCount": CPListTemplate.maximumItemCount,
                "maximumSectionCount": CPListTemplate.maximumSectionCount,
            ]
            result(config)
        case FCPChannelTypes.showTripPreviews:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String,
                  let trips = args["trips"] as? [[String: Any]]
            else {
                result(false)
                return
            }

            let selectedTrip = args["selectedTrip"] as? [String: Any]
            let textConfiguration = args["textConfiguration"] as? [String: Any]

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in

                let fcpTrips = trips.map { FCPTrip(obj: $0) }
                let fcpSelectedTrip = selectedTrip == nil ? nil : FCPTrip(obj: selectedTrip!)
                let fcpTextConfiguration = textConfiguration == nil ? nil : FCPTripPreviewTextConfiguration(obj: textConfiguration!)
                mapTemplate.showTripPreviews(trips: fcpTrips, selectedTrip: fcpSelectedTrip, textConfiguration: fcpTextConfiguration)
                return result(true)
            }

            result(false)

        case FCPChannelTypes.hideTripPreviews:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String
            else {
                result(false)
                return
            }
            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.hideTripPreviews()
                return result(true)
            }
            result(false)
        case FCPChannelTypes.showBanner:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String,
                  let message = args["message"] as? String,
                  let color = args["color"] as? Int
            else {
                result(false)
                return
            }

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.fcpMapViewController?.showBanner(message: message, color: color)
                return result(true)
            }
            result(false)
        case FCPChannelTypes.hideBanner:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String
            else {
                result(false)
                return
            }

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.fcpMapViewController?.hideBanner()
                return result(true)
            }
            result(false)
        case FCPChannelTypes.showToast:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String,
                  let message = args["message"] as? String,
                  let duration = args["duration"] as? Double
            else {
                result(false)
                return
            }

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.fcpMapViewController?.showToast(message: message, duration: TimeInterval(duration))
                return result(true)
            }
            result(false)
        case FCPChannelTypes.showOverlay:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String

            else {
                result(false)
                return
            }

            let primaryTitle = args["primaryTitle"] as? String
            let secondaryTitle = args["secondaryTitle"] as? String
            let subtitle = args["subtitle"] as? String

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.fcpMapViewController?.showOverlay(primaryTitle: primaryTitle, secondaryTitle: secondaryTitle, subtitle: subtitle)
                return result(true)
            }
            result(false)
        case FCPChannelTypes.hideOverlay:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String
            else {
                result(false)
                return
            }

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.fcpMapViewController?.hideOverlay()
                return result(true)
            }
            result(false)

        case FCPChannelTypes.showPanningInterface:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String,
                  let animated = args["animated"] as? Bool
            else {
                result(false)
                return
            }

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.showPanningInterface(animated: animated)
                return result(true)
            }
            result(false)

        case FCPChannelTypes.dismissPanningInterface:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String,
                  let animated = args["animated"] as? Bool
            else {
                result(false)
                return
            }

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.dismissPanningInterface(animated: animated)
                return result(true)
            }
            result(false)

        case FCPChannelTypes.startNavigation:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String,
                  let trip = args["trip"] as? [String: Any]
            else {
                result(false)
                return
            }

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                let cpTrip = FCPTrip(obj: trip).get
                mapTemplate.startNavigation(trip: cpTrip)
                return result(true)
            }
            result(false)

        case FCPChannelTypes.stopNavigation:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String
            else {
                result(false)
                return
            }

            // Find the map template based on the provided element ID
            SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
                mapTemplate.stopNavigation()
                return result(true)
            }
            result(false)

        case FCPChannelTypes.onManeuverActionTextRequestComplete:
            guard let args = call.arguments as? [String: Any],
                  let text = args["actionText"] as? String,
                  let isPrimary = args["isPrimary"] as? Bool
            else {
                result(false)
                return
            }

            isPrimary ? primaryManeuverActionTextHandler?(text) : secondaryManeuverActionTextHandler?(text)

            result(true)

        case FCPChannelTypes.toggleOfflineMode:
            guard let args = call.arguments as? [String: Any],
                  let isOffline = args["isOffline"] as? Bool
            else {
                result(false)
                return
            }

            toggleOfflineModeHandler?(isOffline)

            result(true)

        case FCPChannelTypes.toggleVoiceInstructions:
            guard let args = call.arguments as? [String: Any],
                  let isMuted = args["isMuted"] as? Bool
            else {
                result(false)
                return
            }

            toggleVoiceInstructionsHandler?(isMuted)

            result(true)

        case FCPChannelTypes.toggleSatelliteView:
            guard let args = call.arguments as? [String: Any],
                  let showSatelliteView = args["showSatelliteView"] as? Bool
            else {
                result(false)
                return
            }

            toggleSatelliteViewHandler?(showSatelliteView)

            result(true)

        case FCPChannelTypes.toggleTrafficView:
            guard let args = call.arguments as? [String: Any],
                  let showTrafficView = args["showTrafficView"] as? Bool
            else {
                result(false)
                return
            }

            toggleTrafficViewHandler?(showTrafficView)

            result(true)

        case FCPChannelTypes.recenterMapView:
            guard let args = call.arguments as? [String: Any],
                  let recenterMapPosition = args["recenterMapPosition"] as? String
            else {
                result(false)
                return
            }

            recenterMapViewHandler?(recenterMapPosition)

            result(true)

        case FCPChannelTypes.updateMapCoordinates:
            guard let args = call.arguments as? [String: Any]
            else {
                result(false)
                return
            }

            var stationAddressCoordinates: GeoCoordinates?
            var incidentAddressCoordinates: GeoCoordinates?
            var destinationAddressCoordinates: GeoCoordinates?

            if
                let stationAddressLatitude = args["stationAddressLatitude"] as? Double,
                let stationAddressLongitude = args["stationAddressLongitude"] as? Double
            {
                stationAddressCoordinates = GeoCoordinates(latitude: stationAddressLatitude, longitude: stationAddressLongitude)
            }

            if let incidentAddressLatitude = args["incidentAddressLatitude"] as? Double,
               let incidentAddressLongitude = args["incidentAddressLongitude"] as? Double
            {
                incidentAddressCoordinates = GeoCoordinates(latitude: incidentAddressLatitude, longitude: incidentAddressLongitude)
            }

            if let destinationAddressLatitude = args["destinationAddressLatitude"] as? Double,
               let destinationAddressLongitude = args["destinationAddressLongitude"] as? Double
            {
                destinationAddressCoordinates = GeoCoordinates(latitude: destinationAddressLatitude, longitude: destinationAddressLongitude)
            }

            let mapCoordinates = MapCoordinates(stationAddressCoordinates: stationAddressCoordinates, incidentAddressCoordinates: incidentAddressCoordinates, destinationAddressCoordinates: destinationAddressCoordinates)

            updateMapCoordinatesHandler?(mapCoordinates)

            result(false)

        default:
            result(false)
        }
    }

    /// Creates an event channel for communication with Flutter.
    ///
    /// - Parameter event: The name of the event channel.
    /// - Returns: A Flutter event channel for communication with Flutter.
    static func createEventChannel(event: String?) -> FlutterEventChannel {
        let eventChannel = FlutterEventChannel(name: makeFCPChannelId(event: event),
                                               binaryMessenger: SwiftFlutterCarplayPlugin.registrar!.messenger())
        return eventChannel
    }
}

// MARK: - Helper

extension SwiftFlutterCarplayPlugin {
    /// Creates an FCPRootTemplate based on the provided arguments and runtime type.
    /// - Parameters:
    ///   - args: A dictionary containing the root template arguments.
    ///   - runtimeType: A string representing the runtime type of the root template.
    /// - Returns: An instance of FCPRootTemplate if successful, otherwise nil.
    private func createRootTemplate(from args: [String: Any], runtimeType: String) -> FCPRootTemplate? {
        // Ensure that the rootTemplateArgs key exists in the args dictionary
        guard let rootTemplateArgs = args["rootTemplate"] as? [String: Any] else {
            return nil
        }

        // Create an FCPRootTemplate based on the provided runtime type
        switch runtimeType {
        case String(describing: FCPTabBarTemplate.self):
            return FCPTabBarTemplate(obj: rootTemplateArgs)

        case String(describing: FCPGridTemplate.self):
            return FCPGridTemplate(obj: rootTemplateArgs)

        case String(describing: FCPInformationTemplate.self):
            return FCPInformationTemplate(obj: rootTemplateArgs)

        case String(describing: FCPPointOfInterestTemplate.self):
            return FCPPointOfInterestTemplate(obj: rootTemplateArgs)

        case String(describing: FCPMapTemplate.self):
            let mapTemplate = FCPMapTemplate(obj: rootTemplateArgs)
            return mapTemplate

        case String(describing: FCPListTemplate.self):
            // For FCPListTemplate, set the template type to DEFAULT
            let templateType = FCPListTemplateTypes.DEFAULT
            return FCPListTemplate(obj: rootTemplateArgs, templateType: templateType)

        default:
            return nil
        }
    }

    /// Sets the root template for CarPlay based on the provided FCPRootTemplate.
    /// - Parameters:
    ///   - rootTemplate: The FCPRootTemplate to be set as the root template.
    ///   - args: Additional arguments for setting the root template.
    ///   - result: A FlutterResult callback to communicate the success or failure of the operation.
    private func setRootTemplate(_ rootTemplate: FCPRootTemplate, args: [String: Any], result: FlutterResult) {
        var cpRootTemplate: CPTemplate

        // Check the type of the root template and extract the corresponding FCPRootTemplate
        switch rootTemplate {
        case let tabBarTemplate as FCPTabBarTemplate:
            // Ensure that the number of templates in the tab bar template is within the CarPlay limit
            if tabBarTemplate.getTemplates().count > 5 {
                result(FlutterError(
                    code: "ERROR",
                    message: "CarPlay cannot have more than 5 templates on one screen.",
                    details: nil
                ))
                return
            }
            cpRootTemplate = tabBarTemplate.get

        case let gridTemplate as FCPGridTemplate:
            cpRootTemplate = gridTemplate.get

        case let informationTemplate as FCPInformationTemplate:
            cpRootTemplate = informationTemplate.get

        case let pointOfInterestTemplate as FCPPointOfInterestTemplate:
            cpRootTemplate = pointOfInterestTemplate.get

        case let mapTemplate as FCPMapTemplate:
            // For FCPMapTemplate, set the rootViewController and update the CarPlay window's rootViewController
            cpRootTemplate = mapTemplate.get

            SwiftFlutterCarplayPlugin.rootViewController = mapTemplate.viewController

            if FlutterCarPlayTemplateManager.shared.isDashboardSceneActive {
                FlutterCarPlayTemplateManager.shared.dashboardWindow?.rootViewController = mapTemplate.viewController
            } else {
                FlutterCarPlayTemplateManager.shared.carWindow?.rootViewController = mapTemplate.viewController
            }

        case let listTemplate as FCPListTemplate:
            cpRootTemplate = listTemplate.get

        default:
            // If the root template type is not recognized, return false
            result(false)
            return
        }

        // If an FCPRootTemplate is successfully extracted, set it as the root template
        SwiftFlutterCarplayPlugin.rootTemplate = cpRootTemplate
        FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.setRootTemplate(cpRootTemplate, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
        SwiftFlutterCarplayPlugin.fcpRootTemplate = rootTemplate
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FlutterCarPlayTemplateManager.shared.fcpConnectionStatus)
        let animated = args["animated"] as? Bool ?? false
        SwiftFlutterCarplayPlugin.animated = animated
        result(true)
    }

    /// Pushes a new CarPlay template onto the navigation stack.
    ///
    /// - Parameters:
    ///   - args: Arguments containing information about the template to be pushed.
    ///   - result: The FlutterResult to return the completion status of the operation.
    private func pushTemplate(args: [String: Any], result: @escaping FlutterResult) {
        // Extract necessary information from the provided arguments
        guard let runtimeType = args["runtimeType"] as? String,
              let templateArgs = args["template"] as? [String: Any],
              let animated = args["animated"] as? Bool
        else {
            result(false)
            return
        }

        var pushTemplate: CPTemplate

        // Create the appropriate FCPTemplate based on the runtime type
        switch runtimeType {
        case String(describing: FCPGridTemplate.self):
            pushTemplate = FCPGridTemplate(obj: templateArgs).get
        case String(describing: FCPPointOfInterestTemplate.self):
            pushTemplate = FCPPointOfInterestTemplate(obj: templateArgs).get
        case String(describing: FCPMapTemplate.self):
            pushTemplate = FCPMapTemplate(obj: templateArgs).get
        case String(describing: FCPSearchTemplate.self):
            pushTemplate = FCPSearchTemplate(obj: templateArgs).get
        case String(describing: FCPInformationTemplate.self):
            pushTemplate = FCPInformationTemplate(obj: templateArgs).get
        case String(describing: FCPListTemplate.self):
            pushTemplate = FCPListTemplate(obj: templateArgs, templateType: FCPListTemplateTypes.DEFAULT).get
        default:
            result(false)
            return
        }

        // Push the template onto the navigation stack
        FlutterCarPlaySceneDelegate.push(template: pushTemplate, animated: animated) { completed, _ in
            result(completed)
        }
    }

    /// Notifies Flutter about changes in CarPlay connection status.
    ///
    /// - Parameter status: The CarPlay connection status.
    static func onCarplayConnectionChange(status: String) {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onCarplayConnectionChange,
                                         data: ["status": status])
    }

    /// Sends an event to Flutter with the updated speech recognition transcript.
    ///
    /// - Parameter transcript: The updated speech recognition transcript.
    static func sendSpeechRecognitionTranscriptChangeEvent(transcript: String) {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onVoiceControlTranscriptChanged,
                                         data: ["transcript": transcript])
    }
}

// MARK: - Update FCPObjects

extension SwiftFlutterCarplayPlugin {
    /// Updates a CarPlay information template identified by its element ID with new data.
    ///
    /// - Parameters:
    ///   - elementId: The unique identifier of the information template to be updated.
    ///   - args: Additional arguments for updating the information template.
    private func updateInformationTemplate(elementId: String, args: [String: Any]) {
        // Find the information template based on the provided element ID
        SwiftFlutterCarplayPlugin.findInformationTemplate(elementId: elementId) { infoTemplate in
            // Map dictionary representations to FCPInformationItem instances for items
            let items = (args["informationItems"] as? [[String: Any]])?.map {
                FCPInformationItem(obj: $0)
            }

            // Map dictionary representations to FCPTextButton instances for actions
            let actions = (args["actions"] as? [[String: Any]])?.map {
                FCPTextButton(obj: $0)
            }

            // Map dictionary representations to FCPBarButton instances for navigation bar buttons
            let leadingNavigationBarButtons = (args["leadingNavigationBarButtons"] as? [[String: Any]])?.map {
                FCPBarButton(obj: $0)
            }

            let trailingNavigationBarButtons = (args["trailingNavigationBarButtons"] as? [[String: Any]])?.map {
                FCPBarButton(obj: $0)
            }

            infoTemplate.update(
                items: items,
                actions: actions,
                leadingNavigationBarButtons: leadingNavigationBarButtons,
                trailingNavigationBarButtons: trailingNavigationBarButtons
            )
        }
    }

    /// Updates a CarPlay map template identified by its element ID with new data.
    ///
    /// - Parameters:
    ///   - elementId: The unique identifier of the list template to be updated.
    ///   - args: Additional arguments for updating the list template.
    private func updateMapTemplate(elementId: String, args: [String: Any]) {
        // Find the map template based on the provided element ID
        SwiftFlutterCarplayPlugin.findMapTemplate(elementId: elementId) { mapTemplate in
            // Extract and handle the data for updating the map template
            let title = args["title"] as? String
            let hidesButtonsWithNavigationBar = args["hidesButtonsWithNavigationBar"] as? Bool
            let automaticallyHidesNavigationBar = args["automaticallyHidesNavigationBar"] as? Bool

            // Map dictionary representations to FCPMapButton instances for map buttons
            let mapButtons = (args["mapButtons"] as? [[String: Any]])?.map {
                FCPMapButton(obj: $0)
            }

            // Map dictionary representations to FCPBarButton instances for navigation bar buttons
            let leadingNavigationBarButtons = (args["leadingNavigationBarButtons"] as? [[String: Any]])?.map {
                FCPBarButton(obj: $0)
            }

            let trailingNavigationBarButtons = (args["trailingNavigationBarButtons"] as? [[String: Any]])?.map {
                FCPBarButton(obj: $0)
            }

            mapTemplate.update(
                title: title,
                automaticallyHidesNavigationBar: automaticallyHidesNavigationBar,
                hidesButtonsWithNavigationBar: hidesButtonsWithNavigationBar,
                mapButtons: mapButtons,
                leadingNavigationBarButtons: leadingNavigationBarButtons,
                trailingNavigationBarButtons: trailingNavigationBarButtons
            )
        }
    }

    /// Updates a CarPlay list template identified by its element ID with new data.
    ///
    /// - Parameters:
    ///   - elementId: The unique identifier of the list template to be updated.
    ///   - sections: An array of dictionaries representing the updated sections of the list template.
    ///   - args: Additional arguments for updating the list template.
    private func updateListTemplate(elementId: String, sections: [[String: Any]], args: [String: Any]) {
        // Find the list template based on the provided element ID
        SwiftFlutterCarplayPlugin.findListTemplate(elementId: elementId) { listTemplate in
            // Extract and handle the data for updating the list template
            let emptyViewTitleVariants = args["emptyViewTitleVariants"] as? [String]
            let emptyViewSubtitleVariants = args["emptyViewSubtitleVariants"] as? [String]

            // Map dictionary representations to FCPBarButton instances for navigation bar buttons
            let leadingNavigationBarButtons = (args["leadingNavigationBarButtons"] as? [[String: Any]])?.map {
                FCPBarButton(obj: $0)
            }
            let trailingNavigationBarButtons = (args["trailingNavigationBarButtons"] as? [[String: Any]])?.map {
                FCPBarButton(obj: $0)
            }

            // Update the list template with the extracted data
            listTemplate.update(
                emptyViewTitleVariants: emptyViewTitleVariants,
                emptyViewSubtitleVariants: emptyViewSubtitleVariants,
                sections: sections.map { FCPListSection(obj: $0) },
                leadingNavigationBarButtons: leadingNavigationBarButtons,
                trailingNavigationBarButtons: trailingNavigationBarButtons
            )
        }
    }

    /// Updates a CarPlay list item identified by its element ID with new data.
    ///
    /// - Parameters:
    ///   - elementId: The unique identifier of the list item to be updated.
    ///   - args: Additional arguments for updating the list item.
    private func updateListItem(elementId: String, args: [String: Any]) {
        // Find the list item based on the provided element ID
        SwiftFlutterCarplayPlugin.findListItem(elementId: elementId) { item in
            // Extract and handle the data for updating the list item
            let text = args["text"] as? String
            let detailText = args["detailText"] as? String
            let image = args["image"] as? String
            let darkImage = args["darkImage"] as? String
            let playbackProgress = args["playbackProgress"] as? CGFloat
            let isPlaying = args["isPlaying"] as? Bool
            let isEnabled = args["isEnabled"] as? Bool
            let playingIndicatorLocation = args["playingIndicatorLocation"] as? String
            let accessoryType = args["accessoryType"] as? String
            let accessoryImage = args["accessoryImage"] as? String
            let accessoryDarkImage = args["accessoryDarkImage"] as? String

            // Update the list item with the extracted data
            item.update(
                text: text,
                detailText: detailText,
                image: image,
                darkImage: darkImage,
                accessoryImage: accessoryImage,
                accessoryDarkImage: accessoryDarkImage,
                playbackProgress: playbackProgress,
                isPlaying: isPlaying,
                playingIndicatorLocation: playingIndicatorLocation,
                accessoryType: accessoryType,
                isEnabled: isEnabled
            )
        }
    }
}

// MARK: - Find FCPObjects

private extension SwiftFlutterCarplayPlugin {
    /// Finds a CarPlay search template by element ID and performs an action when found.
    ///
    /// - Parameters:
    ///   - elementId: The element ID of the search template.
    ///   - actionWhenFound: The action to perform when the search template is found.
    static func findSearchTemplate(elementId: String, actionWhenFound: (_ searchTemplate: FCPSearchTemplate) -> Void) {
        // Filter the template history to include only FCPSearchTemplate instances.
        let filteredTemplates = SwiftFlutterCarplayPlugin.cpTemplateHistory.filter { $0 is CPSearchTemplate }

        if let fcpTemplates = filteredTemplates as? [CPSearchTemplate] {
            let templates = fcpTemplates.compactMap { ($0.userInfo as? [String: Any])?["FCPObject"] as? FCPSearchTemplate }
            // Iterate through the templates to find the one with the matching element ID.
            for template in templates where template.elementId == elementId {
                // Perform the specified action when the template is found.
                actionWhenFound(template)
                return
            }
        }
        // If no templates are available or found, return early.
    }

    /// Finds a CarPlay information template by element ID and performs an action when found.
    ///
    /// - Parameters:
    ///   - elementId: The element ID of the information template.
    ///   - actionWhenFound: The action to perform when the information template is found.
    static func findInformationTemplate(elementId: String, actionWhenFound: (_ template: FCPInformationTemplate) -> Void) {
        // Get the array of FCPInformationTemplate instances.
        let templates = getFCPInformationTemplatesFromHistory()

        // Iterate through the templates to find the one with the matching element ID.
        for template in templates where template.elementId == elementId {
            // Perform the specified action when the template is found.
            actionWhenFound(template)
            break
        }
    }

    /// Finds a CarPlay map template by element ID and performs an action when found.
    ///
    /// - Parameters:
    ///   - elementId: The element ID of the map template.
    ///   - actionWhenFound: The action to perform when the map template is found.
    static func findMapTemplate(elementId: String, actionWhenFound: (_ template: FCPMapTemplate) -> Void) {
        // Get the array of FCPMapTemplate instances.
        let templates = getFCPMapTemplatesFromHistory()

        // Iterate through the templates to find the one with the matching element ID.
        for template in templates where template.elementId == elementId {
            // Perform the specified action when the template is found.
            actionWhenFound(template)
            break
        }
    }

    /// Finds a CarPlay list template by element ID and performs an action when found.
    ///
    /// - Parameters:
    ///   - elementId: The element ID of the list template.
    ///   - actionWhenFound: The action to perform when the list template is found.
    static func findListTemplate(elementId: String, actionWhenFound: (_ listTemplate: FCPListTemplate) -> Void) {
        // Get the array of FCPListTemplate instances.
        let templates = getFCPListTemplatesFromHistory()

        // Iterate through the templates to find the one with the matching element ID.
        for template in templates where template.elementId == elementId {
            // Perform the specified action when the template is found.
            actionWhenFound(template)
            break
        }
    }

    /// Finds a CarPlay list item by element ID and performs an action when found.
    ///
    /// - Parameters:
    ///   - elementId: The element ID of the list item.
    ///   - actionWhenFound: The action to perform when the list item is found.
    static func findListItem(elementId: String, actionWhenFound: (_ item: FCPListItem) -> Void) {
        // Get the array of FCPListTemplate instances.
        let templates = getFCPListTemplatesFromHistory()

        // Iterate through the templates, sections, and items to find the one with the matching element ID.
        for template in templates {
            for section in template.getSections() {
                for item in section.getItems() where item.elementId == elementId {
                    // Perform the specified action when the item is found.
                    actionWhenFound(item)
                    return
                }
            }
        }
    }

    /// Finds a CarPlay information template from history.
    ///
    /// - Returns:
    ///   - [FCPInformationTemplate]: Array of FCPInformationTemplate instances
    static func getFCPInformationTemplatesFromHistory() -> [FCPInformationTemplate] {
        // Initialize an array to store FCPInformationTemplate instances.
        var templates: [FCPInformationTemplate] = []

        // Filter the template history to include only FCPInformationTemplate instances.
        for template in SwiftFlutterCarplayPlugin.cpTemplateHistory {
            if let fcpTemplate = (((template as? CPInformationTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPInformationTemplate) {
                templates.append(fcpTemplate)
            }
        }

        return templates
    }

    /// Finds a CarPlay map template from history.
    ///
    /// - Returns:
    ///   - [FCPMapTemplate]: Array of FCPMapTemplate instances
    static func getFCPMapTemplatesFromHistory() -> [FCPMapTemplate] {
        // Initialize an array to store FCPMapTemplate instances.
        var templates: [FCPMapTemplate] = []

        // Filter the template history to include only FCPMapTemplate instances.
        for template in SwiftFlutterCarplayPlugin.cpTemplateHistory {
            if let fcpTemplate = (((template as? CPMapTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPMapTemplate) {
                templates.append(fcpTemplate)
            }
            // else if let fcpTemplate = (((template as? CPTabBarTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPTabBarTemplate) {
            //     templates.append(contentsOf: fcpTemplate.getTemplates())
            // }
        }

        return templates
    }

    /// Finds a CarPlay list templates from history.
    ///
    /// - Returns:
    ///   - [FCPListTemplate]: Array of FCPListTemplate instances
    static func getFCPListTemplatesFromHistory() -> [FCPListTemplate] {
        // Initialize an array to store FCPListTemplate instances.
        var templates: [FCPListTemplate] = []

        // Filter the template history to include only FCPListTemplate instances.
        for template in SwiftFlutterCarplayPlugin.cpTemplateHistory {
            if let fcpTemplate = (((template as? CPListTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPListTemplate) {
                templates.append(fcpTemplate)
            } else if let fcpTemplate = (((template as? CPTabBarTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPTabBarTemplate) {
                templates.append(contentsOf: fcpTemplate.getTemplates())
            }
        }

        return templates
    }
}
