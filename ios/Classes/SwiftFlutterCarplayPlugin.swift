//
//  SwiftFlutterCarplayPlugin.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Flutter

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
    private static var objcRootTemplate: FCPRootTemplate?

    /// The root view controller for CarPlay.
    private static var _rootViewController: UIViewController?

    /// The root template for CarPlay.
    private static var _rootTemplate: CPTemplate?

    /// Indicates whether animations should be used.
    public static var animated: Bool = false

    /// The present template object for CarPlay modals.
    private var objcPresentTemplate: FCPPresentTemplate?

    /// The root template to be displayed on CarPlay.
    public static var rootTemplate: CPTemplate? {
        get {
            return _rootTemplate
        }
        set(template) {
            _rootTemplate = template
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
            SwiftFlutterCarplayPlugin.findItem(elementId: args, actionWhenFound: { item in
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

            let searchResults = (args["searchResults"] as! [[String: Any]]).map {
                FCPListItem(obj: $0)
            }

            SwiftFlutterCarplayPlugin.findSearchTemplate(elementId: elementId, actionWhenFound: { template in
                MemoryLogger.shared.appendEvent("searchTemplate found: \(elementId)")
                template.searchPerformed(searchResults)
            })
            result(true)
        case FCPChannelTypes.setAlert:
            guard objcPresentTemplate == nil else {
                result(FlutterError(code: "ERROR",
                                    message: "CarPlay can only present one modal template at a time.",
                                    details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any],
                  let animated = args["animated"] as? Bool,
                  let rootTemplateArgs = args["rootTemplate"] as? [String: Any]
            else {
                result(false)
                return
            }
            let alertTemplate = FCPAlertTemplate(obj: rootTemplateArgs)
            objcPresentTemplate = alertTemplate
            FlutterCarPlaySceneDelegate
                .presentTemplate(template: alertTemplate.get, animated: animated, completion: { completed, _ in
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                                     data: ["completed": completed])
                    result(completed)
                })
        case FCPChannelTypes.setActionSheet:
            guard objcPresentTemplate == nil else {
                result(FlutterError(code: "ERROR",
                                    message: "CarPlay can only present one modal template at a time.",
                                    details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any],
                  let animated = args["animated"] as? Bool,
                  let rootTemplateArgs = args["rootTemplate"] as? [String: Any]
            else {
                result(false)
                return
            }
            let actionSheetTemplate = FCPActionSheetTemplate(obj: rootTemplateArgs)
            objcPresentTemplate = actionSheetTemplate
            FlutterCarPlaySceneDelegate.presentTemplate(template: actionSheetTemplate.get, animated: animated, completion: { completed, _ in
                result(completed)
            })
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
            objcPresentTemplate = nil
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
            objcPresentTemplate = nil
        case FCPChannelTypes.setVoiceControl:
            guard objcPresentTemplate == nil else {
                result(FlutterError(code: "ERROR",
                                    message: "CarPlay can only present one modal template at a time.",
                                    details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any],
                  let animated = args["animated"] as? Bool,
                  let rootTemplateArgs = args["rootTemplate"] as? [String: Any]
            else {
                result(false)
                return
            }
            let voiceControlTemplate = FCPVoiceControlTemplate(obj: rootTemplateArgs)
            objcPresentTemplate = voiceControlTemplate
            FlutterCarPlaySceneDelegate.presentTemplate(template: voiceControlTemplate.get, animated: animated, completion: { completed, _ in
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                                 data: ["completed": completed])
                result(completed)
            })
        case FCPChannelTypes.activateVoiceControlState:
            guard objcPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To activate a voice control state, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            guard let args = call.arguments as? String else {
                result(false)
                return
            }

            if let voiceControlTemplate = objcPresentTemplate as? FCPVoiceControlTemplate {
                voiceControlTemplate.activateVoiceControlState(identifier: args)
                result(true)
            } else {
                result(false)
            }
        case FCPChannelTypes.getActiveVoiceControlStateIdentifier:
            guard objcPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To get the active voice control state identifier, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }

            if let voiceControlTemplate = objcPresentTemplate as? FCPVoiceControlTemplate {
                let identifier = voiceControlTemplate.getActiveVoiceControlStateIdentifier()
                result(identifier)
            } else {
                result(nil)
            }
        case FCPChannelTypes.startVoiceControl:
            guard objcPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To start the voice control, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            if let voiceControlTemplate = objcPresentTemplate as? FCPVoiceControlTemplate {
                voiceControlTemplate.start()
                result(true)
            } else {
                result(false)
            }
        case FCPChannelTypes.stopVoiceControl:
            guard objcPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To stop the voice control, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            if let voiceControlTemplate = objcPresentTemplate as? FCPVoiceControlTemplate {
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
            // For FCPMapTemplate, set the rootViewController and update the CarPlay window's rootViewController
            let mapTemplate = FCPMapTemplate(obj: rootTemplateArgs)
            SwiftFlutterCarplayPlugin.rootViewController = mapTemplate.viewController
            FlutterCarPlaySceneDelegate.carWindow?.rootViewController = SwiftFlutterCarplayPlugin.rootViewController

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
            FlutterCarPlaySceneDelegate.carWindow?.rootViewController = SwiftFlutterCarplayPlugin.rootViewController

        case let listTemplate as FCPListTemplate:
            cpRootTemplate = listTemplate.get

        default:
            // If the root template type is not recognized, return false
            result(false)
            return
        }

        // If an FCPRootTemplate is successfully extracted, set it as the root template
        SwiftFlutterCarplayPlugin.rootTemplate = cpRootTemplate
        FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(cpRootTemplate, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
        SwiftFlutterCarplayPlugin.objcRootTemplate = rootTemplate
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
        SwiftFlutterCarplayPlugin.findItem(elementId: elementId) { item in
            // Extract and handle the data for updating the list item
            let text = args["text"] as? String
            let detailText = args["detailText"] as? String
            let image = args["image"] as? String
            let playbackProgress = args["playbackProgress"] as? CGFloat
            let isPlaying = args["isPlaying"] as? Bool
            let isEnabled = args["isEnabled"] as? Bool
            let playingIndicatorLocation = args["playingIndicatorLocation"] as? String
            let accessoryType = args["accessoryType"] as? String
            let accessoryImage = args["accessoryImage"] as? String

            // Update the list item with the extracted data
            item.update(
                text: text,
                detailText: detailText,
                image: image,
                accessoryImage: accessoryImage,
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

extension SwiftFlutterCarplayPlugin {
    /// Finds a CarPlay search template by element ID and performs an action when found.
    ///
    /// - Parameters:
    ///   - elementId: The element ID of the search template.
    ///   - actionWhenFound: The action to perform when the search template is found.
    static func findSearchTemplate(elementId: String, actionWhenFound: (_ searchTemplate: FCPSearchTemplate) -> Void) {
        // Filter the template history to include only FCPSearchTemplate instances.
        let filteredTemplates = FlutterCarPlaySceneDelegate.interfaceController?.templates.filter { $0 is CPSearchTemplate }

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

    /// Finds a CarPlay list template by element ID and performs an action when found.
    ///
    /// - Parameters:
    ///   - elementId: The element ID of the list template.
    ///   - actionWhenFound: The action to perform when the list template is found.
    static func findListTemplate(elementId: String, actionWhenFound: (_ listTemplate: FCPListTemplate) -> Void) {
        // Get the runtime type of the root template.
        if let objcRootTemplateType = String(describing: SwiftFlutterCarplayPlugin.objcRootTemplate).match(#"(.*flutter_carplay\.(.*)\))"#).first?[2] {
            // Initialize an array to store FCPListTemplate instances.
            var templates: [FCPListTemplate] = []

            // Filter the template history to include only FCPListTemplate instances.
            let filteredTemplates = FlutterCarPlaySceneDelegate.interfaceController?.templates.filter { $0 is CPListTemplate }

            // Populate the templates array if there are filtered templates.
            if let fcpTemplates = filteredTemplates as? [CPListTemplate] {
                templates = fcpTemplates.compactMap { ($0.userInfo as? [String: Any])?["FCPObject"] as? FCPListTemplate }
            }

            // Append the root template if its type is FCPListTemplate.
            if objcRootTemplateType.elementsEqual(String(describing: FCPListTemplate.self)),
               let rootListTemplate = SwiftFlutterCarplayPlugin.objcRootTemplate as? FCPListTemplate
            {
                templates.append(rootListTemplate)
            }
            // Append the templates from FCPTabBarTemplate if the root template is of that type.
            else if objcRootTemplateType.elementsEqual(String(describing: FCPTabBarTemplate.self)),
                    let tabBarTemplate = SwiftFlutterCarplayPlugin.objcRootTemplate as? FCPTabBarTemplate
            {
                templates.append(contentsOf: tabBarTemplate.getTemplates())
            }
            // If no templates are available, return early.
            else if templates.isEmpty {
                return
            }

            // Iterate through the templates to find the one with the matching element ID.
            for template in templates where template.elementId == elementId {
                // Perform the specified action when the template is found.
                actionWhenFound(template)
                break
            }
        }
    }

    /// Finds a CarPlay list item by element ID and performs an action when found.
    ///
    /// - Parameters:
    ///   - elementId: The element ID of the list item.
    ///   - actionWhenFound: The action to perform when the list item is found.
    static func findItem(elementId: String, actionWhenFound: (_ item: FCPListItem) -> Void) {
        // Get the runtime type of the root template.
        guard let objcRootTemplateType = String(describing: SwiftFlutterCarplayPlugin.objcRootTemplate).match(#"(.*flutter_carplay\.(.*)\))"#).first?[2] else {
            return
        }

        // Initialize an array to store FCPListTemplate instances.
        var templates: [FCPListTemplate] = []

        // Filter the interface controller templates to include only CPListTemplate instances.
        if let filteredTemplates = FlutterCarPlaySceneDelegate.interfaceController?.templates.filter({ $0 is CPListTemplate }) as? [CPListTemplate] {
            templates = filteredTemplates.compactMap { ($0.userInfo as? [String: Any])?["FCPObject"] as? FCPListTemplate }
        }

        // Append the root template if its type is FCPListTemplate.
        if objcRootTemplateType.elementsEqual(String(describing: FCPListTemplate.self)),
           let rootListTemplate = SwiftFlutterCarplayPlugin.objcRootTemplate as? FCPListTemplate
        {
            templates.append(rootListTemplate)
        }
        // Append the templates from FCPTabBarTemplate if the root template is of that type.
        else if objcRootTemplateType.elementsEqual(String(describing: FCPTabBarTemplate.self)),
                let tabBarTemplate = SwiftFlutterCarplayPlugin.objcRootTemplate as? FCPTabBarTemplate
        {
            templates.append(contentsOf: tabBarTemplate.getTemplates())
        }
        // If no templates are available, return early.
        else if templates.isEmpty {
            return
        }

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
}
