package com.oguzhnatly.flutter_android_auto

data class FAAGridButton(
    val elementId: String,
    val titleVariants: List<String>,
    val image: String?,
    val imageData: ByteArray?,
    val loadingMessage: String?,
    val isOnPressListenerActive: Boolean,
) {
    val title: String get() = titleVariants.firstOrNull() ?: ""

    companion object {
        fun fromJson(map: Map<String, Any?>): FAAGridButton {
            val elementId = map["_elementId"] as? String ?: ""
            val titleVariants = (map["titleVariants"] as? List<*>)
                ?.filterIsInstance<String>() ?: emptyList()
            val image = map["image"] as? String
            val imageData = map["imageData"] as? ByteArray
            val loadingMessage = map["loadingMessage"] as? String
            val isOnPressListenerActive = map["onPress"] as? Boolean ?: false

            return FAAGridButton(
                elementId,
                titleVariants,
                image,
                imageData,
                loadingMessage,
                isOnPressListenerActive,
            )
        }
    }
}
