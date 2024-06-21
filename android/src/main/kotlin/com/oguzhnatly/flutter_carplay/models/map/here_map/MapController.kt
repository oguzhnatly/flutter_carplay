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

import android.annotation.SuppressLint
import com.here.sdk.core.Color
import com.here.sdk.core.GeoCircle
import com.here.sdk.core.GeoCoordinates
import com.here.sdk.core.GeoPolygon
import com.here.sdk.core.GeoPolyline
import com.here.sdk.core.Location
import com.here.sdk.core.Metadata
import com.here.sdk.core.Point2D
import com.here.sdk.core.engine.SDKNativeEngine
import com.here.sdk.gestures.GestureState
import com.here.sdk.gestures.LongPressListener
import com.here.sdk.mapview.ImageFormat
import com.here.sdk.mapview.LineCap
import com.here.sdk.mapview.MapImage
import com.here.sdk.mapview.MapMarker
import com.here.sdk.mapview.MapMeasure
import com.here.sdk.mapview.MapMeasureDependentRenderSize
import com.here.sdk.mapview.MapPolygon
import com.here.sdk.mapview.MapPolyline
import com.here.sdk.mapview.MapSurface
import com.here.sdk.mapview.RenderSize
import com.here.sdk.routing.Route
import com.here.sdk.routing.Waypoint
import com.oguzhnatly.flutter_carplay.Bool
import com.oguzhnatly.flutter_carplay.FCPChannelTypes
import com.oguzhnatly.flutter_carplay.FCPStreamHandlerPlugin
import com.oguzhnatly.flutter_carplay.Logger
import com.oguzhnatly.flutter_carplay.MapMarkerType
import com.oguzhnatly.flutter_carplay.UIImage
import java.util.Locale

object ConstantsEnum {
    val DEFAULT_MAP_CENTER = GeoCoordinates(52.520798, 13.409408)
    val DEFAULT_DISTANCE_IN_METERS = 1000.0 * 2
    val ROUTE_DEVIATION_DISTANCE = 20.0 // In Meters
}

data class CGSize(val width: Double, val height: Double)

/**
 * An app that allows to calculate a route and start navigation, using either platform positioning
 * or simulated locations.
 */
class MapController(private val mapView: MapSurface) {
    private val mapMarkers: MutableList<MapMarker> = ArrayList()
    private val mapPolygons: MutableList<MapPolygon> = ArrayList()
    private val mapPolylineList: MutableList<MapPolyline?> = ArrayList()
    private var startWaypoint: Waypoint? = null
    private var destinationWaypoint: Waypoint? = null
    private var setLongpressDestination = false
    private var routeCalculator: RouteCalculator
//    private var isCameraTrackingEnabled = true

    /// NavigationHelper instance
    val navigationHelper: NavigationHelper

    /// lastKnownLocation getter
    val lastKnownLocation: Location?
        get() = navigationHelper.lastKnownLocation

    init {
        val distanceInMeters =
            MapMeasure(MapMeasure.Kind.DISTANCE, ConstantsEnum.DEFAULT_DISTANCE_IN_METERS)
        this.mapView.camera.lookAt(ConstantsEnum.DEFAULT_MAP_CENTER, distanceInMeters)

        routeCalculator =
            RouteCalculator(
                SDKNativeEngine.getSharedInstance()?.isOfflineMode ?: false
            )

        navigationHelper = NavigationHelper(mapView)
        navigationHelper.startLocationProvider()

        // Toggle offline mode to change the RouteCalculator instance
        toggleOfflineModeHandler = { isOffline: Bool ->
            routeCalculator = RouteCalculator(isOffline)
        }

        // Re-Routing callback to find new route
        reroutingHandler = { startWayPoint, completion ->

//            val navigationSession =
//                (FlutterCarplayPlugin.fcpRootTemplate as? FCPMapTemplate)?.navigationSession

//            if #available(iOS 15.4, *) {
//                navigationSession?.pauseTrip(for: .rerouting, description: "", turnCardColor: .systemGreen)
//            } else {
//                navigationSession?.pauseTrip(for: .rerouting, description: "")
//            }

            startWaypoint = startWayPoint

            // Calculates a car route.
            routeCalculator.calculateRoute(
                start = startWayPoint,
                destination = this.destinationWaypoint!!
            )
            { routingError, routes ->
                routingError?.let {
                    onNavigationFailed(
                        title = "Error while calculating a reroute =",
                        message = "$it"
                    )
                    completion()
                    return@calculateRoute
                }

                // When routingError is nil, routes is guaranteed to contain at least one route.
                val route = routes!!.first()
                showRouteDetails(route!!)
                navigationHelper.onNewRoute(route)
                completion()
            }
        }

        setLongPressGestureHandler()

    }

