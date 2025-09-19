package com.oguzhnatly.flutter_android_auto

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

class AndroidAutoSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen {
        val screen = MainScreen(carContext)
        FlutterAndroidAutoPlugin.currentScreen = screen

        lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStart(owner: LifecycleOwner) {
                FlutterAndroidAutoPlugin.onAndroidAutoConnectionChange(
                    FAAConnectionTypes.connected
                )
                super.onStart(owner)
            }


            override fun onResume(owner: LifecycleOwner) {
                FlutterAndroidAutoPlugin.onAndroidAutoConnectionChange(
                    FAAConnectionTypes.connected
                )
                super.onResume(owner)
            }

            override fun onStop(owner: LifecycleOwner) {
                FlutterAndroidAutoPlugin.onAndroidAutoConnectionChange(
                    FAAConnectionTypes.disconnected
                )
                super.onStop(owner)
            }
        })

        return screen
    }
}
