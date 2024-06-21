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
import com.here.sdk.core.Anchor2D
import com.here.sdk.core.GeoCoordinates
import com.here.sdk.core.Location
import com.here.sdk.core.engine.SDKNativeEngine
import com.here.sdk.core.errors.InstantiationErrorException
import com.here.sdk.location.LocationAccuracy
import com.here.sdk.mapview.MapSurface
import com.here.sdk.navigation.DynamicCameraBehavior
import com.here.sdk.navigation.VisualNavigator
import com.here.sdk.prefetcher.RoutePrefetcher
import com.here.sdk.routing.Route
import com.here.sdk.routing.RoutingError
import com.here.sdk.trafficawarenavigation.DynamicRoutingEngine
import com.here.sdk.trafficawarenavigation.DynamicRoutingEngine.StartException
import com.here.sdk.trafficawarenavigation.DynamicRoutingEngineOptions
import com.here.sdk.trafficawarenavigation.DynamicRoutingListener
import com.here.time.Duration
import com.oguzhnatly.flutter_carplay.FlutterCarplayPlugin
import com.oguzhnatly.flutter_carplay.models.map.FCPMapTemplate
import com.oguzhnatly.flutter_carplay.models.map.FCPMapViewController

/**
 * Shows how to start and stop turn-by-turn navigation on a car route.
 * By default, tracking mode is enabled. When navigation is stopped, tracking mode is enabled again.
 * The preferred device language determines the language for voice notifications used for TTS.
 * (Make sure to set language + region in device settings.)
 */
class NavigationHelper(val mapView: MapSurface) {
    private var visualNavigator: VisualNavigator
    private lateinit var dynamicRoutingEngine: DynamicRoutingEngine

    // A class to receive real location events.
    private val herePositioningProvider: HEREPositioningProvider = HEREPositioningProvider()

    // A class to receive simulated location events.
    private val herePositioningSimulator: HEREPositioningSimulator = HEREPositioningSimulator()

    // The RoutePrefetcher downloads map data in advance into the map cache.
    // This is not mandatory, but can help to improve the guidance experience.
    private val routePrefetcher: RoutePrefetcher =
        RoutePrefetcher(SDKNativeEngine.getSharedInstance()!!)

    val navigationEventHandler: NavigationEventHandler

    var visualNavigatorCameraPoint: Anchor2D? = null
        private set
    
    var isNavigationInProgress = false

    val lastKnownLocation: Location?
        get() = herePositioningProvider.lastKnownLocation

