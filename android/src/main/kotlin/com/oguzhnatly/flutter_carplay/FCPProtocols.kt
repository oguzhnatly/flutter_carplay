package com.oguzhnatly.flutter_carplay

import androidx.car.app.CarContext
import androidx.car.app.Screen

/** Protocol representing a generic template in the Flutter CarPlay (FCP) framework. */
abstract class FCPTemplate(carContext: CarContext) : Screen(carContext) {
    /// The unique identifier for the template.
    lateinit var elementId: String
}

/** Protocol representing a root template in the Flutter CarPlay (FCP) framework. */
abstract class FCPRootTemplate(carContext: CarContext) : FCPTemplate(carContext)

/** Protocol representing a template that can be presented in the Flutter CarPlay (FCP) framework. */
abstract class FCPPresentTemplate(carContext: CarContext) : FCPTemplate(carContext)
