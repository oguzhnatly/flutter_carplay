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
package com.oguzhnatly.flutter_carplay.models.map.here_map

import android.util.Log
import com.here.sdk.core.GeoCoordinates
import com.here.sdk.core.LanguageCode
import com.here.sdk.core.UnitSystem
import com.here.sdk.navigation.AspectRatio
import com.here.sdk.navigation.BorderCrossingWarningListener
import com.here.sdk.navigation.BorderCrossingWarningOptions
import com.here.sdk.navigation.DangerZoneWarningListener
import com.here.sdk.navigation.DangerZoneWarningOptions
import com.here.sdk.navigation.DestinationReachedListener
import com.here.sdk.navigation.DistanceType
import com.here.sdk.navigation.EventTextListener
import com.here.sdk.navigation.JunctionViewLaneAssistanceListener
import com.here.sdk.navigation.Lane
import com.here.sdk.navigation.LaneAccess
import com.here.sdk.navigation.LaneRecommendationState
import com.here.sdk.navigation.ManeuverNotificationOptions
import com.here.sdk.navigation.ManeuverViewLaneAssistanceListener
import com.here.sdk.navigation.MapMatchedLocation
import com.here.sdk.navigation.MilestoneStatus
import com.here.sdk.navigation.MilestoneStatusListener
import com.here.sdk.navigation.NavigableLocationListener
import com.here.sdk.navigation.RealisticViewWarningListener
import com.here.sdk.navigation.RealisticViewWarningOptions
import com.here.sdk.navigation.RoadAttributesListener
import com.here.sdk.navigation.RoadSignVehicleType
import com.here.sdk.navigation.RoadSignWarningListener
import com.here.sdk.navigation.RoadSignWarningOptions
import com.here.sdk.navigation.RoadTextsListener
import com.here.sdk.navigation.RouteDeviationListener
import com.here.sdk.navigation.RouteProgressListener
import com.here.sdk.navigation.SafetyCameraWarningListener
import com.here.sdk.navigation.SafetyCameraWarningOptions
import com.here.sdk.navigation.SchoolZoneWarningListener
import com.here.sdk.navigation.SchoolZoneWarningOptions
import com.here.sdk.navigation.SpeedLimit
import com.here.sdk.navigation.SpeedLimitListener
import com.here.sdk.navigation.SpeedLimitOffset
import com.here.sdk.navigation.SpeedWarningListener
import com.here.sdk.navigation.SpeedWarningOptions
import com.here.sdk.navigation.SpeedWarningStatus
import com.here.sdk.navigation.TextNotificationType
import com.here.sdk.navigation.TollStopWarningListener
import com.here.sdk.navigation.TruckRestrictionsWarningListener
import com.here.sdk.navigation.VisualNavigator
import com.here.sdk.routing.Maneuver
import com.here.sdk.routing.ManeuverAction
import com.here.sdk.routing.RoadType
import com.here.sdk.trafficawarenavigation.DynamicRoutingEngine
import com.oguzhnatly.flutter_carplay.CPMapTemplate
import com.oguzhnatly.flutter_carplay.FlutterCarplayPlugin
import com.oguzhnatly.flutter_carplay.models.map.FCPMapTemplate
import com.oguzhnatly.flutter_carplay.models.map.FCPMapViewController
import java.util.Arrays
import java.util.Date
import java.util.Locale

/**
 * This class combines the various events that can be emitted during turn-by-turn navigation.
 *
 * Note that this class does not show an exhaustive list of all possible events.
 */
class NavigationEventHandler {
    private var previousManeuverIndex = -1
    private var lastMapMatchedLocation: MapMatchedLocation? = null
    private val voiceAssistant: VoiceAssistant

    /// The voice instructions toggle button.
    private var isVoiceInstructionsMuted = false

    /// Check if a rerouting is in progress.
    private var isReroutingInProgress = false

    /// Route deviation event counter.
    private var deviationEventCount = 0

    /// Map template instance
    val mapTemplate: CPMapTemplate?
        get() = FlutterCarplayPlugin.rootTemplate as? CPMapTemplate

