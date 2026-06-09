package com.oguzhnatly.flutter_android_auto

data class FAAPaneAction(
    val elementId: String,
    val title: String,
    val imageUrl: String? = null,
    val imageData: ByteArray? = null,
    val imageTint: FAAImageTint? = null,
    val isPrimary: Boolean = false,
    val isOnPressListenerActive: Boolean = false,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAPaneAction {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val imageUrl = map["imageUrl"] as? String
            val imageData = map["imageData"] as? ByteArray
            val imageTint = FAAImageTint.fromJson(map["imageTint"] as? Map<String, Any?>)
            val isPrimary = map["isPrimary"] as? Boolean ?: false
            val isOnPressListenerActive = map["onPress"] as? Boolean ?: false

            return FAAPaneAction(
                elementId,
                title,
                imageUrl,
                imageData,
                imageTint,
                isPrimary,
                isOnPressListenerActive,
            )
        }
    }
}
