package com.oguzhnatly.flutter_android_auto

data class FAAListSection(
    val elementId: String,
    val title: String,
    val items: List<FAAListItem>,
    val selectedIndex: Int? = null,
    val isOnSelectedListenerActive: Boolean = false,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAListSection {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val items = (map["items"] as? List<*>)?.mapNotNull {
                (it as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                    ?.let { FAAListItem.fromJson(it) }
            } ?: emptyList()
            val selectedIndex = map["selectedIndex"] as? Int
            val isOnSelectedListenerActive =
                map["onSelected"] as? Boolean ?: false

            return FAAListSection(
                elementId, title, items, selectedIndex, isOnSelectedListenerActive
            )
        }
    }
}
