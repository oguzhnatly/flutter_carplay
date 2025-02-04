package com.oguzhnatly.flutter_carplay.models.alert

import androidx.car.app.model.ActionStrip
import androidx.car.app.model.MessageTemplate
import com.oguzhnatly.flutter_carplay.CPAlertAction
import com.oguzhnatly.flutter_carplay.CPAlertActionStyle
import com.oguzhnatly.flutter_carplay.CPAlertTemplate
import com.oguzhnatly.flutter_carplay.FCPPresentTemplate

/**
 * A wrapper class for CPAlertTemplate with additional functionality.
 *
 * @param obj A map containing information about the alert template.
 */
class FCPAlertTemplate(obj: Map<String, Any>) : FCPPresentTemplate() {

    /// The underlying CPActionSheetTemplate instance.
    private lateinit var _super: CPAlertTemplate

    /// The title of the alert template (optional).
    private var titleVariants: List<String>?

    /// An array of CPAlertAction instances associated with the alert template.
    private var actions: List<CPAlertAction>

    /// An array of FCPAlertAction instances associated with the alert template.
    private var objcActions: List<FCPAlertAction>

    init {
        val elementIdValue = obj["_elementId"] as? String
        assert(elementIdValue != null) { "Missing required key: _elementId" }
        elementId = elementIdValue!!
        titleVariants = obj["titleVariants"] as? List<String>
        objcActions = (obj["actions"] as? List<Map<String, Any>>)?.map {
            FCPAlertAction(it)
        } ?: emptyList()
        actions = objcActions.map { it.getTemplate() }
    }

    /** Returns the underlying CPAlertTemplate instance configured with the specified properties. */
    override fun getTemplate(): CPAlertTemplate {
        val alertTemplate =
            MessageTemplate.Builder(titleVariants?.first() ?: "").setTitle(" ")
        objcActions.forEach {
            when (it.style) {
                CPAlertActionStyle.destructive, CPAlertActionStyle.cancel -> {
                    alertTemplate.addAction(it.getTemplate())
                }

                else -> {
                    val actionStripBuilder = ActionStrip.Builder()
                    actionStripBuilder.addAction(it.getTemplate())
                    alertTemplate.setActionStrip(actionStripBuilder.build())
                }
            }
        }
        _super = alertTemplate.build()
        return _super
    }

}
