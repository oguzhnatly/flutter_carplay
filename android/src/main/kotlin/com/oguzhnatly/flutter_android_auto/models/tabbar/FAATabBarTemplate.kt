package com.oguzhnatly.flutter_android_auto

data class FAATabBarTemplate(
    val elementId: String,
    val tabs: List<FAATabBarItem>,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAATabBarTemplate {
            val elementId = map["_elementId"] as? String ?: ""
            val tabs = (map["tabs"] as? List<*>)?.mapNotNull {
                (it as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                    ?.let { FAATabBarItem.fromJson(it) }
            } ?: emptyList()
            return FAATabBarTemplate(elementId, tabs)
        }
    }
}