    /// FCP Map View Controller instance
    val fcpMapViewController: FCPMapViewController?
        get() = (FlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.fcpMapViewController

    init {
        try {
            // Without a route set, this starts tracking mode.
            visualNavigator = VisualNavigator()
        } catch (e: InstantiationErrorException) {
            throw RuntimeException("Initialization of VisualNavigator failed: " + e.error.name)
        }

        // This enables a navigation view including a rendered navigation arrow.
        visualNavigator.startRendering(mapView)

        createDynamicRoutingEngine()

        // A class to handle various kinds of guidance events.
        navigationEventHandler = NavigationEventHandler()
        visualNavigator.let {
            navigationEventHandler.setupListeners(it, dynamicRoutingEngine)
        }

    }

    /** Starts location updates. */
    fun startLocationProvider() {
        // Set navigator as listener to receive locations from HERE Positioning
        // and choose a suitable accuracy for the tbt navigation use case.
        herePositioningProvider.startLocating(visualNavigator, LocationAccuracy.NAVIGATION)
    }

    /**
     * Prefetches map data around the provided location with a radius of 2 km into the map cache.
     * For the best experience, this function should be called as early as possible.
     *
     * @param currentGeoCoordinates The current GeoCoordinates of the user's location.
     */
    private fun prefetchMapData(currentGeoCoordinates: GeoCoordinates) {
        // Prefetches map data around the provided location with a radius of 2 km into the map
        // cache.
        // For the best experience, prefetchAroundLocationWithRadius() should be called as early as
        // possible.
        val radiusInMeters = 2000.0
        routePrefetcher.prefetchAroundLocationWithRadius(currentGeoCoordinates, radiusInMeters)
        // Prefetches map data within a corridor along the route that is currently set to the
        // provided Navigator instance.
        // This happens continuously in discrete intervals.
        // If no route is set, no data will be prefetched.
        routePrefetcher.prefetchAroundRouteOnIntervals(visualNavigator)
    }

    // Use this engine to periodically search for better routes during guidance, ie. when the
    // traffic
    // situation changes.
    private fun createDynamicRoutingEngine() {
        val dynamicRoutingOptions = DynamicRoutingEngineOptions()
        // Both, minTimeDifference and minTimeDifferencePercentage, will be checked:
        // When the poll interval is reached, the smaller difference will win.
        dynamicRoutingOptions.minTimeDifference = Duration.ofSeconds(1)
        dynamicRoutingOptions.minTimeDifferencePercentage = 0.1
        dynamicRoutingOptions.pollInterval = Duration.ofMinutes(5)

        try {
            // With the dynamic routing engine you can poll the HERE backend services to search for
            // routes with less traffic.
            // This can happen during guidance - or you can periodically update a route that is
            // shown in a route planner.
            //
            // Make sure to call dynamicRoutingEngine.updateCurrentLocation(...) to trigger
            // execution. If this is not called,
            // no events will be delivered even if the next poll interval has been reached.
            dynamicRoutingEngine = DynamicRoutingEngine(dynamicRoutingOptions)
        } catch (e: InstantiationErrorException) {
            throw RuntimeException("Initialization of DynamicRoutingEngine failed: " + e.error.name)
        }
    }

    /**
     * Starts the dynamic search for better routes.
     *
     * @param route The route to search for better routes.
     */
    private fun startDynamicSearchForBetterRoutes(route: Route) {
        try {
            // Note that the engine will be internally stopped, if it was started before.
            // Therefore, it is not necessary to stop the engine before starting it again.
            dynamicRoutingEngine.start(
                route,
                object : DynamicRoutingListener {
                    // Notifies on traffic-optimized routes that are considered better than the
                    // current route.
                    override fun onBetterRouteFound(
                        newRoute: Route,
                        etaDifferenceInSeconds: Int,
                        distanceDifferenceInMeters: Int,
                    ) {
                        Log.d(TAG, "DynamicRoutingEngine: Calculated a new route.")
                        Log.d(
                            TAG,
                            "DynamicRoutingEngine: etaDifferenceInSeconds: $etaDifferenceInSeconds."
                        )
                        Log.d(
                            TAG,
                            "DynamicRoutingEngine: distanceDifferenceInMeters: $distanceDifferenceInMeters."
                        )

                        val logMessage =
                            "Calculated a new route. etaDifferenceInSeconds: " +
                                    etaDifferenceInSeconds +
                                    " distanceDifferenceInMeters: " +
                                    distanceDifferenceInMeters
//                        messageView.text = "DynamicRoutingEngine update: $logMessage"

                        // An implementation needs to decide when to switch to the new route
                        // based
                        // on above criteria.
                    }

                    override fun onRoutingError(routingError: RoutingError) {
                        Log.d(
                            TAG,
                            "Error while dynamically searching for a better route: " +
                                    routingError.name
                        )
                    }
                }
            )
        } catch (e: StartException) {
            throw RuntimeException(
                "Start of DynamicRoutingEngine failed. Is the RouteHandle missing?"
            )
        }
    }

    /**
     * On new route
     *
     * @param route The new route
     */
    fun onNewRoute(route: Route) {
        visualNavigator.route = route
    }

    /**
     * Starts navigation with the given route.
     *
     * @param route The route to be used for navigation.
     * @param isSimulated Whether to use simulated locations.
     */
    fun startNavigation(route: Route, isSimulated: Boolean) {
        // Check if navigation is already in progress
        if (isNavigationInProgress) return

        isNavigationInProgress = true

        // Don't start camera tracking if panning interface is visible and CarPlay scene is active
        if ((fcpMapViewController?.isPanningInterfaceVisible == true) && fcpMapViewController?.isDashboardSceneActive != true
        ) {
            stopCameraTracking()
        } else {
            visualNavigator.cameraBehavior = DynamicCameraBehavior()
            visualNavigatorCameraPoint?.let {
                visualNavigator.cameraBehavior?.normalizedPrincipalPoint = it
            }
        }

        visualNavigator.startRendering(mapView)

        val startGeoCoordinates = route.geometry.vertices[0]
        prefetchMapData(startGeoCoordinates)

        // Switches to navigation mode when no route was set before, otherwise navigation mode is
        // kept.
        visualNavigator.route = route

        if (isSimulated) {
            enableRoutePlayback(route)
//            messageView.text = "Starting simulated navgation."
        } else {
            enableDevicePositioning()
//            messageView.text = "Starting navgation."
        }

//        startDynamicSearchForBetterRoutes(route)
    }

    /** Stops navigation. */
    fun stopNavigation() {
        // Switches to tracking mode when a route was set before, otherwise tracking mode is kept.
        // Note that tracking mode means that the visual navigator will continue to run, but without
        // turn-by-turn instructions - this can be done with or without camera tracking.
        // Without a route the navigator will only notify on the current map-matched location
        // including info such as speed and current street name.
        if (!isNavigationInProgress) return
        isNavigationInProgress = false

        // SpeedBasedCameraBehavior is recommended for tracking mode.
//        visualNavigator?.cameraBehavior = SpeedBasedCameraBehavior()

        dynamicRoutingEngine.stop()
        routePrefetcher.stopPrefetchAroundRoute()
        visualNavigator.route = null
        enableDevicePositioning()
        visualNavigator.stopRendering()
        navigationEventHandler.resetPreviousManeuverIndex()

        if (fcpMapViewController?.shouldStopVoiceAssistant != false) {
            navigationEventHandler.stopVoiceAssistant()
        }
        fcpMapViewController?.shouldStopVoiceAssistant = true
    }

    /** Provides simulated location updates based on the given route. */
    private fun enableRoutePlayback(route: Route?) {
        herePositioningProvider.stopLocating()
        herePositioningSimulator.startLocating(visualNavigator, route)
    }

    /** Provides location updates based on the device's GPS sensor. */
    private fun enableDevicePositioning() {
        herePositioningSimulator.stopLocating()
        herePositioningProvider.startLocating(visualNavigator, LocationAccuracy.NAVIGATION)
    }

    /** Start the camera tracking
     * Set the normalized principal point of the VisualNavigator camera.
     * */
    fun startCameraTracking() {
        if (visualNavigator.cameraBehavior == null) {
            visualNavigator.cameraBehavior = DynamicCameraBehavior()
        }
        visualNavigatorCameraPoint?.let {
            visualNavigator.cameraBehavior?.normalizedPrincipalPoint = it
        }
    }

    /** Stop the camera tracking */
    fun stopCameraTracking() {
        visualNavigator.cameraBehavior = null
    }

    /**
     * Set the normalized principal point of the VisualNavigator camera.
     *
     * @param normalizedPrincipalPoint The normalized principal point to set.
     */
    fun setVisualNavigatorCameraPoint(normalizedPrincipalPoint: Anchor2D) {
        visualNavigatorCameraPoint = normalizedPrincipalPoint
        visualNavigator.cameraBehavior?.normalizedPrincipalPoint = normalizedPrincipalPoint
    }

    /** Stops location updates. */
    fun stopLocating() {
        herePositioningProvider.stopLocating()
    }

    /** Stops rendering. */
    fun stopRendering() {
        // It is recommended to stop rendering before leaving an activity.
        // This also removes the current location marker.
        visualNavigator.stopRendering()
    }

    companion object {
        private val TAG: String = NavigationHelper::class.java.name
    }
}
