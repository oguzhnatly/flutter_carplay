/*
 * Copyright (C) 2019-2024 HERE Europe B.V.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import AVFoundation
import CarPlay
import heresdk
import UIKit

// This class combines the various events that can be emitted during turn-by-turn navigation.
// Note that this class does not show an exhaustive list of all possible events.
class NavigationEventHandler: NavigableLocationDelegate,
    DestinationReachedDelegate,
    MilestoneStatusDelegate,
    SpeedWarningDelegate,
    SpeedLimitDelegate,
    RouteProgressDelegate,
    RouteDeviationDelegate,
    EventTextDelegate,
    TollStopWarningDelegate,
    ManeuverViewLaneAssistanceDelegate,
    JunctionViewLaneAssistanceDelegate,
    RoadAttributesDelegate,
    RoadSignWarningDelegate,
    TruckRestrictionsWarningDelegate,
    SchoolZoneWarningDelegate,
    RoadTextsDelegate,
    RealisticViewWarningDelegate
{
    private let visualNavigator: VisualNavigator
    private let dynamicRoutingEngine: DynamicRoutingEngine
    private let voiceAssistant: VoiceAssistant
    private var lastMapMatchedLocation: MapMatchedLocation?
    private var previousManeuverIndex: Int32 = -1
    private let messageTextView: UITextView

    /// The voice instructions toggle button.
    private var isVoiceInstructionsMuted = false

    /// Check if a rerouting is in progress.
    private var isReroutingInProgress = false

    /// Route deviation event counter.
    private var deviationEventCount = 0

    /// Map template instance
    var mapTemplate: CPMapTemplate? {
        return SwiftFlutterCarplayPlugin.rootTemplate as? CPMapTemplate
    }

    /// Navigation session instance
    var navigationSession: CPNavigationSession? {
        return (SwiftFlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.navigationSession
    }

    /// Initializes a new `NavigationEventHandler` instance.
    /// - Parameters:
    ///   - visualNavigator: VisualNavigator
    ///   - dynamicRoutingEngine: DynamicRoutingEngine
    ///   - messageTextView: UITextView
    init(_ visualNavigator: VisualNavigator,
         _ dynamicRoutingEngine: DynamicRoutingEngine,
         _ messageTextView: UITextView)
    {
        self.visualNavigator = visualNavigator
        self.dynamicRoutingEngine = dynamicRoutingEngine
        self.messageTextView = messageTextView

        // A helper class for TTS.
        voiceAssistant = VoiceAssistant()

        // Toggle voice instructions handler
        toggleVoiceInstructionsHandler = { [weak self] isMuted in
            guard let self = self else { return }

            self.isVoiceInstructionsMuted = isMuted

            // If voice instructions are muted, stop the voice assistant
            if isMuted { voiceAssistant.stop() }
        }

        visualNavigator.navigableLocationDelegate = self
        visualNavigator.routeDeviationDelegate = self
        visualNavigator.routeProgressDelegate = self
        visualNavigator.eventTextDelegate = self
        visualNavigator.destinationReachedDelegate = self
        visualNavigator.milestoneStatusDelegate = self
        visualNavigator.speedWarningDelegate = self
        visualNavigator.speedLimitDelegate = self
        visualNavigator.tollStopWarningDelegate = self
        visualNavigator.maneuverViewLaneAssistanceDelegate = self
        visualNavigator.junctionViewLaneAssistanceDelegate = self
        visualNavigator.roadAttributesDelegate = self
        visualNavigator.roadSignWarningDelegate = self
        visualNavigator.truckRestrictionsWarningDelegate = self
        visualNavigator.schoolZoneWarningDelegate = self
        visualNavigator.roadTextsDelegate = self
        visualNavigator.realisticViewWarningDelegate = self

        setupSpeedWarnings()
        setupRoadSignWarnings()
        setupVoiceGuidance()
        setupRealisticViewWarnings()
        setupSchoolZoneWarnings()
    }

    /// Conform to RouteProgressDelegate.
    /// Notifies on the progress along the route including maneuver instructions.
    /// - Parameter routeProgress: The current route progress.
    func onRouteProgressUpdated(_ routeProgress: RouteProgress) {
        // [SectionProgress] is guaranteed to be non-empty.
        let distanceToDestination = routeProgress.sectionProgress.last?.remainingDistanceInMeters ?? Int32(0)
        print("Distance to destination in meters: \(distanceToDestination)")

        let timeToDestination = routeProgress.sectionProgress.last?.remainingDuration ?? TimeInterval()
        print("Duration to destination: \(timeToDestination)")

        let trafficDelayAhead = routeProgress.sectionProgress.last?.trafficDelay ?? TimeInterval()
        print("Traffic delay ahead in seconds: \(trafficDelayAhead)")

        // Contains the progress for the next maneuver ahead and the next-next maneuvers, if any.
        let nextManeuverList = routeProgress.maneuverProgress
        guard let currentManeuverProgress = nextManeuverList.first else {
            print("No current maneuver available.")
            return
        }

        let currentManeuverIndex = currentManeuverProgress.maneuverIndex
        // Check if the current maneuver is available in the visualNavigator
        guard let currentManeuver = visualNavigator.getManeuver(index: currentManeuverIndex) else {
            // Should never happen as we retrieved the next maneuver progress above.
            return
        }

        // Travel estimates for the current maneuver
        let initialTravelEstimates = CPTravelEstimates(distanceRemaining: getMeasurement(distanceInMeters: currentManeuverProgress.remainingDistanceInMeters), timeRemaining: currentManeuverProgress.remainingDuration)

        // Travel estimates for the overall route
        let travelEstimates = CPTravelEstimates(distanceRemaining: getMeasurement(distanceInMeters: distanceToDestination), timeRemaining: timeToDestination)

        // Check if the current maneuver has changed
        if previousManeuverIndex != currentManeuverIndex {
            // Log only new maneuvers and ignore changes in distance.

            // Show primary maneuver
            showPrimaryManeuver(maneuver: currentManeuver, initialTravelEstimates: initialTravelEstimates, travelEstimates: travelEstimates)

        } else {
            // A maneuver update contains a different distance to reach the next maneuver.

            // Update the estimates for the current maneuver
            updateEstimates(initialTravelEstimates: initialTravelEstimates, travelEstimates: travelEstimates)
        }

        // Check if the next maneuver is available and the distance is less than 500m.
        if nextManeuverList.count > 1, currentManeuverProgress.remainingDistanceInMeters < Int32(500) {
            let nextManeuverProgress = nextManeuverList[1]

            let nextManeuverIndex = nextManeuverProgress.maneuverIndex
            // Check if the next maneuver is available in the visualNavigator
            guard let nextManeuver = visualNavigator.getManeuver(index: nextManeuverIndex) else {
                // Should never happen as we retrieved the next maneuver progress above.
                return
            }

            // Show secondary maneuver
            showSecondaryManeuver(maneuver: nextManeuver)
        }

        // Update the previous maneuver index.
        previousManeuverIndex = currentManeuverIndex

        if let lastMapMatchedLocation = lastMapMatchedLocation {
            // Update the route based on the current location of the driver.
            // We periodically want to search for better traffic-optimized routes.
            dynamicRoutingEngine.updateCurrentLocation(
                mapMatchedLocation: lastMapMatchedLocation,
                sectionIndex: routeProgress.sectionIndex
            )
        }
    }

    /// Show primary maneuver
    /// - Parameters:
    ///   - maneuver: maneuver
    ///   - initialTravelEstimates: initial travel estimates
    ///   - travelEstimates: travel estimates
    func showPrimaryManeuver(maneuver: Maneuver, initialTravelEstimates: CPTravelEstimates, travelEstimates: CPTravelEstimates) {
        let action = String(describing: maneuver.action)
        let roadName = getRoadName(maneuver: maneuver) ?? ""
        let nextRoadName = maneuver.nextRoadTexts.names.defaultValue() ?? ""

        /// Primary maneuver action text handler
        /// Get the action text for the primary maneuver from the main application.
        primaryManeuverActionTextHandler = { [weak self] actionText in
            guard let self = self else { return }

            print("Primary maneuver: \(actionText)")

            // Create CPManeuver instance and set appropriate properties
            let cpManeuver = CPManeuver()
            cpManeuver.instructionVariants = [actionText]
            cpManeuver.initialTravelEstimates = initialTravelEstimates
            cpManeuver.dashboardInstructionVariants = [actionText]

            let symbolImage = UIImage.dynamicImage(lightImage: "assets/icons/car_play/maneuvers/light/\(action).png",
                                                   darkImage: "assets/icons/car_play/maneuvers/dark/\(action).png")
            cpManeuver.symbolImage = symbolImage
            cpManeuver.dashboardSymbolImage = symbolImage

            // Update the upcoming maneuver
            // It will change the maneuver in the map template automatically
            self.navigationSession?.upcomingManeuvers = [cpManeuver]

            // Update the overall route estimates
            if let trip = self.navigationSession?.trip {
                mapTemplate?.updateEstimates(travelEstimates, for: trip)
            }
        }

        // Send event to get the localized action text for the primary maneuver from main application.
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onManeuverActionTextRequested,
                                         data: [
                                             "action": action,
                                             "roadName": roadName,
                                             "nextRoadName": nextRoadName,
                                             "isPrimary": true,
                                         ])
    }

    /// Show secondary maneuver
    /// - Parameter maneuver: maneuver
    func showSecondaryManeuver(maneuver: Maneuver) {
        let action = String(describing: maneuver.action)
        let roadName = getRoadName(maneuver: maneuver) ?? ""
        let nextRoadName = maneuver.nextRoadTexts.names.defaultValue() ?? ""

        /// Secondary maneuver action text handler
        /// Get the action text for the secondary maneuver from the main application.
        secondaryManeuverActionTextHandler = { [weak self] actionText in
            guard let self = self else { return }
            print("Secondary maneuver: \(actionText)")

            let maneuverTextArr = maneuver.text.components(separatedBy: " ")
            let formattedManeuverText = maneuverTextArr.count > 3 ? Array(maneuverTextArr.prefix(3)).joined(separator: " ").appending("...") : maneuver.text

            let cpManeuver = CPManeuver()
            cpManeuver.instructionVariants = [actionText, maneuver.text, formattedManeuverText]
            cpManeuver.dashboardInstructionVariants = [actionText, maneuver.text, formattedManeuverText]

            let symbolImage = UIImage.dynamicImage(lightImage: "assets/icons/car_play/maneuvers/light/\(action).png",
                                                   darkImage: "assets/icons/car_play/maneuvers/dark/\(action).png")
            cpManeuver.symbolImage = symbolImage
            cpManeuver.dashboardSymbolImage = symbolImage

            // Update the upcoming maneuver in the map template
            // It will add the secondary maneuver in the map template automatically
            if var upcomingManeuvers = self.navigationSession?.upcomingManeuvers,
               upcomingManeuvers.count < 2
            {
                upcomingManeuvers.append(cpManeuver)
                self.navigationSession?.upcomingManeuvers = upcomingManeuvers
            }
        }

        // Send event to get the localized action text for the secondary maneuver from main application.
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onManeuverActionTextRequested,
                                         data: [
                                             "action": action,
                                             "roadName": roadName,
                                             "nextRoadName": nextRoadName,
                                             "isPrimary": false,
                                         ])
    }

    /// Update estimates
    /// - Parameters:
    ///   - initialTravelEstimates: initial travel estimates
    ///   - travelEstimates: travel estimates
    func updateEstimates(initialTravelEstimates: CPTravelEstimates, travelEstimates: CPTravelEstimates) {
        if let cpManeuver = navigationSession?.upcomingManeuvers.first as? CPManeuver {
            navigationSession?.updateEstimates(initialTravelEstimates, for: cpManeuver)
        }

        if let trip = navigationSession?.trip {
            mapTemplate?.updateEstimates(travelEstimates, for: trip)
        }
    }

    /// Returns the road name for the specified maneuver.
    /// - Parameter maneuver: The maneuver to get the road name for.
    /// - Returns: The road name for the specified maneuver.
    func getRoadName(maneuver: Maneuver) -> String? {
        let currentRoadTexts = maneuver.roadTexts
        let nextRoadTexts = maneuver.nextRoadTexts

        let currentRoadName = currentRoadTexts.names.defaultValue()
        let currentRoadNumber = currentRoadTexts.numbersWithDirection.defaultValue()
        let nextRoadName = nextRoadTexts.names.defaultValue()
        let nextRoadNumber = nextRoadTexts.numbersWithDirection.defaultValue()

        var roadName = nextRoadName == nil ? nextRoadNumber : nextRoadName

        // On highways, we want to show the highway number instead of a possible road name,
        // while for inner city and urban areas road names are preferred over road numbers.
        if maneuver.nextRoadType == RoadType.highway {
            roadName = nextRoadNumber == nil ? nextRoadName : nextRoadNumber
        }

        if maneuver.action == ManeuverAction.arrive {
            // We are approaching destination, so there's no next road.
            roadName = currentRoadName == nil ? currentRoadNumber : currentRoadName
        }

        // Nil happens only in rare cases, when also the fallback above is nil.
        return roadName
    }

    /// Get measurement from distance in meters.
    /// - Parameter distanceInMeters: The distance in meters.
    /// - Returns: The measurement in the appropriate unit.
    func getMeasurement(distanceInMeters: Int32) -> Measurement<UnitLength> {
        let measurement = Measurement(value: Double(distanceInMeters), unit: UnitLength.meters)
        if distanceInMeters > Int32(1000) {
            return measurement.converted(to: .kilometers)
        }
        return measurement
    }

    /// Conform to DestinationReachedDelegate.
    /// Notifies when the destination of the route is reached.
    func onDestinationReached() {
        showMessage("Destination reached.")
        // Guidance has stopped. Now consider to, for example,
        // switch to tracking mode or stop rendering or locating or do anything else that may
        // be useful to support your app flow.
        // If the DynamicRoutingEngine was started before, consider to stop it now.
    }

    /// Conform to MilestoneStatusDelegate.
    /// Notifies when a waypoint on the route is reached or missed.
    /// - Parameter milestone: The current milestone.
    /// - Parameter status: The current milestone status.
    func onMilestoneStatusUpdated(milestone: Milestone, status: MilestoneStatus) {
        if milestone.waypointIndex != nil && status == MilestoneStatus.reached {
            print("A user-defined waypoint was reached, index of waypoint: \(String(describing: milestone.waypointIndex))")
            print("Original coordinates: \(String(describing: milestone.originalCoordinates))")
        } else if milestone.waypointIndex != nil && status == MilestoneStatus.missed {
            print("A user-defined waypoint was missed, index of waypoint: \(String(describing: milestone.waypointIndex))")
            print("Original coordinates: \(String(describing: milestone.originalCoordinates))")
        } else if milestone.waypointIndex == nil && status == MilestoneStatus.reached {
            // For example, when transport mode changes due to a ferry a system-defined waypoint may have been added.
            print("A system-defined waypoint was reached at: \(String(describing: milestone.mapMatchedCoordinates))")
        } else if milestone.waypointIndex == nil && status == MilestoneStatus.missed {
            // For example, when transport mode changes due to a ferry a system-defined waypoint may have been added.
            print("A system-defined waypoint was missed at: \(String(describing: milestone.mapMatchedCoordinates))")
        }
    }

    /// Conform to SpeedWarningDelegate.
    /// Notifies when the current speed limit is exceeded.
    /// - Parameter status: The current speed limit status.
    func onSpeedWarningStatusChanged(_ status: SpeedWarningStatus) {
        if status == SpeedWarningStatus.speedLimitExceeded {
            // Driver is faster than current speed limit (plus an optional offset).
            // Play a notification sound to alert the driver.
            // Note that this may not include temporary special speed limits, see SpeedLimitDelegate.
//            AudioServicesPlaySystemSound(SystemSoundID(1016))
        }

        if status == SpeedWarningStatus.speedLimitRestored {
            print("Driver is again slower than current speed limit (plus an optional offset).")
        }
    }

    /// Conform to SpeedLimitDelegate.
    /// Notifies on the current speed limit valid on the current road.
    /// - Parameter speedLimit: The current speed limit valid on the current road.
    func onSpeedLimitUpdated(_ speedLimit: SpeedLimit) {
        let speedLimit = getCurrentSpeedLimit(speedLimit)

        if speedLimit == nil {
            print("Warning: Speed limits unknown, data could not be retrieved.")
        } else if speedLimit == 0 {
            print("No speed limits on this road! Drive as fast as you feel safe ...")
        } else {
            print("Current speed limit (m/s): \(String(describing: speedLimit))")
        }
    }

    /// Conform to SpeedLimitDelegate.
    /// - Parameter speedLimit: The current speed limit valid on the current road.
    /// - Returns: The current speed limit in meters per second.
    private func getCurrentSpeedLimit(_ speedLimit: SpeedLimit) -> Double? {
        // Note that all values can be nil if no data is available.

        // The regular speed limit if available. In case of unbounded speed limit, the value is zero.
        print("speedLimitInMetersPerSecond: \(String(describing: speedLimit.speedLimitInMetersPerSecond))")

        // A conditional school zone speed limit as indicated on the local road signs.
        print("schoolZoneSpeedLimitInMetersPerSecond: \(String(describing: speedLimit.schoolZoneSpeedLimitInMetersPerSecond))")

        // A conditional time-dependent speed limit as indicated on the local road signs.
        // It is in effect considering the current local time provided by the device's clock.
        print("timeDependentSpeedLimitInMetersPerSecond: \(String(describing: speedLimit.timeDependentSpeedLimitInMetersPerSecond))")

        // A conditional non-legal speed limit that recommends a lower speed,
        // for example, due to bad road conditions.
        print("advisorySpeedLimitInMetersPerSecond: \(String(describing: speedLimit.advisorySpeedLimitInMetersPerSecond))")

        // A weather-dependent speed limit as indicated on the local road signs.
        // The HERE SDK cannot detect the current weather condition, so a driver must decide
        // based on the situation if this speed limit applies.
        print("fogSpeedLimitInMetersPerSecond: \(String(describing: speedLimit.fogSpeedLimitInMetersPerSecond))")
        print("rainSpeedLimitInMetersPerSecond: \(String(describing: speedLimit.rainSpeedLimitInMetersPerSecond))")
        print("snowSpeedLimitInMetersPerSecond: \(String(describing: speedLimit.snowSpeedLimitInMetersPerSecond))")

        // For convenience, this returns the effective (lowest) speed limit between
        // - speedLimitInMetersPerSecond
        // - schoolZoneSpeedLimitInMetersPerSecond
        // - timeDependentSpeedLimitInMetersPerSecond
        return speedLimit.effectiveSpeedLimitInMetersPerSecond()
    }

    /// Conform to NavigableLocationDelegate.
    /// Notifies on the current map-matched location and other useful information while driving or walking.
    /// - Parameter navigableLocation: The current map-matched location.
    func onNavigableLocationUpdated(_ navigableLocation: NavigableLocation) {
        guard navigableLocation.mapMatchedLocation != nil else {
            print("The currentNavigableLocation could not be map-matched. Are you off-road?")
            return
        }

        lastMapMatchedLocation = navigableLocation.mapMatchedLocation!

        let speed = navigableLocation.originalLocation.speedInMetersPerSecond
        let accuracy = navigableLocation.originalLocation.speedAccuracyInMetersPerSecond
        print("Driving speed: \(String(describing: speed)) plus/minus accuracy of \(String(describing: accuracy)).")
    }

    /// Conform to RouteDeviationDelegate.
    /// Notifies on a possible deviation from the route.
    /// - Parameter routeDeviation: The possible deviation from the route.
    func onRouteDeviation(_ routeDeviation: RouteDeviation) {
        print("onRouteDeviation: \(routeDeviation)")
        guard let route = visualNavigator.route else {
            // May happen in rare cases when route was set to nil inbetween.
            return
        }

        // Get current geographic coordinates.
        let originalLocation = routeDeviation.currentLocation.originalLocation
        var currentGeoCoordinates = originalLocation.coordinates
        if let currentMapMatchedLocation = routeDeviation.currentLocation.mapMatchedLocation {
            currentGeoCoordinates = currentMapMatchedLocation.coordinates
        }

        // Get last geographic coordinates on route.
        var lastGeoCoordinates: GeoCoordinates?
        if let lastLocationOnRoute = routeDeviation.lastLocationOnRoute {
            lastGeoCoordinates = lastLocationOnRoute.originalLocation.coordinates
            if let lastMapMatchedLocationOnRoute = lastLocationOnRoute.mapMatchedLocation {
                lastGeoCoordinates = lastMapMatchedLocationOnRoute.coordinates
            }
        } else {
            print("User was never following the route. So, we take the start of the route instead.")
            lastGeoCoordinates = route.sections.first?.departurePlace.originalCoordinates
        }

        guard let lastGeoCoordinatesOnRoute = lastGeoCoordinates else {
            print("No lastGeoCoordinatesOnRoute found. Should never happen.")
            return
        }

        let distanceInMeters = currentGeoCoordinates.distance(to: lastGeoCoordinatesOnRoute)
        print("RouteDeviation in meters is \(distanceInMeters)")

        let startingWaypoint = Waypoint(coordinates: originalLocation.coordinates, headingInDegrees: originalLocation.bearingInDegrees)

        // Now, an application needs to decide if the user has deviated far enough and
        // what should happen next: For example, you can notify the user or simply try to
        // calculate a new route. When you calculate a new route, you can, for example,
        // take the current location as new start and keep the destination - another
        // option could be to calculate a new route back to the lastMapMatchedLocationOnRoute.
        // At least, make sure to not calculate a new route every time you get a RouteDeviation
        // event as the route calculation happens asynchronously and takes also some time to
        // complete.
        // The deviation event is sent any time an off-route location is detected: It may make
        // sense to await around 3 events before deciding on possible actions.

        // Update deviation event counter.
        deviationEventCount += 1

        // Check if the user has deviated far enough.
        if distanceInMeters >=
            ConstantsEnum.ROUTE_DEVIATION_DISTANCE &&
            deviationEventCount >= 3 &&
            !isReroutingInProgress
        {
            // Start rerouting.
            isReroutingInProgress = true

            // Call the rerouting handler.
            // Handler will be called to get the new route.
            reroutingHandler?(startingWaypoint, {
                // On reroutingHandler completion, reset the deviation event counter.
                self.deviationEventCount = 0
                self.isReroutingInProgress = false
            })
        }
    }

    /// Conform to EventTextDelegate.
    /// Notifies on voice maneuver messages.
    /// - Parameter eventText: The voice maneuver message.
    func onEventTextUpdated(_ eventText: heresdk.EventText) {
        if !isVoiceInstructionsMuted {
            voiceAssistant.speak(message: eventText.text)
        }
    }

    /// Stops the voice assistant.
    func stopVoiceAssistant() {
        voiceAssistant.stop()
    }

    /// Reset the previous maneuver index.
    func resetPreviousManeuverIndex() {
        previousManeuverIndex = Int32(-1)
    }

    /// Conform to TollStopWarningDelegate.
    /// Notifies on upcoming toll stops. Uses the same notification
    /// thresholds as other warners and provides events with or without a route to follow.
    /// - Parameter tollStop: The upcoming toll stop.
    func onTollStopWarning(_ tollStop: TollStop) {
        let lanes = tollStop.lanes

        // The lane at index 0 is the leftmost lane adjacent to the middle of the road.
        // The lane at the last index is the rightmost lane.
        let laneNumber = 0
        for tollBoothLane in lanes {
            // Log which vehicles types are allowed on this lane that leads to the toll booth.
            logLaneAccess(laneNumber, tollBoothLane.access)
            let tollBooth = tollBoothLane.booth
            let tollCollectionMethods = tollBooth.tollCollectionMethods
            let paymentMethods = tollBooth.paymentMethods
            // The supported collection methods like ticket or automatic / electronic.
            for collectionMethod in tollCollectionMethods {
                print("This toll stop supports collection via: \(collectionMethod).")
            }
            // The supported payment methods like cash or credit card.
            for paymentMethod in paymentMethods {
                print("This toll stop supports payment via: \(paymentMethod).")
            }
        }
    }

    /// Conform to the ManeuverViewLaneAssistanceDelegate.
    /// Notifies which lane(s) lead to the next (next) maneuvers.
    /// - Parameter laneAssistance: The lane(s) that lead to the next maneuver.
    func onLaneAssistanceUpdated(_ laneAssistance: ManeuverViewLaneAssistance) {
        // This lane list is guaranteed to be non-empty.
        let lanes = laneAssistance.lanesForNextManeuver
        logLaneRecommendations(lanes)

        let nextLanes = laneAssistance.lanesForNextNextManeuver
        if !nextLanes.isEmpty {
            print("Attention, the next next maneuver is very close.")
            print("Please take the following lane(s) after the next maneuver: ")
            logLaneRecommendations(nextLanes)
        }
    }

    /// Conform to the JunctionViewLaneAssistanceDelegate.
    /// Notifies which lane(s) allow to follow the route.
    func onLaneAssistanceUpdated(_ laneAssistance: JunctionViewLaneAssistance) {
        let lanes = laneAssistance.lanesForNextJunction
        if lanes.isEmpty {
            print("You have passed the complex junction.")
        } else {
            print("Attention, a complex junction is ahead.")
            logLaneRecommendations(lanes)
        }
    }

    /// Log lane recommendations.
    /// - Parameter lanes: The lane(s) that lead to the next maneuver.
    private func logLaneRecommendations(_ lanes: [Lane]) {
        // The lane at index 0 is the leftmost lane adjacent to the middle of the road.
        // The lane at the last index is the rightmost lane.
        var laneNumber = 0
        for lane in lanes {
            // This state is only possible if laneAssistance.lanesForNextNextManeuver is not empty.
            // For example, when two lanes go left, this lanes leads only to the next maneuver,
            // but not to the maneuver after the next maneuver, while the highly recommended lane also leads
            // to this next next maneuver.
            if lane.recommendationState == .recommended {
                print("Lane \(laneNumber) leads to next maneuver, but not to the next next maneuver.")
            }

            // If laneAssistance.lanesForNextNextManeuver is not empty, this lane leads also to the
            // maneuver after the next maneuver.
            if lane.recommendationState == .highlyRecommended {
                print("Lane \(laneNumber) leads to next maneuver and eventually to the next next maneuver.")
            }

            if lane.recommendationState == .notRecommended {
                print("Do not take lane \(laneNumber) to follow the route.")
            }

            logLaneDetails(laneNumber, lane)

            laneNumber += 1
        }
    }

    /// Log lane details.
    /// - Parameters:
    ///   - laneNumber: Lane number
    ///   - lane: Lane object
    func logLaneDetails(_ laneNumber: Int, _ lane: Lane) {
        // All directions can be true or false at the same time.
        // The possible lane directions are valid independent of a route.
        // If a lane leads to multiple directions and is recommended, then all directions lead to
        // the next maneuver.
        // You can use this information like in a bitmask to visualize the possible directions
        // with a set of image overlays.
        let laneDirectionCategory = lane.directionCategory
        print("Directions for lane \(laneNumber):")
        print("laneDirectionCategory.straight: \(laneDirectionCategory.straight)")
        print("laneDirectionCategory.slightlyLeft: \(laneDirectionCategory.slightlyLeft)")
        print("laneDirectionCategory.quiteLeft: \(laneDirectionCategory.quiteLeft)")
        print("laneDirectionCategory.hardLeft: \(laneDirectionCategory.hardLeft)")
        print("laneDirectionCategory.uTurnLeft: \(laneDirectionCategory.uTurnLeft)")
        print("laneDirectionCategory.slightlyRight: \(laneDirectionCategory.slightlyRight)")
        print("laneDirectionCategory.quiteRight: \(laneDirectionCategory.quiteRight)")
        print("laneDirectionCategory.hardRight: \(laneDirectionCategory.hardRight)")
        print("laneDirectionCategory.uTurnRight: \(laneDirectionCategory.uTurnRight)")

        // More information on each lane is available in these bitmasks (boolean):
        // LaneType provides lane properties such as if parking is allowed.
        _ = lane.type
        // LaneAccess provides which vehicle type(s) are allowed to access this lane.
        logLaneAccess(laneNumber, lane.access)
    }

    /// Log lane access.
    /// - Parameters:
    ///   - laneNumber: Lane number
    ///   - laneAccess: LaneAccess object
    func logLaneAccess(_ laneNumber: Int, _ laneAccess: LaneAccess) {
        print("Lane access for lane \(laneNumber).")
        print("Automobiles are allowed on this lane: \(laneAccess.automobiles).")
        print("Buses are allowed on this lane: \(laneAccess.buses).")
        print("Taxis are allowed on this lane: \(laneAccess.taxis).")
        print("Carpools are allowed on this lane: \(laneAccess.carpools).")
        print("Pedestrians are allowed on this lane: \(laneAccess.pedestrians).")
        print("Trucks are allowed on this lane: \(laneAccess.trucks).")
        print("ThroughTraffic is allowed on this lane: \(laneAccess.throughTraffic).")
        print("DeliveryVehicles are allowed on this lane: \(laneAccess.deliveryVehicles).")
        print("EmergencyVehicles are allowed on this lane: \(laneAccess.emergencyVehicles).")
        print("Motorcycles are allowed on this lane: \(laneAccess.motorcycles).")
    }

    /// Conform to the RoadAttributesDelegate.
    /// Notifies on the attributes of the current road including usage and physical characteristics.
    func onRoadAttributesUpdated(_ roadAttributes: RoadAttributes) {
        // This is called whenever any road attribute has changed.
        // If all attributes are unchanged, no new event is fired.
        // Note that a road can have more than one attribute at the same time.
        print("Received road attributes update.")

        if roadAttributes.isBridge {
            // Identifies a structure that allows a road, railway, or walkway to pass over another road, railway,
            // waterway, or valley serving map display and route guidance functionalities.
            print("Road attributes: This is a bridge.")
        }
        if roadAttributes.isControlledAccess {
            // Controlled access roads are roads with limited entrances and exits that allow uninterrupted
            // high-speed traffic flow.
            print("Road attributes: This is a controlled access road.")
        }
        if roadAttributes.isDirtRoad {
            // Indicates whether the navigable segment is paved.
            print("Road attributes: This is a dirt road.")
        }
        if roadAttributes.isDividedRoad {
            // Indicates if there is a physical structure or painted road marking intended to legally prohibit
            // left turns in right-side driving countries, right turns in left-side driving countries,
            // and U-turns at divided intersections or in the middle of divided segments.
            print("Road attributes: This is a divided road.")
        }
        if roadAttributes.isNoThrough {
            // Identifies a no through road.
            print("Road attributes: This is a no through road.")
        }
        if roadAttributes.isPrivate {
            // Private identifies roads that are not maintained by an organization responsible for maintenance of
            // public roads.
            print("Road attributes: This is a private road.")
        }
        if roadAttributes.isRamp {
            // Range is a ramp: connects roads that do not intersect at grade.
            print("Road attributes: This is a ramp.")
        }
        if roadAttributes.isRightDrivingSide {
            // Indicates if vehicles have to drive on the right-hand side of the road or the left-hand side.
            // For example, in New York it is always true and in London always false as the United Kingdom is
            // a left-hand driving country.
            print("Road attributes: isRightDrivingSide = \(roadAttributes.isRightDrivingSide)")
        }
        if roadAttributes.isRoundabout {
            // Indicates the presence of a roundabout.
            print("Road attributes: This is a roundabout.")
        }
        if roadAttributes.isTollway {
            // Identifies a road for which a fee must be paid to use the road.
            print("Road attributes change: This is a road with toll costs.")
        }
        if roadAttributes.isTunnel {
            // Identifies an enclosed (on all sides) passageway through or under an obstruction.
            print("Road attributes: This is a tunnel.")
        }
    }

    // Conform to the RoadShieldsWarningDelegate.
    // Notifies on road shields as they appear along the road.
    func onRoadSignWarningUpdated(_ roadSignWarning: RoadSignWarning) {
        print("Road sign distance (m): \(roadSignWarning.distanceToRoadSignInMeters)")
        print("Road sign type: \(roadSignWarning.type.rawValue)")

        if let signValue = roadSignWarning.signValue {
            // Optional text as it is printed on the local road sign.
            print("Road sign text: " + signValue.text)
        }

        // For more road sign attributes, please check the API Reference.
    }

    // Conform to the TruckRestrictionsWarningDelegate.
    // Notifies truck drivers on road restrictions ahead. Called whenever there is a change.
    // For example, there can be a bridge ahead not high enough to pass a big truck
    // or there can be a road ahead where the weight of the truck is beyond it's permissible weight.
    // This event notifies on truck restrictions in general,
    // so it will also deliver events, when the transport type was set to a non-truck transport type.
    // The given restrictions are based on the HERE database of the road network ahead.
    func onTruckRestrictionsWarningUpdated(_ restrictions: [TruckRestrictionWarning]) {
        // The list is guaranteed to be non-empty.
        for truckRestrictionWarning in restrictions {
            if truckRestrictionWarning.distanceType == DistanceType.ahead {
                print("TruckRestrictionWarning ahead in \(truckRestrictionWarning.distanceInMeters) meters.")
            } else if truckRestrictionWarning.distanceType == DistanceType.reached {
                print("A restriction has been reached.")
            } else if truckRestrictionWarning.distanceType == DistanceType.passed {
                // If not preceded by a "reached"-notification, this restriction was valid only for the passed location.
                print("A restriction was just passed.")
            }

            // One of the following restrictions applies, if more restrictions apply at the same time,
            // they are part of another TruckRestrictionWarning element contained in the list.
            if truckRestrictionWarning.weightRestriction != nil {
                let type = truckRestrictionWarning.weightRestriction!.type
                let value = truckRestrictionWarning.weightRestriction!.valueInKilograms
                print("TruckRestriction for weight (kg): \(type): \(value)")
            } else if truckRestrictionWarning.dimensionRestriction != nil {
                // Can be either a length, width or height restriction of the truck. For example, a height
                // restriction can apply for a tunnel. Other possible restrictions are delivered in
                // separate TruckRestrictionWarning objects contained in the list, if any.
                let type = truckRestrictionWarning.dimensionRestriction!.type
                let value = truckRestrictionWarning.dimensionRestriction!.valueInCentimeters
                print("TruckRestriction for dimension: \(type): \(value)")
            } else {
                print("TruckRestriction: General restriction - no trucks allowed.")
            }
        }
    }

    /// Conform to SchoolZoneWarningDelegate.
    /// Notifies on school zones ahead.
    /// - Parameter schoolZoneWarnings: The list of school zone warnings
    func onSchoolZoneWarningUpdated(_ schoolZoneWarnings: [heresdk.SchoolZoneWarning]) {
        // The list is guaranteed to be non-empty.
        for schoolZoneWarning in schoolZoneWarnings {
            if schoolZoneWarning.distanceType == DistanceType.ahead {
                print("A school zone ahead in: \(schoolZoneWarning.distanceToSchoolZoneInMeters) meters.")
                // Note that this will be the same speed limit as indicated by SpeedLimitDelegate, unless
                // already a lower speed limit applies, for example, because of a heavy truck load.
                print("Speed limit restriction for this school zone: \(schoolZoneWarning.speedLimitInMetersPerSecond) m/s.")
                if let timeRule = schoolZoneWarning.timeRule {
                    if timeRule.appliesTo(dateTime: Date()) {
                        // For example, during night sometimes a school zone warning does not apply.
                        // If schoolZoneWarning.timeRule is nil, the warning applies at anytime.
                        print("Note that this school zone warning currently does not apply.")
                    }
                }
            } else if schoolZoneWarning.distanceType == DistanceType.reached {
                print("A school zone has been reached.")
            } else if schoolZoneWarning.distanceType == DistanceType.passed {
                print("A school zone has been passed.")
            }
        }
    }

    /// Conform to RealisticViewWarningDelegate.
    /// Notifies on signposts together with complex junction views.
    /// Signposts are shown as they appear along a road on a shield to indicate the upcoming directions and
    /// destinations, such as cities or road names.
    /// Junction views appear as a 3D visualization (as a static image) to help the driver to orientate.
    ///
    /// Optionally, you can use a feature-configuration to preload the assets as part of a Region.
    ///
    /// The event matches the notification for complex junctions, see JunctionViewLaneAssistance.
    /// Note that the SVG data for junction view is composed out of several 3D elements,
    /// a horizon and the actual junction geometry.
    /// - Parameter realisticViewWarning: The list of realistic view warnings
    func onRealisticViewWarningUpdated(_ realisticViewWarning: RealisticViewWarning) {
        let distance = realisticViewWarning.distanceToRealisticViewInMeters
        let distanceType: DistanceType = realisticViewWarning.distanceType

        // Note that DistanceType.reached is not used for Signposts and junction views
        // as a junction is identified through a location instead of an area.
        if distanceType == DistanceType.ahead {
            print("A RealisticView ahead in: " + String(distance) + " meters.")
        } else if distanceType == DistanceType.passed {
            print("A RealisticView just passed.")
        }

        let realisticView = realisticViewWarning.realisticView
        guard let signpostSvgImageContent = realisticView?.signpostSvgImageContent,
              let junctionViewSvgImageContent = realisticView?.junctionViewSvgImageContent
        else {
            print("A RealisticView just passed. No SVG data delivered.")
            return
        }

        // The resolution-independent SVG data can now be used in an application to visualize the image.
        // Use a SVG library of your choice to create an SVG image out of the SVG string.
        // Both SVGs contain the same dimension and the signpostSvgImageContent should be shown on top of
        // the junctionViewSvgImageContent.
        // The images can be quite detailed, therefore it is recommended to show them on a secondary display
        // in full size.
        print("signpostSvgImage: \(signpostSvgImageContent)")
        print("junctionViewSvgImage: \(junctionViewSvgImageContent)")
    }

    /// Conform to RoadTextsDelegate
    /// Notifies whenever any textual attribute of the current road changes, i.e., the current road texts differ
    /// from the previous one. This can be useful during tracking mode, when no maneuver information is provided.
    func onRoadTextsUpdated(_: RoadTexts) {
        // See getRoadName() how to get the current road name from the provided RoadTexts.
    }

    /// Set up speed warnings
    private func setupSpeedWarnings() {
        let speedLimitOffset = SpeedLimitOffset(lowSpeedOffsetInMetersPerSecond: 2,
                                                highSpeedOffsetInMetersPerSecond: 4,
                                                highSpeedBoundaryInMetersPerSecond: 25)
        visualNavigator.speedWarningOptions = SpeedWarningOptions(speedLimitOffset: speedLimitOffset)
    }

    /// Set up road sign warnings
    private func setupRoadSignWarnings() {
        var roadSignWarningOptions = RoadSignWarningOptions()
        // Set a filter to get only shields relevant for trucks and heavyTrucks.
        roadSignWarningOptions.vehicleTypesFilter = [RoadSignVehicleType.trucks, RoadSignVehicleType.heavyTrucks]
        visualNavigator.roadSignWarningOptions = roadSignWarningOptions
    }

    /// Set up realistic view warnings
    private func setupRealisticViewWarnings() {
        let realisticViewWarningOptions = RealisticViewWarningOptions(aspectRatio: AspectRatio.aspectRatio3X4, darkTheme: false)
        visualNavigator.realisticViewWarningOptions = realisticViewWarningOptions
    }

    /// Set up school zone warnings
    private func setupSchoolZoneWarnings() {
        var schoolZoneWarningOptions = SchoolZoneWarningOptions()
        schoolZoneWarningOptions.filterOutInactiveTimeDependentWarnings = true
        schoolZoneWarningOptions.warningDistanceInMeters = 150
        visualNavigator.schoolZoneWarningOptions = schoolZoneWarningOptions
    }

    /// Set up voice guidance
    private func setupVoiceGuidance() {
        let ttsLanguageCode = getLanguageCodeForDevice(supportedVoiceSkins: VisualNavigator.availableLanguagesForManeuverNotifications())
        visualNavigator.maneuverNotificationOptions = ManeuverNotificationOptions(language: ttsLanguageCode,
                                                                                  unitSystem: UnitSystem.metric)

        print("LanguageCode for maneuver notifications: \(ttsLanguageCode).")

        // Set language to our TextToSpeech engine.
        let locale = LanguageCodeConverter.getLocale(languageCode: ttsLanguageCode)
        if voiceAssistant.setLanguage(locale: locale) {
            print("TextToSpeech engine uses this language: \(locale)")
        } else {
            print("TextToSpeech engine does not support this language: \(locale)")
        }
    }

    /// Get the language preferrably used on this device.
    private func getLanguageCodeForDevice(supportedVoiceSkins: [heresdk.LanguageCode]) -> LanguageCode {
        // 1. Determine if preferred device language is supported by our TextToSpeech engine.
        let identifierForCurrenDevice = Locale.preferredLanguages.first!
        var localeForCurrenDevice = Locale(identifier: identifierForCurrenDevice)
        if !voiceAssistant.isLanguageAvailable(identifier: identifierForCurrenDevice) {
            print("TextToSpeech engine does not support: \(identifierForCurrenDevice), falling back to en-US.")
            localeForCurrenDevice = Locale(identifier: "en-US")
        }

        // 2. Determine supported voice skins from HERE SDK.
        var languageCodeForCurrenDevice = LanguageCodeConverter.getLanguageCode(locale: localeForCurrenDevice)
        if !supportedVoiceSkins.contains(languageCodeForCurrenDevice) {
            print("No voice skins available for \(languageCodeForCurrenDevice), falling back to enUs.")
            languageCodeForCurrenDevice = LanguageCode.enUs
        }

        return languageCodeForCurrenDevice
    }

    /// A permanent view to show log content.
    private func showMessage(_ message: String) {
        messageTextView.text = message
        messageTextView.textColor = .white
        messageTextView.layer.cornerRadius = 8
        messageTextView.isEditable = false
        messageTextView.textAlignment = NSTextAlignment.center
        messageTextView.font = .systemFont(ofSize: 14)
    }
}
