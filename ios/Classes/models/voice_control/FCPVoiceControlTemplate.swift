//
//  FCPVoiceControlTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/14/2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPVoiceControlTemplate {
  private(set) var _super: CPVoiceControlTemplate?
  private(set) var elementId: String
  private var speechRecognizer: FCPSpeechRecognizer = FCPSpeechRecognizer()
  private var voiceControlStates: [CPVoiceControlState]
  private var objcVoiceControlStates: [FCPVoiceControlState]
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.objcVoiceControlStates = (obj["voiceControlStates"] as! Array<[String : Any]>).map {
      FCPVoiceControlState(obj: $0)
    }
    self.voiceControlStates = self.objcVoiceControlStates.map {
      $0.get
    }
  }
  
  var get: CPVoiceControlTemplate {
    let voiceControlTemplate = CPVoiceControlTemplate.init(voiceControlStates: voiceControlStates)
    self._super = voiceControlTemplate
    return voiceControlTemplate
  }
  
  func activateVoiceControlState(identifier: String) {
    self._super?.activateVoiceControlState(withIdentifier: identifier)
  }
  
  func getActiveVoiceControlStateIdentifier() -> String? {
    return self._super?.activeStateIdentifier
  }
  
  func start() {
    self.speechRecognizer.record()
  }
  
  func stop() {
    self.speechRecognizer.stopRecording()
  }
}

@available(iOS 14.0, *)
extension FCPVoiceControlTemplate: FCPPresentTemplate { }
