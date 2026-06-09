package com.oguzhnatly.flutter_android_auto

data class FAAPaneTemplate(
    val elementId: String,
    val title: String,
    val items: List<FAAPaneItem>,
    val actions: List<FAAPaneAction>,
    val imageUrl: String? = null,
    val imageData: ByteArray? = null,
    val imageTint: FAAImageTint? = null,
    val isLoading: Boolean = false,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAPaneTemplate {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val items = (map["items"] as? List<*>)?.mapNotNull {
                (it as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                    ?.let { FAAPaneItem.fromJson(it) }
            } ?: emptyList()
            val actions = (map["actions"] as? List<*>)?.mapNotNull {
                (it as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                    ?.let { FAAPaneAction.fromJson(it) }
            } ?: emptyList()
            val imageUrl = map["imageUrl"] as? String
            val imageData = map["imageData"] as? ByteArray
            val imageTint = FAAImageTint.fromJson(map["imageTint"] as? Map<String, Any?>)
            val isLoading = map["isLoading"] as? Boolean ?: false

            return FAAPaneTemplate(
                elementId,
                title,
                items,
                actions,
                imageUrl,
                imageData,
                imageTint,
                isLoading,
            )
        }
    }
}
