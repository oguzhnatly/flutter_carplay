package com.oguzhnatly.flutter_carplay.models.map

import androidx.car.app.model.DateTimeWithZone
import androidx.car.app.model.Distance
import androidx.car.app.navigation.model.TravelEstimate
import androidx.car.app.navigation.model.Trip
import com.oguzhnatly.flutter_carplay.CPTrip
import java.util.TimeZone

/** A wrapper class for CPTrip with additional functionality.
 *
 * @param obj A dictionary containing information about the trip.
 */
class FCPTrip(obj: Map<String, Any>) {
    /// The underlying CPTrip instance.
    private lateinit var _super: CPTrip

    /// The unique identifier for the bar button.
    var elementId: String
        private set

    // The origin and destination
    var origin: FMKMapItem
    var destination: FMKMapItem

    // The route choices
    var routeChoices: List<FCPRouteChoice>

    init {
        val elementIdValue = obj["_elementId"] as? String
        val originValue = obj["origin"] as? Map<String, Any>
        val destinationValue = obj["destination"] as? Map<String, Any>
        assert(elementIdValue != null && originValue != null && destinationValue != null) {
            "Missing required keys in dictionary for FCPTrip initialization."
        }
        elementId = elementIdValue!!
        origin = FMKMapItem(originValue!!)
        destination = FMKMapItem(destinationValue!!)
        routeChoices = (obj["routeChoices"] as? List<Map<String, Any>>)?.map {
            FCPRouteChoice(it)
        } ?: emptyList()
    }

    /** Returns the CPTrip instance. */
    fun getTemplate(): CPTrip {
        val trip = Trip.Builder()
        val estimate = TravelEstimate.Builder(
            Distance.create(0.0, Distance.UNIT_METERS),
            DateTimeWithZone.create(0, TimeZone.getDefault())
        ).build()

        for (route in routeChoices) {
            trip.addDestination(route.getTemplate(), estimate)
        }
        _super = trip.build()
        return _super
    }
}
