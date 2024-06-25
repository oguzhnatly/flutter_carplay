package com.oguzhnatly.flutter_carplay

import androidx.car.app.model.MessageTemplate

/**
 * A class representing the root template in the Flutter CarPlay plugin.
 *
 * @param carContext The car context used to create the template.
 */
class RootTemplate : FCPRootTemplate() {

    init {
        elementId = "rootTemplate"
    }

    override fun getTemplate(): CPTemplate {
        return MessageTemplate.Builder("Loading...").setLoading(true).build()
    }

}
