package com.oguzhnatly.flutter_android_auto

data class FAAMessageTemplate(
    val elementId: String,
    val title: String,
    val message: String,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAMessageTemplate {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val message = map["message"] as? String ?: ""

            return FAAMessageTemplate(elementId, title, message)
        }
    }
}
