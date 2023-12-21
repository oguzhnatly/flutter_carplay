//
//  SwiftFlutterCarplayPlugin.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Flutter

@available(iOS 14.0, *)
public class SwiftFlutterCarplayPlugin: NSObject, FlutterPlugin {
    private static var streamHandler: FCPStreamHandlerPlugin?
    private(set) static var registrar: FlutterPluginRegistrar?
    private static var objcRootTemplate: FCPRootTemplate?
    private static var _rootViewController: UIViewController?
    private static var _rootTemplate: CPTemplate?
    public static var animated: Bool = false
    private var objcPresentTemplate: FCPPresentTemplate?

    private static var fcpTemplateHistory = [FCPTemplate]()

    public static var rootTemplate: CPTemplate? {
        get {
            return _rootTemplate
        }
        set(template) {
            _rootTemplate = template
        }
    }

    public static var rootViewController: UIViewController? {
        get {
            return _rootViewController
        }
        set(viewController) {
            _rootViewController = viewController
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: makeFCPChannelId(event: ""),
                                           binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterCarplayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        self.registrar = registrar

        streamHandler = FCPStreamHandlerPlugin(registrar: registrar)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        MemoryLogger.shared.appendEvent("FlutterMethodCall received : \(call.method)")
        switch call.method {
        case FCPChannelTypes.setRootTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            var rootTemplate: FCPRootTemplate?
            switch args["runtimeType"] as! String {
            case String(describing: FCPTabBarTemplate.self):
                rootTemplate = FCPTabBarTemplate(obj: args["rootTemplate"] as! [String: Any])
                if (rootTemplate as! FCPTabBarTemplate).getTemplates().count > 5 {
                    result(FlutterError(code: "ERROR",
                                        message: "CarPlay cannot have more than 5 templates on one screen.",
                                        details: nil))
                    return
                }
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPTabBarTemplate).get
            case String(describing: FCPGridTemplate.self):
                rootTemplate = FCPGridTemplate(obj: args["rootTemplate"] as! [String: Any])
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPGridTemplate).get
            case String(describing: FCPInformationTemplate.self):
                rootTemplate = FCPInformationTemplate(obj: args["rootTemplate"] as! [String: Any])
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPInformationTemplate).get
            case String(describing: FCPPointOfInterestTemplate.self):
                rootTemplate = FCPPointOfInterestTemplate(obj: args["rootTemplate"] as! [String: Any])
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPPointOfInterestTemplate).get
            case String(describing: FCPMapTemplate.self):
                rootTemplate = FCPMapTemplate(obj: args["rootTemplate"] as! [String: Any])
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPMapTemplate).get
                SwiftFlutterCarplayPlugin.rootViewController = (rootTemplate as! FCPMapTemplate).viewController
                FlutterCarPlaySceneDelegate.carWindow?.rootViewController = SwiftFlutterCarplayPlugin.rootViewController
            case String(describing: FCPListTemplate.self):
                rootTemplate = FCPListTemplate(obj: args["rootTemplate"] as! [String: Any], templateType: FCPListTemplateTypes.DEFAULT)
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPListTemplate).get
            default:
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(SwiftFlutterCarplayPlugin.rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
            SwiftFlutterCarplayPlugin.objcRootTemplate = rootTemplate
            SwiftFlutterCarplayPlugin.fcpTemplateHistory = [rootTemplate as! FCPTemplate]
            let animated = args["animated"] as! Bool
            SwiftFlutterCarplayPlugin.animated = animated
            result(true)
        case FCPChannelTypes.forceUpdateRootTemplate:
            FlutterCarPlaySceneDelegate.forceUpdateRootTemplate(completion: { completed, _ in
                result(completed)
            })
        case FCPChannelTypes.updateListTemplate:
            guard let args = call.arguments as? [String: Any]
            else {
                result(false)
                return
            }
            let elementId = args["_elementId"] as! String
            let emptyViewTitleVariants = args["emptyViewTitleVariants"] as? [String]
            let emptyViewSubtitleVariants = args["emptyViewSubtitleVariants"] as? [String]
            let sections = (args["sections"] as? [[String: Any]])?.map {
                FCPListSection(obj: $0)
            }
            let leadingNavigationBarButtons = (args["leadingNavigationBarButtons"] as? [[String: Any]])?.map {
                FCPBarButton(obj: $0)
            }
            let trailingNavigationBarButtons = (args["trailingNavigationBarButtons"] as? [[String: Any]])?.map {
                FCPBarButton(obj: $0)
            }
            SwiftFlutterCarplayPlugin.findListTemplate(elementId: elementId, actionWhenFound: { listTemplate in
                listTemplate.update(emptyViewTitleVariants: emptyViewTitleVariants, emptyViewSubtitleVariants: emptyViewSubtitleVariants, sections: sections, leadingNavigationBarButtons: leadingNavigationBarButtons, trailingNavigationBarButtons: trailingNavigationBarButtons)
            })
            result(true)
        case FCPChannelTypes.updateListItem:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            let elementId = args["_elementId"] as! String
            let text = args["text"] as? String
            let detailText = args["detailText"] as? String
            let image = args["image"] as? String
            let playbackProgress = args["playbackProgress"] as? CGFloat
            let isPlaying = args["isPlaying"] as? Bool
            let isEnabled = args["isEnabled"] as? Bool
            let playingIndicatorLocation = args["playingIndicatorLocation"] as? String
            let accessoryType = args["accessoryType"] as? String
            let accessoryImage = args["accessoryImage"] as? String
            SwiftFlutterCarplayPlugin.findItem(elementId: elementId, actionWhenFound: { item in
                item.update(text: text, detailText: detailText, image: image, accessoryImage: accessoryImage, playbackProgress: playbackProgress, isPlaying: isPlaying, playingIndicatorLocation: playingIndicatorLocation, accessoryType: accessoryType, isEnabled: isEnabled)
            })
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
        case FCPChannelTypes.setAlert:
            guard objcPresentTemplate == nil else {
                result(FlutterError(code: "ERROR",
                                    message: "CarPlay can only present one modal template at a time.",
                                    details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            let alertTemplate = FCPAlertTemplate(obj: args["rootTemplate"] as! [String: Any])
            objcPresentTemplate = alertTemplate
            let animated = args["animated"] as! Bool
            FlutterCarPlaySceneDelegate
                .presentTemplate(template: alertTemplate.get, animated: animated, completion: { completed, _ in
                    if completed {
                        SwiftFlutterCarplayPlugin.fcpTemplateHistory.append(alertTemplate)
                    }
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
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            let actionSheetTemplate = FCPActionSheetTemplate(obj: args["rootTemplate"] as! [String: Any])
            objcPresentTemplate = actionSheetTemplate
            let animated = args["animated"] as! Bool
            FlutterCarPlaySceneDelegate.presentTemplate(template: actionSheetTemplate.get, animated: animated, completion: { completed, _ in
                if completed {
                    SwiftFlutterCarplayPlugin.fcpTemplateHistory.append(actionSheetTemplate)
                }
                result(completed)
            })
        case FCPChannelTypes.popTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            for _ in 1 ... (args["count"] as! Int) {
                FlutterCarPlaySceneDelegate.pop(animated: args["animated"] as! Bool, completion: { completed, _ in
                    if completed {
                        SwiftFlutterCarplayPlugin.fcpTemplateHistory.removeLast()
                    }
                })
            }
            result(true)
        case FCPChannelTypes.closePresent:
            guard let animated = call.arguments as? Bool else {
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.closePresent(animated: animated, completion: { completed, _ in
                if completed {
                    SwiftFlutterCarplayPlugin.fcpTemplateHistory.removeLast()
                }
                result(completed)
            })
            objcPresentTemplate = nil
        case FCPChannelTypes.pushTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            var pushTemplate: CPTemplate?
            var fcpPushTemplate: FCPTemplate?
            let animated = args["animated"] as! Bool
            switch args["runtimeType"] as! String {
            case String(describing: FCPGridTemplate.self):
                fcpPushTemplate = FCPGridTemplate(obj: args["template"] as! [String: Any])
                pushTemplate = (fcpPushTemplate as! FCPGridTemplate).get
            case String(describing: FCPPointOfInterestTemplate.self):
                fcpPushTemplate = FCPPointOfInterestTemplate(obj: args["template"] as! [String: Any])
                pushTemplate = (fcpPushTemplate as! FCPPointOfInterestTemplate).get
            case String(describing: FCPMapTemplate.self):
                fcpPushTemplate = FCPMapTemplate(obj: args["template"] as! [String: Any])
                pushTemplate = (fcpPushTemplate as! FCPMapTemplate).get
            case String(describing: FCPInformationTemplate.self):
                fcpPushTemplate = FCPInformationTemplate(obj: args["template"] as! [String: Any])
                pushTemplate = (fcpPushTemplate as! FCPInformationTemplate).get
            case String(describing: FCPListTemplate.self):
                fcpPushTemplate = FCPListTemplate(obj: args["template"] as! [String: Any], templateType:
                    FCPListTemplateTypes.DEFAULT)
                pushTemplate = (fcpPushTemplate as! FCPListTemplate).get
            default:
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.push(template: pushTemplate!, animated: animated, completion: { completed, _ in
                if completed {
                    SwiftFlutterCarplayPlugin.fcpTemplateHistory.append(fcpPushTemplate!)
                }
                result(completed)
            })
        case FCPChannelTypes.popToRootTemplate:
            guard let animated = call.arguments as? Bool else {
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.popToRootTemplate(animated: animated, completion: { completed, _ in
                if completed {
                    SwiftFlutterCarplayPlugin.fcpTemplateHistory = [SwiftFlutterCarplayPlugin.fcpTemplateHistory.first!]
                }
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
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            let voiceControlTemplate = FCPVoiceControlTemplate(obj: args["rootTemplate"] as! [String: Any])
            objcPresentTemplate = voiceControlTemplate
            let animated = args["animated"] as! Bool
            FlutterCarPlaySceneDelegate.presentTemplate(template: voiceControlTemplate.get, animated: animated, completion: { completed, _ in
                if completed {
                    SwiftFlutterCarplayPlugin.fcpTemplateHistory.append(voiceControlTemplate)
                }
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
            let voiceControlTemplate = objcPresentTemplate as! FCPVoiceControlTemplate
            voiceControlTemplate.activateVoiceControlState(identifier: args)
            result(true)
        case FCPChannelTypes.getActiveVoiceControlStateIdentifier:
            guard objcPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To get the active voice control state identifier, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            let voiceControlTemplate = objcPresentTemplate as! FCPVoiceControlTemplate
            let identifier = voiceControlTemplate.getActiveVoiceControlStateIdentifier()
            result(identifier)
        case FCPChannelTypes.startVoiceControl:
            guard objcPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To start the voice control, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            let voiceControlTemplate = objcPresentTemplate as! FCPVoiceControlTemplate
            voiceControlTemplate.start()
            result(true)
        case FCPChannelTypes.stopVoiceControl:
            guard objcPresentTemplate != nil else {
                result(FlutterError(code: "ERROR",
                                    message: "To stop the voice control, a voice control template must be presented to CarPlay Screen at first.",
                                    details: nil))
                return
            }
            let voiceControlTemplate = objcPresentTemplate as! FCPVoiceControlTemplate
            voiceControlTemplate.stop()
            result(true)
        case FCPChannelTypes.speak:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            FCPSpeaker.shared.speak(args["text"] as! String, language: args["language"] as! String) {
                if (args["onCompleted"] as! Bool) == true {
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSpeechCompleted,
                                                     data: ["elementId": args["_elementId"] as! String])
                }
            }
            result(true)
        case FCPChannelTypes.playAudio:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            FCPSoundEffects.shared.prepare(sound: args["soundPath"] as! String, volume: (args["volume"] as! NSNumber).floatValue)
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

    static func createEventChannel(event: String?) -> FlutterEventChannel {
        let eventChannel = FlutterEventChannel(name: makeFCPChannelId(event: event),
                                               binaryMessenger: SwiftFlutterCarplayPlugin.registrar!.messenger())
        return eventChannel
    }

    static func onCarplayConnectionChange(status: String) {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onCarplayConnectionChange,
                                         data: ["status": status])
    }

    static func sendSpeechRecognitionTranscriptChangeEvent(transcript: String) {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onVoiceControlTranscriptChanged,
                                         data: ["transcript": transcript])
    }

    static func findListTemplate(elementId: String, actionWhenFound: (_ listTemplate: FCPListTemplate) -> Void) {
        let objcRootTemplateType = String(describing: SwiftFlutterCarplayPlugin.objcRootTemplate).match(#"(.*flutter_carplay\.(.*)\))"#)[0][2]
        var templates: [FCPListTemplate] = []
        let filteredTemplates = SwiftFlutterCarplayPlugin.fcpTemplateHistory.filter { $0 is FCPListTemplate }

        if !filteredTemplates.isEmpty {
            templates = filteredTemplates.map { $0 as! FCPListTemplate }
        }
        if objcRootTemplateType.elementsEqual(String(describing: FCPListTemplate.self)) {
            templates.append(SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPListTemplate)
        } else if objcRootTemplateType.elementsEqual(String(describing: FCPTabBarTemplate.self)) {
            templates.append(contentsOf: (SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPTabBarTemplate).getTemplates())
        } else if templates.isEmpty {
            return
        }
        l1: for template in templates where template.elementId == elementId {
            actionWhenFound(template)
            break l1
        }
    }

    static func findItem(elementId: String, actionWhenFound: (_ item: FCPListItem) -> Void) {
        let objcRootTemplateType = String(describing: SwiftFlutterCarplayPlugin.objcRootTemplate).match(#"(.*flutter_carplay\.(.*)\))"#)[0][2]
        var templates: [FCPListTemplate] = []
        let filteredTemplates = SwiftFlutterCarplayPlugin.fcpTemplateHistory.filter { $0 is FCPListTemplate }

        if !filteredTemplates.isEmpty {
            templates = filteredTemplates.map { $0 as! FCPListTemplate }
        }
        if objcRootTemplateType.elementsEqual(String(describing: FCPListTemplate.self)) {
            templates.append(SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPListTemplate)
        } else if objcRootTemplateType.elementsEqual(String(describing: FCPTabBarTemplate.self)) {
            templates.append(contentsOf: (SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPTabBarTemplate).getTemplates())
        } else if templates.isEmpty {
            return
        }
        l1: for template in templates {
            for section in template.getSections() {
                for item in section.getItems() where item.elementId == elementId {
                    actionWhenFound(item)
                    break l1
                }
            }
        }
    }
}
