//
//  FCPVoiceControlTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/14/2021.
//

import CarPlay

/// A custom template for voice control on CarPlay.
@available(iOS 14.0, *)
class FCPVoiceControlTemplate {
    // MARK: Properties

    /// The underlying CPVoiceControlTemplate instance.
    private(set) var _super: CPVoiceControlTemplate?

    /// The unique identifier for the voice control template.
    private(set) var elementId: String

    /// The speech recognizer associated with the voice control template.
    private var speechRecognizer: FCPSpeechRecognizer = .init()

    /// An array of voice control states for the template.
    private var voiceControlStates: [CPVoiceControlState]

    /// An array of voice control states in Objective-C representation.
    private var objcVoiceControlStates: [FCPVoiceControlState]

    /// The locale associated with the voice control template.
    private var locale: String

    // MARK: Initialization

    /// Initializes a new instance of `FCPVoiceControlTemplate` with the specified parameters.
    ///
    /// - Parameter obj: A dictionary containing the properties of the voice control template.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String,
              let localeValue = obj["locale"] as? String
        else {
            fatalError("Missing required properties for FCPPointOfInterest initialization.")
        }

        elementId = elementIdValue
        locale = localeValue

        objcVoiceControlStates = (obj["voiceControlStates"] as? [[String: Any]] ?? []).map {
            FCPVoiceControlState(obj: $0)
        }
        voiceControlStates = objcVoiceControlStates.map {
            $0.get
        }
    }

    // MARK: Methods

    /// Returns a `CPVoiceControlTemplate` object representing the voice control template.
    ///
    /// - Returns: A `CPVoiceControlTemplate` object.
    var get: CPVoiceControlTemplate {
        let voiceControlTemplate = CPVoiceControlTemplate(voiceControlStates: voiceControlStates)
        voiceControlTemplate.setFCPObject(self)
        _super = voiceControlTemplate
        return voiceControlTemplate
    }

    /// Activates the voice control state with the specified identifier.
    ///
    /// - Parameter identifier: The identifier of the voice control state to activate.
    func activateVoiceControlState(identifier: String) {
        _super?.activateVoiceControlState(withIdentifier: identifier)
    }

    /// Retrieves the identifier of the currently active voice control state.
    ///
    /// - Returns: The identifier of the active voice control state, or `nil` if none is active.
    func getActiveVoiceControlStateIdentifier() -> String? {
        return _super?.activeStateIdentifier
    }

    /// Starts the voice control template, initiating speech recognition.
    func start() {
        speechRecognizer.record(locale: locale)
    }

    /// Stops the voice control template, ending speech recognition.
    func stop() {
        speechRecognizer.stopRecording()
    }
}

@available(iOS 14.0, *)
extension FCPVoiceControlTemplate: FCPPresentTemplate {}

@available(iOS 14.0, *)
extension FCPVoiceControlTemplate: FCPTemplate {}
