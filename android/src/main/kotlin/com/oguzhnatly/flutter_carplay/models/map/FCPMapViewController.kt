package com.oguzhnatly.flutter_carplay.models.map

import android.graphics.Rect
import androidx.car.app.SurfaceCallback
import androidx.car.app.SurfaceContainer
import com.here.sdk.core.Anchor2D
import com.here.sdk.core.GeoBox
import com.here.sdk.core.GeoCoordinates
import com.here.sdk.core.GeoCoordinatesUpdate
import com.here.sdk.core.GeoOrientationUpdate
import com.here.sdk.core.Metadata
import com.here.sdk.core.Point2D
import com.here.sdk.core.Rectangle2D
import com.here.sdk.core.Size2D
import com.here.sdk.mapview.MapCameraAnimationFactory
import com.here.sdk.mapview.MapError
import com.here.sdk.mapview.MapFeatures
import com.here.sdk.mapview.MapMarker
import com.here.sdk.mapview.MapMeasure
import com.here.sdk.mapview.MapScheme
import com.here.sdk.mapview.MapSurface
import com.here.time.Duration
import com.oguzhnatly.flutter_carplay.AndroidAutoService
import com.oguzhnatly.flutter_carplay.Bool
import com.oguzhnatly.flutter_carplay.CPTrip
import com.oguzhnatly.flutter_carplay.FlutterCarplayPlugin
import com.oguzhnatly.flutter_carplay.FlutterCarplayTemplateManager
import com.oguzhnatly.flutter_carplay.Logger
import com.oguzhnatly.flutter_carplay.MapMarkerType
import com.oguzhnatly.flutter_carplay.UIImageObject
import com.oguzhnatly.flutter_carplay.models.map.here_map.CGSize
import com.oguzhnatly.flutter_carplay.models.map.here_map.ConstantsEnum
import com.oguzhnatly.flutter_carplay.models.map.here_map.MapController
import com.oguzhnatly.flutter_carplay.models.map.here_map.MapCoordinates
import com.oguzhnatly.flutter_carplay.models.map.here_map.locationUpdatedHandler
import com.oguzhnatly.flutter_carplay.models.map.here_map.recenterMapViewHandler
import com.oguzhnatly.flutter_carplay.models.map.here_map.toggleSatelliteViewHandler
import com.oguzhnatly.flutter_carplay.models.map.here_map.updateMapCoordinatesHandler
import kotlin.math.max
import kotlin.math.min

/** A custom Android Auto map view controller. */
class FCPMapViewController : SurfaceCallback {
    /// The map view associated with the map view controller.
    var mapView = MapSurface()

    //    /// The banner view associated with the map view controller.
    //    var bannerView: FCPBannerView
    //    {
    //        didSet {
    //            guard let view = bannerView else { return }
    //            view.isHidden = true
    //        }
    //    }
    //
    //    /// The toast view associated with the map view controller.
    //    @IBOutlet
    //    var toastView: FCPToastView!
    //    {
    //        didSet {
    //            guard let view = toastView else { return }
    //            view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    //            view.layer.cornerRadius = 10
    //            view.alpha = 0.0
    //        }
    //    }

    //    /// The maximum width of the toast view.
    //    @IBOutlet
    //    var toastViewMaxWidth: NSLayoutConstraint!
    //
    //    /// The maximum width of the overlay view.
    //    @IBOutlet
    //    var overlayViewMaxWidth: NSLayoutConstraint!
    //
    //    /// The overlay view associated with the map view controller.
    //    @IBOutlet
    //    var overlayView: FCPOverlayView!
    //    {
    //        didSet {
    //            guard let view = overlayView else { return }
    //            view.backgroundColor = . clear
    //                    view.clipsToBounds = true
    //            view.layer.cornerRadius = 8
    //            view.isHidden = true
    //        }
    //    }
    private var surfaceContainer: SurfaceContainer? = null

    private var stableArea: Rect = Rect(0, 0, 0, 0)
    private var visibleArea: Rect = Rect(0, 0, 0, 0)

