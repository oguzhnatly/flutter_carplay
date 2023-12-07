//
//  FCPSpeaker.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/15/2021.
//

import AVFoundation

class FCPSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = FCPSpeaker()

    var errorDescription: String? = nil
    private let synthesizer: AVSpeechSynthesizer = .init()
    private var willEnd: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: String, didEnd: @escaping () -> Void) {
        do {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: language)

            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            synthesizer.speak(utterance)
            willEnd = didEnd
        } catch {
            errorDescription = error.localizedDescription
        }
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        willEnd?()
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        willEnd?()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
