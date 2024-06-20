package com.oguzhnatly.flutter_carplay.models.information

import com.oguzhnatly.flutter_carplay.models.button.FCPTextButton
import androidx.car.app.model.Action
import androidx.car.app.model.ActionStrip
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import com.oguzhnatly.flutter_carplay.CPBarButton
import com.oguzhnatly.flutter_carplay.CPInformationItem
import com.oguzhnatly.flutter_carplay.CPInformationTemplate
import com.oguzhnatly.flutter_carplay.CPTextButton
import com.oguzhnatly.flutter_carplay.FCPRootTemplate
import com.oguzhnatly.flutter_carplay.models.button.FCPBarButton

/**
 * A wrapper class for FCPInformationTemplate with additional functionality.
 *
 * @param obj A dictionary containing information about the information template.
 */
class FCPInformationTemplate(obj: Map<String, Any>) : FCPRootTemplate() {

    /// The underlying CPInformationTemplate instance.
    private lateinit var _super: CPInformationTemplate

    /// The layout style of the information template.
    //private var layout: CPInformationTemplateLayout

    /// The title of the information template.
    private var title: String?

    /// An array of CPInformationItem instances associated with the information template.
    private var informationItems: List<CPInformationItem>

    /// An array of FCPInformationItem instances associated with the information template.
    private var objcInformationItems: List<FCPInformationItem>

    /// An array of CPTextButton instances associated with the information template.
    private var actions: List<CPTextButton>

    /// An array of FCPTextButton instances associated with the information template.
    private var objcActions: List<FCPTextButton>

    /// The back button associated with the list template (optional).
    private var objcBackButton: FCPBarButton? = null

    /// The underlying CPBarButton instance associated with the back button.
    private var backButton: CPBarButton? = null

    /// An array of leading navigation bar buttons for the list template.
    private var leadingNavigationBarButtons: List<FCPBarButton>

    /// An array of trailing navigation bar buttons for the list template.
    private var trailingNavigationBarButtons: List<FCPBarButton>

    init {
        val elementIdValue = obj["_elementId"] as? String
        //let layoutStringValue = obj["layout"] as? String,
        val titleValue = obj["title"] as? String
        assert(elementIdValue != null || titleValue != null) {
            "Missing required keys for FCPInformationTemplate initialization."
        }

        val informationItemsData = obj["informationItems"] as? List<Map<String, Any>>
        val actionsData = obj["actions"] as? List<Map<String, Any>>

        elementId = elementIdValue!!
        //layout = layoutStringValue == "twoColumn" ? CPInformationTemplateLayout.twoColumn : CPInformationTemplateLayout.leading
        title = titleValue

        objcInformationItems = informationItemsData?.map {
            FCPInformationItem(it)
        } ?: emptyList()
        informationItems = objcInformationItems.map {
            it.getTemplate()
        }

        objcActions = actionsData?.map {
            FCPTextButton(it)
        } ?: emptyList()
        actions = objcActions.map {
            it.getTemplate()
        }

        (obj["backButton"] as? Map<String, Any>)?.let {
            objcBackButton = FCPBarButton(it)
            backButtonElementId = objcBackButton?.elementId
            backButton = Action.Builder(Action.BACK).setEnabled(false).build()
        }
        leadingNavigationBarButtons =
            (obj["leadingNavigationBarButtons"] as? List<Map<String, Any>>)?.map {
                FCPBarButton(it)
            }
                ?: emptyList()
        trailingNavigationBarButtons =
            (obj["trailingNavigationBarButtons"] as? List<Map<String, Any>>)?.map {
                FCPBarButton(it)
            }
                ?: emptyList()
    }

    /** Returns the underlying CPInformationTemplate instance configured with the specified properties. */
    override fun getTemplate(): CPInformationTemplate {
        val paneBuilder = Pane.Builder()
        informationItems.forEach {
            paneBuilder.addRow(it)
        }
        actions.forEach {
            paneBuilder.addAction(it)
        }
        val informationTemplate = PaneTemplate.Builder(paneBuilder.build())
        informationTemplate.setTitle(title!!)

        //backButton?.let { informationTemplate.setHeaderAction(it) }
        informationTemplate.setHeaderAction(Action.Builder(Action.BACK).setEnabled(false).build())

        if (leadingNavigationBarButtons.isNotEmpty() || trailingNavigationBarButtons.isNotEmpty()) {
            val actionStrip = ActionStrip.Builder()
            for (button in leadingNavigationBarButtons) {
                actionStrip.addAction(button.getTemplate())
            }
            for (button in trailingNavigationBarButtons) {
                actionStrip.addAction(button.getTemplate())
            }
            informationTemplate.setActionStrip(actionStrip.build())
        }

        _super = informationTemplate.build()
        return _super
    }

    /**
     * Updates the properties of the information template.
     *
     *   @param items The new array of FCPInformationItem instances.
     *   @param actions The new array of FCPTextButton instances.
     *   @param leadingNavigationBarButtons The new array of leading navigation bar buttons.
     *   @param trailingNavigationBarButtons The new array of trailing navigation bar buttons.
     */
    fun update(
        items: List<FCPInformationItem>? = null,
        actions: List<FCPTextButton>? = null,
        leadingNavigationBarButtons: List<FCPBarButton>? = null,
        trailingNavigationBarButtons: List<FCPBarButton>? = null
    ) {
        items?.let {
            objcInformationItems = it
            informationItems = objcInformationItems.map { it1 -> it1.getTemplate() }
        }

        actions?.let {
            objcActions = actions
            this.actions = objcActions.map { it.getTemplate() }
        }

        leadingNavigationBarButtons?.let {
            this.leadingNavigationBarButtons = leadingNavigationBarButtons
            // _super.leadingNavigationBarButtons = leadingNavigationBarButtons.map { $0.get }
        }

        trailingNavigationBarButtons?.let {
            this.trailingNavigationBarButtons = trailingNavigationBarButtons
            //_super?.trailingNavigationBarButtons = trailingNavigationBarButtons.map { $0.get }
        }
        onInvalidate()
    }
}
