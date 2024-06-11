package com.oguzhnatly.flutter_carplay

import FCPChannelTypes
import FCPListTemplateTypes
import androidx.car.app.CarContext
import androidx.car.app.Screen
import com.oguzhnatly.flutter_carplay.models.list.FCPListItem
import com.oguzhnatly.flutter_carplay.models.list.FCPListSection
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

        /// The context for CarPlay.
        var carContext: CarContext? = null

        /// The root template to be displayed on CarPlay.
        var fcpRootTemplate: FCPRootTemplate? = null

//        /// The root view controller for CarPlay.
//        var rootViewController: UIViewController? = null

        /// The root template for CarPlay.
        var rootTemplate: CPTemplate? = null

        /// The present template object for CarPlay modals.
        var fcpPresentTemplate: FCPPresentTemplate? = null

        // The Template history for CarPlay.
        var fcpTemplateHistory: List<Screen> = emptyList()
            private set
            get() = AndroidAutoService.session?.screenManager?.screenStack?.toList() ?: emptyList()
    }

    /// The stream handler for CarPlay communication.
    private var streamHandler: FCPStreamHandlerPlugin? = null

    /// The Flutter plugin registrar.
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    /**
     * Attaches the plugin to the Flutter engine.
     *
     * @param flutterPluginBinding the Flutter plugin binding
     */
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Logger.log("onAttachedToEngine")
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, makeFCPChannelId(""))
        channel.setMethodCallHandler(this)
        this.flutterPluginBinding = flutterPluginBinding
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
                val rootTemplate = createRootTemplate(args = args, runtimeType = runtimeType)
                if (rootTemplate == null) {
                    result.success(false)
                    return
                }

                setRootTemplate(rootTemplate = rootTemplate, result = result)
            }

            FCPChannelTypes.forceUpdateRootTemplate.name -> {
                AndroidAutoService.session?.forceUpdateRootTemplate(result)
            }

            FCPChannelTypes.popTemplate.name -> {
                val args = call.arguments as? Map<String, Any>
                val count = args?.get("count") as? Int
                if (args == null || count == null) {
                    result.success(false)
                    return
                }

                List(count) {
                    AndroidAutoService.session?.pop()
                }

                result.success(true)
            }

            FCPChannelTypes.closePresent.name -> {
                fcpPresentTemplate = null
                AndroidAutoService.session?.closePresent(result)
            }

            FCPChannelTypes.pushTemplate.name -> {
                val args = call.arguments as? Map<String, Any>
                if (args == null) {
                    result.success(false)
                    return
                }
                pushTemplate(args = args, result = result)
            }

            FCPChannelTypes.popToRootTemplate.name -> {
                fcpPresentTemplate = null
                AndroidAutoService.session?.popToRootTemplate(result)
            }

            FCPChannelTypes.updateListTemplate.name -> {
                val args = call.arguments as? Map<String, Any>
                val elementId = args?.get("_elementId") as? String
                val sections = args?.get("sections") as? List<Map<String, Any>>
                if (args == null || elementId == null || (sections?.isEmpty() != false)) {
                    result.success(false)
                    return
                }

                updateListTemplate(elementId = elementId, sections = sections, args = args)
                result.success(true)
            }

            FCPChannelTypes.updateListItem.name -> {

                val args = call.arguments as? Map<String, Any>
                val elementId = args?.get("_elementId") as? String
                if (args == null || elementId == null) {
                    result.success(false)
                    return
                }
                updateListItem(elementId = elementId, args = args)
                result.success(true)
            }

            FCPChannelTypes.onFCPListItemSelectedComplete.name -> {}

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
private fun FlutterCarplayPlugin.Companion.createRootTemplate(
    args: Map<String, Any>, runtimeType: String
): FCPRootTemplate? {
    // Ensure that the rootTemplateArgs key exists in the args map
    val rootTemplateArgs = args["rootTemplate"] as? Map<String, Any> ?: return null

    // Create an FCPRootTemplate based on the provided runtime type
    return when (runtimeType) {
//        FCPTabBarTemplate::class.java.simpleName -> FCPTabBarTemplate(rootTemplateArgs)
//        FCPGridTemplate::class.java.simpleName -> FCPGridTemplate(rootTemplateArgs)
//        FCPInformationTemplate::class.java.simpleName -> FCPInformationTemplate(rootTemplateArgs)
//        FCPPointOfInterestTemplate::class.java.simpleName -> FCPPointOfInterestTemplate(rootTemplateArgs)
//        FCPMapTemplate::class.java.simpleName -> {
//            val mapTemplate = FCPMapTemplate(rootTemplateArgs)
//            mapTemplate
//        }
//
        FCPListTemplate::class.java.simpleName -> {
            val templateType = FCPListTemplateTypes.DEFAULT
            carContext?.let {
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
private fun FlutterCarplayPlugin.Companion.setRootTemplate(
    rootTemplate: FCPRootTemplate, result: Result
) {
    val cpRootTemplate: CPTemplate

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

    // If an FCPRootTemplate is successfully extracted, set it as the root template
    FlutterCarplayPlugin.rootTemplate = cpRootTemplate
    fcpRootTemplate = rootTemplate
    AndroidAutoService.session?.forceUpdateRootTemplate()

    onCarplayConnectionChange(
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
private fun FlutterCarplayPlugin.Companion.pushTemplate(
    args: Map<String, Any>, result: Result
) {
    // Extract necessary information from the provided arguments

    val runtimeType = args["runtimeType"] as? String?
    val templateArgs = args["template"] as? Map<String, Any>?
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
            carContext = carContext!!,
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
    AndroidAutoService.session?.push(pushTemplate, result)
}

/**
 * Notifies Flutter about changes in Android Auto connection status.
 *
 * @param status The Android Auto connection status.
 */
fun FlutterCarplayPlugin.Companion.onCarplayConnectionChange(status: String) {
    FCPStreamHandlerPlugin.sendEvent(
        FCPChannelTypes.onCarplayConnectionChange.name, mapOf("status" to status)
    )
}

/**
 * Updates a Android Auto list template identified by its element ID with new data.
 *
 * @param elementId The unique identifier of the list template to be updated.
 * @param sections An array of dictionaries representing the updated sections of the list template.
 * @param args Additional arguments for updating the list template.
 */
private fun FlutterCarplayPlugin.Companion.updateListTemplate(
    elementId: String,
    sections: List<Map<String, Any>>,
    args: Map<String, Any>
) {
    // Find the list template based on the provided element ID
    findListTemplate(elementId) { listTemplate ->

        // Extract and handle the data for updating the list template
        val isLoading = args["isLoading"] as? Bool
        val emptyViewTitleVariants = args["emptyViewTitleVariants"] as? List<String>
        val emptyViewSubtitleVariants = args["emptyViewSubtitleVariants"] as? List<String>

        // Map dictionary representations to FCPBarButton instances for navigation bar buttons
//        val leadingNavigationBarButtons = (args["leadingNavigationBarButtons"] as? List<Map<String,Any>>)?.map {
//            FCPBarButton(it as Map<String, Any>)
//        }
//        val trailingNavigationBarButtons = (args["trailingNavigationBarButtons"] as? List<Map<String,Any>>)?.map {
//            FCPBarButton(it as Map<String, Any>)
//        }

        // Update the list template with the extracted data
        listTemplate.update(
            isLoading = isLoading,
            emptyViewTitleVariants = emptyViewTitleVariants,
            emptyViewSubtitleVariants = emptyViewSubtitleVariants,
            sections = sections.map { FCPListSection(it) },
//        leadingNavigationBarButtons = leadingNavigationBarButtons,
//        trailingNavigationBarButtons = trailingNavigationBarButtons
        )
    }
}


/**
 * Updates a CarPlay list item identified by its element ID with new data.
 *
 * @param elementId The unique identifier of the list item to be updated.
 * @param args Additional arguments for updating the list item.
 */
private fun FlutterCarplayPlugin.Companion.updateListItem(
    elementId: String,
    args: Map<String, Any>
) {
    // Find the list item based on the provided element ID
    findListItem(elementId) { item ->

        // Update the list item with the extracted data
        item.update(
            text = args["text"] as? String,
            detailText = args["detailText"] as? String,
            image = args["image"] as? String,
            darkImage = args["darkImage"] as? String,
            playbackProgress = args["playbackProgress"] as? CGFloat,
            isPlaying = args["isPlaying"] as? Bool,
            isEnabled = args["isEnabled"] as? Bool,
            playingIndicatorLocation = args["playingIndicatorLocation"] as? String,
            accessoryType = args["accessoryType"] as? String,
            accessoryImage = args["accessoryImage"] as? String,
            accessoryDarkImage = args["accessoryDarkImage"] as? String
        )
    }

}

/**
 * Finds a CarPlay list template by element ID and performs an action when found.
 *
 * @param elementId The element ID of the list template.
 * @param actionWhenFound The action to perform when the list template is found.
 */
private fun FlutterCarplayPlugin.Companion.findListTemplate(
    elementId: String,
    actionWhenFound: (listTemplate: FCPListTemplate) -> Unit
) {
    // Get the array of FCPListTemplate instances.
    val templates = getFCPListTemplatesFromHistory()

    // Iterate through the templates to find the one with the matching element ID.
    for (template in templates) {
        if (template.elementId == elementId) {
            // Perform the specified action when the template is found.
            actionWhenFound(template)
            break
        }
    }
}

/**
 * Finds a CarPlay list item by element ID and performs an action when found.
 *
 * @param elementId The element ID of the list item.
 * @param actionWhenFound The action to perform when the list item is found.
 */
private fun FlutterCarplayPlugin.Companion.findListItem(
    elementId: String,
    actionWhenFound: (item: FCPListItem) -> Unit
) {
    // Get the array of FCPListTemplate instances.
    val templates = getFCPListTemplatesFromHistory()

    // Iterate through the templates, sections, and items to find the one with the matching element ID.
    for (template in templates) {
        for (section in template.getSections()) {
            for (item in section.getItems()) {
                if (item.elementId == elementId) {
                    // Perform the specified action when the item is found.
                    actionWhenFound(item)
                    return
                }
            }
        }
    }
}

/**
 * Finds a CarPlay list templates from history.
 *
 * @return An array of FCPListTemplate instances.
 */
private fun FlutterCarplayPlugin.Companion.getFCPListTemplatesFromHistory(): List<FCPListTemplate> {
    // Initialize an array to store FCPListTemplate instances.
    val templates: MutableList<FCPListTemplate> = mutableListOf()

    // Filter the template history to include only FCPListTemplate instances.
    for (template in fcpTemplateHistory) {
        if (template is FCPListTemplate) {
            templates.add(template)
        }
//        else if (template is CPTabBarTemplate) {
//            templates.addAll(template.getTemplates())
//        }
    }

    return templates
}
