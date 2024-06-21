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
package com.oguzhnatly.flutter_carplay.models.map.here_map

import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.util.Log
import com.oguzhnatly.flutter_carplay.AndroidAutoService
import java.util.Locale

// A simple class that uses Android's TextToSpeech engine to speak texts.
class VoiceAssistant {
    private val textToSpeech: TextToSpeech
    private var utteranceId: String? = null
    private var messageId = 0

    init {
        AndroidAutoService.session?.carContext?.applicationContext.let {
            textToSpeech =
                TextToSpeech(it) { status: Int ->
                    if (status == TextToSpeech.ERROR) {
                        Log.d(TAG, ("ERROR: Initialization of Android's TextToSpeech failed."))
                    }
                }
        }
    }

    fun isLanguageAvailable(locale: Locale?): Boolean {
        return textToSpeech.isLanguageAvailable(locale) == TextToSpeech.LANG_AVAILABLE
    }

    fun setLanguage(locale: Locale?): Boolean {
        val isLanguageSet = textToSpeech.setLanguage(locale) == TextToSpeech.LANG_AVAILABLE
        return isLanguageSet
    }

    fun speak(speechMessage: String) {
        Log.d(TAG, "Voice message: $speechMessage")

        // No engine specific params used for this example.
        val engineParams: Bundle? = null
        utteranceId = TAG + messageId++

        // QUEUE_FLUSH interrupts already speaking messages.
        val error =
            textToSpeech.speak(
                speechMessage,
                TextToSpeech.QUEUE_FLUSH,
                engineParams,
                utteranceId
            )
        if (error != -1) {
            Log.e(TAG, "Error when speaking using Android's TextToSpeech: $error")
        }
    }

    fun stop() {}

    companion object {
        private val TAG: String = VoiceAssistant::class.java.name
    }
}
