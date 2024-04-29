//
//  FCPSpeaker.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/15/2021.
//

import AVFoundation

/// A singleton class responsible for handling text-to-speech functionality in the Flutter CarPlay plugin.
class FCPSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    /// Shared instance of the text-to-speech manager.
    static let shared = FCPSpeaker()

    /// An optional error description that provides information about any encountered errors during text-to-speech.
    var errorDescription: String? = nil

    /// The AVSpeechSynthesizer responsible for synthesizing and speaking text.
    private let synthesizer: AVSpeechSynthesizer = .init()

    /// A closure that will be called when speech synthesis is completed or canceled.
    private var willEnd: (() -> Void)?

    /// The locale identifier.
    private var locale = Locale(identifier: "en-US")

    /// Initializes the text-to-speech manager and sets itself as the delegate for the AVSpeechSynthesizer.
    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Determines if the given language is supported.
    /// - Parameter locale: The locale identifier.
    /// - Returns: True if supported, false if not.
    public func isLanguageAvailable(locale: Locale) -> Bool {
        return isLanguageAvailable(identifier: locale.identifier)
    }

    /// Determines if the given language is supported.
    /// - Parameter identifier: The locale identifier.
    /// - Returns: True if supported, false if not.
    public func isLanguageAvailable(identifier: String) -> Bool {
        let supportedVoices = AVSpeechSynthesisVoice.speechVoices()
        for aVSpeechSynthesisVoice in supportedVoices {
            if aVSpeechSynthesisVoice.language == identifier {
                return true
            }
        }

        return false
    }

    /// Sets the language.
    /// - Parameter locale: The locale identifier.
    /// - Returns: True if supported, false if not.
    public func setLanguage(locale: Locale) -> Bool {
        if isLanguageAvailable(locale: locale) {
            self.locale = locale
            return true
        }

        print("Apple's AVSpeechSynthesisVoice does not support this language: \(locale). Keeping \(self.locale).")
        return false
    }

    /// Synthesizes and speaks the provided text using the specified language.
    ///
    /// - Parameters:
    ///   - text: The text to be spoken.
    ///   - language: The language in which the text should be spoken.
    ///   - didEnd: A closure to be executed when speech synthesis is completed or canceled.
    func speak(_ text: String, didEnd: @escaping () -> Void) {
        do {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: locale.identifier)
            if utterance.voice == nil {
                print("Error: Apple's AVSpeechSynthesisVoice does not support this language: \(locale).")
                return
            }

            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt)
            try AVAudioSession.sharedInstance().setActive(true)
            synthesizer.speak(utterance)
            willEnd = didEnd
        } catch {
            errorDescription = error.localizedDescription
        }
    }

    /// Handles the cancellation of speech synthesis, deactivates the audio session, and executes the associated closure.
    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        willEnd?()
    }

    /// Handles the completion of speech synthesis, deactivates the audio session, and executes the associated closure.
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        willEnd?()
    }

    /// Stops the ongoing speech synthesis immediately.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
