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

/// Completion handler for toggle voice instructions.
var toggleVoiceInstructionsHandler: ((Bool) -> Void)?

/// Completion handler for toggle satellite view.
var toggleSatelliteViewHandler: ((Bool) -> Void)?

/// Completion handler for toggle traffic view.
var toggleTrafficViewHandler: ((Bool) -> Void)?

/// Completion handler for recenter map view.
var recenterMapViewHandler: ((String) -> Void)?

/// Completion handler for update map coordinates.
var updateMapCoordinatesHandler: ((MapCoordinates) -> Void)?

class MapCoordinates {
    let stationAddressCoordinates: GeoCoordinates?
    let incidentAddressCoordinates: GeoCoordinates?
    let destinationAddressCoordinates: GeoCoordinates?

    init(stationAddressCoordinates: GeoCoordinates?,
         incidentAddressCoordinates: GeoCoordinates?,
         destinationAddressCoordinates: GeoCoordinates?)
    {
        self.stationAddressCoordinates = stationAddressCoordinates
        self.incidentAddressCoordinates = incidentAddressCoordinates
        self.destinationAddressCoordinates = destinationAddressCoordinates
    }
}
