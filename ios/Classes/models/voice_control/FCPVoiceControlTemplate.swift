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
    private var speechRecognizer: FCPSpeechRecognizer = .init()
    private var voiceControlStates: [CPVoiceControlState]
    private var objcVoiceControlStates: [FCPVoiceControlState]
    private var locale: String

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        locale = obj["locale"] as! String
        objcVoiceControlStates = (obj["voiceControlStates"] as! [[String: Any]]).map {
            FCPVoiceControlState(obj: $0)
        }
        voiceControlStates = objcVoiceControlStates.map {
            $0.get
        }
    }

    var get: CPVoiceControlTemplate {
        let voiceControlTemplate = CPVoiceControlTemplate(voiceControlStates: voiceControlStates)
        _super = voiceControlTemplate
        return voiceControlTemplate
    }

    func activateVoiceControlState(identifier: String) {
        _super?.activateVoiceControlState(withIdentifier: identifier)
    }

    func getActiveVoiceControlStateIdentifier() -> String? {
        return _super?.activeStateIdentifier
    }

    func start() {
        speechRecognizer.record(locale: locale)
    }

    func stop() {
        speechRecognizer.stopRecording()
    }
}

@available(iOS 14.0, *)
extension FCPVoiceControlTemplate: FCPPresentTemplate {}

@available(iOS 14.0, *)
extension FCPVoiceControlTemplate: FCPTemplate {}
