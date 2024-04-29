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
    private static var _rootTemplate: CPTemplate?
    public static var animated: Bool = false
    private var objcPresentTemplate: FCPPresentTemplate?

    public static var rootTemplate: CPTemplate? {
        get {
            return _rootTemplate
        }
        set(tabBarTemplate) {
            _rootTemplate = tabBarTemplate
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
            case String(describing: FCPListTemplate.self):
                rootTemplate = FCPListTemplate(obj: args["rootTemplate"] as! [String: Any], templateType: FCPListTemplateTypes.DEFAULT)
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPListTemplate).get
            default:
                result(false)
                return
            }
            SwiftFlutterCarplayPlugin.objcRootTemplate = rootTemplate
            let animated = args["animated"] as! Bool
            SwiftFlutterCarplayPlugin.animated = animated
            result(true)
        case FCPChannelTypes.forceUpdateRootTemplate:
            FlutterCarPlaySceneDelegate.forceUpdateRootTemplate()
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
            let playingIndicatorLocation = args["playingIndicatorLocation"] as? String
            let accessoryType = args["accessoryType"] as? String
            SwiftFlutterCarplayPlugin.findItem(elementId: elementId, actionWhenFound: { item in
                item.update(text: text, detailText: detailText, image: image, playbackProgress: playbackProgress, isPlaying: isPlaying, playingIndicatorLocation: playingIndicatorLocation, accessoryType: accessoryType)
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
                template.searchCompleted(searchResults)
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
                .presentTemplate(template: alertTemplate.get, animated: animated, onPresent: { completed in
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                                     data: ["completed": completed])
                })
            result(true)
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
            FlutterCarPlaySceneDelegate.presentTemplate(template: actionSheetTemplate.get, animated: animated, onPresent: { _ in })
            result(true)
        case FCPChannelTypes.popTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            for _ in 1 ... (args["count"] as! Int) {
                FlutterCarPlaySceneDelegate.pop(animated: args["animated"] as! Bool)
            }
            result(true)
        case FCPChannelTypes.closePresent:
            guard let animated = call.arguments as? Bool else {
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.closePresent(animated: animated)
            objcPresentTemplate = nil
            result(true)
        case FCPChannelTypes.pushTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            var pushTemplate: CPTemplate?
            let animated = args["animated"] as! Bool
            switch args["runtimeType"] as! String {
            case String(describing: FCPGridTemplate.self):
                pushTemplate = FCPGridTemplate(obj: args["template"] as! [String: Any]).get
            case String(describing: FCPPointOfInterestTemplate.self):
                pushTemplate = FCPPointOfInterestTemplate(obj: args["template"] as! [String: Any]).get
            case String(describing: FCPInformationTemplate.self):
                pushTemplate = FCPInformationTemplate(obj: args["template"] as! [String: Any]).get

            case String(describing: FCPListTemplate.self):
                pushTemplate = FCPListTemplate(obj: args["template"] as! [String: Any], templateType: FCPListTemplateTypes.DEFAULT).get

            case String(describing: FCPSearchTemplate.self):
                pushTemplate = FCPSearchTemplate(obj: args["template"] as! [String: Any]).get
            default:
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.push(template: pushTemplate!, animated: animated)
            result(true)
        case FCPChannelTypes.popToRootTemplate:
            guard let animated = call.arguments as? Bool else {
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.popToRootTemplate(animated: animated)
            objcPresentTemplate = nil
            result(true)
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

    static func findItem(elementId: String, actionWhenFound: (_ item: FCPListItem) -> Void) {
        let objcRootTemplateType = String(describing: SwiftFlutterCarplayPlugin.objcRootTemplate).match(#"(.*flutter_carplay\.(.*)\))"#)[0][2]
        var templates: [FCPListTemplate] = []
        if objcRootTemplateType.elementsEqual(String(describing: FCPListTemplate.self)) {
            templates.append(SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPListTemplate)
        } else if objcRootTemplateType.elementsEqual(String(describing: FCPTabBarTemplate.self)) {
            templates = (SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPTabBarTemplate).getTemplates()
        } else {
            return
        }
        l1: for t in templates {
            for s in t.getSections() {
                for i in s.getItems() {
                    if i.elementId == elementId {
                        actionWhenFound(i)
                        break l1
                    }
                }
            }
        }
    }

    static func findSearchTemplate(elementId: String, actionWhenFound: (_ searchTemplate: FCPSearchTemplate) -> Void) {
        let filteredTemplates = FlutterCarPlaySceneDelegate.getTemplates().filter { $0 is CPSearchTemplate }

        for t in filteredTemplates {
            if let userInfo = t.userInfo as? [String: Any],
               let fcpTemplate = userInfo["FCPObject"] as? FCPSearchTemplate,
               fcpTemplate.elementId == elementId
            {
                actionWhenFound(fcpTemplate)
                break
            }
        }
    }
}
