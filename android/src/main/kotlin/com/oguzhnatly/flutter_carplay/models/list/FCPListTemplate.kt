package com.oguzhnatly.flutter_carplay.models.list

import FCPListTemplateTypes
import androidx.car.app.CarContext
import androidx.car.app.model.ListTemplate
import com.oguzhnatly.flutter_carplay.Bool
import com.oguzhnatly.flutter_carplay.CPBarButton
import com.oguzhnatly.flutter_carplay.CPListSection
import com.oguzhnatly.flutter_carplay.CPListTemplate
import com.oguzhnatly.flutter_carplay.CPTemplate
import com.oguzhnatly.flutter_carplay.FCPRootTemplate
import com.oguzhnatly.flutter_carplay.models.button.FCPBarButton

/**
 * A wrapper class for CPListTemplate with additional functionality.
 *
 * @param obj A map containing information about the list template.
 * @param templateType The template type of the list template.
 */
class FCPListTemplate(
    carContext: CarContext,
    obj: Map<String, Any>,

    /// The template type of the list template.
    private var templateType: FCPListTemplateTypes
) : FCPRootTemplate(carContext) {

    /// The underlying CPListTemplate instance.
    private lateinit var _super: CPListTemplate

    /// The title text for the list template (optional).
    private var title: String?

    /// The system icon for the list template (optional).
    private var systemIcon: String?

    /// An array of CPListSection instances associated with the list template.
    private var sections: List<CPListSection>

    /// An array of FCPListSection instances associated with the list template.
    private var objcSections: List<FCPListSection>

    /// An array of title variants for the empty view.
    private var emptyViewTitleVariants: List<String>

    /// An array of subtitle variants for the empty view.
    private var emptyViewSubtitleVariants: List<String>

    /// Indicates whether the list template shows a tab badge.
    private var showsTabBadge: Bool

    /// Indicates whether the list template is loading.
    private var isLoading: Bool

    /// The back button associated with the list template (optional).
    private var objcBackButton: FCPBarButton? = null

    /// The underlying CPBarButton instance associated with the back button.
    private var backButton: CPBarButton? = null

    /// An array of leading navigation bar buttons for the list template.
    private var leadingNavigationBarButtons: List<FCPBarButton> = emptyList()

    /// An array of trailing navigation bar buttons for the list template.
    private var trailingNavigationBarButtons: List<FCPBarButton> = emptyList()

    init {
        val elementIdValue = obj["_elementId"] as? String?
        assert(elementIdValue != null) {
            "Missing required keys in dictionary for FCPListTemplate initialization."
        }
        elementId = elementIdValue!!
        title = obj["title"] as? String
        systemIcon = obj["systemIcon"] as? String
        emptyViewTitleVariants = obj["emptyViewTitleVariants"] as? List<String> ?: emptyList()
        emptyViewSubtitleVariants = obj["emptyViewSubtitleVariants"] as? List<String> ?: emptyList()
        showsTabBadge = obj["showsTabBadge"] as? Bool ?: false
        isLoading = obj["isLoading"] as? Bool ?: false
        objcSections =
            (obj["sections"] as? List<Map<String, Any>> ?: emptyList<FCPListSection>()).map {
                FCPListSection(it as Map<String, Any>)
            }
        sections = objcSections.map { it.getTemplate }
        //        if let backButtonData = obj ["backButton"] as? [ String : Any] {
        //            objcBackButton = FCPBarButton(obj: backButtonData)
        //            backButton = objcBackButton?.get
        //        }
        //        leadingNavigationBarButtons = (obj["leadingNavigationBarButtons"] as?
        // List<Map<String, Any>>
        //            ?: emptyList<FCPBarButton>()).map {
        //            FCPBarButton(it as Map<String, Any>)
        //        }
        //        trailingNavigationBarButtons =
        //            (obj["trailingNavigationBarButtons"] as? List<Map<String, Any>>
        //                ?: emptyList<FCPBarButton>()).map {
        //                FCPBarButton(it as Map<String, Any>)
        //            }
    }

    /// Returns the underlying CPListTemplate instance configured with the specified properties.
    val getTemplate: CPListTemplate
        get() {
            // Implementation details for returning CPListTemplate instance
            val listTemplate = ListTemplate.Builder().setTitle(title ?: "").setLoading(isLoading)
            sections.forEach { listTemplate.addSectionedList(it) }
            //        listTemplate.setFCPObject(self)
            //        listTemplate.emptyViewTitleVariants = emptyViewTitleVariants
            //        listTemplate.emptyViewSubtitleVariants = emptyViewSubtitleVariants
            //        listTemplate.showsTabBadge = showsTabBadge

            //        if let icon = systemIcon {
            //            listTemplate.tabImage = UIImage(systemName: icon)
            //        }

            //        if (templateType == FCPListTemplateTypes.DEFAULT) {
            //            listTemplate.backButton = backButton
            //        }

            //        var lBButtons: MutableList<CPBarButton> = mutableListOf()
            //        for (button in leadingNavigationBarButtons) {
            //            lBButtons.add(button.getTemplate)
            //        }
            //
            //        var tBButtons: MutableList<CPBarButton> = mutableListOf()
            //        for (button in trailingNavigationBarButtons) {
            //            tBButtons.add(button.getTemplate)
            //        }
            //        listTemplate.leadingNavigationBarButtons = lBButtons
            //        listTemplate.trailingNavigationBarButtons = tBButtons

            _super = listTemplate.build()
            return _super
        }

    /**
     * Retrieves an array of FCPListSection instances associated with the list template.
     *
     * @return An array of FCPListSection instances.
     */
    fun getSections(): List<FCPListSection> {
        return objcSections
    }

    /**
     * Updates the properties of the list template.
     *
     * @param emptyViewTitleVariants The new title variants for the empty view.
     * @param emptyViewSubtitleVariants The new subtitle variants for the empty view.
     * @param sections The new array of FCPListSection instances.
     * @param leadingNavigationBarButtons The new array of leading navigation bar buttons.
     * @param trailingNavigationBarButtons The new array of trailing navigation bar buttons.
     * @param isLoading The new loading state of the list template.
     */
    fun update(
        isLoading: Bool? = null,
        emptyViewTitleVariants: List<String>? = null,
        emptyViewSubtitleVariants: List<String>? = null,
        sections: List<FCPListSection>? = null,
        leadingNavigationBarButtons: List<FCPBarButton>? = null,
        trailingNavigationBarButtons: List<FCPBarButton>? = null
    ) {
        isLoading?.let { this.isLoading = it }
        emptyViewTitleVariants?.let { this.emptyViewTitleVariants = it }
        emptyViewSubtitleVariants?.let { this.emptyViewSubtitleVariants = it }
        leadingNavigationBarButtons?.let { this.leadingNavigationBarButtons = it }
        trailingNavigationBarButtons?.let { this.trailingNavigationBarButtons = it }
        sections?.let {
            objcSections = it
            this.sections = objcSections.map { section -> section.getTemplate }
        }

        invalidate()
    }

    override fun onGetTemplate(): CPTemplate {
        return getTemplate
    }
}
