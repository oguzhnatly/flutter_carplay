package com.oguzhnatly.flutter_android_auto

data class FAAListTemplate(
    val elementId: String,
    val title: String,
    val sections: List<FAAListSection>,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAListTemplate {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val sections = (map["sections"] as? List<*>)?.mapNotNull {
                (it as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                    ?.let { FAAListSection.fromJson(it) }
            } ?: emptyList()

            return FAAListTemplate(elementId, title, sections)
        }
    }
}
