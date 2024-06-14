package com.oguzhnatly.flutter_carplay.models.action_sheet

import androidx.car.app.model.Action
import androidx.car.app.model.ActionStrip
import androidx.car.app.model.LongMessageTemplate
import com.oguzhnatly.flutter_carplay.CPActionSheetTemplate
import com.oguzhnatly.flutter_carplay.FCPPresentTemplate
import com.oguzhnatly.flutter_carplay.models.alert.FCPAlertAction

/**
 * A wrapper class for CPActionSheetTemplate with additional functionality.
 *
 * @param obj A map containing information about the action sheet template.
 */
class FCPActionSheetTemplate(obj: Map<String, Any>) : FCPPresentTemplate() {

    /// The underlying CPActionSheetTemplate instance.
    private lateinit var _super: CPActionSheetTemplate

    /// The title of the action sheet template (optional).
    private var title: String?

    /// The message of the action sheet template (optional).
    private var message: String?

    /// An array of CPAlertAction instances associated with the action sheet template.
    private var actions: List<Action>

    /// An array of FCPAlertAction instances associated with the action sheet template.
    private var objcActions: List<FCPAlertAction>

    init {
        val elementIdValue = obj["_elementId"] as? String
        assert(elementIdValue != null) {
            "Missing required key: _elementId"
        }
        elementId = elementIdValue!!

        title = obj["title"] as? String
        message = obj["message"] as? String

        objcActions = (obj["actions"] as? List<Map<String, Any>>)?.map {
            FCPAlertAction(it)
        } ?: emptyList()
        actions = objcActions.map { it.getTemplate() }
    }

    /** Returns the underlying CPActionSheetTemplate instance configured with the specified properties. */
    override fun getTemplate(): CPActionSheetTemplate {
        val actionSheetTemplate =
            LongMessageTemplate.Builder(message.toString()).setTitle(title.toString())
        objcActions.forEach {
            when (it.style) {
                CPAlertActionStyle.destructive, CPAlertActionStyle.cancel -> {
                    actionSheetTemplate.addAction(it.getTemplate())
                }

                else -> {
                    val actionStripBuilder = ActionStrip.Builder()
                    actionStripBuilder.addAction(it.getTemplate())
                    actionSheetTemplate.setActionStrip(actionStripBuilder.build())
                }
            }
        }
        _super = actionSheetTemplate.build()
        return _super
    }

}
