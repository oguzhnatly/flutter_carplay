package com.oguzhnatly.flutter_carplay.models.information

import androidx.car.app.model.Row
import com.oguzhnatly.flutter_carplay.CPInformationItem

/**
 * A wrapper class for CPInformationItem with additional functionality.
 *
 * @param obj A dictionary containing information about the information item.
 */
class FCPInformationItem(obj: Map<String, Any>) {

    /// The underlying CPInformationItem instance.
    private lateinit var _super: CPInformationItem

    /// The unique identifier for the information item.
    var elementId: String
        private set

    /// The title of the information item (optional).
    private var title: String?

    /// The detail text of the information item (optional).
    private var detail: String?

    init {
        val elementIdValue = obj["_elementId"] as? String
        assert(elementIdValue != null) {
            "Missing required key: _elementId"
        }

        elementId = elementIdValue!!
        title = obj["title"] as? String
        detail = obj["detail"] as? String
    }

    /** Returns the underlying CPInformationItem instance configured with the specified properties. */
    fun getTemplate(): CPInformationItem {
        val informationItem = Row.Builder().setTitle(title!!).addText(detail!!)
        _super = informationItem.build()
        return _super
    }
}
