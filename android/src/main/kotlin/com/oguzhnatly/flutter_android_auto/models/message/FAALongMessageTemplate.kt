package com.oguzhnatly.flutter_android_auto

data class FAALongMessageTemplate(
    val elementId: String,
    val title: String,
    val message: String,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAALongMessageTemplate {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val message = map["message"] as? String ?: ""

            return FAALongMessageTemplate(elementId, title, message)
        }
    }
}