    /// The app associated with the map view controller.
    var mapController: MapController? = null

    /// The map marker associated with the map view controller.
    var mapMarker: MapMarker? = null

    /// The size of the marker pin.
    val markerPinSize: Double
        get() = 40 * mapView.pixelScale

    /// Recenter map position to adjust the map camera
    var recenterMapPosition = "initialMarker"

    /// Map coordinates to render marker on the map
    var mapCoordinates = MapCoordinates()

    /// Whether the satellite view is enabled.
    var isSatelliteViewEnabled = false

    /// Whether the dashboard scene is active.
    val isDashboardSceneActive
        get() = FlutterCarplayTemplateManager.isDashboardSceneActive


    /// Whether the dashboard scene is active.
    val isPanningInterfaceVisible
        get() = (FlutterCarplayPlugin.fcpRootTemplate as?
                FCPMapTemplate)?.isPanningInterfaceVisible ?: false


    /// Should stop voice assistant
    var shouldStopVoiceAssistant = true

    /// Should show banner
    var shouldShowBanner = false

    /// Should show overlay
    var shouldShowOverlay = false

    /// Overlay view width
    var overlayViewWidth = 0.0

    /// Banner view height
    var bannerViewHeight = 0.0

    /// To perform actions only once when map is loaded
    var mapLoadedOnce = false

    /// Default coordinates for the map
    val defaultCoordinates = GeoCoordinates(21.1812352, 72.8629248)
//    val defaultCoordinates = GeoCoordinates(-25.02970994781628, 134.28333173662492)

    /**
     * Sets the surface of the map view with the provided surface container.
     *
     * @param surfaceContainer the surface container containing the surface, width, and height
     */
    override fun onSurfaceAvailable(surfaceContainer: SurfaceContainer) {
        print("surface available: $surfaceContainer")

        mapLoadedOnce = false
        this.surfaceContainer = surfaceContainer

        AndroidAutoService.session?.carContext.let {
            mapView.setSurface(
                it,
                surfaceContainer.surface,
                surfaceContainer.width,
                surfaceContainer.height,
            )
        }
        mapView.mapScene.loadScene(MapScheme.NORMAL_DAY, ::onLoadScene)

        // Load the map scene using a map scheme to render the map with.

        toggleSatelliteViewHandler = { isSatelliteViewEnabled: Bool ->
            this.isSatelliteViewEnabled = isSatelliteViewEnabled

            var mapScheme: MapScheme = MapScheme.NORMAL_DAY

            //            if (this.traitCollection.userInterfaceStyle == .dark) {
            //                mapScheme = if(isSatelliteViewEnabled)  MapScheme.HYBRID_NIGHT else
            // MapScheme.NORMAL_NIGHT
            //            } else {
            //                mapScheme = if(isSatelliteViewEnabled)  MapScheme.HYBRID_DAY else
            // MapScheme.NORMAL_DAY
            //            }

            mapView.mapScene.loadScene(mapScheme, ::onLoadScene)
        }
    }

    /**
     * Updates the stable area of the view controller and updates the camera principal point.
     *
     * @param stableArea the new stable area of the view controller
     */
    override fun onStableAreaChanged(stableArea: Rect) {
        super.onStableAreaChanged(stableArea)

        this.stableArea = stableArea

//        updateCameraPrincipalPoint()
    }

    /**
     * Updates the visible area of the map view controller and updates the camera principal point.
     *
     * @param visibleArea the new visible area of the map view controller
     */
    override fun onVisibleAreaChanged(visibleArea: Rect) {
        super.onVisibleAreaChanged(visibleArea)

        this.visibleArea = visibleArea

//        updateCameraPrincipalPoint()
    }

    /**
     * Will be called on scroll event. Needs car api version 2 to work. See
     * [SurfaceCallback.onScroll] definition for more details.
     */
    override fun onScroll(distanceX: Float, distanceY: Float) {
        mapView.gestures.scrollHandler.onScroll(distanceX, distanceY)
    }

