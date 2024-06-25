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

import com.here.sdk.core.errors.InstantiationErrorException
import com.here.sdk.routing.CalculateRouteCallback
import com.here.sdk.routing.CarOptions
import com.here.sdk.routing.OfflineRoutingEngine
import com.here.sdk.routing.RoutingEngine
import com.here.sdk.routing.RoutingInterface
import com.here.sdk.routing.Waypoint
import com.oguzhnatly.flutter_carplay.Bool

// A class that creates car Routes with the HERE SDK.
class RouteCalculator(isOfflineMode: Bool = false) {
    private var routingEngine: RoutingInterface? = null

    init {
        try {
            routingEngine = if (isOfflineMode) OfflineRoutingEngine() else RoutingEngine()
        } catch (e: InstantiationErrorException) {
            throw RuntimeException("Initialization of RoutingEngine failed: " + e.error.name)
        }
    }

    /**
     * Calculates a route between two waypoints.
     *
     * @param start          The starting waypoint.
     * @param destination    The destination waypoint.
     * @param calculateRouteCallback The completion callback.
     */
    fun calculateRoute(
        start: Waypoint?,
        destination: Waypoint?,
        calculateRouteCallback: CalculateRouteCallback?,
    ) {
        val waypoints: List<Waypoint?> =
            ArrayList(listOf(start, destination))

        // A route handle is required for the DynamicRoutingEngine to get updates on
        // traffic-optimized routes.
        val routingOptions = CarOptions()
        routingOptions.routeOptions.enableRouteHandle = true

        routingEngine!!.calculateRoute(waypoints, routingOptions, calculateRouteCallback!!)
    }
}
