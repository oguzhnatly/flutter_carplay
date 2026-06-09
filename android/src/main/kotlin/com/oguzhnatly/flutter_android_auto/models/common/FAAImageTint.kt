package com.oguzhnatly.flutter_android_auto

import android.graphics.Color
import androidx.car.app.model.CarColor
import kotlin.math.roundToInt

data class FAAImageTint(
    val type: String,
    val color: FAAColor? = null,
    val darkColor: FAAColor? = null,
    val selectedSafe: Boolean = true,
) {
    fun toCarColor(): CarColor {
        return when (type) {
            "platform" -> CarColor.DEFAULT
            "primary" -> CarColor.PRIMARY
            "secondary" -> CarColor.SECONDARY
            "red" -> CarColor.RED
            "green" -> CarColor.GREEN
            "blue" -> CarColor.BLUE
            "yellow" -> CarColor.YELLOW
            "custom" -> {
                val lightColor = color?.toColorInt() ?: Color.WHITE
                val darkColor = darkColor?.toColorInt() ?: lightColor
                CarColor.createCustom(lightColor, darkColor)
            }
            else -> CarColor.DEFAULT
        }
    }

    companion object {
        fun fromJson(map: Map<String, Any?>?): FAAImageTint? {
            if (map == null) return null
            val type = map["type"] as? String ?: return null
            return FAAImageTint(
                type = type,
                color = FAAColor.fromJson(map["color"] as? Map<String, Any?>),
                darkColor = FAAColor.fromJson(map["darkColor"] as? Map<String, Any?>),
                selectedSafe = map["selectedSafe"] as? Boolean ?: true,
            )
        }
    }
}

data class FAAColor(
    val red: Int,
    val green: Int,
    val blue: Int,
    val alpha: Double = 1.0,
) {
    fun toColorInt(): Int {
        val alphaInt = if (alpha > 1) alpha.roundToInt() else (alpha * 255).roundToInt()
        return Color.argb(
            alphaInt.coerceIn(0, 255),
            red.coerceIn(0, 255),
            green.coerceIn(0, 255),
            blue.coerceIn(0, 255),
        )
    }

    companion object {
        fun fromJson(map: Map<String, Any?>?): FAAColor? {
            if (map == null) return null
            val red = numberValue(map["red"])?.roundToInt() ?: return null
            val green = numberValue(map["green"])?.roundToInt() ?: return null
            val blue = numberValue(map["blue"])?.roundToInt() ?: return null
            val alpha = numberValue(map["alpha"]) ?: 1.0
            return FAAColor(red, green, blue, alpha)
        }

        private fun numberValue(value: Any?): Double? {
            return when (value) {
                is Number -> value.toDouble()
                else -> null
            }
        }
    }
}
