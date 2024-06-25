package com.oguzhnatly.flutter_carplay.models.map

/** A wrapper class for MKMapItem with additional functionality.
 *
 * @param obj The dictionary containing the map item data.
 */
class FMKMapItem(obj: Map<String, Any>) {
    /// The unique identifier for the map item.
    var elementId: String
        private set

    /// latitude and longitude
    var latitude: Double
    var longitude: Double

    /// The name of the map item
    var name: String

    init {
        val elementIdValue = obj["_elementId"] as? String
        assert(elementIdValue != null) {
            "Missing required keys in dictionary for FMKMapItem initialization."
        }
        elementId = elementIdValue!!
        latitude = obj["latitude"] as? Double ?: 0.0
        longitude = obj["longitude"] as? Double ?: 0.0
        name = obj["name"] as? String ?: ""
    }
}
