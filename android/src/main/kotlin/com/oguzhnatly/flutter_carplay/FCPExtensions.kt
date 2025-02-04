package com.oguzhnatly.flutter_carplay

import androidx.car.app.model.CarColor
import androidx.car.app.model.CarIcon

/**
 * Applies a color tint to the UIImage and returns a new UIImage with the tint applied.
 *
 * @param color The color to apply as a tint.
 * @param colorDark The dark color to apply as a tint (optional).
 * @return A new UIImage with the color tint applied.
 */
fun UIImage.withColor(color: Long, colorDark: Long? = null): UIImage {
    return CarIcon.Builder(this).setTint(
        CarColor.createCustom(color.toInt(), (colorDark ?: color).toInt())
    ).build()
}