    /**
     * Will be called on scale event. Needs car api version 2 to work. See [SurfaceCallback.onScale]
     * definition for more details.
     */
    override fun onScale(focusX: Float, focusY: Float, scaleFactor: Float) {
        mapView.gestures.scaleHandler.onScale(focusX, focusY, scaleFactor)
    }

    /**
     * Will be called on scale event. Needs car api version 2 to work. See [SurfaceCallback.onFling]
     * definition for more details.
     */
    override fun onFling(velocityX: Float, velocityY: Float) {
        /**
         *
         * Fling event appears to have inverted axis compared to scroll event on desktop head unit.
         * This should not be the case according to
         * [androidx.car.app.navigation.model.NavigationTemplate]. To compensate inverted axis ,
         * factor of -1 was introduced. This might differ depending on which head unit model is
         * used.
         */
        mapView.gestures.flingHandler.onFling(-1 * velocityX, -1 * velocityY)
    }

    /**
     * Destroys the surface of the map view when the surface is destroyed.
     *
     * @param surfaceContainer the surface container that is being destroyed
     */
    override fun onSurfaceDestroyed(surfaceContainer: SurfaceContainer) {
        mapView.destroySurface()
    }

    //    /// Trait collection
    //    /// - Parameter previousTraitCollection: Previous trait collection
    //    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    //    {
    //        super.traitCollectionDidChange(previousTraitCollection)
    //
    //        toggleSatelliteViewHandler?.invoke(isSatelliteViewEnabled)
    //    }

    /**
     * Completion handler when loading a map scene.
     *
     * @param mapError The map error, if any.
     */
    private fun onLoadScene(mapError: MapError?): Unit {
        if (mapError != null) {
            Logger.log("Error: Map scene not loaded, $mapError")
            return
        }

        if (mapController == null) mapController = MapController(mapView)

        //        mapView.isMultipleTouchEnabled = true

        // Disable traffic view support
        mapView.mapScene.disableFeatures(
            listOf(MapFeatures.TRAFFIC_FLOW, MapFeatures.TRAFFIC_INCIDENTS)
        )

        // Update the map coordinates
        updateMapCoordinatesHandler = { mapCoordinates: MapCoordinates ->
            this.mapCoordinates = mapCoordinates
            when {
                mapController?.lastKnownLocation != null -> {
                    val location = mapController!!.lastKnownLocation!!
                    renderInitialMarker(
                        coordinates = location.coordinates,
                        accuracy = location.horizontalAccuracyInMeters ?: 0.0
                    )
                }

                mapCoordinates.stationAddressCoordinates != null -> {
                    renderInitialMarker(
                        coordinates = mapCoordinates.stationAddressCoordinates!!,
                        accuracy = 0.0
                    )
                }

                else -> {
                    mapController?.removeMarker(MapMarkerType.INITIAL)
                    mapController?.removePolygon(MapMarkerType.INITIAL)
                }
            }

            mapCoordinates.incidentAddressCoordinates?.let { renderIncidentAddressMarker(it) }
                ?: mapController?.removeMarker(MapMarkerType.INCIDENT_ADDRESS)

            mapCoordinates.destinationAddressCoordinates?.let { renderDestinationAddressMarker(it) }
                ?: mapController?.removeMarker(MapMarkerType.DESTINATION_ADDRESS)
        }

        // Recenter map position
        recenterMapViewHandler =
            recenterMapViewHandler@{ recenterMapPosition: String ->
                this.recenterMapPosition = recenterMapPosition

                if (isPanningInterfaceVisible) return@recenterMapViewHandler

                if (mapController?.navigationHelper?.isNavigationInProgress == true) {
                    mapController?.navigationHelper?.startCameraTracking()
                } else {
                    val initialMarkerCoordinates =
                        mapController?.getMarkerCoordinates(MapMarkerType.INITIAL)
                    val incidentAddressCoordinates =
                        mapController?.getMarkerCoordinates(MapMarkerType.INCIDENT_ADDRESS)
                    val destinationAddressCoordinates =
                        mapController?.getMarkerCoordinates(
                            MapMarkerType.DESTINATION_ADDRESS
                        )

                    when (recenterMapPosition) {
                        "initialMarker" -> {
                            if (initialMarkerCoordinates != null) {
                                flyToCoordinates(initialMarkerCoordinates)
                            }
                        }

                        "addressMarker" -> {
                            if (incidentAddressCoordinates != null &&
                                destinationAddressCoordinates != null
                            ) {
                                lookAtArea(
                                    geoCoordinates =
                                    listOf(
                                        incidentAddressCoordinates,
                                        destinationAddressCoordinates,
                                    )
                                )
                            } else if (incidentAddressCoordinates != null) {
                                flyToCoordinates(incidentAddressCoordinates)
                            }
                        }

                        "bothMarkers" -> {
                            if (initialMarkerCoordinates != null &&
                                incidentAddressCoordinates != null
                            ) {
                                val geoCoordinates =
                                    mutableListOf(
                                        initialMarkerCoordinates,
                                        incidentAddressCoordinates,
                                    )
                                if (destinationAddressCoordinates != null) {
                                    geoCoordinates.add(destinationAddressCoordinates)
                                }

                                lookAtArea(geoCoordinates)
                            }
                        }

                        else -> {}
                    }
                }
            }

        // Update the initial location marker
        locationUpdatedHandler = {
            updateMapCoordinatesHandler?.invoke(mapCoordinates)

            recenterMapViewHandler?.invoke(recenterMapPosition)
        }

        if (!mapLoadedOnce) {
            flyToCoordinates(defaultCoordinates)
            mapLoadedOnce = true
        }
    }

