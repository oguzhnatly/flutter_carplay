package com.oguzhnatly.flutter_carplay

import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator

/**
 * A service that handles the Android Auto session in the Flutter CarPlay framework.
 *
 * This service is responsible for starting and stopping the Android Auto session, managing the
 * screen manager, and handling method channel callbacks.
 *
 * @property session The Android Auto session that this service is handling.
 * @property flutterEngine The Flutter engine used to run the Flutter app.
 * @property screenManager The screen manager used to manage the screens in the Android Auto
 * session.
 */
class AndroidAutoService : CarAppService() {

    companion object {
        var session: AndroidAutoSession? = null
    }

    override fun createHostValidator(): HostValidator {
        return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    }

    override fun onCreateSession(): Session {
        Logger.log("onCreateSession")
        session = AndroidAutoSession()
        return session!!
    }
}
