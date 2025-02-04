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
    
    var carplayScene: CPTemplateApplicationScene?
    
    // CarPlay connection status (either CarPlay or Dashboard)
    var fcpConnectionStatus = FCPConnectionTypes.disconnected {
        didSet {
            FlutterCarplayPlugin.onCarplayConnectionChange(status: fcpConnectionStatus)
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
        if let topTemplate = carplayInterfaceController?.topTemplate {
            let elementId = ((aTemplate.userInfo as? [String: Any])?["FCPObject"] as? FCPTemplate)?.elementId
            let topTemplateId = ((topTemplate.userInfo as? [String: Any])?["FCPObject"] as? FCPTemplate)?.elementId
            if(elementId != topTemplateId){
                if aTemplate is CPListTemplate || aTemplate is CPInformationTemplate || aTemplate is CPGridTemplate  || aTemplate is CPSearchTemplate || aTemplate is CPTabBarTemplate || aTemplate is CPPointOfInterestTemplate{
                    
                    if(elementId != nil){
                        DispatchQueue.main.async {
                            FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onActiveTemplateChanged,
                                                             data: ["elementId": elementId!])
                    }
                    }
                }
            }
           
        }
        
        if aTemplate is CPAlertTemplate || aTemplate is CPActionSheetTemplate || aTemplate is CPVoiceControlTemplate  {
            
            if let elementId = ((aTemplate.userInfo as? [String: Any])?["FCPObject"] as? FCPPresentTemplate)?.elementId {
                DispatchQueue.main.async {
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                                     data: ["elementId": elementId, "popped": true])
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
    
    // Determine which view controller's view is actively showing.
    func setActiveViewController(with activeScene: UIScene) {
        MemoryLogger.shared.appendEvent("Set Active ViewController to \(activeScene.session.configuration.name ?? "")")
        
        if activeScene is CPTemplateApplicationScene {
            isDashboardSceneActive = false
            carplayScene = activeScene as? CPTemplateApplicationScene
            
            
            // Set the root view controller for CarPlay
            if let rootViewController = FlutterCarplayPlugin.rootViewController {
                // Remove the dashboard window's root view controller if CarPlay scene is active
                dashboardWindow?.rootViewController = nil
                
                // Set the root view controller for CarPlay
                carWindow?.rootViewController = rootViewController
                
                
            }
            
            // Update the root template
            FlutterCarplaySceneDelegate.forceUpdateRootTemplate()
            
        } else if activeScene is CPTemplateApplicationDashboardScene {
            isDashboardSceneActive = true
            
            // Set the root view controller for Dashboard
            if let rootViewController = FlutterCarplayPlugin.rootViewController {
                // Remove the carplay window's root view controller if Dashboard scene is active
                carWindow?.rootViewController = nil
                
                // Set the root view controller for Dashboard
                dashboardWindow?.rootViewController = rootViewController
                
                
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
        if let rootViewController = FlutterCarplayPlugin.rootViewController, isDashboardSceneActive {
            // Remove the carWindow root view controller if the dashboard scene is active
            carWindow?.rootViewController = nil
            window.rootViewController = rootViewController
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
    func interfaceController(_ interfaceController: CPInterfaceController) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")
        // save interface controller
        carplayInterfaceController = interfaceController
        carplayInterfaceController?.delegate = self
    }
    
    /// CarPlay scene did disconnect
    /// - Parameters:
    ///   - interfaceController: Interface controller
    ///   - window: CarPlay window
    func interfaceController(_: CPInterfaceController, didDisconnectWith _: CPWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay window.")
        
        carplayInterfaceController = nil
        carWindow?.rootViewController = nil
    }
}
