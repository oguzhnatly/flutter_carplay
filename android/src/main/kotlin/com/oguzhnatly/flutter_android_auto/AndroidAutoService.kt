package com.oguzhnatly.flutter_android_auto

import androidx.car.app.CarAppService
import androidx.car.app.validation.HostValidator
import androidx.car.app.Session
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.FlutterEngineCache;

class AndroidAutoService : CarAppService() {
    companion object {
        /// The Android Auto session that this service is handling.
        var session: AndroidAutoSession? = null
    }

    override fun onCreate() {
        super.onCreate()
        val engineCache = FlutterEngineCache.getInstance()
        val flutterEngineId = FAAConstants.flutterEngineId

        if (engineCache.get(flutterEngineId) != null) return;

        // Create new engine in headless mode
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        // Cache the engine
        engineCache.put(flutterEngineId, flutterEngine)
    }


    override fun createHostValidator() = HostValidator.ALLOW_ALL_HOSTS_VALIDATOR

    override fun onCreateSession(): Session {
        session = AndroidAutoSession()
        return session!!
    }
}
