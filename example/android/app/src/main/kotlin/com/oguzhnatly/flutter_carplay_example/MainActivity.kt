package com.oguzhnatly.flutter_carplay_example

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        var flutterEngine = FlutterEngineCache.getInstance().get("SharedEngine")
        if (flutterEngine == null) {
            flutterEngine = FlutterEngine(applicationContext)
            FlutterEngineCache.getInstance().put(("SharedEngine"), flutterEngine)
        }
        return flutterEngine
    }
}