    /** Set destination waypoint for route calculation. */
    fun setDestinationWaypoint(destination: Waypoint) {
        destinationWaypoint = destination
    }

    /**
     * Calculate a route and start navigation using a location simulator.
     * Start is map center and destination location is set random within viewport,
     * unless a destination is set via long press.
     */
    fun addRouteSimulatedLocation() {
        calculateRoute(true)
    }

    /**
     * Calculate a route and start navigation using locations from the device.
     * Start is the current location and the destination is set randomly within the viewport,
     * unless a destination is set via long press.
     */
    fun addRouteDeviceLocation() {
        calculateRoute(false)
    }

    /**
     * Add a marker on the map.
     *
     * @param coordinates The coordinates of the marker
     * @param markerImage The image of the marker
     * @param markerSize The size of the marker
     * @param metadata The metadata of the marker
     */
    @SuppressLint("RestrictedApi")
    fun addMapMarker(
        coordinates: GeoCoordinates,
        markerImage: UIImage,
        markerSize: CGSize,
        metadata: Metadata?,
    ) {
        val marker = mapMarkers.find {
            it.metadata?.getString("marker") == metadata?.getString("marker")
        }

        if (marker != null) {
            marker.coordinates = coordinates
            mapView.mapScene.removeMapMarker(marker)
            mapView.mapScene.addMapMarker(marker)
        } else {
            val imageData = markerImage.icon?.mData ?: return
            val mapImage = MapImage(
                imageData,
                ImageFormat.PNG,
                markerSize.width.toLong(),
                markerSize.height.toLong(),
            )
            val mapMarker = MapMarker(coordinates, mapImage)
            mapMarker.metadata = metadata
            mapView.mapScene.addMapMarker(mapMarker)
            mapMarkers.add(mapMarker)
        }
    }

    /**
     * Add a polygon on the map.
     *
     * @param coordinate The coordinates of the polygon
     * @param accuracy The accuracy of the polygon
     * @param metadata The metadata of the polygon
     */
    fun addMapPolygon(coordinate: GeoCoordinates, accuracy: Double, metadata: Metadata?) {
        val polygon = mapPolygons.find {
            it.metadata?.getString("polygon") == metadata?.getString("polygon")
        }

        if (polygon != null) {
            polygon.geometry = GeoPolygon(GeoCircle(coordinate, accuracy))
            mapView.mapScene.removeMapPolygon(polygon)
            mapView.mapScene.addMapPolygon(polygon)
        } else {
            val mapPolygon = MapPolygon(
                GeoPolygon(GeoCircle(coordinate, accuracy)),
                Color.valueOf(0x550BC7C2)
            )
            mapPolygon.metadata = metadata
            mapView.mapScene.addMapPolygon(mapPolygon)
            mapPolygons.add(mapPolygon)
        }
    }

    /**
     * Calculates a route and starts navigation.
     *
     * @param isSimulated Whether to use simulated locations.
     */
    private fun calculateRoute(isSimulated: Boolean) {
        clearMap(clearInitialOnly = true)

        if (!determineRouteWaypoints(isSimulated)) return

        // Calculates a car route.
        routeCalculator.calculateRoute(startWaypoint, destinationWaypoint) { routingError, routes ->
            if (routingError == null) {
                // When routingError is null, routes is guaranteed to contain at least one route.
                showRouteDetails(routes!!.first())
            } else {
                onNavigationFailed(
                    title = "Error while calculating a route:",
                    message = "$routingError"
                )
            }
        }
    }

    /**
     * Determines the starting and destination waypoints for the route calculation.
     *
     * @param isSimulated Whether to use simulated locations.
     * @return True if waypoints are determined, false if not.
     */
    private fun determineRouteWaypoints(isSimulated: Boolean): Boolean {
        // When using real GPS locations, we always start from the current location of user.
        val location = lastKnownLocation

        if (location == null) {
            onNavigationFailed(title = "Error", message = "No GPS location found.")
            return false
        }

        startWaypoint = Waypoint(location.coordinates)

        // If a driver is moving, the bearing value can help to improve the route calculation.
        startWaypoint?.headingInDegrees = location.bearingInDegrees

        // Update the camera position.
        mapView.camera.lookAt(location.coordinates)

        // When using real GPS locations, we always start from the current location of user.
        if (isSimulated && destinationWaypoint == null) {
            destinationWaypoint = Waypoint(createRandomGeoCoordinatesAroundMapCenter())
        }

        return true
    }

