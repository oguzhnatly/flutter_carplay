package com.oguzhnatly.flutter_android_auto

data class FAAListItem(
    val elementId: String,
    val title: String,
    val subtitle: String? = null,
    val imageUrl: String? = null,
    val imageData: ByteArray? = null,
    val imageTint: FAAImageTint? = null,
    val isOnPressListenerActive: Boolean,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAListItem {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val subtitle = map["subtitle"] as? String
            val imageUrl = map["imageUrl"] as? String
            val imageData = map["imageData"] as? ByteArray
            val imageTint = FAAImageTint.fromJson(map["imageTint"] as? Map<String, Any?>)
            val isOnPressListenerActive = map["onPress"] as? Boolean ?: false

            return FAAListItem(
                elementId, title, subtitle, imageUrl, imageData, imageTint, isOnPressListenerActive
            )
        }
    }
}
