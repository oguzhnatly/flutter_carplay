package com.oguzhnatly.flutter_carplay

import android.content.Context
import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class PlacesSession(applicationContext: Context) : Session() {
    private var flutterEngine: FlutterEngine? = null
    var isStartRequired = false
    override fun onCreateScreen(intent: Intent): Screen {

        // MainScreen will be an unresolved reference until the next step
        lifecycle.addObserver(
                object : DefaultLifecycleObserver {

                    override fun onCreate(owner: LifecycleOwner) {
                        flutterEngine = FlutterEngineCache.getInstance().get("SharedEngine")
                        if (flutterEngine == null) {
                            isStartRequired = true
                            flutterEngine = FlutterEngine(carContext.applicationContext)
                            FlutterEngineCache.getInstance().put("SharedEngine", flutterEngine)
                        }

                        super.onCreate(owner)
                    }

                    override fun onStart(owner: LifecycleOwner) {
                        if (isStartRequired) {
                            flutterEngine!!.dartExecutor.executeDartEntrypoint(
                                    DartExecutor.DartEntrypoint.createDefault()
                            )
                        }
                        super.onStart(owner)
                    }
                }
        )

        return MainScreen(carContext, flutterEngine!!)
    }
}
