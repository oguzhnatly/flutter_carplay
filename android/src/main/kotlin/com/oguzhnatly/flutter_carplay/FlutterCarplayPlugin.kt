package com.oguzhnatly.flutter_carplay

import FCPChannelTypes
import FCPListTemplateTypes
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Template
import com.oguzhnatly.flutter_carplay.models.list.FCPListTemplate
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * FlutterCarplayPlugin A Kotlin Flutter plugin for Android Auto integration.
 *
 * This plugin provides a bridge between Flutter and Android Auto, allowing developers to create
 * Android Auto-enabled Flutter apps.
 */
class FlutterCarplayPlugin : FlutterPlugin, MethodCallHandler {
    /**
     * The MethodChannel that will handle the communication between Flutter and native Android
     *
     * This local reference serves to register the plugin with the Flutter Engine and unregister it
     * when the Flutter Engine is detached from the Activity
     */
    private lateinit var channel: MethodChannel

    companion object {
        val instance = FlutterCarplayPlugin()
    }

    /// The context for CarPlay.
    var carContext: CarContext? = null

    /// The stream handler for CarPlay communication.
    private var streamHandler: FCPStreamHandlerPlugin? = null

    /// The Flutter plugin registrar.
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    /// The root template to be displayed on CarPlay.
    var fcpRootTemplate: FCPRootTemplate? = null

//    /// The root view controller for CarPlay.
//    var rootViewController: UIViewController? = null

    /// The root template for CarPlay.
    var rootTemplate: Template? = null

    /// The present template object for CarPlay modals.
    var fcpPresentTemplate: FCPPresentTemplate? = null

    // The Template history for CarPlay.
    var cpTemplateHistory: List<Screen> = emptyList()
        private set
        get() = AndroidAutoService.session.screenManager.screenStack.toList()

    /**
     * Attaches the plugin to the Flutter engine.
     *
     * @param flutterPluginBinding the Flutter plugin binding
     */
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Logger.log("onAttachedToEngine")
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, makeFCPChannelId(""))
        channel.setMethodCallHandler(instance)
        instance.flutterPluginBinding = flutterPluginBinding
        streamHandler = FCPStreamHandlerPlugin(flutterPluginBinding)
    }

    /**
     * Handles a Flutter method call and provides a result callback.
     *
     * This method is responsible for processing Flutter method calls and producing a result through
     * the provided `FlutterResult` callback. It is typically used as part of a Flutter plugin
     * implementation.
     *
     * @param call The `FlutterMethodCall` representing the invoked method.
     * @param result The callback to provide the result of the method call to Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method != FCPChannelTypes.showOverlay.name) {
            Logger.log("FlutterMethodCall received : ${call.method}")
        }

        when (call.method) {
            FCPChannelTypes.setRootTemplate.name -> {
                val args = call.arguments as? Map<String, Any>
                val runtimeType = args?.get("runtimeType") as? String
                if (args == null || runtimeType == null) {
                    result.success(false)
                    return
                }
                val rootTemplate = createRootTemplate(args, runtimeType)
                if (rootTemplate == null) {
                    result.success(false)
                    return
                }

                setRootTemplate(rootTemplate, result)
            }

            FCPChannelTypes.forceUpdateRootTemplate.name -> {
                AndroidAutoService.session.forceUpdateRootTemplate(result)
            }

            FCPChannelTypes.popTemplate.name -> {
                val args = call.arguments as? Map<String, Any>
                val count = args?.get("count") as? Int
                if (args == null || count == null) {
                    result.success(false)
                    return
                }

                List(count) {
                    AndroidAutoService.session.pop()
                }

                result.success(true)
            }

            FCPChannelTypes.closePresent.name -> {
                fcpPresentTemplate = null
                AndroidAutoService.session.closePresent(result)
            }

            FCPChannelTypes.pushTemplate.name -> {
                val args = call.arguments as? Map<String, Any>
                if (args == null) {
                    result.success(false)
                    return
                }
                pushTemplate(args, result)
            }

            FCPChannelTypes.popToRootTemplate.name -> {
                fcpPresentTemplate = null
                AndroidAutoService.session.popToRootTemplate(result)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Detaches the plugin from the Flutter engine.
     *
     * @param binding the Flutter plugin binding
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}


/**
 * Creates an FCPRootTemplate based on the provided arguments and runtime type.
 *
 * @param args A dictionary containing the root template arguments.
 * @param runtimeType A string representing the runtime type of the root template.
 * @return An instance of FCPRootTemplate if successful, otherwise null.
 */
fun FlutterCarplayPlugin.createRootTemplate(
    args: Map<String, Any>, runtimeType: String
): FCPRootTemplate? {
    // Ensure that the rootTemplateArgs key exists in the args map
    val rootTemplateArgs = args["rootTemplate"] as? Map<String, Any> ?: return null

    // Create an FCPRootTemplate based on the provided runtime type
    return when (runtimeType) {
//        FCPTabBarTemplate::class.java.name -> FCPTabBarTemplate(rootTemplateArgs)
//        FCPGridTemplate::class.java.name -> FCPGridTemplate(rootTemplateArgs)
//        FCPInformationTemplate::class.java.name -> FCPInformationTemplate(rootTemplateArgs)
//        FCPPointOfInterestTemplate::class.java.name -> FCPPointOfInterestTemplate(rootTemplateArgs)
//        FCPMapTemplate::class.java.name -> {
//            val mapTemplate = FCPMapTemplate(rootTemplateArgs)
//            mapTemplate
//        }
//
        FCPListTemplate::class.java.simpleName -> {
            val templateType = FCPListTemplateTypes.DEFAULT
            FlutterCarplayPlugin.instance.carContext?.let {
                FCPListTemplate(
                    it,
                    rootTemplateArgs,
                    templateType
                )
            }
        }

        else -> null
    }
}

