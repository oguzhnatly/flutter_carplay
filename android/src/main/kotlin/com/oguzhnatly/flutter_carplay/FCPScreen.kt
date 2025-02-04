package com.oguzhnatly.flutter_carplay

import androidx.activity.OnBackPressedCallback
import androidx.car.app.CarContext
import androidx.car.app.Screen
import com.oguzhnatly.flutter_carplay.models.information.FCPInformationTemplate

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
    /** The OnBackPressedCallback used to handle the back button press. */
    private val onBackPressedCallback = object : OnBackPressedCallback(true) {
        override fun handleOnBackPressed() {
            when (fcpTemplate) {
                is FCPInformationTemplate -> {
                    AndroidAutoService.session?.pop()
                }

                is FCPPresentTemplate -> {
                    AndroidAutoService.session?.pop()
                }

                else -> {
                    // Handle the back button press from dart side
                    fcpTemplate.backButtonElementId?.let {
                        FCPStreamHandlerPlugin.sendEvent(
                            type = FCPChannelTypes.onBarButtonPressed.name,
                            data = mapOf("elementId" to it)
                        )
                    }
                }
            }
        }
    }

    init {
        carContext.onBackPressedDispatcher.addCallback(this, onBackPressedCallback)
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