    /**
     * Look at the area containing all the markers.
     *
     * @param geoCoordinates The coordinates of the markers.
     */
    fun lookAtArea(geoCoordinates: List<GeoCoordinates>) {
        GeoBox.containing(geoCoordinates)?.let { geoBox ->
            //        val scale = FlutterCarplayTemplateManager.carWindow ?. screen . scale ?? 1.0
            //        val topSafeArea = view . safeAreaInsets . top * scale
            //                val leftSafeArea = view . safeAreaInsets . left * scale
            //                val rightSafeArea = view . safeAreaInsets . right * scale
            //                val width = view . frame . width * scale
            //                val height = view . frame . height * scale
            //                val bannerHeight = bannerView . isHidden ? 0.0 :
            // bannerView.bounds.height * scale

            val topSafeArea = visibleArea.top
            val leftSafeArea = visibleArea.bottom
            val rightSafeArea = visibleArea.right
            val width = visibleArea.width()
            val height = visibleArea.height()
            //            val bannerHeight = bannerView . isHidden ? 0.0 : bannerView.bounds.height
            // * scale

            val rectangle2D =
                if (isDashboardSceneActive)
                    Rectangle2D(
                        Point2D(markerPinSize, markerPinSize),
                        Size2D(width - markerPinSize * 2, height - markerPinSize * 2)
                    )
                else
                    Rectangle2D(
                        Point2D(
                            leftSafeArea + markerPinSize,
                            topSafeArea + markerPinSize
                            //                            topSafeArea + bannerHeight
                            // + markerPinSize
                        ),
                        Size2D(
                            width -
                                    leftSafeArea -
                                    rightSafeArea -
                                    markerPinSize * 2,
                            height - topSafeArea - markerPinSize * 2
                            //                            height -topSafeArea -
                            // bannerHeight - markerPinSize * 2
                        )
                    )

            mapView.camera.lookAt(
                geoBox,
                GeoOrientationUpdate(0.0, 0.0),
                rectangle2D,
            )
        }
    }

