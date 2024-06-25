package com.oguzhnatly.flutter_carplay.models.map

import androidx.car.app.AppManager
import androidx.car.app.OnDoneCallback
import androidx.car.app.SurfaceCallback
import androidx.car.app.model.Action
import androidx.car.app.model.ActionStrip
import androidx.car.app.navigation.NavigationManager
import androidx.car.app.navigation.NavigationManagerCallback
import androidx.car.app.navigation.model.NavigationTemplate
import androidx.car.app.serialization.Bundleable
import com.oguzhnatly.flutter_carplay.AndroidAutoService
import com.oguzhnatly.flutter_carplay.Bool
import com.oguzhnatly.flutter_carplay.CPMapTemplate
import com.oguzhnatly.flutter_carplay.CPTrip
import com.oguzhnatly.flutter_carplay.FCPRootTemplate
import com.oguzhnatly.flutter_carplay.models.button.FCPBarButton


/**
 * A custom Android Auto map template with additional customization options.
 *
 * @param obj A dictionary containing the configuration parameters for the map template.
 */
class FCPMapTemplate(obj: Map<String, Any>) : FCPRootTemplate() {

    /// The super template object representing the CarPlay map template.
    lateinit var _super: CPMapTemplate

    /// The view controller associated with the map template.
    var viewController: SurfaceCallback
        private set

    /// The title displayed on the map template.
    private var title: String?

    /// The map buttons to be displayed on the map template.
    private var mapButtons: List<FCPMapButton>

    /// The leading navigation bar buttons for the map template.
    private var leadingNavigationBarButtons: List<FCPBarButton>

    /// The trailing navigation bar buttons for the map template.
    private var trailingNavigationBarButtons: List<FCPBarButton>

//    /// The dashboard buttons to be displayed on the CarPlay dashboard.
//    private var dashboardButtons: List<FCPDashboardButton>

    /// A boolean value indicating whether the navigation bar is automatically hidden.
    private var automaticallyHidesNavigationBar: Bool

    /// A boolean value indicating whether buttons are hidden with the navigation bar.
    private var hidesButtonsWithNavigationBar: Bool

    /// A boolean value indicating whether the map is in panning mode.
    var isPanningInterfaceVisible: Bool = false

    /// Navigation session used to manage the upcomingManeuvers and  arrival estimation details
    var navigationSession: NavigationManager? = null

    /// Get the `FCPMapViewController` associated with the map template.
    val fcpMapViewController: FCPMapViewController?
        get() = viewController as? FCPMapViewController

    init {
        val elementIdValue = obj["_elementId"] as? String
        assert(elementIdValue != null) {
            "Missing required keys in dictionary for FCPMapTemplate initialization."
        }
        elementId = elementIdValue!!
        title = obj["title"] as? String
        automaticallyHidesNavigationBar = obj["automaticallyHidesNavigationBar"] as? Bool ?: false
        hidesButtonsWithNavigationBar = obj["hidesButtonsWithNavigationBar"] as? Bool ?: false
        isPanningInterfaceVisible = obj["isPanningInterfaceVisible"] as? Bool ?: false

        mapButtons = (obj["mapButtons"] as? List<Map<String, Any>>)?.map {
            FCPMapButton(it)
        } ?: emptyList()

//        dashboardButtons = (obj["dashboardButtons"] as? List<Map<String, Any>>)?.map {
//            FCPDashboardButton(it)
//        } ?: emptyList()

        leadingNavigationBarButtons =
            (obj["leadingNavigationBarButtons"] as? List<Map<String, Any>>)?.map {
                FCPBarButton(it)
            }
                ?: emptyList()
        trailingNavigationBarButtons =
            (obj["trailingNavigationBarButtons"] as? List<Map<String, Any>>)?.map {
                FCPBarButton(it)
            }
                ?: emptyList()

        // Initialize the view controller.
        viewController = FCPMapViewController()

        AndroidAutoService.session?.carContext?.getCarService(AppManager::class.java)
            ?.setSurfaceCallback(viewController)

        navigationSession =
            AndroidAutoService.session?.carContext?.getCarService(NavigationManager::class.java)

        navigationSession?.setNavigationManagerCallback(object : NavigationManagerCallback {
            /**
             * Overrides the `onStopNavigation` function and calls the `super.onStopNavigation()`
             * method to perform any necessary cleanup. Then, calls the `stopNavigation()`
             * method to stop the navigation.
             *
             * @return void
             */
            override fun onStopNavigation() {
                stopNavigation()
            }
        })
    }

