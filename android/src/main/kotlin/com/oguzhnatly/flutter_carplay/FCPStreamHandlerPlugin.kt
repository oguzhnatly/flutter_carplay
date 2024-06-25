package com.oguzhnatly.flutter_carplay

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

/** Flutter CarPlay (FCP) Stream Handler Plugin for handling communication between Flutter and Android Auto.
 *
 * @param flutterPluginBinding The Flutter plugin registrar.
 */
class FCPStreamHandlerPlugin
    (flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) : EventChannel.StreamHandler {

    init {
        val eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger, makeFCPChannelId("/event")
        )
        eventChannel.setStreamHandler(this)
    }

    companion object {
        /// Static property to store the Flutter event sink for communication.
        private var eventSink: EventChannel.EventSink? = null

        /**
         * Sends a custom event to the Flutter side.
         *
         * @param type The type of the event.
         * @param data The data associated with the event.
         */
        fun sendEvent(type: String, data: Map<String, Any>) {
            if (this.eventSink == null) return

            eventSink?.success(
                mapOf(
                    "type" to type,
                    "data" to data,
                )
            )
        }
    }

//    /**
//     * Sends a CarPlay connection change event to the Flutter side.
//     *
//     * @param status The status of the CarPlay connection.
//     */
//    fun sendCarplayConnectionChangeEvent(status: String) {
//        sendEvent(FCPChannelTypes.onCarplayConnectionChange.name, mapOf("status" to status))
//    }

    /**
     * Sets up the event sink when a listener is added.
     *
     * @param arguments The arguments passed when a listener is added (unused).
     * @param eventSink The Flutter event sink for communication.
     * @return A FlutterError if there is an issue, otherwise null.
     */
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
//        return null
    }

    /**
     * Removes the event sink when the listener is canceled.
     *
     * @param arguments The arguments passed when the listener is canceled (unused).
     * @return A FlutterError if there is an issue, otherwise null.
     */
    override fun onCancel(arguments: Any?) {
        eventSink = null
//        return null
    }
}

/**
 * Generates a Flutter CarPlay (FCP) channel ID based on the specified event.
 *
 * @param event The event associated with the channel.
 * @return The FCP channel ID combining the base identifier and the provided event.
 */
fun makeFCPChannelId(event: String?): String {
    return "com.oguzhnatly.flutter_carplay" + (event ?: "")
}
