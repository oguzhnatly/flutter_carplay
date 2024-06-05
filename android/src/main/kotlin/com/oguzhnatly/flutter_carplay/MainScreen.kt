package com.oguzhnatly.flutter_carplay

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainScreen(carContext: CarContext, private val flutterEngine: FlutterEngine) :
    Screen(carContext) {
    var title: Int = 0
    private val channel = "samples.flutter.dev/androidAuto"
    private val methodChannel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        channel
    )

    override fun onGetTemplate(): Template {
        // MainScreen will be an unresolved reference until the next step
        lifecycle.addObserver(object : DefaultLifecycleObserver {

            override fun onStart(owner: LifecycleOwner) {

                methodChannel.setMethodCallHandler { call, result ->
                    if (call.method == "initialCount") {
                        title = call.arguments<Int>() ?: 0
                        invalidate()
                    } else if (call.method == "countUpdates") {
                        title = call.arguments<Int>() ?: 0
                        invalidate()
                    }
                }
                methodChannel.invokeMethod("getInitialCount", null)
                super.onStart(owner)
            }

        })

        val action1 = Action.Builder()
            .setTitle("-")
            .setOnClickListener {
                methodChannel.invokeMethod("decrement", title - 1)
            }
            .build()
        val action2 = Action.Builder()
            .setTitle("+")
            .setOnClickListener {
                methodChannel.invokeMethod("increment", title + 1)
            }
            .build()

        return MessageTemplate.Builder("Message template")
            .setTitle(title.toString())
            .addAction(action1)
            .addAction(action2)
            .build()
    }

}