    /** Gets the Android Auto map template object based on the configured parameters. */
    override fun getTemplate(): CPMapTemplate {
        val mapTemplate = NavigationTemplate.Builder()
        if (mapButtons.isNotEmpty()) {
            val actionStrip = ActionStrip.Builder()
            for (button in mapButtons) {
                actionStrip.addAction(button.getTemplate())
            }
            actionStrip.addAction(Action.PAN)
            mapTemplate.setMapActionStrip(actionStrip.build())
        }

        if (leadingNavigationBarButtons.isNotEmpty() || trailingNavigationBarButtons.isNotEmpty()) {
            val actionStrip = ActionStrip.Builder()
            for (button in leadingNavigationBarButtons) {
                actionStrip.addAction(button.getTemplate())
            }
            for (button in trailingNavigationBarButtons) {
                actionStrip.addAction(button.getTemplate())
            }
            mapTemplate.setActionStrip(actionStrip.build())
        }

        mapTemplate.setPanModeListener { isPanningInterfaceVisible = it }

//        mapTemplate.automaticallyHidesNavigationBar = automaticallyHidesNavigationBar
//        mapTemplate.hidesButtonsWithNavigationBar = hidesButtonsWithNavigationBar
//        mapTemplate.mapDelegate = self

        _super = mapTemplate.build()
        return _super
    }

    /**
     * Updates the properties of the map template.
     *
     * @param title The new title text.
     * @param automaticallyHidesNavigationBar A boolean value indicating whether the navigation bar is automatically hidden.
     * @param hidesButtonsWithNavigationBar A boolean value indicating whether buttons are hidden with the navigation bar.
     * @param mapButtons The new array of map buttons.
     * @param leadingNavigationBarButtons The new array of leading navigation bar buttons.
     * @param trailingNavigationBarButtons The new array of trailing navigation bar buttons.
     */
    fun update(
        title: String?,
        automaticallyHidesNavigationBar: Bool?,
        hidesButtonsWithNavigationBar: Bool?,
        isPanningInterfaceVisible: Bool?,
        mapButtons: List<FCPMapButton>?,
        leadingNavigationBarButtons: List<FCPBarButton>?,
        trailingNavigationBarButtons: List<FCPBarButton>?,
    ) {
        title?.let { this.title = it }
        automaticallyHidesNavigationBar?.let { this.automaticallyHidesNavigationBar = it }
        hidesButtonsWithNavigationBar?.let { this.hidesButtonsWithNavigationBar = it }
        isPanningInterfaceVisible?.let { this.isPanningInterfaceVisible = it }
        mapButtons?.let { this.mapButtons = it }
        leadingNavigationBarButtons?.let { this.leadingNavigationBarButtons = it }
        trailingNavigationBarButtons?.let { this.trailingNavigationBarButtons = it }

        onInvalidate()
    }
}

/**
 * Show trip previews
 *
 * @param trips The array of trips to show
 * @param selectedTrip The selected trip
 * @param textConfiguration The text configuration
 */
fun FCPMapTemplate.showTripPreviews(
    trips: List<FCPTrip>,
    selectedTrip: FCPTrip?,
//    textConfiguration: FCPTripPreviewTextConfiguration?,
) {
    val cpTrips = trips.map { it.getTemplate() }
//    _super?.showTripPreviews(cpTrips, selectedTrip: selectedTrip?. get,
//    textConfiguration: textConfiguration?.get)
}

