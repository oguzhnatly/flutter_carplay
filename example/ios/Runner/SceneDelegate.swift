//
//  SceneDelegate.swift
//  Runner
//
//  Created by Oğuzhan Atalay on 20.08.2021.
//

import os
import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        Logger.statistics.log("Flutter plugin ran from SceneDelegate")
        let controller = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
        Logger.statistics.log("FlutterViewController assigned")
    }
}
