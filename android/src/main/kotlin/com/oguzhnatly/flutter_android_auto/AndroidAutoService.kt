package com.oguzhnatly.flutter_android_auto                               
           
import androidx.car.app.CarAppService                                     
import androidx.car.app.validation.HostValidator            
import androidx.car.app.Session                                           
import io.flutter.embedding.engine.FlutterEngine                          
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.FlutterEngineCache;

class AndroidAutoService : CarAppService() {
    companion object {
        var session: AndroidAutoSession? = null
    }

    override fun onCreate() {
        super.onCreate()
        val engineCache = FlutterEngineCache.getInstance()
        val flutterEngineId = FAAConstants.flutterEngineId

        val existing = engineCache.get(flutterEngineId)
        if (existing != null && existing.dartExecutor.isExecutingDart) return

        if (existing != null) {
            engineCache.remove(flutterEngineId)
        }

        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        engineCache.put(flutterEngineId, flutterEngine)
    }

    override fun onDestroy() {
        super.onDestroy()

        FlutterEngineCache.getInstance().remove(FAAConstants.flutterEngineId)
    }

    override fun createHostValidator() = HostValidator.ALLOW_ALL_HOSTS_VALIDATOR

    override fun onCreateSession(): Session {
        session = AndroidAutoSession()
        return session!!
    }
}