/** Hide trip previews. */
fun FCPMapTemplate.hideTripPreviews() {
//    _super?.hideTripPreviews()
}

/**
 * Starts the navigation
 *
 * @param trip The trip to start navigation
 */
fun FCPMapTemplate.startNavigation(trip: CPTrip) {
//    if (navigationSession != null) {
//        navigationSession?.navigationEnded()
//        navigationSession = null
//    }

    hideTripPreviews()
//    navigationSession = _super?.startNavigationSession(for: trip)

//    if # available(iOS 15.4, *) {
//        navigationSession?.pauseTrip(for:.loading, description: "", turnCardColor: .systemGreen)
//    } else {
//        navigationSession?.pauseTrip(for:.loading, description: "")
//    }

    navigationSession?.updateTrip(trip)
    fcpMapViewController?.startNavigation(trip)
    navigationSession?.navigationStarted()
}

/** Stops the navigation. */
fun FCPMapTemplate.stopNavigation() {
    navigationSession?.navigationEnded()
//    navigationSession = null

    fcpMapViewController?.stopNavigation()
}

/**
 * Pans the camera in the specified direction
 *
 * @param animated A boolean value indicating whether the transition should be animated
 */
fun FCPMapTemplate.showPanningInterface() {
    _super.panModeDelegate?.sendPanModeChanged(true, object : OnDoneCallback {
        override fun onSuccess(response: Bundleable?) {
            print("pan mode enable success: $response")
        }

        override fun onFailure(response: Bundleable) {
            print("pan mode enable failed: $response")

        }
    })
}

/**
 * Dismisses the panning interface
 *
 * @param animated A boolean value indicating whether the transition should be animated
 */
fun FCPMapTemplate.dismissPanningInterface() {
    _super.panModeDelegate?.sendPanModeChanged(false, object : OnDoneCallback {
        override fun onSuccess(response: Bundleable?) {
            print("pan mode enable success: $response")
        }

        override fun onFailure(response: Bundleable) {
            print("pan mode enable failed: $response")

        }
    })
}


//extension FCPMapTemplate: CPMapTemplateDelegate {
//    /// Called when the map template has started a trip
//    /// - Parameter
//    ///   - mapTemplate: The map template
//    ///   - trip: The trip that was started
//    ///   - routeChoice: The route choice
//    func mapTemplate (_: CPMapTemplate, startedTrip trip: CPTrip, using _: CPRouteChoice) {
//        let originCoordinate = trip . origin . placemark . coordinate
//                let destinationCoordinate = trip . destination . placemark . coordinate
//
//                DispatchQueue.main.async {
//                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes. onNavigationStartedFromCarplay, data: ["sourceLatitude": originCoordinate.latitude, "sourceLongitude": originCoordinate.longitude, "destinationLatitude": destinationCoordinate.latitude, "destinationLongitude": destinationCoordinate.longitude])
//                }
//    }
//
//    /// Called when the panning interface is shown
//    /// - Parameter mapTemplate: The map template
//    func mapTemplateDidShowPanningInterface (_: CPMapTemplate) {
//        fcpMapViewController?.hideSubviews()
//        fcpMapViewController?.mapController?.navigationHelper.stopCameraTracking()
//    }
//
//    /// Called when the panning interface is dismissed
//    /// - Parameter mapTemplate: The map template
//    func mapTemplateDidDismissPanningInterface (_: CPMapTemplate) {
//        fcpMapViewController?.showSubviews()
//        fcpMapViewController?.mapController?.navigationHelper.startCameraTracking()
//    }
//
//    /// Called when the map template is panning
//    /// - Parameters:
//    ///   - maptemplate: The map template
//    ///   - direction: The direction of the panning
//    func mapTemplate (_: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
//        fcpMapViewController?.panInDirection(direction)
//    }
//}
