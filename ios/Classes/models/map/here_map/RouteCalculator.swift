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

import heresdk

// A class that creates car Routes with the HERE SDK.
class RouteCalculator {

    private let routingEngine: RoutingEngine

    init() {
        do {
            try routingEngine = RoutingEngine()
        } catch let engineInstantiationError {
            fatalError("Failed to initialize routing engine. Cause: \(engineInstantiationError)")
        }
    }

    func calculateRoute(start: Waypoint,
                        destination: Waypoint,
                        calculateRouteCompletionHandler: @escaping CalculateRouteCompletionHandler) {

        // A route handle is required for the DynamicRoutingEngine to get updates on traffic-optimized routes.
        var carOptions = CarOptions()
        carOptions.routeOptions.enableRouteHandle = true
        
        routingEngine.calculateRoute(with: [start, destination],
                                     carOptions: carOptions,
                                     completion: calculateRouteCompletionHandler)
    }
}
