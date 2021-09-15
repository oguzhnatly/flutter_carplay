//
//  FCPSpeaker.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/15/2021.
//

import AVFoundation

internal class FCPSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
  static let shared = FCPSpeaker()
  
  internal var errorDescription: String? = nil
  private let synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
  private var willEnd: (() -> Void)?

  override init() {
    super.init()
    self.synthesizer.delegate = self
  }

  internal func speak(_ text: String, language: String, didEnd: @escaping () -> Void) {
    do {
      let utterance = AVSpeechUtterance(string: text)
      utterance.voice = AVSpeechSynthesisVoice(language: language)
      
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      self.synthesizer.speak(utterance)
      self.willEnd = didEnd
    } catch let error {
      self.errorDescription = error.localizedDescription
    }
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    self.willEnd?()
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    self.willEnd?()
  }
  
  internal func stop() {
    self.synthesizer.stopSpeaking(at: .immediate)
  }
}
