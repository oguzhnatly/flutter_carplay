package com.oguzhnatly.flutter_carplay.models.button

import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.ParkedOnlyOnClickListener
import com.oguzhnatly.flutter_carplay.CPTextButton
import com.oguzhnatly.flutter_carplay.CPTextButtonStyle
import com.oguzhnatly.flutter_carplay.FCPChannelTypes
import com.oguzhnatly.flutter_carplay.FCPStreamHandlerPlugin

/**
 * A wrapper class for CPTextButton with additional functionality.
 *
 * @param obj A dictionary containing information about the text button.
 */
class FCPTextButton(obj: Map<String, Any>) {

    /// The underlying CPTextButton instance.
    private lateinit var _super: CPTextButton

    /// The unique identifier for the text button.
    var elementId: String
        private set

    /// The title associated with the text button.
    private var title: String

    /// The style of the text button.
    private var style: CPTextButtonStyle

    init {
        val elementIdValue = obj["_elementId"] as? String
        val titleValue = obj["title"] as? String
        assert(elementIdValue != null || titleValue != null) {
            "Missing required keys: _elementId, title"
        }

        elementId = elementIdValue!!
        title = titleValue!!

        val styleString = obj["style"] as? String ?: "normal"

        style = when (styleString) {
            "confirm" -> CPTextButtonStyle.confirm
            "cancel" -> CPTextButtonStyle.cancel
            else -> CPTextButtonStyle.normal
        }
    }

    /** Returns the underlying CPTextButton instance configured with the specified properties. */
    fun getTemplate(): CPTextButton {
        val onClick = {
            FCPStreamHandlerPlugin.sendEvent(
                type = FCPChannelTypes.onTextButtonPressed.name,
                data = mapOf("elementId" to elementId)
            )
        }
        val textButton = Action.Builder().setTitle(title)
            .setOnClickListener(ParkedOnlyOnClickListener.create(onClick))
        when (style) {
            CPTextButtonStyle.confirm -> textButton.setBackgroundColor(CarColor.BLUE)
            CPTextButtonStyle.cancel -> textButton.setBackgroundColor(CarColor.RED)
            else -> {}
        }

        _super = textButton.build()
        return _super
    }
}
