//
//  FlutterCarplayPluginSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// Scene delegate for managing interactions between Flutter and CarPlay.
@available(iOS 14.0, *)
class FlutterCarPlaySceneDelegate: UIResponder {
    /// Static properties to store the CPInterfaceController and CPWindow instances.
    static var interfaceController: CPInterfaceController?
    static var carWindow: CPWindow?

    /// Fired when the CarPlay scene becomes active.
    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did become active.")
        }
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    }

    /// Fired when the CarPlay scene enters the background.
    func sceneDidEnterBackground(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did enter background.")
        }
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.background)
    }
}

// MARK: - CPTemplateApplicationSceneDelegate

extension FlutterCarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    /// Called when the template application scene connects to an interface controller and window.
    func templateApplicationScene(_: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")

        FlutterCarPlaySceneDelegate.carWindow = window
        FlutterCarPlaySceneDelegate.interfaceController = interfaceController
        FlutterCarPlaySceneDelegate.interfaceController?.delegate = self

        if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController {
            window.rootViewController = rootViewController
        }

        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)

        if let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate {
            FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
        }
    }

    /// Called when the template application scene disconnects from an interface controller and window.
    func templateApplicationScene(_: CPTemplateApplicationScene, didDisconnect _: CPInterfaceController, from _: CPWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay.")
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
        // FlutterCarPlaySceneDelegate.interfaceController = nil
    }
}

// MARK: - CPInterfaceControllerDelegate

/// Extension conforming to CPInterfaceControllerDelegate for handling template appearance and disappearance events.
extension FlutterCarPlaySceneDelegate: CPInterfaceControllerDelegate {
    func templateWillAppear(_: CPTemplate, animated _: Bool) {
        // MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) will appear.")
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated _: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) did appear.")
    }

    func templateWillDisappear(_: CPTemplate, animated _: Bool) {
        // MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) will disappear.")
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated _: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) did disappear.")

        // Handle the cancel button event on search template
        if let topTemplate = FlutterCarPlaySceneDelegate.interfaceController?.topTemplate {
            if aTemplate is CPSearchTemplate && !(topTemplate is CPSearchTemplate) {
                if let elementId = (((aTemplate as? CPSearchTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPSearchTemplate)?.elementId {
                    DispatchQueue.main.async {
                        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSearchCancelled,
                                                         data: ["elementId": elementId])
                    }
                }
            }
        }
    }
}

// MARK: - Public Funcitons

extension FlutterCarPlaySceneDelegate {
    /// Forces an update of the root template.
    /// - Parameter completion: A closure to be executed upon completion of the update.
    public static func forceUpdateRootTemplate(completion: ((Bool, Error?) -> Void)? = nil) {
        if let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate {
            let animated = SwiftFlutterCarplayPlugin.animated
            interfaceController?.setRootTemplate(rootTemplate, animated: animated, completion: completion)
        } else {
            completion?(false, nil)
        }
    }

    /// Pops the current template from the navigation hierarchy.
    public static func pop(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Pop Template.")
        interfaceController?.popTemplate(animated: animated, completion: completion)
    }

    /// Pops to the root template in the navigation hierarchy.
    public static func popToRootTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Pop to Root Template.")
        interfaceController?.popToRootTemplate(animated: animated, completion: completion)
    }

    /// Pushes a new template onto the navigation hierarchy.
    /// - Parameters:
    ///   - template: The template to push onto the navigation hierarchy.
    ///   - animated: A Boolean value that indicates whether the transition should be animated.
    ///   - completion: A closure to be executed upon completion of the push operation.
    public static func push(template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        guard (interfaceController?.templates.count ?? 0) <= 4 else {
            MemoryLogger.shared.appendEvent("Template navigation hierarchy exceeded")
            let error = NSError(domain: "FlutterCarplay", code: 0, userInfo: ["LocalizedDescriptionKey": "CarPlay cannot have more than 5 templates on navigation hierarchy."])
            completion?(false, error)
            return
        }
        MemoryLogger.shared.appendEvent("Push to \(template).")
        interfaceController?.pushTemplate(template, animated: animated, completion: completion)
    }

    /// Closes the currently presented template.
    public static func closePresent(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Close the presented template")
        interfaceController?.dismissTemplate(animated: animated, completion: completion)
    }

    /// Presents a new template.
    /// - Parameters:
    ///   - template: The template to present.
    ///   - animated: A Boolean value that indicates whether the presentation should be animated.
    ///   - completion: A closure to be executed upon completion of the presentation.
    public static func presentTemplate(template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Present \(template)")
        interfaceController?.presentTemplate(template, animated: animated, completion: completion)
    }
}
