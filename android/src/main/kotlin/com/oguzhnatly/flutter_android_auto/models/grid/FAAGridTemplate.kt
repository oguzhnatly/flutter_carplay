package com.oguzhnatly.flutter_android_auto

data class FAAGridTemplate(
    val elementId: String,
    val title: String,
    val buttons: List<FAAGridButton>,
    val emptyViewTitleVariants: List<String>,
) {
    companion object {
        fun fromJson(map: Map<String, Any?>): FAAGridTemplate {
            val elementId = map["_elementId"] as? String ?: ""
            val title = map["title"] as? String ?: ""
            val buttons = (map["buttons"] as? List<*>)?.mapNotNull {
                (it as? Map<*, *>)
                    ?.mapKeys { entry -> entry.key.toString() }
                    ?.let { btn -> FAAGridButton.fromJson(btn) }
            } ?: emptyList()
            val emptyViewTitleVariants = (map["emptyViewTitleVariants"] as? List<*>)
                ?.filterIsInstance<String>() ?: emptyList()

            return FAAGridTemplate(elementId, title, buttons, emptyViewTitleVariants)
        }
    }
}
