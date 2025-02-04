package com.oguzhnatly.flutter_carplay.models.grid

import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ItemList
import com.oguzhnatly.flutter_carplay.CPGridTemplate
import com.oguzhnatly.flutter_carplay.FCPRootTemplate

/**
 * A wrapper class for CPGridTemplate with additional functionality.
 *
 * @param obj A dictionary containing information about the grid template.
 */
class FCPGridTemplate(obj: Map<String, Any>) : FCPRootTemplate() {

    /// The underlying CPGridTemplate instance.
    private lateinit var _super: CPGridTemplate

    /// The title of the grid template.
    private var title: String

    /// An array of CPGridButton instances associated with the grid template.
    private var buttons: ItemList

    /// An array of FCPGridButton instances associated with the grid template.
    private var objcButtons: List<FCPGridButton>


    init {
        val elementIdValue = obj["_elementId"] as? String
        val titleValue = obj["title"] as? String
        val buttonsData = obj["buttons"] as? List<Map<String, Any>>
        assert(elementIdValue != null && titleValue != null && buttonsData != null) {
            "Missing required keys in dictionary for FCPGridTemplate initialization."
        }
        elementId = elementIdValue!!
        title = titleValue!!

        objcButtons = buttonsData!!.map {
            FCPGridButton(it)
        }

        val builder = ItemList.Builder()
        objcButtons.forEach {
            builder.addItem(it.getTemplate())
        }
        buttons = builder.build()
    }


    /** Returns the underlying CPGridTemplate instance configured with the specified properties. */
    override fun getTemplate(): CPGridTemplate {
        val gridTemplate = GridTemplate.Builder().setTitle(title).setSingleList(buttons)
        _super = gridTemplate.build()
        return _super
    }
}
