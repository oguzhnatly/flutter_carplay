package com.oguzhnatly.flutter_android_auto

data class FAAAlertAction(
    val elementId: String,
    val title: String,
    val style: String,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAAlertAction {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val style = map["style"] as? String ?: "normal"
            return FAAAlertAction(elementId, title, style)
        }
    }
}
