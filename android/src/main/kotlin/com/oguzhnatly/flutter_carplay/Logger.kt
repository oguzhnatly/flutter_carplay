package com.oguzhnatly.flutter_carplay

import android.util.Log

/** A class representing the logger used in the Flutter CarPlay plugin. */
object Logger {

    /**
     * Logs a message with a specified tag.
     *
     * @param message the message to be logged
     * @param tag the tag to be associated with the log message (default: "AndroidAutoLogs")
     */
    fun log(message: String, tag: String = "AndroidAutoLogs") {
        Log.d(tag, message)
    }
}
