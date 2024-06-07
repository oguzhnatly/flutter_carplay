package com.oguzhnatly.flutter_carplay

import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator

class AndroidAutoService : CarAppService() {

    companion object {
        lateinit var session: AndroidAutoSession
    }

    override fun createHostValidator(): HostValidator {
        return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    }

    override fun onCreateSession(): Session {
        Logger.log("onCreateSession")
        session = AndroidAutoSession(applicationContext)
        return session
    }
}
