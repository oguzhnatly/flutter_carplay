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

import android.util.Log
import com.here.sdk.core.LanguageCode
import java.util.Locale

// Converts from com.here.sdk.core.LanguageCode to java.util.Locale and vice versa.
// Both language and country must be set, if available.
object LanguageCodeConverter {
    private val TAG: String = LanguageCodeConverter::class.java.name

    private var languageCodeMap: HashMap<LanguageCode, Locale>? = null

    fun getLocale(languageCode: LanguageCode): Locale? {
        if (languageCodeMap == null) {
            initLanguageCodeMap()
        }

        if (languageCodeMap!!.containsKey(languageCode)) {
            return languageCodeMap!![languageCode]
        }

        // Should never happen, unless the languageCodeMap was not updated
        // to support the latest LanguageCodes from HERE SDK.
        Log.e(TAG, "LanguageCode not found. Falling Back to en-US.")
        return Locale("en", "US")
    }

    fun getLanguageCode(locale: Locale): LanguageCode {
        if (languageCodeMap == null) {
            initLanguageCodeMap()
        }

        val language = locale.language
        val country = locale.country

        for (languageCodeLocaleEntry in languageCodeMap!!.entries) {
            val localeEntry = (languageCodeLocaleEntry as Map.Entry<*, *>).value as Locale

            val languageEntry = localeEntry.language
            val countryEntry = localeEntry.country

            if (country == null) {
                if (language == languageEntry) {
                    return (languageCodeLocaleEntry as Map.Entry<*, *>).key as LanguageCode
                }
            } else {
                if (language == languageEntry && country == countryEntry) {
                    return (languageCodeLocaleEntry as Map.Entry<*, *>).key as LanguageCode
                }
            }
        }

        Log.e(TAG, "LanguageCode not found. Falling back to EN_US.")
        return LanguageCode.EN_US
    }

