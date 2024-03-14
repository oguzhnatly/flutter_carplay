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
import heresdk
import UIKit

// Shows how to start and stop turn-by-turn navigation on a car route.
// By default, tracking mode is enabled. When navigation is stopped, tracking mode is enabled again.
// The preferred device language determines the language for voice notifications used for TTS.
// (Make sure to set language + region in device settings.)
class NavigationExample : DynamicRoutingDelegate {

    private let visualNavigator: VisualNavigator
    private let dynamicRoutingEngine: DynamicRoutingEngine
    private let herePositioningProvider: HEREPositioningProvider
    private let herePositioningSimulator: HEREPositioningSimulator
    private let routePrefetcher: RoutePrefetcher
    private let navigationEventHandler: NavigationEventHandler
    private let messageTextView: UITextView

    init(mapView: MapView, messageTextView: UITextView) {
        self.messageTextView = messageTextView

        do {
            // Without a route set, this starts tracking mode.
            try visualNavigator = VisualNavigator()
        } catch let engineInstantiationError {
            fatalError("Failed to initialize VisualNavigator. Cause: \(engineInstantiationError)")
        }

        // By default, enable auto-zoom during guidance.
        visualNavigator.cameraBehavior = DynamicCameraBehavior()

        visualNavigator.startRendering(mapView: mapView)

        // A class to receive real location events.
        herePositioningProvider = HEREPositioningProvider()
        // A class to receive simulated location events.
        herePositioningSimulator = HEREPositioningSimulator()

        // The RoutePrefetcher downloads map data in advance into the map cache.
        // This is not mandatory, but can help to improve the guidance experience.
        routePrefetcher = RoutePrefetcher(SDKNativeEngine.sharedInstance!)

        // An engine to find better routes during guidance.
        dynamicRoutingEngine = NavigationExample.createDynamicRoutingEngine()

        // A class to handle various kinds of guidance events.
        navigationEventHandler = NavigationEventHandler(
            visualNavigator, dynamicRoutingEngine, messageTextView)
    }

    func startLocationProvider() {
        // Set navigator as delegate to receive locations from HERE Positioning.
        herePositioningProvider.startLocating(locationDelegate: visualNavigator,
                                              // Choose a suitable accuracy for the tbt navigation use case.
                                              accuracy: .navigation)
    }

    private func prefetchMapData(currentGeoCoordinates: GeoCoordinates) {
        // Prefetches map data around the provided location with a radius of 2 km into the map cache.
        // For the best experience, prefetchAroundLocationWithRadius() should be called as early as possible.
        routePrefetcher.prefetchAroundLocationWithRadius(currentLocation: currentGeoCoordinates, radiusInMeters: 2000.0)
        // Prefetches map data within a corridor along the route that is currently set to the provided Navigator instance.
        // This happens continuously in discrete intervals.
        // If no route is set, no data will be prefetched.
        routePrefetcher.prefetchAroundRouteOnIntervals(navigator: visualNavigator)
    }

    // Use this engine to periodically search for better routes during guidance, ie. when the traffic
    // situation changes.
    private class func createDynamicRoutingEngine() -> DynamicRoutingEngine {
        // Both, minTimeDifference and minTimeDifferencePercentage, will be checked:
        // When the poll interval is reached, the smaller difference will win.
        let minTimeDifferencePercentage = 0.1
        let minTimeDifferenceInSeconds: TimeInterval = 1
        let pollIntervalInSeconds: TimeInterval = 5 * 60

        let dynamicRoutingOptions =
            DynamicRoutingEngineOptions(minTimeDifferencePercentage: minTimeDifferencePercentage,
                                        minTimeDifference: minTimeDifferenceInSeconds,
                                        pollInterval: pollIntervalInSeconds)

        do {
            // With the dynamic routing engine you can poll the HERE backend services to search for routes with less traffic.
            // This can happen during guidance - or you can periodically update a route that is shown in a route planner.
            //
            // Make sure to call dynamicRoutingEngine.updateCurrentLocation(...) to trigger execution. If this is not called,
            // no events will be delivered even if the next poll interval has been reached.
            return try DynamicRoutingEngine(options: dynamicRoutingOptions)
        } catch let engineInstantiationError {
            fatalError("Failed to initialize DynamicRoutingEngine. Cause: \(engineInstantiationError)")
        }
    }

    // Conform to the DynamicRoutingDelegate.
    // Notifies on traffic-optimized routes that are considered better than the current route.
    func onBetterRouteFound(newRoute: Route,
                            etaDifferenceInSeconds: Int32,
                            distanceDifferenceInMeters: Int32) {
        print("DynamicRoutingEngine: Calculated a new route.")
        print("DynamicRoutingEngine: etaDifferenceInSeconds: \(etaDifferenceInSeconds).")
        print("DynamicRoutingEngine: distanceDifferenceInMeters: \(distanceDifferenceInMeters).")

        // An implementation needs to decide when to switch to the new route based
        // on above criteria.
    }

    // Conform to the DynamicRoutingDelegate.
    func onRoutingError(routingError: RoutingError) {
        print("Error while dynamically searching for a better route: \(routingError).")
    }

    func startNavigation(route: Route,
                                isSimulated: Bool) {
        let startGeoCoordinates = route.geometry.vertices[0]
        prefetchMapData(currentGeoCoordinates: startGeoCoordinates)

        // Switches to navigation mode when no route was set before, otherwise navigation mode is kept.
        visualNavigator.route = route

        if isSimulated {
            enableRoutePlayback(route: route)
            showMessage("Starting simulated navigation.")
        } else {
            enableDevicePositioning()
            showMessage("Starting navigation.")
        }

        startDynamicSearchForBetterRoutes(route)
    }

    private func startDynamicSearchForBetterRoutes(_ route: Route) {
        do {
            // Note that the engine will be internally stopped, if it was started before.
            // Therefore, it is not necessary to stop the engine before starting it again.
            try dynamicRoutingEngine.start(route: route, delegate: self)
        } catch let instantiationError {
            fatalError("Start of DynamicRoutingEngine failed: \(instantiationError). Is the RouteHandle missing?")
        }
    }

    func stopNavigation() {
        // Switches to tracking mode when a route was set before, otherwise tracking mode is kept.
        // Without a route the navigator will only notify on the current map-matched location
        // including info such as speed and current street name.
        dynamicRoutingEngine.stop()
        routePrefetcher.stopPrefetchAroundRoute()
        visualNavigator.route = nil
        enableDevicePositioning()
        showMessage("Tracking device's location.")
    }

    // Provides location updates based on the given route.
    func enableRoutePlayback(route: Route) {
        herePositioningProvider.stopLocating()
        herePositioningSimulator.startLocating(locationDelegate: visualNavigator, route: route)
    }

    // Provides location updates based on the device's GPS sensor.
    func enableDevicePositioning() {
        herePositioningSimulator.stopLocating()
        herePositioningProvider.startLocating(locationDelegate: visualNavigator,
                                              accuracy: .navigation)
    }

    func startCameraTracking() {
        visualNavigator.cameraBehavior = DynamicCameraBehavior()
    }

    func stopCameraTracking() {
        visualNavigator.cameraBehavior = nil
    }

    func getLastKnownLocation() -> Location? {
        return herePositioningProvider.getLastKnownLocation()
    }

    // A permanent view to show log content.
    private func showMessage(_ message: String) {
        messageTextView.text = message
        messageTextView.textColor = .white
        messageTextView.layer.cornerRadius = 8
        messageTextView.isEditable = false
        messageTextView.textAlignment = NSTextAlignment.center
        messageTextView.font = .systemFont(ofSize: 14)
    }
}
