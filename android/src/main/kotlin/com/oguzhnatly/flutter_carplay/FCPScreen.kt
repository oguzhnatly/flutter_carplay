package com.oguzhnatly.flutter_carplay

import androidx.car.app.CarContext
import androidx.car.app.Screen

/**
 * Represents a CarPlay screen in the Flutter CarPlay plugin.
 *
 * This class extends the `Screen` class provided by the Car App library and is responsible for
 * rendering the CarPlay screen based on the provided template.
 *
 * @property carContext The CarContext used to create the screen.
 * @property fcpTemplate The FCPTemplate used to render the screen.
 */
class FCPScreen(carContext: CarContext, val fcpTemplate: FCPTemplate) : Screen(carContext) {

    init {
        fcpTemplate.onInvalidate = { invalidate() }
    }

    /**
     * Returns the template for this screen.
     *
     * @return The template for this screen.
     */
    override fun onGetTemplate(): CPTemplate {
        return fcpTemplate.getTemplate()
    }
}