    // / Language is always set, country may not be set.
    private fun initLanguageCodeMap() {
        languageCodeMap = HashMap()

        /// English (United States)
        languageCodeMap!![LanguageCode.EN_US] = Locale("en", "US")

        /// Afrikaans
        languageCodeMap!![LanguageCode.AF_ZA] = Locale("af", "ZA")

        /// Albanian
        languageCodeMap!![LanguageCode.SQ_AL] = Locale("sq", "AL")

        /// Amharic (Ethiopia)
        languageCodeMap!![LanguageCode.AM_ET] = Locale("am", "ET")

        /// Arabic (Saudi Arabia)
        languageCodeMap!![LanguageCode.AR_SA] = Locale("ar", "SA")

        /// Armenian
        languageCodeMap!![LanguageCode.HY_AM] = Locale("hy", "AM")

        /// Assamese (India)
        languageCodeMap!![LanguageCode.AS_IN] = Locale("as", "IN")

        /// Azeri - Latin
        languageCodeMap!![LanguageCode.AZ_LATN_AZ] = Locale("az", "LATN_AZ")

        /// Bangla (Bangladesh)
        languageCodeMap!![LanguageCode.BN_BD] = Locale("bn", "BD")

        /// Bangla (India)
        languageCodeMap!![LanguageCode.BN_IN] = Locale("bn", "IN")

        /// Basque
        languageCodeMap!![LanguageCode.EU_ES] = Locale("eu", "ES")

        /// Belarusian
        languageCodeMap!![LanguageCode.BE_BY] = Locale("be", "BY")

        /// Bosnian - Latin
        languageCodeMap!![LanguageCode.BS_LATN_BA] = Locale("bs", "LATN_BA")

        /// Bulgarian
        languageCodeMap!![LanguageCode.BG_BG] = Locale("bg", "BG")

        /// Catalan (Spain)
        languageCodeMap!![LanguageCode.CA_ES] = Locale("ca", "ES")

        /// Central Kurdish - Arabic
        languageCodeMap!![LanguageCode.KU_ARAB] = Locale("ku", "ARAB")

        /// Chinese (Simplified China)
        languageCodeMap!![LanguageCode.ZH_CN] = Locale("zh", "CN")

        /// Chinese (Traditional Hong Kong)
        languageCodeMap!![LanguageCode.ZH_HK] = Locale("zh", "HK")

        /// Chinese (Traditional Taiwan)
        languageCodeMap!![LanguageCode.ZH_TW] = Locale("zh", "TW")

        /// Croatian
        languageCodeMap!![LanguageCode.HR_HR] = Locale("hr", "HR")

        /// Czech
        languageCodeMap!![LanguageCode.CS_CZ] = Locale("cs", "CZ")

        /// Danish
        languageCodeMap!![LanguageCode.DA_DK] = Locale("da", "DK")

        /// Dari - Arabic (Afghanistan)
        languageCodeMap!![LanguageCode.PRS_ARAB_AF] = Locale("prs", "ARAB_AF")

        /// Dutch
        languageCodeMap!![LanguageCode.NL_NL] = Locale("nl", "NL")

        /// English (British)
        languageCodeMap!![LanguageCode.EN_GB] = Locale("en", "GB")

        /// Estonian
        languageCodeMap!![LanguageCode.ET_EE] = Locale("et", "EE")

        /// Farsi (Iran)
        languageCodeMap!![LanguageCode.FA_IR] = Locale("fa", "IR")

        /// Filipino
        languageCodeMap!![LanguageCode.FIL_PH] = Locale("fil", "PH")

        /// Finnish
        languageCodeMap!![LanguageCode.FI_FI] = Locale("fi", "FI")

        /// French
        languageCodeMap!![LanguageCode.FR_FR] = Locale("fr", "FR")

        /// French (Canada)
        languageCodeMap!![LanguageCode.FR_CA] = Locale("fr", "CA")

        /// Galician
        languageCodeMap!![LanguageCode.GL_ES] = Locale("gl", "ES")

        /// Georgian
        languageCodeMap!![LanguageCode.KA_GE] = Locale("ka", "GE")

        /// German
        languageCodeMap!![LanguageCode.DE_DE] = Locale("de", "DE")

        /// Greek
        languageCodeMap!![LanguageCode.EL_GR] = Locale("el", "GR")

        /// Gujarati (India)
        languageCodeMap!![LanguageCode.GU_IN] = Locale("gu", "IN")

        /// Hausa - Latin (Nigeria)
        languageCodeMap!![LanguageCode.HA_LATN_NG] = Locale("ha", "LATN_NG")

        /// Hebrew
        languageCodeMap!![LanguageCode.HE_IL] = Locale("he", "IL")

        /// Hindi
        languageCodeMap!![LanguageCode.HI_IN] = Locale("hi", "IN")

        /// Hungarian
        languageCodeMap!![LanguageCode.HU_HU] = Locale("hu", "HU")

        /// Icelandic
        languageCodeMap!![LanguageCode.IS_IS] = Locale("is", "IS")

        /// Igbo - Latin (Nigera)
        languageCodeMap!![LanguageCode.IG_LATN_NG] = Locale("ig", "LATN_NG")

        /// Indonesian (Bahasa)
        languageCodeMap!![LanguageCode.ID_ID] = Locale("id", "ID")

        /// Irish
        languageCodeMap!![LanguageCode.GA_IE] = Locale("ga", "IE")

        /// IsiXhosa
        languageCodeMap!![LanguageCode.XH] = Locale("xh")

        /// IsiZulu (South Africa)
        languageCodeMap!![LanguageCode.ZU_ZA] = Locale("zu", "ZA")

        /// Italian
        languageCodeMap!![LanguageCode.IT_IT] = Locale("it", "IT")

        /// Japanese
        languageCodeMap!![LanguageCode.JA_JP] = Locale("ja", "JP")

        /// Kannada (India)
        languageCodeMap!![LanguageCode.KN_IN] = Locale("kn", "IN")

        /// Kazakh
        languageCodeMap!![LanguageCode.KK_KZ] = Locale("kk", "KZ")

        /// Khmer (Cambodia)
        languageCodeMap!![LanguageCode.KM_KH] = Locale("km", "KH")

        /// K'iche' - Latin (Guatemala)
        languageCodeMap!![LanguageCode.QUC_LATN_GT] = Locale("quc", "LATN_GT")

        /// Kinyarwanda (Rwanda)
        languageCodeMap!![LanguageCode.RW_RW] = Locale("rw", "RW")

        /// KiSwahili
        languageCodeMap!![LanguageCode.SW] = Locale("sw")

        /// Konkani (India)
        languageCodeMap!![LanguageCode.KOK_IN] = Locale("kok", "IN")

        /// Korean
        languageCodeMap!![LanguageCode.KO_KR] = Locale("ko", "KR")

        /// Kyrgyz - Cyrillic
        languageCodeMap!![LanguageCode.KY_CYRL_KG] = Locale("ky", "CYRL_KG")

        /// Latvian
        languageCodeMap!![LanguageCode.LV_LV] = Locale("lv", "LV")

        /// Lithuanian
        languageCodeMap!![LanguageCode.LT_LT] = Locale("lt", "LT")

        /// Luxembourgish
        languageCodeMap!![LanguageCode.LB_LU] = Locale("lb", "LU")

        /// Macedonian
        languageCodeMap!![LanguageCode.MK_MK] = Locale("mk", "MK")

        /// Malay (Bahasa)
        languageCodeMap!![LanguageCode.MS_MY] = Locale("ms", "MY")

        /// Malayalam (India)
        languageCodeMap!![LanguageCode.ML_IN] = Locale("ml", "IN")

        /// Maltese  (Malta)
        languageCodeMap!![LanguageCode.MT_MT] = Locale("mt", "MT")

        /// Maori - Latin (New Zealand)
        languageCodeMap!![LanguageCode.MI_LATN_NZ] = Locale("mi", "LATN_NZ")

        /// Marathi (India)
        languageCodeMap!![LanguageCode.MR_IN] = Locale("mr", "IN")

        /// Mongolian - Cyrillic
        languageCodeMap!![LanguageCode.MN_CYRL_MN] = Locale("mn", "CYRL_MN")

        /// Nepali (Nepal)
        languageCodeMap!![LanguageCode.NE_NP] = Locale("ne", "NP")

        /// Norwegian (Bokmål)
        languageCodeMap!![LanguageCode.NB_NO] = Locale("nb", "NO")

        /// Norwegian (Nynorsk)
        languageCodeMap!![LanguageCode.NN_NO] = Locale("nn", "NO")

        /// Odia (India)
        languageCodeMap!![LanguageCode.OR_IN] = Locale("or", "IN")

        /// Polish
        languageCodeMap!![LanguageCode.PL_PL] = Locale("pl", "PL")

        /// Portuguese (Brazil)
        languageCodeMap!![LanguageCode.PT_BR] = Locale("pt", "BR")

        /// Portuguese (Portugal)
        languageCodeMap!![LanguageCode.PT_PT] = Locale("pt", "PT")

        /// Punjabi - Gurmukhi
        languageCodeMap!![LanguageCode.PA_GURU] = Locale("pa", "GURU")

        /// Punjabi - Arabic
        languageCodeMap!![LanguageCode.PA_ARAB] = Locale("pa", "ARAB")

        /// Quechua - Latin (Peru)
        languageCodeMap!![LanguageCode.QU_LATN_PE] = Locale("qu", "LATN_PE")

        /// Romanian
        languageCodeMap!![LanguageCode.RO_RO] = Locale("ro", "RO")

        /// Russian
        languageCodeMap!![LanguageCode.RU_RU] = Locale("ru", "RU")

        /// Scottish Gaelic - Latin
        languageCodeMap!![LanguageCode.GD_LATN_GB] = Locale("gd", "LATN_GB")

        /// Serbian - Cyrillic (Bosnia)
        languageCodeMap!![LanguageCode.SR_CYRL_BA] = Locale("sr", "CYRL_BA")

        /// Serbian - Cyrillic (Serbia)
        languageCodeMap!![LanguageCode.SR_CYRL_RS] = Locale("sr", "CYRL_RS")

        /// Serbian - Latin (Serbia)
        languageCodeMap!![LanguageCode.SR_LATN_RS] = Locale("sr", "LATN_RS")

        /// Sesotho Sa Leboa (South Africa)
        languageCodeMap!![LanguageCode.NSO_ZA] = Locale("nso", "ZA")

        /// Setswana
        languageCodeMap!![LanguageCode.TN] = Locale("tn")

        /// Sindhi - Arabic
        languageCodeMap!![LanguageCode.SD_ARAB] = Locale("sd", "ARAB")

        /// Sinhala (Sri Lanka)
        languageCodeMap!![LanguageCode.SI_LK] = Locale("si", "LK")

        /// Slovak
        languageCodeMap!![LanguageCode.SK_SK] = Locale("sk", "SK")

        /// Slovenian
        languageCodeMap!![LanguageCode.SL_SI] = Locale("sl", "SI")

        /// Spanish (Mexico)
        languageCodeMap!![LanguageCode.ES_MX] = Locale("es", "MX")

        /// Spanish (Spain)
        languageCodeMap!![LanguageCode.ES_ES] = Locale("es", "ES")

        /// Swedish
        languageCodeMap!![LanguageCode.SV_SE] = Locale("sv", "SE")

        /// Tajik - Cyrillic
        languageCodeMap!![LanguageCode.TG_CYRL_TJ] = Locale("tg", "CYRL_TJ")

        /// Tamil
        languageCodeMap!![LanguageCode.TA] = Locale("ta")

        /// Tatar - Cyrillic (Russia)
        languageCodeMap!![LanguageCode.TT_CYRL_RU] = Locale("tt", "CYRL_RU")

        /// Telugu (India)
        languageCodeMap!![LanguageCode.TE_IN] = Locale("te", "IN")

        /// Thai
        languageCodeMap!![LanguageCode.TH_TH] = Locale("th", "TH")

        /// Tigrinya (Ethiopia)
        languageCodeMap!![LanguageCode.TI_ET] = Locale("ti", "ET")

        /// Turkish
        languageCodeMap!![LanguageCode.TR_TR] = Locale("tr", "TR")

        /// Turkmen - Latin
        languageCodeMap!![LanguageCode.TK_LATN_TM] = Locale("tk", "LATN_TM")

        /// Ukrainian
        languageCodeMap!![LanguageCode.UK_UA] = Locale("uk", "UA")

        /// Urdu
        languageCodeMap!![LanguageCode.UR] = Locale("ur")

        /// Uyghur - Arabic
        languageCodeMap!![LanguageCode.UG_ARAB] = Locale("ug", "ARAB")

        /// Uzbek - Cyrillic
        languageCodeMap!![LanguageCode.UZ_CYRL_UZ] = Locale("uz", "CYRL_UZ")

        /// Uzbek - Latin
        languageCodeMap!![LanguageCode.UZ_LATN_UZ] = Locale("uz", "LATN_UZ")

        /// Valencian (Spain)
        languageCodeMap!![LanguageCode.CAT_ES] = Locale("cat", "ES")

        /// Vietnamese
        languageCodeMap!![LanguageCode.VI_VN] = Locale("vi", "VN")

        /// Welsh
        languageCodeMap!![LanguageCode.CY_GB] = Locale("cy", "GB")

        /// Wolof - Latin
        languageCodeMap!![LanguageCode.WO_LATN] = Locale("wo", "LATN")

        /// Yoruba - Latin
        languageCodeMap!![LanguageCode.YO_LATN] = Locale("yo", "LATN")
    }
}
