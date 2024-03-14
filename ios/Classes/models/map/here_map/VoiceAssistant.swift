/*
 * Copyright (C) 2019-2024 HERE Europe B.V.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import heresdk
import AVFoundation
import Foundation

// A simple TTS engine that uses Apple's AVSpeechSynthesizer to speak texts.
class VoiceAssistant {

    private let avSpeechSynthesizer = AVSpeechSynthesizer()
    private var locale = Locale(identifier: "en-US")

    public func isLanguageAvailable(locale: Locale) -> Bool {
        return isLanguageAvailable(identifier: locale.identifier)
    }

    public func isLanguageAvailable(identifier: String) -> Bool {
        let supportedVoices = AVSpeechSynthesisVoice.speechVoices()
        for aVSpeechSynthesisVoice in supportedVoices {
            if aVSpeechSynthesisVoice.language == identifier {
                return true
            }
        }

        return false
    }

    public func setLanguage(locale: Locale) -> Bool {
        if isLanguageAvailable(locale: locale) {
            self.locale = locale
            return true
        }

        print("Apple's AVSpeechSynthesisVoice does not support this language: \(locale). Keeping \(self.locale).")
        return false
    }

    func speak(message: String) {
        print("Voice message: \(message)")

        let voiceMessage = AVSpeechUtterance(string: message)
        voiceMessage.voice = AVSpeechSynthesisVoice(language: locale.identifier)
        if voiceMessage.voice == nil {
            print("Error: Apple's AVSpeechSynthesisVoice does not support this language: \(locale).")
            return
        }

        if avSpeechSynthesizer.isSpeaking {
            avSpeechSynthesizer.stopSpeaking(at: .immediate)
        }

        avSpeechSynthesizer.speak(voiceMessage)
    }
}
