package com.oguzhnatly.flutter_carplay.models.grid

import androidx.car.app.model.GridItem
import com.oguzhnatly.flutter_carplay.CPGridButton
import com.oguzhnatly.flutter_carplay.FCPChannelTypes
import com.oguzhnatly.flutter_carplay.FCPStreamHandlerPlugin
import com.oguzhnatly.flutter_carplay.UIImage
import com.oguzhnatly.flutter_carplay.UIImageObject

/**
 * A wrapper class for CPGridButton with additional functionality.
 *
 * @param obj A dictionary containing information about the grid button.
 */
class FCPGridButton(obj: Map<String, Any>) {

    /// The underlying CPGridButton instance.
    private lateinit var _super: CPGridButton

    /// The unique identifier for the grid button.
    var elementId: String
        private set

    /// An array of title variants for the grid button.
    private var titleVariants: List<String>

    /// The image associated with the grid button.
    private var image: UIImage

    init {
        val elementIdValue = obj["_elementId"] as? String
        val titleVariantsValue = obj["titleVariants"] as? List<String>
        val imageValue = obj["image"] as? String
        assert(elementIdValue != null && titleVariantsValue != null || imageValue != null) {
            "Missing required keys in dictionary for FCPGridButton initialization."
        }
        elementId = elementIdValue!!
        titleVariants = titleVariantsValue!!
        image = UIImageObject.fromFlutterAsset(imageValue!!)
    }

    /** Returns the underlying CPGridButton instance configured with the specified properties. */
    fun getTemplate(): CPGridButton {
        val gridButton =
            GridItem.Builder().setImage(image)
                .setOnClickListener {
                    // Dispatch an event when the grid button is pressed.
                    FCPStreamHandlerPlugin.sendEvent(
                        type = FCPChannelTypes.onGridButtonPressed.name,
                        data = mapOf("elementId" to elementId)
                    )
                }

        titleVariants.forEach { gridButton.setTitle(it) }

        _super = gridButton.build()
        return _super
    }
}
