//
//  FlutterCarplayPluginSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FlutterCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private static var interfaceController: CPInterfaceController?
    private static var carWindow: CPWindow?

    public static func forceUpdateRootTemplate() {
        let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
        let animated = SwiftFlutterCarplayPlugin.animated

        interfaceController?.setRootTemplate(rootTemplate!, animated: animated, completion: nil)
    }

    // Fired when just before the carplay become active
    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did become active.")
        }
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    }

    // Fired when carplay entered background
    func sceneDidEnterBackground(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did enter background.")
        }
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.background)
    }

    public static func pop(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Pop Template.")
        interfaceController?.popTemplate(animated: animated, completion: completion)
    }

    public static func popToRootTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Pop to Root Template.")
        interfaceController?.popToRootTemplate(animated: animated, completion: completion)
    }

    public static func push(template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        guard (interfaceController?.templates.count ?? 0) <= 4 else {
            MemoryLogger.shared.appendEvent("Template navigation hierarchy exceeded")
            let error = NSError(domain: "FlutterCarplay", code: 0, userInfo: ["LocalizedDescriptionKey": "CarPlay cannot have more than 5 templates on navigation hierarchy."])
            completion?(false, error as? Error)
            return
        }
        MemoryLogger.shared.appendEvent("Push to \(template).")
        interfaceController?.pushTemplate(template, animated: animated, completion: completion)
    }

    public static func closePresent(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Close the presented template")
        interfaceController?.dismissTemplate(animated: animated, completion: completion)
    }

    public static func presentTemplate(template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Present \(template)")
        interfaceController?.presentTemplate(template, animated: animated, completion: completion)
    }

    func templateApplicationScene(_: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            FlutterCarPlaySceneDelegate.interfaceController = interfaceController

            if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController {
                window.rootViewController = rootViewController
                FlutterCarPlaySceneDelegate.carWindow = window
            }

            SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
            let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate

            guard rootTemplate != nil else {
                // FlutterCarPlaySceneDelegate.interfaceController = nil
                return
            }

            FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
        }
    }

    func templateApplicationScene(_: CPTemplateApplicationScene, didDisconnect _: CPInterfaceController, from _: CPWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay.")
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
        // FlutterCarPlaySceneDelegate.interfaceController = nil
    }

    func templateApplicationScene(_: CPTemplateApplicationScene, didDisconnectInterfaceController _: CPInterfaceController) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay.")
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
        // FlutterCarPlaySceneDelegate.interfaceController = nil
    }
}
