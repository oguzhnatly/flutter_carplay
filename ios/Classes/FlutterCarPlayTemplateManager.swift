//
// FlutterCarPlayTemplateManager.swift
// flutter_carplay
//
// Created by Pradip Sutariya on 09/04/24.
//

import CarPlay
import Foundation

class FlutterCarPlayTemplateManager: NSObject, CPInterfaceControllerDelegate, CPSessionConfigurationDelegate {
    static let shared = FlutterCarPlayTemplateManager()

    var carWindow: UIWindow?
    var dashboardWindow: UIWindow?

    var carplayInterfaceController: CPInterfaceController?
    var carplayDashboardController: CPDashboardController?

    var fcpConnectionStatus = FCPConnectionTypes.disconnected {
        didSet {
            SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: fcpConnectionStatus)
        }
    }

    var sessionConfiguration: CPSessionConfiguration!

    var dashboardMapViewOffset: CGPoint?
    var currentZoomScale: CGFloat?

    var isDashboardSceneActive = false

    override init() {
        super.init()
        sessionConfiguration = CPSessionConfiguration(delegate: self)
    }

    // MARK: CPInterfaceControllerDelegate

    func templateWillAppear(_ aTemplate: CPTemplate, animated _: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) will appear.")
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated _: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) did appear.")
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated _: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) will disappear.")
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated _: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) did disappear.")

        // Handle the cancel button event on search template
        if let topTemplate = carplayInterfaceController?.topTemplate {
            if aTemplate is CPSearchTemplate && !(topTemplate is CPSearchTemplate) {
                if let elementId = (((aTemplate as? CPSearchTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPSearchTemplate)?.elementId {
                    DispatchQueue.main.async {
                        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSearchCancelled,
                                                         data: ["elementId": elementId])
                    }
                }
            } else if aTemplate is CPInformationTemplate, !(topTemplate is CPInformationTemplate) {
                if let elementId = (((aTemplate as? CPInformationTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPInformationTemplate)?.elementId {
                    DispatchQueue.main.async {
                        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onInformationTemplatePopped,
                                                         data: ["elementId": elementId])
                    }
                }
            } else if aTemplate is CPVoiceControlTemplate, !(topTemplate is CPVoiceControlTemplate) {
                if let elementId = (((aTemplate as? CPVoiceControlTemplate)?.userInfo as? [String: Any])?["FCPObject"] as? FCPVoiceControlTemplate)?.elementId {
                    DispatchQueue.main.async {
                        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onVoiceControlTemplatePopped,
                                                         data: ["elementId": elementId])
                    }
                }
            }
        }
    }

    // MARK: CPSessionConfigurationDelegate

    func sessionConfiguration(_: CPSessionConfiguration,
                              limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface)
    {
        MemoryLogger.shared.appendEvent("Limited UI changed: \(limitedUserInterfaces)")
    }

    // MARK: Response to UISceneDelegate

    // Determine which map view controller's view is actively showing.
    func setActiveMapViewController(with activeScene: UIScene) {
        MemoryLogger.shared.appendEvent("Set Active MapViewController to \(activeScene.session.configuration.name ?? "")")

        if activeScene is CPTemplateApplicationScene {
            isDashboardSceneActive = false

            if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController as? FCPMapViewController {
                dashboardWindow?.rootViewController = nil
                carWindow?.rootViewController = rootViewController
                rootViewController.showSubviews()
            }
            FlutterCarPlaySceneDelegate.forceUpdateRootTemplate()

        } else if activeScene is CPTemplateApplicationDashboardScene {
            isDashboardSceneActive = true
            if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController as? FCPMapViewController {
                carWindow?.rootViewController = nil
                dashboardWindow?.rootViewController = rootViewController
                rootViewController.hideSubviews()
            }
        }
    }

    // MARK: CPTemplateApplicationDashboardSceneDelegate

    func dashboardController(_ dashboardController: CPDashboardController, didConnectWith window: UIWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay dashboard window.")

        carplayDashboardController = dashboardController

        // Or consider the button here is a short cut to my vaforite destination (home, work, shopping)
        let beachesButton = CPDashboardButton(
            titleVariants: ["Beaches"],
            subtitleVariants: ["Beach Trip"],
            image: UIImage()
        ) { _ in
            //                self.beginNavigation(fromDashboard: true)
        }

        let parksButton = CPDashboardButton(
            titleVariants: ["Parks"],
            subtitleVariants: ["Park Trip"],
            image: UIImage()
        ) { _ in
            //                self.beginNavigation(fromDashboard: true)
        }

        if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController {
            carWindow?.rootViewController = nil
            window.rootViewController = rootViewController
        }

        dashboardController.shortcutButtons = [beachesButton, parksButton]

        // save dashboard window
        FlutterCarPlayTemplateManager.shared.dashboardWindow = window
    }

    func dashboardController(_: CPDashboardController, didDisconnectWith _: UIWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay dashboard window.")
        carplayDashboardController = nil
        dashboardWindow?.rootViewController = nil
    }

    /// - Tag: did_connect

    // MARK: CPTemplateApplicationSceneDelegate

    func interfaceController(_ interfaceController: CPInterfaceController, didConnectWith window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")
        carWindow = window
        carWindow?.isUserInteractionEnabled = true
        carWindow?.isMultipleTouchEnabled = true
        carplayInterfaceController = interfaceController
        carplayInterfaceController?.delegate = self
        if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController {
            dashboardWindow?.rootViewController = nil
            window.rootViewController = rootViewController
        }

        fcpConnectionStatus = FCPConnectionTypes.connected

        if let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate {
            carplayInterfaceController?.setRootTemplate(rootTemplate, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
        }
    }

    func interfaceController(_: CPInterfaceController, didDisconnectWith _: CPWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay window.")

        if let mapTemplate = SwiftFlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate {
            mapTemplate.stopNavigation()
        }
        fcpConnectionStatus = FCPConnectionTypes.disconnected
        carplayInterfaceController = nil
        carWindow?.rootViewController = nil
    }
}
