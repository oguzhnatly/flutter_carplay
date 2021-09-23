//
//  FlutterCarPlayPluginsSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import MediaPlayer

class FCPNowPlayingTemplate: NSObject, CPNowPlayingTemplateObserver {
  func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
    print("nowPlayingTemplateUpNextButtonTapped")
  }
  
  func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
    print("nowPlayingTemplateAlbumArtistButtonTapped")
  }
}

@available(iOS 14.0, *)
class FlutterCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  static private var interfaceController: CPInterfaceController?
  
  static public func forceUpdateRootTemplate() {
//    let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
//    let animated = SwiftFlutterCarplayPlugin.animated
//
//    self.interfaceController?.setRootTemplate(rootTemplate!, animated: animated)
//    MPPlayableContentManager.shared().dataSource
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
    let nowPlayingLanguageOption = MPNowPlayingInfoLanguageOption(type: .audible, languageTag: "en-US", characteristics: nil, displayName: "English", identifier: "en")
    let notPlayingLogo = UIImage().fromFlutterAsset(name: "images/logo_flutter_1080px_clr.png")
    
    NSLog("%@", "**** Set playback info: rate \(String(describing: FCPSoundEffects.shared.audioPlayer?.rate)), position \(String(describing: FCPSoundEffects.shared.audioPlayer?.currentTime)), duration \(String(describing: FCPSoundEffects.shared.duration))")
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = FCPSoundEffects.shared.duration
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = FCPSoundEffects.shared.audioPlayer?.currentTime
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = FCPSoundEffects.shared.audioPlayer?.rate
    nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
    nowPlayingInfo[MPNowPlayingInfoPropertyCurrentLanguageOptions] = [nowPlayingLanguageOption]
    nowPlayingInfo[MPNowPlayingInfoPropertyAvailableLanguageOptions] = [MPNowPlayingInfoLanguageOptionGroup(languageOptions: [nowPlayingLanguageOption], defaultLanguageOption: nowPlayingLanguageOption, allowEmptySelection: true)]
    nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = FCPSoundEffects.shared.audioURL
    nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
    nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
    nowPlayingInfo[MPMediaItemPropertyTitle] = "NCS Music"
    nowPlayingInfo[MPMediaItemPropertyArtist] = "NCS"
    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: notPlayingLogo.size, requestHandler: { (size) -> UIImage in
      return notPlayingLogo
    })
    nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = "NCS Artist"
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "NCS Album"
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = 1
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = 5
    
    nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    
    CPNowPlayingTemplate.shared.add(FCPNowPlayingTemplate())
    CPNowPlayingTemplate.shared.updateNowPlayingButtons([
      CPNowPlayingButton(handler: { _ in
        print("CPNowPlayingButton")
      }),
      CPNowPlayingImageButton(image: notPlayingLogo, handler: { _ in
        print("CPNowPlayingImageButton")
      }),
      CPNowPlayingAddToLibraryButton(handler: {_ in
        print("CPNowPlayingAddToLibraryButton")
      }),
      CPNowPlayingPlaybackRateButton(handler: {_ in
        print("CPNowPlayingPlaybackRateButton")
      }),
      CPNowPlayingShuffleButton(handler: {_ in
        print("CPNowPlayingShuffleButton")
      }),
      CPNowPlayingMoreButton(handler: {_ in
        print("CPNowPlayingMoreButton")
      })
    ])
    CPNowPlayingTemplate.shared.isUpNextButtonEnabled = true
    CPNowPlayingTemplate.shared.upNextTitle = "Details"
    CPNowPlayingTemplate.shared.isAlbumArtistButtonEnabled = false
    
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    remoteCommandCenter.changePlaybackRateCommand.supportedPlaybackRates = [1.0, 2.0]
    remoteCommandCenter.skipForwardCommand.preferredIntervals = [15.0]
    remoteCommandCenter.skipBackwardCommand.preferredIntervals = [15.0]
    remoteCommandCenter.changeRepeatModeCommand.currentRepeatType = MPRepeatType.off
    remoteCommandCenter.playCommand.addTarget(handler: { (event: MPRemoteCommandEvent) in
      FCPSoundEffects.shared.play()
      return MPRemoteCommandHandlerStatus.success
    })
    remoteCommandCenter.pauseCommand.addTarget(handler: { (event: MPRemoteCommandEvent) in
      FCPSoundEffects.shared.pause()
      return MPRemoteCommandHandlerStatus.success
    })
    remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
    remoteCommandCenter.nextTrackCommand.addTarget(handler: { (event: MPRemoteCommandEvent) in
      print("nextTrackCommand")
      return MPRemoteCommandHandlerStatus.success
    })
    remoteCommandCenter.previousTrackCommand.addTarget(handler: { (event: MPRemoteCommandEvent) in
      print("previousTrackCommand")
      return MPRemoteCommandHandlerStatus.success
    })
    
    
    self.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true)
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
