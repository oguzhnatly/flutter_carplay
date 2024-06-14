package com.oguzhnatly.flutter_carplay.models.alert

import CPAlertActionStyle
import android.graphics.Color
import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.CarIcon
import androidx.car.app.model.ParkedOnlyOnClickListener
import com.oguzhnatly.flutter_carplay.CPAlertAction
import com.oguzhnatly.flutter_carplay.FCPStreamHandlerPlugin

/**
 * Wrapper class for CPAlertAction with additional functionality.
 *
 * @param obj A map containing information about the alert action.
 */
class FCPAlertAction(obj: Map<String, Any>) {

    /// The underlying CPAlertAction instance.
    private lateinit var _super: CPAlertAction

    /// The unique identifier for the alert action.
    var elementId: String
        private set

    /// The title of the alert action.
    private var title: String

    /// The style of the alert action.
    var style: CPAlertActionStyle
        private set

    init {
        val elementIdValue = obj["_elementId"] as? String
        val titleValue = obj["title"] as? String

        assert(elementIdValue != null || titleValue != null) {
            "Missing required keys: _elementId, title"
        }

        elementId = elementIdValue!!
        title = titleValue!!

        val styleString = obj["style"] as? String ?: ""

        style = when (styleString) {
            "destructive" -> CPAlertActionStyle.destructive
            "cancel" -> CPAlertActionStyle.cancel
            else -> CPAlertActionStyle.normal
        }
    }

    /** Returns the underlying CPAlertAction instance configured with the specified properties. */
    fun getTemplate(): CPAlertAction {
        val onClick = {
            FCPStreamHandlerPlugin.sendEvent(
                type = FCPChannelTypes.onFCPAlertActionPressed.name,
                data = mapOf("elementId" to elementId)
            )
        }
        val alertAction = Action.Builder().setTitle(title)
            .setOnClickListener(ParkedOnlyOnClickListener.create(onClick))
        when (style) {
            CPAlertActionStyle.cancel -> alertAction.setBackgroundColor(CarColor.BLUE)
            CPAlertActionStyle.destructive -> alertAction.setBackgroundColor(CarColor.RED)
            else -> {}
        }

        _super = alertAction.build()
        return _super
    }
}
