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

import com.here.sdk.core.LocationListener
import com.here.sdk.core.errors.InstantiationErrorException
import com.here.sdk.navigation.LocationSimulator
import com.here.sdk.navigation.LocationSimulatorOptions
import com.here.sdk.routing.Route
import com.here.time.Duration

// A class that provides simulated location updates along a given route.
// The frequency of the provided updates can be set via LocationSimulatorOptions.
class HEREPositioningSimulator {
    private var locationSimulator: LocationSimulator? = null

    // Starts route playback.
    fun startLocating(locationListener: LocationListener?, route: Route?) {
        if (locationSimulator != null) {
            locationSimulator!!.stop()
        }

        locationSimulator = createLocationSimulator(locationListener, route)
        locationSimulator!!.start()
    }

    fun stopLocating() {
        if (locationSimulator != null) {
            locationSimulator!!.stop()
            locationSimulator = null
        }
    }

    // Provides fake GPS signals based on the route geometry.
    private fun createLocationSimulator(
            locationListener: LocationListener?,
            route: Route?
    ): LocationSimulator {
        val locationSimulatorOptions = LocationSimulatorOptions()
        locationSimulatorOptions.speedFactor = 2.0
        locationSimulatorOptions.notificationInterval = Duration.ofMillis(500)

        val locationSimulator: LocationSimulator

        try {
            locationSimulator = LocationSimulator(route!!, locationSimulatorOptions)
        } catch (e: InstantiationErrorException) {
            throw RuntimeException("Initialization of LocationSimulator failed: " + e.error.name)
        }

        locationSimulator.listener = locationListener

        return locationSimulator
    }
}
