package com.oguzhnatly.flutter_carplay

import androidx.car.app.CarContext

/** Protocol representing a generic template in the Flutter CarPlay (FCP) framework. */
abstract class FCPTemplate {
    /// The unique identifier for the template.
    lateinit var elementId: String

    /// The unique identifier for the template's back button.
    var backButtonElementId: String? = null

    /// Update the template on UI.
    var onInvalidate: (() -> Unit) = {}

    /// Returns the underlying CPTemplate instance configured with the specified properties.
    abstract fun getTemplate(): CPTemplate
}

/** Protocol representing a root template in the Flutter CarPlay (FCP) framework. */
abstract class FCPRootTemplate : FCPTemplate()

/** Protocol representing a template that can be presented in the Flutter CarPlay (FCP) framework. */
abstract class FCPPresentTemplate : FCPTemplate()

/**
 * Converts the FCPTemplate to a FCPScreen.
 *
 * @param carContext the CarContext used to create the FCPScreen
 * @return the FCPScreen created from the FCPTemplate
 */
fun FCPTemplate.toScreen(carContext: CarContext) = FCPScreen(carContext, this)
