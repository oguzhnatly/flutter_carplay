//
//  FlutterCarPlayPluginsSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FlutterCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  static private var interfaceController: CPInterfaceController?
  
  static public func forceUpdateRootTemplate() {
    let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
    let animated = SwiftFlutterCarplayPlugin.animated
    
    self.interfaceController?.setRootTemplate(rootTemplate!, animated: animated)
  }
  
  // Fired when just before the carplay become active
  func sceneDidBecomeActive(_ scene: UIScene) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
  }
  
  // Fired when carplay entered background
  func sceneDidEnterBackground(_ scene: UIScene) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.background)
  }
  
  static public func pop(animated: Bool) {
    self.interfaceController?.popTemplate(animated: animated)
  }
  
  static public func popToRootTemplate(animated: Bool) {
    self.interfaceController?.popToRootTemplate(animated: animated)
  }
  
  static public func push(template: CPTemplate, animated: Bool) {
    self.interfaceController?.pushTemplate(template, animated: animated)
  }
  
  static public func closePresent(animated: Bool) {
    self.interfaceController?.dismissTemplate(animated: animated)
  }
  
  static public func presentTemplate(template: CPTemplate, animated: Bool,
                                     onPresent: @escaping (_ completed: Bool) -> Void) {
    self.interfaceController?.presentTemplate(template, animated: animated, completion: { completed, error in
      guard error != nil else {
        onPresent(false)
        return
      }
      onPresent(completed)
    })
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
    FlutterCarPlaySceneDelegate.interfaceController = interfaceController
    
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate

    guard rootTemplate != nil else {
      FlutterCarPlaySceneDelegate.interfaceController = nil
      return
    }
    
    FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated)
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
    
    //FlutterCarPlaySceneDelegate.interfaceController = nil
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnectInterfaceController interfaceController: CPInterfaceController) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
    
    //FlutterCarPlaySceneDelegate.interfaceController = nil
  }
}