/**
 * Sets the root template for CarPlay based on the provided FCPRootTemplate.
 *
 * @param rootTemplate The FCPRootTemplate to be set as the root template.
 * @param args Additional arguments for setting the root template.
 * @param result A FlutterResult callback to communicate the success or failure of the operation.
 */
fun FlutterCarplayPlugin.setRootTemplate(
    rootTemplate: FCPRootTemplate, result: Result
) {
    val cpRootTemplate: Template

    // Check the type of the root template and extract the corresponding FCPRootTemplate
    when (rootTemplate) {
//        is FCPTabBarTemplate -> {
//            // Ensure that the number of templates in the tab bar template is within the CarPlay limit
//            if (rootTemplate.getTemplates().count > 5) {
//                result.success(false)
//                return
//            }
//            cpRootTemplate = get
//        }
//
//        is FCPGridTemplate -> {
//            cpRootTemplate = get
//        }
//
//        is FCPInformationTemplate -> {
//            cpRootTemplate = get
//        }
//
//        is FCPPointOfInterestTemplate -> {
//            cpRootTemplate = get
//        }
//
//        is FCPMapTemplate -> {
//            // For FCPMapTemplate, set the rootViewController and update the CarPlay window's rootViewController
//            cpRootTemplate = get
//
//            rootViewController = viewController
//
//            if (FlutterCarplayTemplateManager.shared.isDashboardSceneActive) {
//                FlutterCarplayTemplateManager.shared.dashboardWindow?.rootViewController =
//                    viewController
//            } else {
//                FlutterCarplayTemplateManager.shared.carWindow?.rootViewController = viewController
//            }
//        }
//
        is FCPListTemplate -> {
            cpRootTemplate = rootTemplate.getTemplate
        }

        else -> {
            // If the root template type is not recognized, return false
            result.success(false)
            return
        }
    }
    Logger.log("rootTemplate : $cpRootTemplate")

    // If an FCPRootTemplate is successfully extracted, set it as the root template
    Logger.log("fcpRootTemplate : ${FlutterCarplayPlugin.instance.fcpRootTemplate}")
    FlutterCarplayPlugin.instance.rootTemplate = cpRootTemplate
    FlutterCarplayPlugin.instance.fcpRootTemplate = rootTemplate
    AndroidAutoService.session.forceUpdateRootTemplate()

    FlutterCarplayPlugin.instance.onCarplayConnectionChange(
        status = FlutterCarplayTemplateManager.fcpConnectionStatus.name
    )
    result.success(true)
}

/**
 * Pushes a new CarPlay template onto the navigation stack.
 *
 * @param args Arguments containing information about the template to be pushed.
 * @param result The FlutterResult to return the completion status of the operation.
 */
fun FlutterCarplayPlugin.pushTemplate(
    args: Map<String, Any>, result: Result
) {
    // Extract necessary information from the provided arguments

    val runtimeType = args.get("runtimeType") as String?
    val templateArgs = args.get("template") as Map<String, Any>?
    if (runtimeType == null || templateArgs == null) {
        result.success(false)
        return
    }


    // Create the appropriate FCPTemplate based on the runtime type
    val pushTemplate = when (runtimeType) {
//        FCPTabBarTemplate::class.java.name ->
//             FCPGridTemplate(obj = templateArgs)
//
//        FCPGridTemplate::class.java.name ->
//             FCPPointOfInterestTemplate(obj = templateArgs)
//
//        FCPInformationTemplate::class.java.name ->
//             FCPMapTemplate(obj = templateArgs)
//
//        FCPPointOfInterestTemplate::class.java.name ->
//             FCPSearchTemplate(obj = templateArgs)
//
//        FCPMapTemplate::class.java.name ->
//             FCPInformationTemplate(obj = templateArgs)

        FCPListTemplate::class.java.simpleName -> FCPListTemplate(
            carContext = FlutterCarplayPlugin.instance.carContext!!,
            obj = templateArgs,
            templateType = FCPListTemplateTypes.DEFAULT
        )

        else -> null
    }
    if (pushTemplate == null) {
        result.success(false)
        return
    }

    // Push the template onto the navigation stack
    AndroidAutoService.session.push(pushTemplate, result)
}

/**
 * Notifies Flutter about changes in Android Auto connection status.
 *
 * @param status The Android Auto connection status.
 */
fun FlutterCarplayPlugin.onCarplayConnectionChange(status: String) {
    FCPStreamHandlerPlugin.sendEvent(
        FCPChannelTypes.onCarplayConnectionChange.name, mapOf("status" to status)
    )
}