    /**
     * Shows the route details on the screen.
     *
     * @param route The route.
     */
    private fun showRouteDetails(route: Route) {
        val estimatedTravelTimeInSeconds: Long = route.duration.seconds
        val lengthInMeters: Int = route.lengthInMeters

        val routeDetails =
            ("Travel Time: " +
                    formatTime(estimatedTravelTimeInSeconds) +
                    ", Length: " +
                    formatLength(lengthInMeters))

//        showStartNavigationDialog(
//            "Route Details",
//            routeDetails,
//            route,
//            isSimulated
//        )
    }

    /**
     * Format time in minutes and seconds.
     *
     * @param sec the time in seconds
     * @return the time in minutes and seconds
     */
    private fun formatTime(sec: Long): String {
        val hours = (sec / 3600).toInt()
        val minutes = ((sec % 3600) / 60).toInt()

        return String.format(Locale.getDefault(), "%02d:%02d", hours, minutes)
    }

    /**
     * Format length in kilometers and meters.
     *
     * @param meters the length in meters
     * @return the length in kilometers and meters
     */
    private fun formatLength(meters: Int): String {
        val kilometers = meters / 1000
        val remainingMeters = meters % 1000

        return String.format(Locale.getDefault(), "%02d.%02d km", kilometers, remainingMeters)
    }

    /**
     * Shows the route on the map.
     *
     * @param route The route.
     */
    private fun showRouteOnMap(route: Route) {
        // Show route as polyline.
        val routeGeoPolyline: GeoPolyline = route.geometry
        val widthInPixels = 20f
        val polylineColor = Color.valueOf(0f, 0.56f, 0.54f, 0.63f)
        var routeMapPolyline: MapPolyline? = null
        try {
            routeMapPolyline =
                MapPolyline(
                    routeGeoPolyline,
                    MapPolyline.SolidRepresentation(
                        MapMeasureDependentRenderSize(
                            RenderSize.Unit.PIXELS,
                            widthInPixels.toDouble()
                        ),
                        polylineColor,
                        LineCap.ROUND
                    )
                )
        } catch (e: MapPolyline.Representation.InstantiationException) {
            Logger.log("MapPolyline Representation Exception:", e.error.name)
        } catch (e: MapMeasureDependentRenderSize.InstantiationException) {
            Logger.log("MapMeasureDependentRenderSize Exception:", e.error.name)
        }

        routeMapPolyline?.let { mapView.mapScene.addMapPolyline(it) }
        mapPolylineList.add(routeMapPolyline)
    }

    /**
     * Clears the map.
     *
     * @param clearInitialOnly Whether to clear only the initial map marker
     */
    fun clearMap(clearInitialOnly: Bool = false) {
        if (clearInitialOnly) {
            removeMarker(MapMarkerType.INITIAL)
            removePolygon(MapMarkerType.INITIAL)
        } else {
            clearWaypointMapMarkers()
            clearMapPolygons()
        }
        clearRoute()

        navigationHelper.stopNavigation()
    }

    /** Clear the map markers. */
    private fun clearWaypointMapMarkers() {
        for (mapMarker in mapMarkers) {
            mapView.mapScene.removeMapMarker(mapMarker)
        }
        mapMarkers.clear()
    }

    /** Clear the map polygons. */
    private fun clearMapPolygons() {
        for (mapPolygon in mapPolygons) {
            mapView.mapScene.removeMapPolygon(mapPolygon)
        }
        mapPolygons.clear()
    }

    /** Clear the route. */
    private fun clearRoute() {
        for (mapPolyline in mapPolylineList) {
            mapPolyline?.let { mapView.mapScene.removeMapPolyline(it) }
        }
        mapPolylineList.clear()
    }