    /** Update the camera principal point */
    fun updateCameraPrincipalPoint() {
        //            val scale = FlutterCarplayTemplateManager.carWindow?.screen.scale ?? 1.0
        //            val topSafeArea = view.safeAreaInsets.top * scale
        //            val bottomSafeArea = view.safeAreaInsets.bottom * scale
        //            val leftSafeArea = view.safeAreaInsets.left * scale
        //            val rightSafeArea = isPanningInterfaceVisible ? 0.0 :
        // view.safeAreaInsets.right * scale
        //            val width = view.frame.width * scale
        //            val height = view.frame.height * scale

        val topSafeArea = visibleArea.top
        val bottomSafeArea = visibleArea.bottom
        val leftSafeArea = visibleArea.bottom
        val rightSafeArea = if (isPanningInterfaceVisible) 0 else visibleArea.right
        val width = visibleArea.width()
        val height = visibleArea.height()

        if (isDashboardSceneActive) {
            val cameraPrincipalPoint = Point2D(width / 2.0, height / 2.0)
            mapView.camera.principalPoint = cameraPrincipalPoint

            val anchor2D = Anchor2D(0.5, 0.65)
            mapController?.navigationHelper?.setVisualNavigatorCameraPoint(anchor2D)

            recenterMapViewHandler?.invoke(recenterMapPosition)

            mapView.setWatermarkLocation(
                Anchor2D(
                    (leftSafeArea / width).toDouble(),
                    ((height - bottomSafeArea) / height).toDouble()
                ),
                Point2D(-mapView.watermarkSize.width / 2, -mapView.watermarkSize.height / 2)
            )
        } else {
            //            val bannerHeight =
            //                if (bannerView.isHidden) 0.0 else bannerView.bounds.height * scale
            //            val overlayViewWidth =
            //                if (overlayView.isHidden) 0.0 else overlayView.bounds.width * scale +
            // 16.0

            val cameraPrincipalPoint =
                Point2D(
                    leftSafeArea +
                            overlayViewWidth +
                            (width - leftSafeArea - rightSafeArea - overlayViewWidth) / 2.0,
                    topSafeArea + (height - topSafeArea) / 2.0
                    //                        topSafeArea +bannerHeight + (height -
                    // topSafeArea - bannerHeight) / 2.0
                )
            mapView.camera.principalPoint = cameraPrincipalPoint

            val anchor2D =
                Anchor2D(
                    cameraPrincipalPoint.x / width,
                    if (isPanningInterfaceVisible) cameraPrincipalPoint.y / height else 0.75
                )
            mapController?.navigationHelper?.setVisualNavigatorCameraPoint(anchor2D)

            if (isPanningInterfaceVisible) {
                mapController?.navigationHelper?.stopCameraTracking()
            } else {
                recenterMapViewHandler?.invoke(recenterMapPosition)
            }

            mapView.setWatermarkLocation(
                Anchor2D(
                    (leftSafeArea / width).toDouble(),
                    ((height - bottomSafeArea) / height).toDouble(),
                ),
                Point2D(
                    mapView.watermarkSize.width / 2,
                    mapView.watermarkSize.height / 2,
                )
            )
        }
    }
}

/**
 * Displays a banner message at the top of the screen.
 *
 * @param message The message to display.
 * @param color The color of the banner.
 */
// fun FCPMapViewController.showBanner(message: String, color: Int) {
//    shouldShowBanner = true
//    bannerView.setMessage(message)
//    bannerView.setBackgroundColor(color)
//    bannerView.isHidden = isDashboardSceneActive || isPanningInterfaceVisible
//
//    if (!isDashboardSceneActive && bannerViewHeight != bannerView.bounds.height) {
//        bannerViewHeight = bannerView.bounds.height
//        updateCameraPrincipalPoint()
//    }
// }

/** Hides the banner message at the top of the screen. */
// fun FCPMapViewController.hideBanner () {
//    bannerView.isHidden = true
//    shouldShowBanner = false
// }

/**
 * Displays a toast message on the screen for a specified duration.
 *
 * @param message The message to display.
 * @param duration The duration of the toast.
 */
// fun FCPMapViewController.showToast (message: String, duration: Double = 2.0) {
//    if(isDashboardSceneActive) return
//
//    // Cancel any previous toast
//    NSObject.cancelPreviousPerformRequests(withTarget: self)
//
//    toastViewMaxWidth.constant = view.bounds.size.width * 0.65
//
//    // Set the message and show the toast
//    toastView.setMessage(message)
//
//    // Fade in the toast
//    toastView.alpha = 1.0
//
//    // Dismiss the toast after the specified duration
//    perform(# selector (dismissToast), with: null, afterDelay: duration)
// }

