package com.oguzhnatly.flutter_android_auto

data class FAATabBarItem(
    val elementId: String,
    val runtimeType: String,
    val templateData: Map<String, Any?>,
    val tabTitle: String,
    val systemIcon: String?,
    val iconUrl: String?,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAATabBarItem {
            val elementId = map["elementId"] as? String ?: ""
            val runtimeType = map["runtimeType"] as? String ?: ""
            val templateData = (map["template"] as? Map<*, *>)
                ?.mapKeys { it.key.toString() } ?: emptyMap()
            val tabTitle = (templateData["tabTitle"] as? String)
                ?: (templateData["title"] as? String)
                ?: ""
            val systemIcon = templateData["systemIcon"] as? String
            val iconUrl = templateData["iconUrl"] as? String

            return FAATabBarItem(elementId, runtimeType, templateData, tabTitle, systemIcon, iconUrl)
        }
    }
}
