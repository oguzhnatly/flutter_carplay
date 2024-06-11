package com.oguzhnatly.flutter_carplay

import androidx.car.app.CarContext
import androidx.car.app.model.MessageTemplate

/**
 * A class representing the root template in the Flutter CarPlay plugin.
 *
 * @param carContext The car context used to create the template.
 */
class RootTemplate(carContext: CarContext) : FCPRootTemplate(carContext) {

    init {
        elementId = "rootTemplate"
    }

    override fun onGetTemplate(): CPTemplate {
        return MessageTemplate.Builder("Loading...").build()
    }
}
