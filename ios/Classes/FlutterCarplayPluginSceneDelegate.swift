//
//  FlutterCarplayPluginSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import UIKit

class FlutterCarPlaySceneDelegate: NSObject {
    // MARK: UISceneDelegate

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options _: UIScene.ConnectionOptions) {
        if scene is CPTemplateApplicationScene, session.configuration.name == "CarPlayConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton scene will connect.")
            FlutterCarPlayTemplateManager.shared.isDashboardSceneActive = false
        } else if scene is CPTemplateApplicationDashboardScene, session.configuration.name == "CarPlayDashboardConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton dashboard scene will connect.")
            FlutterCarPlayTemplateManager.shared.isDashboardSceneActive = true
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if scene.session.configuration.name == "CarPlayConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton scene did disconnect.")
        } else if scene.session.configuration.name == "CarPlayDashboardConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton dashboard scene did disconnect.")
        }

        FlutterCarPlayTemplateManager.shared.fcpConnectionStatus = FCPConnectionTypes.disconnected
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == "CarPlayConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton scene did become active.")
            FlutterCarPlayTemplateManager.shared.setActiveMapViewController(with: scene)
        } else if scene.session.configuration.name == "CarPlayDashboardConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton dashboard scene did become active.")
            FlutterCarPlayTemplateManager.shared.setActiveMapViewController(with: scene)
        }

        FlutterCarPlayTemplateManager.shared.fcpConnectionStatus = FCPConnectionTypes.connected
    }

    func sceneWillResignActive(_ scene: UIScene) {
        if scene.session.configuration.name == "CarPlayConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton scene will resign active.")
        } else if scene.session.configuration.name == "CarPlayDashboardConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton dashboard scene will resign active.")
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        if scene.session.configuration.name == "CarPlayConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect applicaiton scene did enter background.")
        } else if scene.session.configuration.name == "CarPlayDashboardConfiguration" {
            MemoryLogger.shared.appendEvent("STEMConnect application Dashboard scene did enter background.")
        }
        FlutterCarPlayTemplateManager.shared.fcpConnectionStatus = FCPConnectionTypes.background
    }
}

// MARK: CPTemplateApplicationSceneDelegate

extension FlutterCarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(_: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController, to window: CPWindow)
    {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")
        FlutterCarPlayTemplateManager.shared.interfaceController(interfaceController, didConnectWith: window)
    }

    func templateApplicationScene(_: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController, from window: CPWindow)
    {
        FlutterCarPlayTemplateManager.shared.interfaceController(interfaceController, didDisconnectWith: window)
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay.")
    }
}

extension FlutterCarPlaySceneDelegate: CPTemplateApplicationDashboardSceneDelegate {
    func templateApplicationDashboardScene(
        _: CPTemplateApplicationDashboardScene,
        didConnect dashboardController: CPDashboardController,
        to window: UIWindow
    ) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay dashboard.")
        FlutterCarPlayTemplateManager.shared.dashboardController(dashboardController, didConnectWith: window)
    }

    func templateApplicationDashboardScene(
        _: CPTemplateApplicationDashboardScene,
        didDisconnect dashboardController: CPDashboardController,
        from window: UIWindow
    ) {
        FlutterCarPlayTemplateManager.shared.dashboardController(dashboardController, didDisconnectWith: window)
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay dashboard.")
    }
}

// MARK: - Public Funcitons

extension FlutterCarPlaySceneDelegate {
    /// Forces an update of the root template.
    /// - Parameter completion: A closure to be executed upon completion of the update.
    public static func forceUpdateRootTemplate(completion: ((Bool, Error?) -> Void)? = nil) {
        if let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate {
            let animated = SwiftFlutterCarplayPlugin.animated
            FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.setRootTemplate(rootTemplate, animated: animated, completion: completion)
        } else {
            completion?(false, nil)
        }
    }

    /// Pops the current template from the navigation hierarchy.
    public static func pop(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Pop Template.")
        FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.popTemplate(animated: animated, completion: completion)
    }

    /// Pops to the root template in the navigation hierarchy.
    public static func popToRootTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Pop to Root Template.")
        FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.popToRootTemplate(animated: animated, completion: completion)
    }

    /// Pushes a new template onto the navigation hierarchy.
    /// - Parameters:
    ///   - template: The template to push onto the navigation hierarchy.
    ///   - animated: A Boolean value that indicates whether the transition should be animated.
    ///   - completion: A closure to be executed upon completion of the push operation.
    public static func push(template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        guard (FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.templates.count ?? 0) <= 4 else {
            MemoryLogger.shared.appendEvent("Template navigation hierarchy exceeded")
            let error = NSError(domain: "FlutterCarplay", code: 0, userInfo: ["LocalizedDescriptionKey": "CarPlay cannot have more than 5 templates on navigation hierarchy."])
            completion?(false, error)
            return
        }
        MemoryLogger.shared.appendEvent("Push to \(template).")
        FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.pushTemplate(template, animated: animated, completion: completion)
    }

    /// Closes the currently presented template.
    public static func closePresent(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Close the presented template")
        FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.dismissTemplate(animated: animated, completion: completion)
    }

    /// Presents a new template.
    /// - Parameters:
    ///   - template: The template to present.
    ///   - animated: A Boolean value that indicates whether the presentation should be animated.
    ///   - completion: A closure to be executed upon completion of the presentation.
    public static func presentTemplate(template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        MemoryLogger.shared.appendEvent("Present \(template)")
        FlutterCarPlayTemplateManager.shared.carplayInterfaceController?.presentTemplate(template, animated: animated, completion: completion)
    }
}
