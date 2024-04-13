//
// FlutterCarplayTemplateManager.swift
// flutter_carplay
//
// Created by Pradip Sutariya on 09/04/24.
//

import CarPlay
import Foundation

/// FlutterCarPlayTemplateManager handles CarPlay scene and the Dashboard scene
class FlutterCarplayTemplateManager: NSObject, CPInterfaceControllerDelegate, CPSessionConfigurationDelegate {
    static let shared = FlutterCarplayTemplateManager()

    // MARK: - Properties

    var carWindow: CPWindow?
    var dashboardWindow: UIWindow?

    var carplayInterfaceController: CPInterfaceController?
    var carplayDashboardController: CPDashboardController?

    // CarPlay connection status (either CarPlay or Dashboard)
    var fcpConnectionStatus = FCPConnectionTypes.disconnected {
        didSet {
            SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: fcpConnectionStatus)
        }
    }

    // CarPlay Dashboard connection status
    var dashboardConnectionStatus = FCPConnectionTypes.disconnected

    // CarPlay scene connection status
    var carplayConnectionStatus = FCPConnectionTypes.disconnected

    // CarPlay session configuration
    var sessionConfiguration: CPSessionConfiguration!

    // Whether the dashboard scene is active
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

            // Set the root view controller for CarPlay
            if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController as? FCPMapViewController {
                // Remove the dashboard window's root view controller if CarPlay scene is active
                dashboardWindow?.rootViewController = nil

                // Set the root view controller for CarPlay
                carWindow?.rootViewController = rootViewController

                // Update UI when CarPlay scene is active
                rootViewController.showSubviews()
            }

            // Update the root template
            FlutterCarplaySceneDelegate.forceUpdateRootTemplate()

        } else if activeScene is CPTemplateApplicationDashboardScene {
            isDashboardSceneActive = true

            // Set the root view controller for Dashboard
            if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController as? FCPMapViewController {
                // Remove the carplay window's root view controller if Dashboard scene is active
                carWindow?.rootViewController = nil

                // Set the root view controller for Dashboard
                dashboardWindow?.rootViewController = rootViewController

                if let dashboardButtons = (SwiftFlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.dashboardButtons {
                    carplayDashboardController?.shortcutButtons = dashboardButtons.map { $0.get }
                }

                // Update UI when Dashboard scene is active
                rootViewController.hideSubviews()
            }
        }
    }

    // MARK: CPTemplateApplicationDashboardSceneDelegate

    /// Called when the dashboard scene becomes active.
    /// - Parameters:
    ///   - dashboardController: Dashboard controller
    ///   - window: CarPlay window
    func dashboardController(_ dashboardController: CPDashboardController, didConnectWith window: UIWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay dashboard window.")

        // Set the root view controller for Dashboard if the dashboard scene is active
        if let rootViewController = SwiftFlutterCarplayPlugin.rootViewController, isDashboardSceneActive {
            // Remove the carWindow root view controller if the dashboard scene is active
            carWindow?.rootViewController = nil
            window.rootViewController = rootViewController
        }

        if let dashboardButtons = (SwiftFlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.dashboardButtons {
            dashboardController.shortcutButtons = dashboardButtons.map { $0.get }
        }

        // save dashboard controller
        carplayDashboardController = dashboardController

        // save dashboard window
        FlutterCarplayTemplateManager.shared.dashboardWindow = window
    }

    /// Dashboard scene did disconnect
    /// - Parameters:
    ///   - dashboardController: Dashboard controller
    ///   - window: Dashboard window
    func dashboardController(_: CPDashboardController, didDisconnectWith _: UIWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay dashboard window.")
        dashboardConnectionStatus = FCPConnectionTypes.disconnected
        carplayDashboardController = nil
        dashboardWindow?.rootViewController = nil
    }

    /// - Tag: did_connect

    // MARK: CPTemplateApplicationSceneDelegate

    /// Called when the scene becomes active.
    /// - Parameters:
    ///   - interfaceController: Interface controller
    ///   - window: CarPlay window
    func interfaceController(_ interfaceController: CPInterfaceController, didConnectWith window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")
        // save the carplay window
        carWindow = window
        carWindow?.isUserInteractionEnabled = true
        carWindow?.isMultipleTouchEnabled = true

        // save interface controller
        carplayInterfaceController = interfaceController
        carplayInterfaceController?.delegate = self

        // Set the root view controller for CarPlay if the scene is active
        if let rootViewController = (SwiftFlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.viewController {
            SwiftFlutterCarplayPlugin.rootViewController = rootViewController
            // Remove the dashboard window's root view controller if the scene is active
            dashboardWindow?.rootViewController = nil
            window.rootViewController = rootViewController
        }

        // Update the root template
        if let rootTemplate = (SwiftFlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.get {
            SwiftFlutterCarplayPlugin.rootTemplate = rootTemplate
            carplayInterfaceController?.setRootTemplate(rootTemplate, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
        }
    }

    /// CarPlay scene did disconnect
    /// - Parameters:
    ///   - interfaceController: Interface controller
    ///   - window: CarPlay window
    func interfaceController(_: CPInterfaceController, didDisconnectWith _: CPWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay window.")

        if let mapTemplate = SwiftFlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate {
            mapTemplate.stopNavigation()
        }
        carplayInterfaceController = nil
        carWindow?.rootViewController = nil
    }
}
