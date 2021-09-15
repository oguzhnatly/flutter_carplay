//
//  FCPSpeechRecognizer.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/14/2021.
//

import AVFoundation
import Speech
import SwiftUI

struct FCPSpeechRecognizer {
  private class FCPSpeechTranscript {
    var transcript = ""
    
    func set(newValue: String) {
      SwiftFlutterCarplayPlugin.sendSpeechRecognitionTranscriptChangeEvent(transcript: newValue)
      transcript = newValue
    }
    
    func get() -> String {
      return transcript
    }
  }
  
  private class FCPSpeechAssist {
    var audioEngine: AVAudioEngine?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let speechRecognizer = SFSpeechRecognizer()

    deinit {
      reset()
    }

    func reset() {
      recognitionTask?.cancel()
      audioEngine?.stop()
      audioEngine = nil
      recognitionRequest = nil
      recognitionTask = nil
    }
  }

  private let transcript = FCPSpeechTranscript()
  private let assistant = FCPSpeechAssist()

  func record() {
    print("[FlutterCarPlay]: Requesting access for Voice Control.")
    
    canAccess { authorized in
      guard authorized else {
        print("[FlutterCarPlay]: Access denied.")
        return
      }
      print("[FlutterCarPlay]: Access granted.")
      
      assistant.audioEngine = AVAudioEngine()
      guard let audioEngine = assistant.audioEngine else {
        fatalError("[FlutterCarPlay]: Unable to create audio engine. If you're not sure, please create an issue in https://github.com/oguzhnatly/flutter_carplay/issues")
      }
      assistant.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      guard let recognitionRequest = assistant.recognitionRequest else {
        fatalError("[FlutterCarPlay]: Unable to create recognition request. If you're not sure, please create an issue in https://github.com/oguzhnatly/flutter_carplay/issues")
      }
      recognitionRequest.shouldReportPartialResults = true

      do {
        print("[FlutterCarPlay]: Booting audio subsystem and finding input node, please wait.")

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            recognitionRequest.append(buffer)
        }
        print("[FlutterCarPlay]: Preparing audio engine.")
        audioEngine.prepare()
        try audioEngine.start()
        assistant.recognitionTask = assistant.speechRecognizer?.recognitionTask(with: recognitionRequest) { (result, error) in
          var isFinal = false
          if let result = result {
            relay(message: result.bestTranscription.formattedString)
            isFinal = result.isFinal
          }

          if error != nil || isFinal {
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
            self.assistant.recognitionRequest = nil
          }
        }
      } catch {
        print("[FlutterCarPlay]: Error while transcibing audio: " + error.localizedDescription)
        assistant.reset()
      }
    }
  }
  
  func stopRecording() {
    print("[FlutterCarPlay]: Voice Control Record has been stopped.")
    assistant.reset()
  }
  
  private func canAccess(withHandler handler: @escaping (Bool) -> Void) {
    SFSpeechRecognizer.requestAuthorization { status in
      if status == .authorized {
        AVAudioSession.sharedInstance().requestRecordPermission { authorized in
          handler(authorized)
        }
      } else {
        handler(false)
      }
    }
  }
  
  private func relay(message: String) {
    DispatchQueue.main.async {
      transcript.set(newValue: message)
    }
  }
}