/** Hides the toast message on the screen. */
// @objc private fun FCPMapViewController.dismissToast() {
//    UIView.animate(withDuration: 0.3) {
//        self.toastView.alpha = 0.0
//    }
// }

/**
 * Displays an overlay view on the screen.
 *
 * @param primaryTitle The primary title of the overlay view.
 * @param secondaryTitle The secondary title of the overlay view.
 * @param subtitle The subtitle of the overlay view.
 */
// fun FCPMapViewController.showOverlay (primaryTitle: String?, secondaryTitle: String?, subtitle:
// String?) {
//    shouldShowOverlay = true
//    overlayViewMaxWidth.constant = view.bounds.size.width * 0.65
//
//    primaryTitle?.let {
//        overlayView.setPrimaryTitle(it)
//    }
//    secondaryTitle?.let {
//        overlayView.setSecondaryTitle(it)
//    }
//    subtitle?.let {
//        overlayView.setSubtitle(it)
//    }
//    overlayView.isHidden = isDashboardSceneActive || isPanningInterfaceVisible
//
//    if (!isDashboardSceneActive && overlayViewWidth != overlayView.bounds.width) {
//        overlayViewWidth = overlayView.bounds.width
//        updateCameraPrincipalPoint()
//    }
// }

/** Hides the overlay view on the screen. */
// fun FCPMapViewController.hideOverlay () {
//    overlayView.setPrimaryTitle("00:00:00")
//    overlayView.setSecondaryTitle("--")
//    overlayView.setSubtitle("--")
//    overlayView.isHidden = true
//    overlayViewWidth = 0.0
//    shouldShowOverlay = false
// }

/** Hide all the subviews. */
// fun FCPMapViewController.hideSubviews () {
//    bannerView.isHidden = true
//    overlayView.isHidden = true
//    updateCameraPrincipalPoint()
// }

/** Show the subviews. */
// fun FCPMapViewController.showSubviews() {
//    bannerView.isHidden = !shouldShowBanner || isPanningInterfaceVisible
//    overlayView.isHidden = !shouldShowOverlay || isPanningInterfaceVisible
//    updateCameraPrincipalPoint()
// }

/**
 * Adds an initial marker on the map.
 *
 * @param coordinates The coordinates of the marker
 * @param accuracy The accuracy of the marker
 */
fun FCPMapViewController.renderInitialMarker(coordinates: GeoCoordinates, accuracy: Double) {
    if (mapController?.navigationHelper?.isNavigationInProgress == true) {
        mapController?.removeMarker(MapMarkerType.INITIAL)
        mapController?.removePolygon(MapMarkerType.INITIAL)
        return
    }

    val metadata = Metadata()
    metadata.setString("marker", MapMarkerType.INITIAL.name)
    metadata.setString("polygon", MapMarkerType.INITIAL.name)

    val image = UIImageObject.fromFlutterAsset("assets/icons/carplay/position.png")
    val markerSize = 30 * mapView.pixelScale

    mapController?.addMapMarker(
        coordinates = coordinates,
        markerImage = image,
        markerSize = CGSize(width = markerSize, height = markerSize),
        metadata = metadata,
    )
    mapController?.addMapPolygon(coordinate = coordinates, accuracy = accuracy, metadata = metadata)
}

/**
 * Adds an incident marker on the map.
 *
 * @param coordinates The coordinates of the marker
 */
fun FCPMapViewController.renderIncidentAddressMarker(coordinates: GeoCoordinates) {
    val metadata = Metadata()
    metadata.setString("marker", MapMarkerType.INCIDENT_ADDRESS.name)

    val image = UIImageObject.fromFlutterAsset("assets/icons/carplay/map_marker_big.png")

    mapController?.addMapMarker(
        coordinates = coordinates,
        markerImage = image,
        markerSize = CGSize(width = markerPinSize, height = markerPinSize),
        metadata = metadata,
    )
}

