package com.oguzhnatly.flutter_android_auto

data class FAAAlertTemplate(
    val elementId: String,
    val title: String,
    val message: String?,
    val actions: List<FAAAlertAction>,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAAlertTemplate {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val message = map["message"] as? String
            val actions = (map["actions"] as? List<*>)?.mapNotNull {
                (it as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                    ?.let { FAAAlertAction.fromJson(it) }
            } ?: emptyList()
            return FAAAlertTemplate(elementId, title, message, actions)
        }
    }
}
