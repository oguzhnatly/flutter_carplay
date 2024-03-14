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

// A class that provides simulated location updates along a given route.
// The frequency of the provided updates can be set via LocationSimulatorOptions.
class HEREPositioningSimulator {

    private var locationSimulator: LocationSimulator?

    func startLocating(locationDelegate: LocationDelegate, route: Route) {
        if let locationSimulator = locationSimulator {
            locationSimulator.stop()
        }

        locationSimulator = createLocationSimulator(locationDelegate: locationDelegate, route: route)
        locationSimulator!.start()
    }

    func stopLocating() {
        if locationSimulator != nil {
            locationSimulator!.stop()
            locationSimulator = nil
        }
    }

    // Provides fake GPS signals based on the route geometry.
    private func createLocationSimulator(locationDelegate: LocationDelegate,
                                         route: Route) -> LocationSimulator {
        let notificationIntervalInSeconds: TimeInterval = 0.5
        let locationSimulatorOptions = LocationSimulatorOptions(speedFactor: 2,
                                                                notificationInterval: notificationIntervalInSeconds)
        let locationSimulator: LocationSimulator
        
        do {
            try locationSimulator = LocationSimulator(route: route,
                                                      options: locationSimulatorOptions)
        } catch let instantiationError {
            fatalError("Failed to initialize LocationSimulator. Cause: \(instantiationError)")
        }

        locationSimulator.delegate = locationDelegate
        locationSimulator.start()

        return locationSimulator
    }
}
