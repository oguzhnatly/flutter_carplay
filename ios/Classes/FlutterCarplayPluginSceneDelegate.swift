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

    public static func forceUpdateRootTemplate(completion: ((Bool, (any Error)?) -> Void)? = nil) {
        let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
        let animated = SwiftFlutterCarplayPlugin.animated

        interfaceController?.setRootTemplate(rootTemplate!, animated: animated, completion: completion)
    }

    // Fired when just before the carplay become active
    func sceneDidBecomeActive(_: UIScene) {
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    }

    // Fired when carplay entered background
    func sceneDidEnterBackground(_: UIScene) {
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.background)
    }

    public static func pop(animated: Bool, completion: ((Bool, (any Error)?) -> Void)? = nil) {
        interfaceController?.popTemplate(animated: animated, completion: completion)
    }

    public static func popToRootTemplate(animated: Bool, completion: ((Bool, (any Error)?) -> Void)? = nil) {
        interfaceController?.popToRootTemplate(animated: animated, completion: completion)
    }

    public static func push(template: CPTemplate, animated: Bool, completion: ((Bool, (any Error)?) -> Void)? = nil) {
        interfaceController?.pushTemplate(template, animated: animated, completion: completion)
    }

    public static func closePresent(animated: Bool, completion: ((Bool, (any Error)?) -> Void)? = nil) {
        interfaceController?.dismissTemplate(animated: animated, completion: completion)
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
    
   public static func getTemplates() -> [CPTemplate] {
       return interfaceController?.templates ?? []
    }

    func templateApplicationScene(_: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController)
    {
        FlutterCarPlaySceneDelegate.interfaceController = interfaceController
        FlutterCarPlaySceneDelegate.interfaceController?.delegate = self

        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
        let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate

        guard rootTemplate != nil else {
            FlutterCarPlaySceneDelegate.interfaceController = nil
            return
        }

        FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
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

// MARK: CPInterfaceControllerDelegate
extension FlutterCarPlaySceneDelegate: CPInterfaceControllerDelegate {
    func templateWillAppear(_ aTemplate: CPTemplate, animated _: Bool) {
        print("Template \(aTemplate.classForCoder) will appear.")
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated _: Bool) {
        print("Template \(aTemplate.classForCoder) did appear.")
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated _: Bool) {
        print("Template \(aTemplate.classForCoder) will disappear.")
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated _: Bool) {
        print("Template \(aTemplate.classForCoder) did disappear.")

        if let topTemplate = FlutterCarPlaySceneDelegate.interfaceController?.topTemplate {
            // Handle the cancel button event on search template
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
