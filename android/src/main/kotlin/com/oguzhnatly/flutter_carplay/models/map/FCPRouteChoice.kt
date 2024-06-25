package com.oguzhnatly.flutter_carplay.models.map

import androidx.car.app.navigation.model.Destination
import com.oguzhnatly.flutter_carplay.CPRouteChoice

/** A wrapper class for CPRouteChoice with additional functionality.
 *
 * @param obj A dictionary containing information about the route choice.
 */
class FCPRouteChoice(obj: Map<String, Any>) {
    /// The underlying CPRouteChoice instance.
    private lateinit var _super: CPRouteChoice

    /// The unique identifier for the bar button.
    var elementId: String
        private set

    /// The array of summary variants for this route choice
    private var summaryVariants: List<String>

    /// The array of selection summary variants
    /// for this route choice
    private var selectionSummaryVariants: List<String>

    /// The array of additional information variants for this route choice
    private var additionalInformationVariants: List<String>

    init {
        val elementIdValue = obj["_elementId"] as? String
        assert(elementIdValue != null) {
            "Missing required keys in dictionary for FCPRouteChoice initialization."
        }
        elementId = elementIdValue!!
        summaryVariants = obj["summaryVariants"] as? List<String> ?: emptyList()
        selectionSummaryVariants = obj["selectionSummaryVariants"] as? List<String> ?: emptyList()
        additionalInformationVariants =
            obj["additionalInformationVariants"] as? List<String> ?: emptyList()
    }

    /** Get the underlying CPRouteChoice */
    fun getTemplate(): CPRouteChoice {
        val route = Destination.Builder()
        if (summaryVariants.isNotEmpty()) {
            route.setName(summaryVariants.first())
        }

        if (additionalInformationVariants.isNotEmpty()) {
            route.setAddress(additionalInformationVariants.first())
        }

        _super = route.build()
        return _super
    }
}
