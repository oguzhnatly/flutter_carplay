package com.oguzhnatly.flutter_carplay.models.button

import androidx.car.app.model.Action
import com.oguzhnatly.flutter_carplay.Bool
import com.oguzhnatly.flutter_carplay.CPBarButton
import com.oguzhnatly.flutter_carplay.CPBarButtonStyle
import com.oguzhnatly.flutter_carplay.FCPChannelTypes
import com.oguzhnatly.flutter_carplay.FCPStreamHandlerPlugin
import com.oguzhnatly.flutter_carplay.UIImage
import com.oguzhnatly.flutter_carplay.UIImageObject

/**
 * A wrapper class for CPBarButton with additional functionality.
 *
 * @param obj A dictionary containing information about the bar button.
 */
class FCPBarButton(obj: Map<String, Any>) {
    /// The underlying CPBarButton instance.
    private lateinit var _super: CPBarButton

    /// The unique identifier for the bar button.
    var elementId: String
        private set

    /// The image associated with the bar button (optional).
    private var image: UIImage? = null

    /// The title associated with the bar button (optional).
    private var title: String?

    /// The style of the bar button.
    private var style: CPBarButtonStyle

    /// The enabled state of the bar button.
    private var isEnabled: Bool

    init {
        val elementIdValue = obj["_elementId"] as? String
        assert(elementIdValue != null) { "Missing required keys in dictionary for FCPBarButton initialization." }
        elementId = elementIdValue!!
        title = obj["title"] as? String

        (obj["image"] as? String)?.let {
            image = UIImageObject.fromFlutterAsset(it)
        }
        isEnabled = obj["isEnabled"] as? Bool ?: true
        style =
            if (obj["style"] as? String == "none") CPBarButtonStyle.none else CPBarButtonStyle.rounded
    }

    /** Returns the underlying CPBarButton instance configured with the specified properties. */
    fun getTemplate(): CPBarButton {
        val action = Action.Builder().setEnabled(isEnabled)
            .setOnClickListener {
                // Dispatch an event when the bar button is pressed.
                FCPStreamHandlerPlugin.sendEvent(
                    type = FCPChannelTypes.onBarButtonPressed.name,
                    data = mapOf("elementId" to elementId)
                )
            }
        when {
            title != null -> action.setTitle(title!!)
            image != null -> action.setIcon(image!!)
            else -> {}
        }

        _super = action.build()
        return _super
    }
}
