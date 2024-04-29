//
//  CompletionHandlers.swift
//  flutter_carplay
//
//  Created by Bhavik Dodia on 29/03/24.
//

import heresdk

/// Completion handler for primary maneuver actions.
var primaryManeuverActionTextHandler: ((String) -> Void)?

/// Completion handler for secondary maneuver actions.
var secondaryManeuverActionTextHandler: ((String) -> Void)?

/// Completion handler for toggle offline mode.
var toggleOfflineModeHandler: ((Bool) -> Void)?

/// Completion handler for toggle voice instructions.
var toggleVoiceInstructionsHandler: ((Bool) -> Void)?

/// Completion handler for toggle satellite view.
var toggleSatelliteViewHandler: ((Bool) -> Void)?

/// Completion handler for recenter map view.
var recenterMapViewHandler: ((String) -> Void)?

/// Completion handler for update map coordinates.
var updateMapCoordinatesHandler: ((MapCoordinates) -> Void)?

/// Completion handler for on route deviation
var reroutingHandler: ((Waypoint, @escaping () -> Void) -> Void)?

/// Completion handler for on location updated
var locationUpdatedHandler: ((Location) -> Void)?

/// Map coordinates to render marker on the map
class MapCoordinates {
    let stationAddressCoordinates: GeoCoordinates?
    let incidentAddressCoordinates: GeoCoordinates?
    let destinationAddressCoordinates: GeoCoordinates?

    init(stationAddressCoordinates: GeoCoordinates? = nil,
         incidentAddressCoordinates: GeoCoordinates? = nil,
         destinationAddressCoordinates: GeoCoordinates? = nil)
    {
        self.stationAddressCoordinates = stationAddressCoordinates
        self.incidentAddressCoordinates = incidentAddressCoordinates
        self.destinationAddressCoordinates = destinationAddressCoordinates
    }
}
