package com.oguzhnatly.flutter_carplay.models.list

import androidx.car.app.model.ItemList
import androidx.car.app.model.SectionedItemList

/**
 * A wrapper class for CPListSection with additional functionality.
 *
 * @param obj A map containing information about the list section.
 */
class FCPListSection
    (obj: Map<String, Any>) {

    /// The underlying CPListSection instance.
    private lateinit var _super: SectionedItemList

    /// The unique identifier for the list section.
    var elementId: String
        private set

    /// The header text for the list section (optional).
    private var header: String

    /// An array of CPListTemplateItem instances associated with the list section.
    private lateinit var items: ItemList

    /// An array of FCPListItem instances associated with the list section.
    private var objcItems: List<FCPListItem>

    init {
        val elementIdValue = obj["_elementId"] as? String?
        assert(elementIdValue != null) { "Missing required keys in dictionary for FCPListSection initialization." }
        elementId = elementIdValue!!
        header = obj["header"] as? String ?: ""
        objcItems = (obj["items"] as? List<Map<String, Any>> ?: emptyList<FCPListItem>()).map {
            FCPListItem(it as Map<String, Any>)
        }
        val builder = ItemList.Builder()
        objcItems.forEach {
            builder.addItem(it.getTemplate)
        }
        items = builder.build()
    }


    /** Returns the underlying CPListSection instance configured with the specified properties. */
    val getTemplate: SectionedItemList
        get() {
            val listSection = SectionedItemList.create(items, header)
            _super = listSection
            return listSection
        }


    /**
     * Retrieves an array of FCPListItem instances associated with the list section.
     *
     * @return An array of FCPListItem instances.
     */
    fun getItems(): List<FCPListItem> {
        return objcItems
    }
}