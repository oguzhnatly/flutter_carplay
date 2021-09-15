//
//  FCPSoundEffects.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/15/2021.
//

import AVFoundation

public final class FCPSoundEffects: NSObject {
  static let shared = FCPSoundEffects()
  
  var audioPlayer: AVAudioPlayer? = nil
  
  private override init() {}
  
  func play(sound: String) {
    let x = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: sound)
    
    guard let s = Bundle.main.path(forResource: x, ofType: nil) else {
      fatalError("[FlutterCarPlay]: Music could not be found in the resources.")
    }
    
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: s))
    } catch {
      fatalError("[FlutterCarPlay]: Music could not be played. If you're not sure, please create an issue in https://github.com/oguzhnatly/flutter_carplay/issues")
    }
    
    audioPlayer?.play()
  }
}
