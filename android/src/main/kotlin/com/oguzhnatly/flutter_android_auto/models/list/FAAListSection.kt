package com.oguzhnatly.flutter_android_auto

data class FAAListSection(
    val elementId: String,
    val title: String,
    val items: List<FAAListItem>,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAListSection {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val items = (map["items"] as? List<*>)?.mapNotNull {
                (it as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                    ?.let { FAAListItem.fromJson(it) }
            } ?: emptyList()

            return FAAListSection(elementId, title, items)
        }
    }
}
