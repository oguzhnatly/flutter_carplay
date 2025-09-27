//
//  FlutterCarPlayPluginsSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

extension CPTemplate {
  private static var elementIdKey: UInt8 = 0

  var elementId: String? {
    get {
      return objc_getAssociatedObject(self, &CPTemplate.elementIdKey) as? String
    }
    set {
      objc_setAssociatedObject(self, &CPTemplate.elementIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

@available(iOS 14.0, *)
class FlutterCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPInterfaceControllerDelegate {
  static private var interfaceController: CPInterfaceController?
  static private var templateStack: [CPTemplate] = []

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
    guard self.interfaceController?.rootTemplate != nil else { return }

    self.templateStack.append(template)
    self.interfaceController?.pushTemplate(template, animated: animated)
  }

  static public func pushIfNotExist(template: CPTemplate, animated: Bool) {
    guard let interfaceController = self.interfaceController else { return }
    guard interfaceController.rootTemplate != nil else { return }

    let isAlreadyPushed = interfaceController.templates.contains { $0 === template }
    let isTopSameInstance = interfaceController.topTemplate === template

    if !isAlreadyPushed && !isTopSameInstance {
        self.templateStack.append(template)
        interfaceController.pushTemplate(template, animated: animated)
    }
  }

  func templateDidDisappear(_ template: CPTemplate, animated: Bool) {
    // Only treat it as a pop if it was the top of the stack
    if FlutterCarPlaySceneDelegate.templateStack.last === template {
      FlutterCarPlaySceneDelegate.templateStack.removeLast()
      if let elementId = template.elementId {
        SwiftFlutterCarplayPlugin.sendOnScreenBackButtonPressed(elementId: elementId)
      }
    }
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
    interfaceController.delegate = self
    
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate

    if rootTemplate != nil {
      FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
    }
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)

    interfaceController.delegate = nil
    FlutterCarPlaySceneDelegate.interfaceController = nil
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnectInterfaceController interfaceController: CPInterfaceController) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)

    interfaceController.delegate = nil
    FlutterCarPlaySceneDelegate.interfaceController = nil
  }
}
