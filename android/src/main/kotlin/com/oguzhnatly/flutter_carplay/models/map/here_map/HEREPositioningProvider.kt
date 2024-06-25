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
import com.here.sdk.consent.Consent
import com.here.sdk.consent.ConsentEngine
import com.here.sdk.core.Location
import com.here.sdk.core.LocationListener
import com.here.sdk.core.errors.InstantiationErrorException
import com.here.sdk.location.LocationAccuracy
import com.here.sdk.location.LocationEngine
import com.here.sdk.location.LocationEngineStatus
import com.here.sdk.location.LocationFeature
import com.here.sdk.location.LocationStatusListener

// A reference implementation using HERE Positioning to get notified on location updates
// from various location sources available from a device and HERE services.
class HEREPositioningProvider {
    private var locationEngine: LocationEngine? = null
    private var updateListener: LocationListener? = null

    private val locationStatusListener: LocationStatusListener =
        object : LocationStatusListener {
            override fun onStatusChanged(locationEngineStatus: LocationEngineStatus) {
                Log.d(LOG_TAG, "Location engine status: " + locationEngineStatus.name)
            }

            override fun onFeaturesNotAvailable(features: List<LocationFeature>) {
                for (feature in features) {
                    Log.d(LOG_TAG, "Location feature not available: " + feature.name)
                }
            }
        }

    init {
        val consentEngine: ConsentEngine

        try {
            consentEngine = ConsentEngine()
            locationEngine = LocationEngine()
        } catch (e: InstantiationErrorException) {
            throw RuntimeException("Initialization failed: " + e.message)
        }

        // Ask user to optionally opt in to HERE's data collection / improvement program.
        if (consentEngine.userConsentState == Consent.UserReply.NOT_HANDLED) {
            consentEngine.requestUserConsent()
        }
    }

    val lastKnownLocation: Location?
        get() = locationEngine!!.lastKnownLocation

    // Does nothing when engine is already running.
    fun startLocating(updateListener: LocationListener?, accuracy: LocationAccuracy?) {
        if (locationEngine!!.isStarted) {
            return
        }

        this.updateListener = updateListener

        // Set listeners to get location updates.
        locationEngine!!.addLocationListener(updateListener!!)
        locationEngine!!.addLocationStatusListener(locationStatusListener)

        locationEngine!!.start(accuracy!!)
    }

    // Does nothing when engine is already stopped.
    fun stopLocating() {
        if (!locationEngine!!.isStarted) {
            return
        }

        // Remove listeners and stop location engine.
        locationEngine!!.removeLocationListener(updateListener!!)
        locationEngine!!.removeLocationStatusListener(locationStatusListener)
        locationEngine!!.stop()
    }

    companion object {
        private val LOG_TAG: String = HEREPositioningProvider::class.java.name
    }
}
