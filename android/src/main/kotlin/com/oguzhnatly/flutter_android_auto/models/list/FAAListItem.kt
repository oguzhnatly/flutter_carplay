package com.oguzhnatly.flutter_android_auto

data class FAAListItem(
    val elementId: String,
    val title: String,
    val subtitle: String? = null,
    val image: String? = null,
    val isOnPressListenerActive: Boolean,
    val loadingMessage: String? = null,
    val onPressTimeoutMs: Long? = null,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAListItem {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val subtitle = map["subtitle"] as? String
            val image = map["image"] as? String
            val isOnPressListenerActive = map["onPress"] as? Boolean ?: false
            val loadingMessage = map["loadingMessage"] as? String
            val onPressTimeoutMs = (map["onPressTimeout"] as? Int)
                ?.takeIf { it >= 1 }
                ?.let { it.toLong() * 1_000L }

            return FAAListItem(
                elementId, title, subtitle, image, isOnPressListenerActive,
                loadingMessage, onPressTimeoutMs,
            )
        }
    }
}