/**
 * Adds a destination marker on the map.
 *
 * @param coordinates The coordinates of the marker
 * @param accuracy The accuracy of the marker
 */
fun FCPMapViewController.renderDestinationAddressMarker(coordinates: GeoCoordinates) {
    val metadata = Metadata()
    metadata.setString("marker", MapMarkerType.DESTINATION_ADDRESS.name)

    val image = UIImageObject.fromFlutterAsset("assets/icons/carplay/map_marker_wp.png")

    mapController?.addMapMarker(
        coordinates = coordinates,
        markerImage = image,
        markerSize = CGSize(width = markerPinSize, height = markerPinSize),
        metadata = metadata,
    )
}

/**
 * Fly to coordinates with animation on the map.
 *
 * @param coordinates The coordinates to fly to
 * @param bowFactor The bow factor of the animation
 * @param duration The duration of the animation
 */
fun FCPMapViewController.flyToCoordinates(
    coordinates: GeoCoordinates,
    bowFactor: Double = 0.2,
    duration: Duration = Duration.ofSeconds(1),
) {
    Logger.log("principlePoint at fly to: ${mapView.camera.principalPoint}")

    if (isPanningInterfaceVisible) {
        val animation =
            MapCameraAnimationFactory.flyTo(
                GeoCoordinatesUpdate(coordinates),
                GeoOrientationUpdate(0.0, 0.0),
                0.0,
                Duration.ofMillis(500)
            )

        mapView.camera.startAnimation(animation)
    } else {
        val animation =
            MapCameraAnimationFactory.flyTo(
                GeoCoordinatesUpdate(coordinates),
                GeoOrientationUpdate(0.0, 0.0),
                MapMeasure(
                    MapMeasure.Kind.DISTANCE,
                    ConstantsEnum.DEFAULT_DISTANCE_IN_METERS
                ),
                bowFactor,
                duration
            )

        mapView.camera.startAnimation(animation)
    }
}

/**
 * Starts the navigation.
 *
 * @param destination The destination waypoint
 */
fun FCPMapViewController.startNavigation(trip: CPTrip) {
    //    val wayPoint = Waypoint(
    //        GeoCoordinates(
    //            trip.destination.placemark.coordinate.latitude,
    //            trip.destination.placemark.coordinate.longitude
    //        )
    //    )
    //    mapController?.setDestinationWaypoint(wayPoint)

    mapController?.addRouteDeviceLocation()

    mapController?.removeMarker(MapMarkerType.INITIAL)
    mapController?.removePolygon(MapMarkerType.INITIAL)
}

/** Stops the navigation. */
fun FCPMapViewController.stopNavigation() {
    mapController?.clearMap()
    updateMapCoordinatesHandler?.invoke(mapCoordinates)
}

/**
 * Pans the camera in the specified direction.
 *
 * @param direction The direction to pan
 */
// fun FCPMapViewController.panInDirection(direction: CPMapTemplate.PanDirection) {
//    Logger.log("Panning to ${direction}.")
//
//    var offset = mapView.camera.principalPoint
//    when (direction) {
//        down ->
//            offset.y += mapView.viewportSize.height / 2.0
//
//        up ->
//            offset.y -= mapView.viewportSize.height / 2.0
//
//        left ->
//            offset.x -= mapView.viewportSize.width / 2.0
//
//        right ->
//            offset.x += mapView.viewportSize.width / 2.0
//
//        else -> return
//    }
//
//    // Update the Map camera position
//    mapView.viewToGeoCoordinates(offset)?.let { flyToCoordinates(it) }
// }

/** Zooms in the camera. */
fun FCPMapViewController.zoomInMapView() {
    val zoomLevel = min(mapView.camera.state.zoomLevel.toDouble() + 1, 22.0)
    mapView.camera.zoomTo(zoomLevel)
}

/** Zooms out the camera. */
fun FCPMapViewController.zoomOutMapView() {
    val zoomLevel = max(mapView.camera.state.zoomLevel.toDouble() - 1, 0.0)
    mapView.camera.zoomTo(zoomLevel)
}
