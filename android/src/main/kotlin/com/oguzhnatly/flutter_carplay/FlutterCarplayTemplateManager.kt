package com.oguzhnatly.flutter_carplay

import FCPConnectionTypes
import androidx.car.app.CarContext

object FlutterCarplayTemplateManager {
    var carplayInterfaceController: CarContext? = null
//    var carplayDashboardController: CPDashboardController?

    // CarPlay connection status (either CarPlay or Dashboard)
    var fcpConnectionStatus = FCPConnectionTypes.DISCONNECTED
        set(value) {
            field = value
            FlutterCarplayPlugin.onCarplayConnectionChange(value.name)
        }

    // Android Auto Dashboard connection status
    var dashboardConnectionStatus = FCPConnectionTypes.DISCONNECTED

    // Android Auto scene connection status
    var carplayConnectionStatus = FCPConnectionTypes.DISCONNECTED

    // Android Auto session configuration
    var sessionConfiguration: AndroidAutoSession? = null

    // Whether the dashboard scene is active
    var isDashboardSceneActive = false
}
