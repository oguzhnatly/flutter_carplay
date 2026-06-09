package com.oguzhnatly.flutter_android_auto

data class FAAPaneItem(
    val elementId: String,
    val title: String,
    val detail: String? = null,
    val imageUrl: String? = null,
    val imageData: ByteArray? = null,
    val imageTint: FAAImageTint? = null,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAPaneItem {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val detail = map["detail"] as? String
            val imageUrl = map["imageUrl"] as? String
            val imageData = map["imageData"] as? ByteArray
            val imageTint = FAAImageTint.fromJson(map["imageTint"] as? Map<String, Any?>)

            return FAAPaneItem(elementId, title, detail, imageUrl, imageData, imageTint)
        }
    }
}
