package com.oguzhnatly.flutter_carplay.models.map

import androidx.car.app.model.Action
import com.oguzhnatly.flutter_carplay.Bool
import com.oguzhnatly.flutter_carplay.CPMapButton
import com.oguzhnatly.flutter_carplay.FCPChannelTypes
import com.oguzhnatly.flutter_carplay.FCPStreamHandlerPlugin
import com.oguzhnatly.flutter_carplay.UIImage
import com.oguzhnatly.flutter_carplay.UIImageObject
import com.oguzhnatly.flutter_carplay.withColor

/**
 * A wrapper class for CPMapButton with additional functionality.
 *
 * @param obj A dictionary containing information about the map button.
 */
class FCPMapButton(obj: Map<String, Any>) {
    /// The underlying CPMapButton instance.
    private lateinit var _super: CPMapButton

    /// The unique identifier for the map button.
    var elementId: String
        private set

    /// A Boolean value indicating whether the map button is enabled.
    private var isEnabled: Bool

    /// A Boolean value indicating whether the map button is hidden.
    private var isHidden: Bool

    /// The image associated with the map button.
    private var image: UIImage?

    /// The focused image associated with the map button.
    private var focusedImage: UIImage?

    init {
        val elementIdValue = obj["_elementId"] as? String
        assert(elementIdValue != null) {
            "Missing required keys in dictionary for FCPMapButton initialization."
        }
        elementId = elementIdValue!!
        isEnabled = obj["isEnabled"] as? Bool ?: true
        isHidden = obj["isHidden"] as? Bool ?: false
        image = (obj["focusedImage"] as? String)?.let { UIImageObject.fromFlutterAsset(it) }
        focusedImage =
            (obj["focusedImage"] as? String)?.let { UIImageObject.fromFlutterAsset(it) }

        //        image = UIImage.dynamicImage(lightImage: obj["image"] as? String,
        //            darkImage: obj["darkImage"] as? String)

        (obj["tintColor"] as? Long)?.let {
            image = image?.withColor(color = it)
        }
    }

    /** Returns the underlying CPMapButton instance configured with the specified properties. */
    fun getTemplate(): CPMapButton {
        val action =
            Action.Builder().setEnabled(isEnabled).setIcon(image!!)
                .setOnClickListener {
                    // Dispatch an event when the bar button is pressed.
                    FCPStreamHandlerPlugin.sendEvent(
                        type = FCPChannelTypes.onMapButtonPressed.name,
                        data = mapOf("elementId" to elementId)
                    )
                }

        //        mapButton.isHidden = isHidden
        //        mapButton.isEnabled = isEnabled
        //        mapButton.focusedImage = focusedImage
        //        mapButton.image = image

        _super = action.build()
        return _super
    }
}
