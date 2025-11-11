package com.example.flutter_carplay_example

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import com.oguzhnatly.flutter_android_auto.FAAConstants

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        // Use engine from cache if it has been started by Android Auto.
        return FlutterEngineCache.getInstance()
            .get(FAAConstants.flutterEngineId);
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Cache the engine to make it usable by Android Auto.
        FlutterEngineCache.getInstance()
            .put(FAAConstants.flutterEngineId, flutterEngine)
        super.configureFlutterEngine(flutterEngine)
    }
}
