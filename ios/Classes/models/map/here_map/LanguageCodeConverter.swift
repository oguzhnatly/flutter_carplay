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

import Foundation
import heresdk

// Converts from HERE SDK's LanguageCode to Locale and vice versa.
// Both language and country must be set, if available.
class LanguageCodeConverter {

    // Language is always set, region may not be set.
    private static let languageCodeMap = [

        /// English (United States)
        LanguageCode.enUs: Locale(identifier: "en-US"),

        /// Afrikaans
        LanguageCode.afZa: Locale(identifier: "af-ZA"),

        /// Albanian
        LanguageCode.sqAl: Locale(identifier: "sq-AL"),

        /// Amharic (Ethiopia)
        LanguageCode.amEt: Locale(identifier: "am-ET"),

        /// Arabic (Saudi Arabia)
        LanguageCode.arSa: Locale(identifier: "ar-SA"),

        /// Armenian
        LanguageCode.hyAm: Locale(identifier: "hy-AM"),

        /// Assamese (India)
        LanguageCode.asIn: Locale(identifier: "as-IN"),

        /// Azeri - Latin
        LanguageCode.azLatnAz: Locale(identifier: "az-LATN_AZ"),

        /// Bangla (Bangladesh)
        LanguageCode.bnBd: Locale(identifier: "bn-BD"),

        /// Bangla (India)
        LanguageCode.bnIn: Locale(identifier: "bn-IN"),

        /// Basque
        LanguageCode.euEs: Locale(identifier: "eu-ES"),

        /// Belarusian
        LanguageCode.beBy: Locale(identifier: "be-BY"),

        /// Bosnian - Latin
        LanguageCode.bsLatnBa: Locale(identifier: "bs-LATN_BA"),

        /// Bulgarian
        LanguageCode.bgBg: Locale(identifier: "bg-BG"),

        /// Catalan (Spain)
        LanguageCode.caEs: Locale(identifier: "ca-ES"),

        /// Central Kurdish - Arabic
        LanguageCode.kuArab: Locale(identifier: "ku-ARAB"),

        /// Chinese (Simplified China)
        LanguageCode.zhCn: Locale(identifier: "zh-CN"),

        /// Chinese (Traditional Hong Kong)
        LanguageCode.zhHk: Locale(identifier: "zh-HK"),

        /// Chinese (Traditional Taiwan)
        LanguageCode.zhTw: Locale(identifier: "zh-TW"),

        /// Croatian
        LanguageCode.hrHr: Locale(identifier: "hr-HR"),

        /// Czech
        LanguageCode.csCz: Locale(identifier: "cs-CZ"),

        /// Danish
        LanguageCode.daDk: Locale(identifier: "da-DK"),

        /// Dari - Arabic (Afghanistan)
        LanguageCode.prsArabAf: Locale(identifier: "prs-ARAB_AF"),

        /// Dutch
        LanguageCode.nlNl: Locale(identifier: "nl-NL"),

        /// English (British)
        LanguageCode.enGb: Locale(identifier: "en-GB"),

        /// Estonian
        LanguageCode.etEe: Locale(identifier: "et-EE"),

        /// Farsi (Iran)
        LanguageCode.faIr: Locale(identifier: "fa-IR"),

        /// Filipino
        LanguageCode.filPh: Locale(identifier: "fil-PH"),

        /// Finnish
        LanguageCode.fiFi: Locale(identifier: "fi-FI"),

        /// French
        LanguageCode.frFr: Locale(identifier: "fr-FR"),

        /// French (Canada)
        LanguageCode.frCa: Locale(identifier: "fr-CA"),

        /// Galician
        LanguageCode.glEs: Locale(identifier: "gl-ES"),

        /// Georgian
        LanguageCode.kaGe: Locale(identifier: "ka-GE"),

        /// German
        LanguageCode.deDe: Locale(identifier: "de-DE"),

        /// Greek
        LanguageCode.elGr: Locale(identifier: "el-GR"),

        /// Gujarati (India)
        LanguageCode.guIn: Locale(identifier: "gu-IN"),

        /// Hausa - Latin (Nigeria)
        LanguageCode.haLatnNg: Locale(identifier: "ha-LATN_NG"),

        /// Hebrew
        LanguageCode.heIl: Locale(identifier: "he-IL"),

        /// Hindi
        LanguageCode.hiIn: Locale(identifier: "hi-IN"),

        /// Hungarian
        LanguageCode.huHu: Locale(identifier: "hu-HU"),

        /// Icelandic
        LanguageCode.isIs: Locale(identifier: "is-IS"),

        /// Igbo - Latin (Nigera)
        LanguageCode.igLatnNg: Locale(identifier: "ig-LATN_NG"),

        /// Indonesian (Bahasa)
        LanguageCode.idId: Locale(identifier: "id-ID"),

        /// Irish
        LanguageCode.gaIe: Locale(identifier: "ga-IE"),

        /// IsiXhosa
        LanguageCode.xh: Locale(identifier: "xh"),

        /// IsiZulu (South Africa)
        LanguageCode.zuZa: Locale(identifier: "zu-ZA"),

        /// Italian
        LanguageCode.itIt: Locale(identifier: "it-IT"),

        /// Japanese
        LanguageCode.jaJp: Locale(identifier: "ja-JP"),

        /// Kannada (India)
        LanguageCode.knIn: Locale(identifier: "kn-IN"),

        /// Kazakh
        LanguageCode.kkKz: Locale(identifier: "kk-KZ"),

        /// Khmer (Cambodia)
        LanguageCode.kmKh: Locale(identifier: "km-KH"),

        /// K'iche' - Latin (Guatemala)
        LanguageCode.qucLatnGt: Locale(identifier: "quc-LATN_GT"),

        /// Kinyarwanda (Rwanda)
        LanguageCode.rwRw: Locale(identifier: "rw-RW"),

        /// KiSwahili
        LanguageCode.sw: Locale(identifier: "sw"),

        /// Konkani (India)
        LanguageCode.kokIn: Locale(identifier: "kok-IN"),

        /// Korean
        LanguageCode.koKr: Locale(identifier: "ko-KR"),

        /// Kyrgyz - Cyrillic
        LanguageCode.kyCyrlKg: Locale(identifier: "ky-CYRL_KG"),

        /// Latvian
        LanguageCode.lvLv: Locale(identifier: "lv-LV"),

        /// Lithuanian
        LanguageCode.ltLt: Locale(identifier: "lt-LT"),

        /// Luxembourgish
        LanguageCode.lbLu: Locale(identifier: "lb-LU"),

        /// Macedonian
        LanguageCode.mkMk: Locale(identifier: "mk-MK"),

        /// Malay (Bahasa)
        LanguageCode.msMy: Locale(identifier: "ms-MY"),

        /// Malayalam (India)
        LanguageCode.mlIn: Locale(identifier: "ml-IN"),

        /// Maltese  (Malta)
        LanguageCode.mtMt: Locale(identifier: "mt-MT"),

        /// Maori - Latin (New Zealand)
        LanguageCode.miLatnNz: Locale(identifier: "mi-LATN_NZ"),

        /// Marathi (India)
        LanguageCode.mrIn: Locale(identifier: "mr-IN"),

        /// Mongolian - Cyrillic
        LanguageCode.mnCyrlMn: Locale(identifier: "mn-CYRL_MN"),

        /// Nepali (Nepal)
        LanguageCode.neNp: Locale(identifier: "ne-NP"),

        /// Norwegian (Bokmål)
        LanguageCode.nbNo: Locale(identifier: "nb-NO"),

        /// Norwegian (Nynorsk)
        LanguageCode.nnNo: Locale(identifier: "nn-NO"),

        /// Odia (India)
        LanguageCode.orIn: Locale(identifier: "or-IN"),

        /// Polish
        LanguageCode.plPl: Locale(identifier: "pl-PL"),

        /// Portuguese (Brazil)
        LanguageCode.ptBr: Locale(identifier: "pt-BR"),

        /// Portuguese (Portugal)
        LanguageCode.ptPt: Locale(identifier: "pt-PT"),

        /// Punjabi - Gurmukhi
        LanguageCode.paGuru: Locale(identifier: "pa-GURU"),

        /// Punjabi - Arabic
        LanguageCode.paArab: Locale(identifier: "pa-ARAB"),

        /// Quechua - Latin (Peru)
        LanguageCode.quLatnPe: Locale(identifier: "qu-LATN_PE"),

        /// Romanian
        LanguageCode.roRo: Locale(identifier: "ro-RO"),

        /// Russian
        LanguageCode.ruRu: Locale(identifier: "ru-RU"),

        /// Scottish Gaelic - Latin
        LanguageCode.gdLatnGb: Locale(identifier: "gd-LATN_GB"),

        /// Serbian - Cyrillic (Bosnia)
        LanguageCode.srCyrlBa: Locale(identifier: "sr-CYRL_BA"),

        /// Serbian - Cyrillic (Serbia)
        LanguageCode.srCyrlRs: Locale(identifier: "sr-CYRL_RS"),

        /// Serbian - Latin (Serbia)
        LanguageCode.srLatnRs: Locale(identifier: "sr-LATN_RS"),

        /// Sesotho Sa Leboa (South Africa)
        LanguageCode.nsoZa: Locale(identifier: "nso-ZA"),

        /// Setswana
        LanguageCode.tn: Locale(identifier: "tn"),

        /// Sindhi - Arabic
        LanguageCode.sdArab: Locale(identifier: "sd-ARAB"),

        /// Sinhala (Sri Lanka)
        LanguageCode.siLk: Locale(identifier: "si-LK"),

        /// Slovak
        LanguageCode.skSk: Locale(identifier: "sk-SK"),

        /// Slovenian
        LanguageCode.slSi: Locale(identifier: "sl-SI"),

        /// Spanish (Mexico)
        LanguageCode.esMx: Locale(identifier: "es-MX"),

        /// Spanish (Spain)
        LanguageCode.esEs: Locale(identifier: "es-ES"),

        /// Swedish
        LanguageCode.svSe: Locale(identifier: "sv-SE"),

        /// Tajik - Cyrillic
        LanguageCode.tgCyrlTj: Locale(identifier: "tg-CYRL_TJ"),

        /// Tamil
        LanguageCode.ta: Locale(identifier: "ta"),

        /// Tatar - Cyrillic (Russia)
        LanguageCode.ttCyrlRu: Locale(identifier: "tt-CYRL_RU"),

        /// Telugu (India)
        LanguageCode.teIn: Locale(identifier: "te-IN"),

        /// Thai
        LanguageCode.thTh: Locale(identifier: "th-TH"),

        /// Tigrinya (Ethiopia)
        LanguageCode.tiEt: Locale(identifier: "ti-ET"),

        /// Turkish
        LanguageCode.trTr: Locale(identifier: "tr-TR"),

        /// Turkmen - Latin
        LanguageCode.tkLatnTm: Locale(identifier: "tk-LATN_TM"),

        /// Ukrainian
        LanguageCode.ukUa: Locale(identifier: "uk-UA"),

        /// Urdu
        LanguageCode.ur: Locale(identifier: "ur"),

        /// Uyghur - Arabic
        LanguageCode.ugArab: Locale(identifier: "ug-ARAB"),

        /// Uzbek - Cyrillic
        LanguageCode.uzCyrlUz: Locale(identifier: "uz-CYRL_UZ"),

        /// Uzbek - Latin
        LanguageCode.uzLatnUz: Locale(identifier: "uz-LATN_UZ"),

        /// Valencian (Spain)
        LanguageCode.catEs: Locale(identifier: "cat-ES"),

        /// Vietnamese
        LanguageCode.viVn: Locale(identifier: "vi-VN"),

        /// Welsh
        LanguageCode.cyGb: Locale(identifier: "cy-GB"),

        /// Wolof - Latin
        LanguageCode.woLatn: Locale(identifier: "wo-LATN"),

        /// Yoruba - Latin
        LanguageCode.yoLatn: Locale(identifier: "yo-LATN")]

    public static func getLocale(languageCode: LanguageCode) -> Locale {
        guard let index = languageCodeMap.index(forKey: languageCode) else {
            // Should never happen, unless the languageCodeMap was not updated
            // to support the latest LanguageCodes from HERE SDK.
            print("LanguageCode not found. Falling Back to en-US.")
            return Locale(identifier: "en-US")
        }

        return languageCodeMap[index].value
    }

    public static func getLanguageCode(locale: Locale) -> LanguageCode {
        let language = locale.languageCode
        let country = locale.regionCode

        for (languageCodeEntry, localeEntry) in languageCodeMap {
            if country == nil {
                if language == localeEntry.languageCode {
                    return languageCodeEntry
                }
            } else {
                if language == localeEntry.languageCode && country == localeEntry.regionCode {
                    return languageCodeEntry
                }
            }
        }

        print("LanguageCode not found. Falling back to enUs.")
        return LanguageCode.enUs
    }

    public static func getLanguageCode(identifier: String) -> LanguageCode {
        for (languageCodeEntry, localeEntry) in languageCodeMap {
            if identifier == localeEntry.identifier {
                return languageCodeEntry
            }
        }

        print("LanguageCode not found. Falling back to enUs.")
        return LanguageCode.enUs
    }
}
