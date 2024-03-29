//
//  CompletionHandlers.swift
//  flutter_carplay
//
//  Created by Bhavik Dodia on 29/03/24.
//

/// Completion handler for maneuver actions.
var maneuverActionTextHandler: ((String) -> Void)?

/// Completion handler for toggle voice instructions.
var toggleVoiceInstructionsHandler: ((Bool) -> Void)?

/// Completion handler for toggle satellite view.
var toggleSatelliteViewHandler: ((Bool) -> Void)?

/// Completion handler for toggle traffic view.
var toggleTrafficViewHandler: ((Bool) -> Void)?

/// Completion handler for recenter map view.
var recenterMapViewHandler: (() -> Void)?