    /// FCP Map View Controller instance
    val fcpMapViewController: FCPMapViewController?
        get() = (FlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.fcpMapViewController

    /// Navigation session instance
//    val navigationSession: CPNavigationSession?
//        get() = (FlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.navigationSession

    init {
        // A helper class for TTS.
        voiceAssistant = VoiceAssistant()

        // Toggle voice instructions handler
        toggleVoiceInstructionsHandler = { isMuted ->
            isVoiceInstructionsMuted = isMuted

            // If voice instructions are muted, stop the voice assistant
            if (isMuted) voiceAssistant.stop()
        }
    }

    /**
     * Sets up listeners for the visual navigator.
     *
     * @param visualNavigator The VisualNavigator instance.
     * @param dynamicRoutingEngine The DynamicRoutingEngine instance.
     */
    fun setupListeners(
        visualNavigator: VisualNavigator,
        dynamicRoutingEngine: DynamicRoutingEngine?,
    ) {
        setupSpeedWarnings(visualNavigator)
        setupVoiceGuidance(visualNavigator)

        // Notifies on the progress along the route including maneuver instructions.
        visualNavigator.routeProgressListener = RouteProgressListener { routeProgress ->
            val sectionProgressList = routeProgress.sectionProgress
            // sectionProgressList is guaranteed to be non-empty.
            val lastSectionProgress = sectionProgressList[sectionProgressList.size - 1]
            Log.d(
                TAG,
                "Distance to destination in meters: " +
                        lastSectionProgress.remainingDistanceInMeters
            )
            Log.d(
                TAG,
                "Traffic delay ahead in seconds: " + lastSectionProgress.trafficDelay.seconds
            )

            // Contains the progress for the next maneuver ahead and the next-next maneuvers, if
            // any.
            val nextManeuverList = routeProgress.maneuverProgress

            val nextManeuverProgress = nextManeuverList[0]
            if (nextManeuverProgress == null) {
                Log.d(TAG, "No next maneuver available.")
                return@RouteProgressListener
            }

            val nextManeuverIndex = nextManeuverProgress.maneuverIndex
            val nextManeuver =
                visualNavigator.getManeuver(nextManeuverIndex)
                    ?: // Should never happen as we retrieved the next maneuver progress
                    // above.
                    return@RouteProgressListener

            val action = nextManeuver.action
            val roadName = getRoadName(nextManeuver)
            val logMessage =
                action.name +
                        " on " +
                        roadName +
                        " in " +
                        nextManeuverProgress.remainingDistanceInMeters +
                        " meters."

            // Angle is null for some maneuvers like Depart, Arrive and Roundabout.
            val turnAngle = nextManeuver.turnAngleInDegrees
            if (turnAngle != null) {
                if (turnAngle > 10) {
                    Log.d(TAG, "At the next maneuver: Make a right turn of $turnAngle degrees.")
                } else if (turnAngle < -10) {
                    Log.d(TAG, "At the next maneuver: Make a left turn of $turnAngle degrees.")
                } else {
                    Log.d(TAG, "At the next maneuver: Go straight.")
                }
            }

            // Angle is null when the roundabout maneuver is not an enter, exit or keep maneuver.
            val roundaboutAngle = nextManeuver.roundaboutAngleInDegrees
            if (roundaboutAngle != null) {
                // Note that the value is negative only for left-driving countries such as UK.
                Log.d(
                    TAG,
                    "At the next maneuver: Follow the roundabout for " +
                            roundaboutAngle +
                            " degrees to reach the exit."
                )
            }

            if (previousManeuverIndex != nextManeuverIndex) {
//                messageView.text = "New maneuver: $logMessage"
            } else {
                // A maneuver update contains a different distance to reach the next maneuver.
//                messageView.text = "Maneuver update: $logMessage"
            }

            previousManeuverIndex = nextManeuverIndex
            if (lastMapMatchedLocation != null) {
                // Update the route based on the current location of the driver.
                // We periodically want to search for better traffic-optimized routes.
                dynamicRoutingEngine!!.updateCurrentLocation(
                    lastMapMatchedLocation!!,
                    routeProgress.sectionIndex
                )
            }
        }

        // Notifies when the destination of the route is reached.
        visualNavigator.destinationReachedListener = DestinationReachedListener {
            val message = "Destination reached."
//            messageView.text = message
            // Guidance has stopped. Now consider to, for example,
            // switch to tracking mode or stop rendering or locating or do anything else that may
            // be useful to support your app flow.
            // If the DynamicRoutingEngine was started before, consider to stop it now.
        }

        // Notifies when a waypoint on the route is reached or missed.
        visualNavigator.milestoneStatusListener =
            MilestoneStatusListener { milestone, milestoneStatus ->
                if (milestone.waypointIndex != null &&
                    milestoneStatus == MilestoneStatus.REACHED
                ) {
                    Log.d(
                        TAG,
                        "A user-defined waypoint was reached, index of waypoint: " +
                                milestone.waypointIndex
                    )
                    Log.d(TAG, "Original coordinates: " + milestone.originalCoordinates)
                } else if (milestone.waypointIndex != null &&
                    milestoneStatus == MilestoneStatus.MISSED
                ) {
                    Log.d(
                        TAG,
                        "A user-defined waypoint was missed, index of waypoint: " +
                                milestone.waypointIndex
                    )
                    Log.d(TAG, "Original coordinates: " + milestone.originalCoordinates)
                } else if (milestone.waypointIndex == null &&
                    milestoneStatus == MilestoneStatus.REACHED
                ) {
                    // For example, when transport mode changes due to a ferry a system-defined
                    // waypoint may have been added.
                    Log.d(
                        TAG,
                        "A system-defined waypoint was reached at: " +
                                milestone.mapMatchedCoordinates
                    )
                } else if (milestone.waypointIndex == null &&
                    milestoneStatus == MilestoneStatus.MISSED
                ) {
                    // For example, when transport mode changes due to a ferry a system-defined
                    // waypoint may have been added.
                    Log.d(
                        TAG,
                        "A system-defined waypoint was missed at: " +
                                milestone.mapMatchedCoordinates
                    )
                }
            }

        // Notifies on safety camera warnings as they appear along the road.
        visualNavigator.safetyCameraWarningListener =
            SafetyCameraWarningListener { safetyCameraWarning ->
                if (safetyCameraWarning.distanceType == DistanceType.AHEAD) {
                    Log.d(
                        TAG,
                        "Safety camera warning " +
                                safetyCameraWarning.type.name +
                                " ahead in: " +
                                safetyCameraWarning.distanceToCameraInMeters +
                                "with speed limit =" +
                                safetyCameraWarning.speedLimitInMetersPerSecond +
                                "m/s"
                    )
                } else if (safetyCameraWarning.distanceType == DistanceType.PASSED) {
                    Log.d(
                        TAG,
                        "Safety camera warning " +
                                safetyCameraWarning.type.name +
                                " passed: " +
                                safetyCameraWarning.distanceToCameraInMeters +
                                "with speed limit =" +
                                safetyCameraWarning.speedLimitInMetersPerSecond +
                                "m/s"
                    )
                } else if (safetyCameraWarning.distanceType == DistanceType.REACHED) {
                    Log.d(
                        TAG,
                        "Safety camera warning " +
                                safetyCameraWarning.type.name +
                                " reached at: " +
                                safetyCameraWarning.distanceToCameraInMeters +
                                "with speed limit =" +
                                safetyCameraWarning.speedLimitInMetersPerSecond +
                                "m/s"
                    )
                }
            }

        val safetyCameraWarningOptions = SafetyCameraWarningOptions()
        // Warning distance setting for highways, defaults to 1500 meters.
        safetyCameraWarningOptions.highwayWarningDistanceInMeters = 1600
        // Warning distance setting for rural roads, defaults to 750 meters.
        safetyCameraWarningOptions.ruralWarningDistanceInMeters = 800
        // Warning distance setting for urban roads, defaults to 500 meters.
        safetyCameraWarningOptions.urbanWarningDistanceInMeters = 600
        visualNavigator.safetyCameraWarningOptions = safetyCameraWarningOptions

        // Notifies when the current speed limit is exceeded.
        visualNavigator.speedWarningListener = SpeedWarningListener { speedWarningStatus ->
            if (speedWarningStatus == SpeedWarningStatus.SPEED_LIMIT_EXCEEDED) {
                // Driver is faster than current speed limit (plus an optional offset).
                // Play a notification sound to alert the driver.
                // Note that this may not include temporary special speed limits, see
                // SpeedLimitListener.
//                val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
//                val ringtone = RingtoneManager.getRingtone(context, ringtoneUri)
//                ringtone.play()
            }
            if (speedWarningStatus == SpeedWarningStatus.SPEED_LIMIT_RESTORED) {
                Log.d(
                    TAG,
                    "Driver is again slower than current speed limit (plus an optional offset)."
                )
            }
        }

        // Notifies on the current speed limit valid on the current road.
        visualNavigator.speedLimitListener = SpeedLimitListener { speedLimit ->
            val currentSpeedLimit = getCurrentSpeedLimit(speedLimit)
            if (currentSpeedLimit == null) {
                Log.d(TAG, "Warning: Speed limits unknown, data could not be retrieved.")
            } else if (currentSpeedLimit == 0.0) {
                Log.d(TAG, "No speed limits on this road! Drive as fast as you feel safe ...")
            } else {
                Log.d(TAG, "Current speed limit (m/s):$currentSpeedLimit")
            }
        }

        // Notifies on the current map-matched location and other useful information while driving
        // or walking.
        visualNavigator.navigableLocationListener =
            NavigableLocationListener { currentNavigableLocation ->
                lastMapMatchedLocation = currentNavigableLocation.mapMatchedLocation
                if (lastMapMatchedLocation == null) {
                    Log.d(
                        TAG,
                        "The currentNavigableLocation could not be map-matched. Are you off-road?"
                    )
                    return@NavigableLocationListener
                }

                if (lastMapMatchedLocation!!.isDrivingInTheWrongWay) {
                    Log.d(TAG, "User is driving in the wrong direction of the route.")
                }

                val speed = currentNavigableLocation.originalLocation.speedInMetersPerSecond
                val accuracy =
                    currentNavigableLocation.originalLocation.speedAccuracyInMetersPerSecond
                Log.d(
                    TAG,
                    "Driving speed (m/s): " +
                            speed +
                            "plus/minus an accuracy of: " +
                            accuracy
                )
            }

        // Notifies on a possible deviation from the route.
        visualNavigator.routeDeviationListener = RouteDeviationListener { routeDeviation ->
            val route =
                visualNavigator.route
                    ?: // May happen in rare cases when route was set to null inbetween.
                    return@RouteDeviationListener
            // Get current geographic coordinates.
            val currentMapMatchedLocation = routeDeviation.currentLocation.mapMatchedLocation
            val currentGeoCoordinates =
                currentMapMatchedLocation?.coordinates
                    ?: routeDeviation.currentLocation.originalLocation.coordinates

            // Get last geographic coordinates on route.
            val lastGeoCoordinatesOnRoute: GeoCoordinates?
            if (routeDeviation.lastLocationOnRoute != null) {
                val lastMapMatchedLocationOnRoute =
                    routeDeviation.lastLocationOnRoute!!.mapMatchedLocation
                lastGeoCoordinatesOnRoute =
                    lastMapMatchedLocationOnRoute?.coordinates
                        ?: routeDeviation.lastLocationOnRoute!!.originalLocation.coordinates
            } else {
                Log.d(
                    TAG,
                    "User was never following the route. So, we take the start of the route instead."
                )
                lastGeoCoordinatesOnRoute = route.sections[0].departurePlace.originalCoordinates
            }

            val distanceInMeters =
                currentGeoCoordinates.distanceTo(lastGeoCoordinatesOnRoute!!).toInt()
            Log.d(TAG, "RouteDeviation in meters is $distanceInMeters")

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
        }

        // Notifies on messages that can be fed into TTS engines to guide the user with audible
        // instructions.
        // The texts can be maneuver instructions or warn on certain obstacles, such as speed
        // cameras.
        visualNavigator.eventTextListener =
            EventTextListener {
                    eventText,
                -> // We use the built-in TTS engine to synthesize the localized text as audio.
                voiceAssistant.speak(eventText.text)
                // We can optionally retrieve the associated maneuver. The details will be null
                // if the text contains
                // non-maneuver related information, such as for speed camera warnings.
                if (eventText.type == TextNotificationType.MANEUVER &&
                    eventText.maneuverNotificationDetails != null
                ) {
                    val maneuver = eventText.maneuverNotificationDetails!!.maneuver
                }
            }

        // Notifies which lane(s) lead to the next (next) maneuvers.
        visualNavigator.maneuverViewLaneAssistanceListener =
            ManeuverViewLaneAssistanceListener {
                    maneuverViewLaneAssistance,
                -> // This lane list is guaranteed to be non-empty.
                val lanes = maneuverViewLaneAssistance.lanesForNextManeuver
                logLaneRecommendations(lanes)

                val nextLanes = maneuverViewLaneAssistance.lanesForNextNextManeuver
                if (!nextLanes.isEmpty()) {
                    Log.d(TAG, "Attention, the next next maneuver is very close.")
                    Log.d(TAG, "Please take the following lane(s) after the next maneuver: ")
                    logLaneRecommendations(nextLanes)
                }
            }

        // Notifies which lane(s) allow to follow the route.
        visualNavigator.junctionViewLaneAssistanceListener =
            JunctionViewLaneAssistanceListener { junctionViewLaneAssistance ->
                val lanes = junctionViewLaneAssistance.lanesForNextJunction
                if (lanes.isEmpty()) {
                    Log.d(TAG, "You have passed the complex junction.")
                } else {
                    Log.d(TAG, "Attention, a complex junction is ahead.")
                    logLaneRecommendations(lanes)
                }
            }

        // Notifies on the attributes of the current road including usage and physical
        // characteristics.
        visualNavigator.roadAttributesListener = RoadAttributesListener { roadAttributes ->
            // This is called whenever any road attribute has changed.
            // If all attributes are unchanged, no new event is fired.
            // Note that a road can have more than one attribute at the same time.

            Log.d(TAG, "Received road attributes update.")

            if (roadAttributes.isBridge) {
                // Identifies a structure that allows a road, railway, or walkway to pass over
                // another road, railway,
                // waterway, or valley serving map display and route guidance functionalities.
                Log.d(TAG, "Road attributes: This is a bridge.")
            }
            if (roadAttributes.isControlledAccess) {
                // Controlled access roads are roads with limited entrances and exits that allow
                // uninterrupted
                // high-speed traffic flow.
                Log.d(TAG, "Road attributes: This is a controlled access road.")
            }
            if (roadAttributes.isDirtRoad) {
                // Indicates whether the navigable segment is paved.
                Log.d(TAG, "Road attributes: This is a dirt road.")
            }
            if (roadAttributes.isDividedRoad) {
                // Indicates if there is a physical structure or painted road marking intended to
                // legally prohibit
                // left turns in right-side driving countries, right turns in left-side driving
                // countries,
                // and U-turns at divided intersections or in the middle of divided segments.
                Log.d(TAG, "Road attributes: This is a divided road.")
            }
            if (roadAttributes.isNoThrough) {
                // Identifies a no through road.
                Log.d(TAG, "Road attributes: This is a no through road.")
            }
            if (roadAttributes.isPrivate) {
                // Private identifies roads that are not maintained by an organization responsible
                // for maintenance of
                // public roads.
                Log.d(TAG, "Road attributes: This is a private road.")
            }
            if (roadAttributes.isRamp) {
                // Range is a ramp: connects roads that do not intersect at grade.
                Log.d(TAG, "Road attributes: This is a ramp.")
            }
            if (roadAttributes.isRightDrivingSide) {
                // Indicates if vehicles have to drive on the right-hand side of the road or the
                // left-hand side.
                // For example, in New York it is always true and in London always false as the
                // United Kingdom is
                // a left-hand driving country.
                Log.d(
                    TAG,
                    "Road attributes: isRightDrivingSide = " + roadAttributes.isRightDrivingSide
                )
            }
            if (roadAttributes.isRoundabout) {
                // Indicates the presence of a roundabout.
                Log.d(TAG, "Road attributes: This is a roundabout.")
            }
            if (roadAttributes.isTollway) {
                // Identifies a road for which a fee must be paid to use the road.
                Log.d(TAG, "Road attributes change: This is a road with toll costs.")
            }
            if (roadAttributes.isTunnel) {
                // Identifies an enclosed (on all sides) passageway through or under an obstruction.
                Log.d(TAG, "Road attributes: This is a tunnel.")
            }
        }

        val roadSignWarningOptions = RoadSignWarningOptions()
        // Set a filter to get only shields relevant for TRUCKS and HEAVY_TRUCKS.
        roadSignWarningOptions.vehicleTypesFilter =
            Arrays.asList(RoadSignVehicleType.TRUCKS, RoadSignVehicleType.HEAVY_TRUCKS)
        // Warning distance setting for highways, defaults to 1500 meters.
        roadSignWarningOptions.highwayWarningDistanceInMeters = 1600
        // Warning distance setting for rural roads, defaults to 750 meters.
        roadSignWarningOptions.ruralWarningDistanceInMeters = 800
        // Warning distance setting for urban roads, defaults to 500 meters.
        roadSignWarningOptions.urbanWarningDistanceInMeters = 600
        visualNavigator.roadSignWarningOptions = roadSignWarningOptions

        // Notifies on road shields as they appear along the road.
        visualNavigator.roadSignWarningListener = RoadSignWarningListener { roadSignWarning ->
            Log.d(TAG, "Road sign distance (m): " + roadSignWarning.distanceToRoadSignInMeters)
            Log.d(TAG, "Road sign type: " + roadSignWarning.type.name)

            if (roadSignWarning.signValue != null) {
                // Optional text as it is printed on the local road sign.
                Log.d(TAG, "Road sign text: " + roadSignWarning.signValue!!.text)
            }
            // For more road sign attributes, please check the API Reference.
        }

        // Notifies truck drivers on road restrictions ahead. Called whenever there is a change.
        // For example, there can be a bridge ahead not high enough to pass a big truck
        // or there can be a road ahead where the weight of the truck is beyond it's permissible
        // weight.
        // This event notifies on truck restrictions in general,
        // so it will also deliver events, when the transport type was set to a non-truck transport
        // type.
        // The given restrictions are based on the HERE database of the road network ahead.
        visualNavigator.truckRestrictionsWarningListener =
            TruckRestrictionsWarningListener { list ->
                // The list is guaranteed to be non-empty.
                for (truckRestrictionWarning in list) {
                    if (truckRestrictionWarning.distanceType == DistanceType.AHEAD) {
                        Log.d(
                            TAG,
                            "TruckRestrictionWarning ahead in: " +
                                    truckRestrictionWarning.distanceInMeters +
                                    " meters."
                        )
                        if (truckRestrictionWarning.timeRule != null &&
                            !truckRestrictionWarning.timeRule!!.appliesTo(Date())
                        ) {
                            // For example, during a specific time period of a day, some truck
                            // restriction warnings do not apply.
                            // If truckRestrictionWarning.timeRule is null, the warning applies
                            // at anytime.
                            Log.d(
                                TAG,
                                "Note that this truck restriction warning currently does not apply."
                            )
                        }
                    } else if (truckRestrictionWarning.distanceType == DistanceType.REACHED) {
                        Log.d(TAG, "A restriction has been reached.")
                    } else if (truckRestrictionWarning.distanceType == DistanceType.PASSED) {
                        // If not preceded by a "REACHED"-notification, this restriction was
                        // valid only for the passed location.
                        Log.d(TAG, "A restriction just passed.")
                    }

                    // One of the following restrictions applies ahead, if more restrictions
                    // apply at the same time,
                    // they are part of another TruckRestrictionWarning element contained in the
                    // list.
                    if (truckRestrictionWarning.weightRestriction != null) {
                        val type = truckRestrictionWarning.weightRestriction!!.type
                        val value = truckRestrictionWarning.weightRestriction!!.valueInKilograms
                        Log.d(
                            TAG,
                            "TruckRestriction for weight (kg): " + type.name + ": " + value
                        )
                    } else if (truckRestrictionWarning.dimensionRestriction != null) {
                        // Can be either a length, width or height restriction of the truck. For
                        // example, a height
                        // restriction can apply for a tunnel. Other possible restrictions are
                        // delivered in
                        // separate TruckRestrictionWarning objects contained in the list, if
                        // any.
                        val type = truckRestrictionWarning.dimensionRestriction!!.type
                        val value =
                            truckRestrictionWarning.dimensionRestriction!!
                                .valueInCentimeters
                        Log.d(
                            TAG,
                            "TruckRestriction for dimension: " + type.name + ": " + value
                        )
                    } else {
                        Log.d(TAG, "TruckRestriction: General restriction - no trucks allowed.")
                    }
                }
            }

        // Notifies on school zones ahead.
        visualNavigator.schoolZoneWarningListener = SchoolZoneWarningListener { list ->
            // The list is guaranteed to be non-empty.
            for (schoolZoneWarning in list) {
                if (schoolZoneWarning.distanceType == DistanceType.AHEAD) {
                    Log.d(
                        TAG,
                        "A school zone ahead in: " +
                                schoolZoneWarning.distanceToSchoolZoneInMeters +
                                " meters."
                    )
                    // Note that this will be the same speed limit as indicated by
                    // SpeedLimitListener, unless
                    // already a lower speed limit applies, for example, because of a heavy truck
                    // load.
                    Log.d(
                        TAG,
                        "Speed limit restriction for this school zone: " +
                                schoolZoneWarning.speedLimitInMetersPerSecond +
                                " m/s."
                    )
                    if (schoolZoneWarning.timeRule != null &&
                        !schoolZoneWarning.timeRule!!.appliesTo(Date())
                    ) {
                        // For example, during night sometimes a school zone warning does not apply.
                        // If schoolZoneWarning.timeRule is null, the warning applies at anytime.
                        Log.d(TAG, "Note that this school zone warning currently does not apply.")
                    }
                } else if (schoolZoneWarning.distanceType == DistanceType.REACHED) {
                    Log.d(TAG, "A school zone has been reached.")
                } else if (schoolZoneWarning.distanceType == DistanceType.PASSED) {
                    Log.d(TAG, "A school zone has been passed.")
                }
            }
        }

        val schoolZoneWarningOptions = SchoolZoneWarningOptions()
        schoolZoneWarningOptions.filterOutInactiveTimeDependentWarnings = true
        schoolZoneWarningOptions.warningDistanceInMeters = 150
        visualNavigator.schoolZoneWarningOptions = schoolZoneWarningOptions

        // Notifies whenever a border is crossed of a country and optionally, by default, also when
        // a state
        // border of a country is crossed.
        visualNavigator.borderCrossingWarningListener =
            BorderCrossingWarningListener { borderCrossingWarning ->
                // Since the border crossing warning is given relative to a single location,
                // the DistanceType.REACHED will never be given for this warning.
                if (borderCrossingWarning.distanceType == DistanceType.AHEAD) {
                    Log.d(
                        TAG,
                        "BorderCrossing: A border is ahead in: " +
                                borderCrossingWarning.distanceToBorderCrossingInMeters +
                                " meters."
                    )
                    Log.d(
                        TAG,
                        "BorderCrossing: Type (such as country or state): " +
                                borderCrossingWarning.type.name
                    )
                    Log.d(
                        TAG,
                        "BorderCrossing: Country code: " +
                                borderCrossingWarning.countryCode.name
                    )

                    // The state code after the border crossing. It represents the state /
                    // province code.
                    // It is a 1 to 3 upper-case characters string that follows the ISO 3166-2
                    // standard,
                    // but without the preceding country code (e.g. for Texas, the state code
                    // will be TX).
                    // It will be null for countries without states or countries in which the
                    // states have very
                    // similar regulations (e.g. for Germany there will be no state borders).
                    if (borderCrossingWarning.stateCode != null) {
                        Log.d(
                            TAG,
                            "BorderCrossing: State code: " + borderCrossingWarning.stateCode
                        )
                    }

                    // The general speed limits that apply in the country / state after border
                    // crossing.
                    val generalVehicleSpeedLimits = borderCrossingWarning.speedLimits
                    Log.d(
                        TAG,
                        "BorderCrossing: Speed limit in cities (m/s): " +
                                generalVehicleSpeedLimits.maxSpeedUrbanInMetersPerSecond
                    )
                    Log.d(
                        TAG,
                        "BorderCrossing: Speed limit outside cities (m/s): " +
                                generalVehicleSpeedLimits.maxSpeedRuralInMetersPerSecond
                    )
                    Log.d(
                        TAG,
                        "BorderCrossing: Speed limit on highways (m/s): " +
                                generalVehicleSpeedLimits.maxSpeedHighwaysInMetersPerSecond
                    )
                } else if (borderCrossingWarning.distanceType == DistanceType.PASSED) {
                    Log.d(TAG, "BorderCrossing: A border has been passed.")
                }
            }

        val borderCrossingWarningOptions = BorderCrossingWarningOptions()
        // If set to true, all the state border crossing notifications will not be given.
        // If the value is false, all border crossing notifications will be given for both
        // country borders and state borders. Defaults to false.
        borderCrossingWarningOptions.filterOutStateBorderWarnings = true
        // Warning distance setting for urban, in meters. Defaults to 500 meters.
        borderCrossingWarningOptions.urbanWarningDistanceInMeters = 400
        visualNavigator.borderCrossingWarningOptions = borderCrossingWarningOptions

        // Notifies on danger zones.
        // A danger zone refers to areas where there is an increased risk of traffic incidents.
        // These zones are designated to alert drivers to potential hazards and encourage safer
        // driving behaviors.
        // The HERE SDK warns when approaching the danger zone, as well as when leaving such a zone.
        // A danger zone may or may not have one or more speed cameras in it. The exact location of
        // such speed cameras
        // is not provided. Note that danger zones are only available in selected countries, such as
        // France.
        visualNavigator.dangerZoneWarningListener = DangerZoneWarningListener { dangerZoneWarning ->
            if (dangerZoneWarning.distanceType == DistanceType.AHEAD) {
                Log.d(
                    TAG,
                    "A danger zone ahead in: " + dangerZoneWarning.distanceInMeters + " meters."
                )
                // isZoneStart indicates if we enter the danger zone from the start.
                // It is false, when the danger zone is entered from a side street.
                // Based on the route path, the HERE SDK anticipates from where the danger zone will
                // be entered.
                // In tracking mode, the most probable path will be used to anticipate from where
                // the danger zone is entered.
                Log.d(TAG, "isZoneStart: " + dangerZoneWarning.isZoneStart)
            } else if (dangerZoneWarning.distanceType == DistanceType.REACHED) {
                Log.d(
                    TAG,
                    "A danger zone has been reached. isZoneStart: " +
                            dangerZoneWarning.isZoneStart
                )
            } else if (dangerZoneWarning.distanceType == DistanceType.PASSED) {
                Log.d(TAG, "A danger zone has been passed.")
            }
        }

        val dangerZoneWarningOptions = DangerZoneWarningOptions()
        // Distance setting for urban, in meters. Defaults to 500 meters.
        dangerZoneWarningOptions.urbanWarningDistanceInMeters = 400
        visualNavigator.dangerZoneWarningOptions = dangerZoneWarningOptions

        // Notifies whenever any textual attribute of the current road changes, i.e., the current
        // road texts differ
        // from the previous one. This can be useful during tracking mode, when no maneuver
        // information is provided.
        visualNavigator.roadTextsListener =
            RoadTextsListener {
                // See getRoadName() how to get the current road name from the provided
                // RoadTexts.
            }

        val realisticViewWarningOptions = RealisticViewWarningOptions()
        realisticViewWarningOptions.aspectRatio = AspectRatio.ASPECT_RATIO_3_X_4
        realisticViewWarningOptions.darkTheme = false
        // Warning distance setting for highways, defaults to 1500 meters.
        realisticViewWarningOptions.highwayWarningDistanceInMeters = 1600
        // Warning distance setting for rural roads, defaults to 750 meters.
        realisticViewWarningOptions.ruralWarningDistanceInMeters = 800
        // Warning distance setting for urban roads, defaults to 500 meters.
        realisticViewWarningOptions.urbanWarningDistanceInMeters = 600
        visualNavigator.realisticViewWarningOptions = realisticViewWarningOptions

        // Notifies on signposts together with complex junction views.
        // Signposts are shown as they appear along a road on a shield to indicate the upcoming
        // directions and
        // destinations, such as cities or road names.
        // Junction views appear as a 3D visualization (as a static image) to help the driver to
        // orientate.
        //
        // Optionally, you can use a feature-configuration to preload the assets as part of a
        // Region.
        //
        // The event matches the notification for complex junctions, see JunctionViewLaneAssistance.
        // Note that the SVG data for junction view is composed out of several 3D elements,
        // a horizon and the actual junction geometry.
        visualNavigator.realisticViewWarningListener =
            RealisticViewWarningListener { realisticViewWarning ->
                val distance = realisticViewWarning.distanceToRealisticViewInMeters
                val distanceType = realisticViewWarning.distanceType

                // Note that DistanceType.REACHED is not used for Signposts and junction views
                // as a junction is identified through a location instead of an area.
                if (distanceType == DistanceType.AHEAD) {
                    Log.d(TAG, "A RealisticView ahead in: $distance meters.")
                } else if (distanceType == DistanceType.PASSED) {
                    Log.d(TAG, "A RealisticView just passed.")
                }

                val realisticView = realisticViewWarning.realisticView
                if (realisticView == null) {
                    Log.d(TAG, "A RealisticView just passed. No SVG data delivered.")
                    return@RealisticViewWarningListener
                }

                val signpostSvgImageContent = realisticView.signpostSvgImageContent
                val junctionViewSvgImageContent = realisticView.junctionViewSvgImageContent
                // The resolution-independent SVG data can now be used in an application to
                // visualize the image.
                // Use a SVG library of your choice to create an SVG image out of the SVG
                // string.
                // Both SVGs contain the same dimension and the signpostSvgImageContent should
                // be shown on top of
                // the junctionViewSvgImageContent.
                // The images can be quite detailed, therefore it is recommended to show them on
                // a secondary display
                // in full size.
                Log.d("signpostSvgImage", signpostSvgImageContent)
                Log.d("junctionViewSvgImage", junctionViewSvgImageContent)
            }

        // Notifies on upcoming toll stops. Uses the same notification
        // thresholds as other warners and provides events with or without a route to follow.
        visualNavigator.tollStopWarningListener = TollStopWarningListener { tollStop ->
            val lanes = tollStop.lanes
            // The lane at index 0 is the leftmost lane adjacent to the middle of the road.
            // The lane at the last index is the rightmost lane.
            val laneNumber = 0
            for (tollBoothLane in lanes) {
                // Log which vehicles types are allowed on this lane that leads to the toll booth.
                logLaneAccess(laneNumber, tollBoothLane.access)
                val tollBooth = tollBoothLane.booth
                val tollCollectionMethods = tollBooth.tollCollectionMethods
                val paymentMethods = tollBooth.paymentMethods
                // The supported collection methods like ticket or automatic / electronic.
                for (collectionMethod in tollCollectionMethods) {
                    Log.d(TAG, "This toll stop supports collection via: " + collectionMethod.name)
                }
                // The supported payment methods like cash or credit card.
                for (paymentMethod in paymentMethods) {
                    Log.d(TAG, "This toll stop supports payment via: " + paymentMethod.name)
                }
            }
        }
    }

    /** Stops the voice assistant. */
    fun stopVoiceAssistant() {
        voiceAssistant.stop()
    }

    /** Reset the previous maneuver index. */
    fun resetPreviousManeuverIndex() {
        previousManeuverIndex = -1
    }

    private fun setupSpeedWarnings(visualNavigator: VisualNavigator) {
        val speedLimitOffset = SpeedLimitOffset()
        speedLimitOffset.lowSpeedOffsetInMetersPerSecond = 2.0
        speedLimitOffset.highSpeedOffsetInMetersPerSecond = 4.0
        speedLimitOffset.highSpeedBoundaryInMetersPerSecond = 25.0

        visualNavigator.speedWarningOptions = SpeedWarningOptions(speedLimitOffset)
    }

    private fun setupVoiceGuidance(visualNavigator: VisualNavigator) {
        val ttsLanguageCode =
            getLanguageCodeForDevice(
                VisualNavigator.getAvailableLanguagesForManeuverNotifications()
            )
        visualNavigator.maneuverNotificationOptions =
            ManeuverNotificationOptions(ttsLanguageCode, UnitSystem.METRIC)
        Log.d(TAG, "LanguageCode for maneuver notifications: $ttsLanguageCode")

        // Set language to our TextToSpeech engine.
        val locale = LanguageCodeConverter.getLocale(ttsLanguageCode)
        if (voiceAssistant.setLanguage(locale)) {
            Log.d(TAG, "TextToSpeech engine uses this language: $locale")
        } else {
            Log.e(TAG, "TextToSpeech engine does not support this language: $locale")
        }
    }

    // Get the language preferably used on this device.
    private fun getLanguageCodeForDevice(supportedVoiceSkins: List<LanguageCode>): LanguageCode {
        // 1. Determine if preferred device language is supported by our TextToSpeech engine.

        var localeForCurrenDevice = Locale.getDefault()
        if (!voiceAssistant.isLanguageAvailable(localeForCurrenDevice)) {
            Log.e(
                TAG,
                "TextToSpeech engine does not support: $localeForCurrenDevice, falling back to EN_US."
            )
            localeForCurrenDevice = Locale("en", "US")
        }

        // 2. Determine supported voice skins from HERE SDK.
        var languageCodeForCurrentDevice: LanguageCode =
            LanguageCodeConverter.getLanguageCode(localeForCurrenDevice)
        if (!supportedVoiceSkins.contains(languageCodeForCurrentDevice)) {
            Log.e(
                TAG,
                "No voice skins available for $languageCodeForCurrentDevice, falling back to EN_US."
            )
            languageCodeForCurrentDevice = LanguageCode.EN_US
        }

        return languageCodeForCurrentDevice
    }

    private fun getRoadName(maneuver: Maneuver): String {
        val currentRoadTexts = maneuver.roadTexts
        val nextRoadTexts = maneuver.nextRoadTexts

        val currentRoadName = currentRoadTexts.names.defaultValue
        val currentRoadNumber = currentRoadTexts.numbersWithDirection.defaultValue
        val nextRoadName = nextRoadTexts.names.defaultValue
        val nextRoadNumber = nextRoadTexts.numbersWithDirection.defaultValue

        var roadName = nextRoadName ?: nextRoadNumber

        // On highways, we want to show the highway number instead of a possible road name,
        // while for inner city and urban areas road names are preferred over road numbers.
        if (maneuver.nextRoadType == RoadType.HIGHWAY) {
            roadName = nextRoadNumber ?: nextRoadName
        }

        if (maneuver.action == ManeuverAction.ARRIVE) {
            // We are approaching the destination, so there's no next road.
            roadName = currentRoadName ?: currentRoadNumber
        }

        if (roadName == null) {
            // Happens only in rare cases, when also the fallback is null.
            roadName = "unnamed road"
        }

        return roadName
    }

    private fun getCurrentSpeedLimit(speedLimit: SpeedLimit): Double? {
        // Note that all values can be null if no data is available.

        // The regular speed limit if available. In case of unbounded speed limit, the value is
        // zero.

        Log.d(TAG, "speedLimitInMetersPerSecond: " + speedLimit.speedLimitInMetersPerSecond)

        // A conditional school zone speed limit as indicated on the local road signs.
        Log.d(
            TAG,
            "schoolZoneSpeedLimitInMetersPerSecond: " +
                    speedLimit.schoolZoneSpeedLimitInMetersPerSecond
        )

        // A conditional time-dependent speed limit as indicated on the local road signs.
        // It is in effect considering the current local time provided by the device's clock.
        Log.d(
            TAG,
            "timeDependentSpeedLimitInMetersPerSecond: " +
                    speedLimit.timeDependentSpeedLimitInMetersPerSecond
        )

        // A conditional non-legal speed limit that recommends a lower speed,
        // for example, due to bad road conditions.
        Log.d(
            TAG,
            "advisorySpeedLimitInMetersPerSecond: " +
                    speedLimit.advisorySpeedLimitInMetersPerSecond
        )

        // A weather-dependent speed limit as indicated on the local road signs.
        // The HERE SDK cannot detect the current weather condition, so a driver must decide
        // based on the situation if this speed limit applies.
        Log.d(TAG, "fogSpeedLimitInMetersPerSecond: " + speedLimit.fogSpeedLimitInMetersPerSecond)
        Log.d(TAG, "rainSpeedLimitInMetersPerSecond: " + speedLimit.rainSpeedLimitInMetersPerSecond)
        Log.d(TAG, "snowSpeedLimitInMetersPerSecond: " + speedLimit.snowSpeedLimitInMetersPerSecond)

        // For convenience, this returns the effective (lowest) speed limit between
        // - speedLimitInMetersPerSecond
        // - schoolZoneSpeedLimitInMetersPerSecond
        // - timeDependentSpeedLimitInMetersPerSecond
        return speedLimit.effectiveSpeedLimitInMetersPerSecond()
    }

    private fun logLaneRecommendations(lanes: List<Lane>) {
        // The lane at index 0 is the leftmost lane adjacent to the middle of the road.
        // The lane at the last index is the rightmost lane.
        var laneNumber = 0
        for (lane in lanes) {
            // This state is only possible if maneuverViewLaneAssistance.lanesForNextNextManeuver is
            // not empty.
            // For example, when two lanes go left, this lanes leads only to the next maneuver,
            // but not to the maneuver after the next maneuver, while the highly recommended lane
            // also leads
            // to this next next maneuver.
            if (lane.recommendationState == LaneRecommendationState.RECOMMENDED) {
                Log.d(
                    TAG,
                    "Lane $laneNumber leads to next maneuver, but not to the next next maneuver."
                )
            }

            // If laneAssistance.lanesForNextNextManeuver is not empty, this lane leads also to the
            // maneuver after the next maneuver.
            if (lane.recommendationState == LaneRecommendationState.HIGHLY_RECOMMENDED) {
                Log.d(
                    TAG,
                    "Lane $laneNumber leads to next maneuver and eventually to the next next maneuver."
                )
            }

            if (lane.recommendationState == LaneRecommendationState.NOT_RECOMMENDED) {
                Log.d(TAG, "Do not take lane $laneNumber to follow the route.")
            }

            logLaneDetails(laneNumber, lane)

            laneNumber++
        }
    }

    private fun logLaneDetails(laneNumber: Int, lane: Lane) {
        // All directions can be true or false at the same time.
        // The possible lane directions are valid independent of a route.
        // If a lane leads to multiple directions and is recommended, then all directions lead to
        // the next maneuver.
        // You can use this information like in a bitmask to visualize the possible directions
        // with a set of image overlays.
        val laneDirectionCategory = lane.directionCategory
        Log.d(TAG, "Directions for lane $laneNumber")
        Log.d(TAG, "laneDirectionCategory.straight: " + laneDirectionCategory.straight)
        Log.d(TAG, "laneDirectionCategory.slightlyLeft: " + laneDirectionCategory.slightlyLeft)
        Log.d(TAG, "laneDirectionCategory.quiteLeft: " + laneDirectionCategory.quiteLeft)
        Log.d(TAG, "laneDirectionCategory.hardLeft: " + laneDirectionCategory.hardLeft)
        Log.d(TAG, "laneDirectionCategory.uTurnLeft: " + laneDirectionCategory.uTurnLeft)
        Log.d(TAG, "laneDirectionCategory.slightlyRight: " + laneDirectionCategory.slightlyRight)
        Log.d(TAG, "laneDirectionCategory.quiteRight: " + laneDirectionCategory.quiteRight)
        Log.d(TAG, "laneDirectionCategory.hardRight: " + laneDirectionCategory.hardRight)
        Log.d(TAG, "laneDirectionCategory.uTurnRight: " + laneDirectionCategory.uTurnRight)

        // More information on each lane is available in these bitmasks (boolean):
        // LaneType provides lane properties such as if parking is allowed.
        val laneType = lane.type
        // LaneAccess provides which vehicle type(s) are allowed to access this lane.
        val laneAccess = lane.access
        logLaneAccess(laneNumber, laneAccess)
    }

    private fun logLaneAccess(laneNumber: Int, laneAccess: LaneAccess) {
        Log.d(TAG, "Lane access for lane $laneNumber")
        Log.d(TAG, "Automobiles are allowed on this lane: " + laneAccess.automobiles)
        Log.d(TAG, "Buses are allowed on this lane: " + laneAccess.buses)
        Log.d(TAG, "Taxis are allowed on this lane: " + laneAccess.taxis)
        Log.d(TAG, "Carpools are allowed on this lane: " + laneAccess.carpools)
        Log.d(TAG, "Pedestrians are allowed on this lane: " + laneAccess.pedestrians)
        Log.d(TAG, "Trucks are allowed on this lane: " + laneAccess.trucks)
        Log.d(TAG, "ThroughTraffic is allowed on this lane: " + laneAccess.throughTraffic)
        Log.d(TAG, "DeliveryVehicles are allowed on this lane: " + laneAccess.deliveryVehicles)
        Log.d(TAG, "EmergencyVehicles are allowed on this lane: " + laneAccess.emergencyVehicles)
        Log.d(TAG, "Motorcycles are allowed on this lane: " + laneAccess.motorcycles)
    }

    companion object {
        private val TAG: String = NavigationEventHandler::class.java.name
    }
}
