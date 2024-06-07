package com.oguzhnatly.flutter_carplay

import android.util.Log

object Logger {

    fun log(message: String, tag: String = "AndroidAutoLogs") {
        Log.d(tag, message)
    }
}