    /** Set the long press gesture handler. */
    private fun setLongPressGestureHandler() {
        mapView.gestures.longPressListener =
            LongPressListener { gestureState: GestureState, touchPoint: Point2D? ->
                val geoCoordinates: GeoCoordinates =
                    touchPoint?.let { mapView.viewToGeoCoordinates(it) }
                        ?: return@LongPressListener
                if (gestureState == GestureState.BEGIN) {
                    if (setLongpressDestination) {
                        destinationWaypoint = Waypoint(geoCoordinates)
//                        addCircleMapMarker(geoCoordinates, R.drawable.green_dot)
//                        messageView.text = "New long press destination set."
                    } else {
                        startWaypoint = Waypoint(geoCoordinates)
//                        addCircleMapMarker(geoCoordinates, R.drawable.green_dot)
//                        messageView.text = "New long press starting point set."
                    }
                    setLongpressDestination = !setLongpressDestination
                }
            }
    }

    /** Create a random geo coordinates.
     *
     * @return the random geo coordinates
     */
    private fun createRandomGeoCoordinatesAroundMapCenter(): GeoCoordinates {
        val centerGeoCoordinates: GeoCoordinates = mapViewCenter
        val lat: Double = centerGeoCoordinates.latitude
        val lon: Double = centerGeoCoordinates.longitude
        return GeoCoordinates(getRandom(lat - 0.02, lat + 0.02), getRandom(lon - 0.02, lon + 0.02))
    }

    /**
     * Get a random number between the specified minimum and maximum values (inclusive).
     *
     * @param min The minimum number.
     * @param max The maximum number.
     * @return The randomly generated number.
     */
    private fun getRandom(min: Double, max: Double): Double {
        return min + Math.random() * (max - min)
    }

    /**
     * Get the map view center.
     *
     * @return The map view center.
     */
    private val mapViewCenter: GeoCoordinates
        get() = mapView.camera.state.targetCoordinates

    /**
     * Get the marker coordinates.
     *
     * @param markerType The type of the map marker.
     * @return The coordinates of the marker.
     */
    fun getMarkerCoordinates(markerType: MapMarkerType): GeoCoordinates? {
        val marker = mapMarkers.find {
            it.metadata?.getString("marker") == markerType.name
        }

        return marker?.coordinates
    }

    /**
     * Remove a marker.
     *
     * @param markerType The type of the map marker to be removed.
     */
    fun removeMarker(markerType: MapMarkerType) {
        val marker = mapMarkers.find {
            it.metadata?.getString("marker") == markerType.name
        }

        marker?.let { mapMarker ->
            mapView.mapScene.removeMapMarker(mapMarker)
            mapMarkers.removeAll { it.metadata?.getString("marker") == markerType.name }
        }
    }

    /**
     * Removes a polygon from the map.
     *
     * @param markerType The type of the map marker.
     */
    fun removePolygon(markerType: MapMarkerType) {
        val polygon = mapPolygons.find {
            it.metadata?.getString("polygon") == markerType.name
        }

        polygon?.let { mapPolygon ->
            mapView.mapScene.removeMapPolygon(mapPolygon)
            mapPolygons.removeAll { it.metadata?.getString("polygon") == markerType.name }
        }
    }

    private fun showStartNavigationDialog(
        title: String,
        message: String,
        route: Route,
        isSimulated: Boolean,
    ) {
        val buttonText =
            if (isSimulated) "Start navigation (simulated)"
            else "Start navigation (device location)"
        Logger.log("$title\n$message")

//        val builder: AlertDialog.Builder = Builder(context)
//        builder.setTitle(title)
//            .setMessage(message)
//            .setNeutralButton(buttonText) { dialog, which ->
//                navigationHelper.startNavigation(route, isSimulated, isCameraTrackingEnabled)
//            }
//            .show()
    }

    /**
     * Logs the given title and message, and sends an event with the message to the FCPStreamHandlerPlugin.
     *
     * @param title the title of the error
     * @param message the error message
     */
    private fun onNavigationFailed(title: String, message: String) {
        Logger.log("$title\n$message")

        FCPStreamHandlerPlugin.sendEvent(
            type = FCPChannelTypes.onNavigationFailedFromCarplay.name,
            data = mapOf("message" to message)
        )
//        val builder: AlertDialog.Builder = Builder(context)
//        builder.setTitle(title).setMessage(message).show()
    }

    fun detach() {
        // Disables TBT guidance (if running) and enters tracking mode.
        navigationHelper.stopNavigation()
        // Disables positioning.
        navigationHelper.stopLocating()
        // Disables rendering.
        navigationHelper.stopRendering()
    }
}
