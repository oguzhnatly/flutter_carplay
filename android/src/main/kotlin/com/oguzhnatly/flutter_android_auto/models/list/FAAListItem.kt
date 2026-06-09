package com.oguzhnatly.flutter_android_auto

data class FAAListItem(
    val elementId: String,
    val title: String,
    val subtitle: String? = null,
    val imageUrl: String? = null,
    val imageData: ByteArray? = null,
    val imageTint: FAAImageTint? = null,
    val trailingImage: String? = null,
    val trailingImageData: ByteArray? = null,
    val trailingImageTint: FAAImageTint? = null,
    val loadingMessage: String? = null,
    val isBrowsable: Boolean? = null,
    val toggle: FAAToggle? = null,
    val isOnPressListenerActive: Boolean,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAListItem {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val subtitle = map["subtitle"] as? String
            val imageUrl = map["imageUrl"] as? String ?: map["image"] as? String
            val imageData = map["imageData"] as? ByteArray
            val imageTint = FAAImageTint.fromJson(map["imageTint"] as? Map<String, Any?>)
            val trailingImage = map["trailingImage"] as? String
            val trailingImageData = map["trailingImageData"] as? ByteArray
            val trailingImageTint =
                FAAImageTint.fromJson(map["trailingImageTint"] as? Map<String, Any?>)
            val loadingMessage = map["loadingMessage"] as? String
            val isBrowsable = map["isBrowsable"] as? Boolean
            val toggle = (map["toggle"] as? Map<*, *>)?.mapKeys { entry ->
                entry.key.toString()
            }?.let { FAAToggle.fromJson(it) }
            val isOnPressListenerActive = map["onPress"] as? Boolean ?: false

            return FAAListItem(
                elementId,
                title,
                subtitle,
                imageUrl,
                imageData,
                imageTint,
                trailingImage,
                trailingImageData,
                trailingImageTint,
                loadingMessage,
                isBrowsable,
                toggle,
                isOnPressListenerActive,
            )
        }
    }
}

data class FAAToggle(
    val isChecked: Boolean = false,
    val isEnabled: Boolean? = null,
    val isOnCheckedChangeListenerActive: Boolean = false,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAToggle {
            val isChecked = map["isChecked"] as? Boolean ?: false
            val isEnabled = map["isEnabled"] as? Boolean
            val isOnCheckedChangeListenerActive =
                map["onCheckedChange"] as? Boolean ?: false

            return FAAToggle(
                isChecked, isEnabled, isOnCheckedChangeListenerActive
            )
        }
    }
}
