package com.oguzhnatly.flutter_carplay.models.map.here_map

import com.here.sdk.core.GeoCoordinates
import com.here.sdk.core.Location
import com.here.sdk.routing.Waypoint
import com.oguzhnatly.flutter_carplay.Bool

/// Completion handler for primary maneuver actions.
var primaryManeuverActionTextHandler: ((String) -> Unit)? = null

/// Completion handler for secondary maneuver actions.
var secondaryManeuverActionTextHandler: ((String) -> Unit)? = null

/// Completion handler for toggle offline mode.
var toggleOfflineModeHandler: ((Bool) -> Unit)? = null

/// Completion handler for toggle voice instructions.
var toggleVoiceInstructionsHandler: ((Bool) -> Unit)? = null

/// Completion handler for toggle satellite view.
var toggleSatelliteViewHandler: ((Bool) -> Unit)? = null

/// Completion handler for recenter map view.
var recenterMapViewHandler: ((String) -> Unit)? = null

/// Completion handler for update map coordinates.
var updateMapCoordinatesHandler: ((MapCoordinates) -> Unit)? = null

/// Completion handler for on route deviation
var reroutingHandler: ((Waypoint, () -> Unit) -> Unit)? = null

/// Completion handler for on location updated
var locationUpdatedHandler: ((Location) -> Unit)? = null

/// Map coordinates to render marker on the map
class MapCoordinates(
    var stationAddressCoordinates: GeoCoordinates? = null,
    var incidentAddressCoordinates: GeoCoordinates? = null,
    var destinationAddressCoordinates: GeoCoordinates? = null,
)
