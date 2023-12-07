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

        interfaceController?.setRootTemplate(rootTemplate!, animated: animated)
    }

    // Fired when just before the carplay become active
    func sceneDidBecomeActive(_: UIScene) {
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    }

    // Fired when carplay entered background
    func sceneDidEnterBackground(_: UIScene) {
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.background)
    }

    public static func pop(animated: Bool) {
        interfaceController?.popTemplate(animated: animated)
    }

    public static func popToRootTemplate(animated: Bool) {
        interfaceController?.popToRootTemplate(animated: animated)
    }

    public static func push(template: CPTemplate, animated: Bool) {
        interfaceController?.pushTemplate(template, animated: animated)
    }

    public static func closePresent(animated: Bool) {
        interfaceController?.dismissTemplate(animated: animated)
    }

    public static func presentTemplate(template: CPTemplate, animated: Bool,
                                       onPresent: @escaping (_ completed: Bool) -> Void)
    {
        interfaceController?.presentTemplate(template, animated: animated, completion: { completed, error in
            guard error != nil else {
                onPresent(false)
                return
            }
            onPresent(completed)
        })
    }

    func templateApplicationScene(_: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController, to window: CPWindow)
    {
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

        FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated)
    }

    func templateApplicationScene(_: CPTemplateApplicationScene,
                                  didDisconnect _: CPInterfaceController, from _: CPWindow)
    {
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)

        // FlutterCarPlaySceneDelegate.interfaceController = nil
    }

    func templateApplicationScene(_: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController _: CPInterfaceController)
    {
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)

        // FlutterCarPlaySceneDelegate.interfaceController = nil
    }
}
