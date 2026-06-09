package com.oguzhnatly.flutter_android_auto

import androidx.car.app.CarContext
import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.CarText
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.SectionedItemList
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.Screen
import androidx.car.app.ScreenManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner


class FlutterAndroidAutoPlugin : FlutterPlugin, EventChannel.StreamHandler {
    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    lateinit var channel: MethodChannel
    lateinit var eventChannel: EventChannel

    companion object {
        var events: EventChannel.EventSink? = null
        var currentTemplate: Template? = null
        var currentTemplateElementId: String? = null
        var currentScreen: Screen? = null
        val pushedTemplates = mutableMapOf<String, Template>()
        val pushedScreens = mutableMapOf<String, Screen>()

        fun sendEvent(type: String, data: Map<String, Any>) {
            events?.success(
                mapOf(
                    "type" to type, "data" to data
                )
            )
        }

        fun onAndroidAutoConnectionChange(status: FAAConnectionTypes) {
            sendEvent(
                type = FAAChannelTypes.onAndroidAutoConnectionChange.name,
                data = mapOf("status" to status.name)
            )
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            FAAHelpers.makeFCPChannelId("")
        )
        eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            FAAHelpers.makeFCPChannelId("/event")
        )
        setUpHandlers()
    }

    private fun setUpHandlers() {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    FAAChannelTypes.forceUpdateRootTemplate.name -> forceUpdateRootTemplate(
                        call, result
                    )

                    FAAChannelTypes.setRootTemplate.name -> setRootTemplate(
                        call, result
                    )

                    FAAChannelTypes.pushTemplate.name -> pushTemplate(
                        call, result
                    )

                    FAAChannelTypes.popTemplate.name -> popTemplate(
                        call, result

                    )

                    FAAChannelTypes.popToRootTemplate.name -> popToRootTemplate(
                        call, result
                    )

                    FAAChannelTypes.updatePaneTemplate.name -> updatePaneTemplate(
                        call, result
                    )

                    FAAChannelTypes.onListItemSelectedComplete.name

                        -> onListItemSelectedComplete(
                        call, result
                    )

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                e.printStackTrace()
                result.error("Error: $e", null, null)
            }
        }
        eventChannel.setStreamHandler(this)
    }

    private fun forceUpdateRootTemplate(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) return;

        currentScreen?.let {
            it.invalidate()
            result.success(true)
        } ?: run {
            result.error(
                "No screen found", "You must set a RootTemplate first", null
            )
        }
    }

    private fun popTemplate(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) return;

        val screenManager = carContext.getCarService(ScreenManager::class.java)
        if (screenManager.stackSize > 1) {
            screenManager.pop()
            result.success(true)
        } else {
            result.error("No screens to pop", "You are at root screen", null)
        }
    }

    private fun popToRootTemplate(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) return;

        val screenManager = carContext.getCarService(ScreenManager::class.java)
        if (screenManager.stackSize > 1) {
            screenManager.popToRoot()
            result.success(true)
        } else {
            result.error("No screens to pop", "You are at root screen", null)
        }
    }


    private fun onListItemSelectedComplete(
        call: MethodCall, result: MethodChannel.Result
    ) {
        result.success(true)
    }

    private fun pushTemplate(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) return;

        val runtimeType = call.argument<String>("runtimeType") ?: ""
        val data = call.argument<Map<String, Any?>>("template")!!
        val elementId = data["_elementId"] as? String ?: ""

        pluginScope.launch {
            val template = when (runtimeType) {
                "FAAListTemplate" -> getListTemplate(data)

                "FAAPaneTemplate" -> getPaneTemplate(data)

                else -> null
            }
            if (template == null) {
                result.error(
                    "Unsupported template type",
                    "Template type: $runtimeType is not supported",
                    null
                )
            } else {
                pushedTemplates[elementId] = template

                val newScreen = object : Screen(carContext) {
                    override fun onGetTemplate(): Template = pushedTemplates[elementId] ?: template

                    init {
                        lifecycle.addObserver(object : LifecycleEventObserver {
                            override fun onStateChanged(
                                source: LifecycleOwner, event: Lifecycle.Event
                            ) {
                                when (event) {
                                    Lifecycle.Event.ON_DESTROY -> {
                                        sendEvent(
                                            type = FAAChannelTypes.onScreenBackButtonPressed.name,
                                            data = mapOf("elementId" to elementId)
                                        )
                                        pushedTemplates.remove(elementId)
                                        pushedScreens.remove(elementId)
                                    }

                                    else -> {}
                                }
                            }
                        })
                    }
                }

                pushedScreens[elementId] = newScreen

                carContext.getCarService(ScreenManager::class.java)
                    .push(newScreen)

                result.success(true)
            }
        }
    }

    private fun setRootTemplate(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val runtimeType = call.argument<String>("runtimeType") ?: ""
        val data = call.argument<Map<String, Any?>>("template")!!
        val elementId = data["_elementId"] as? String ?: ""

        pluginScope.launch {
            val template = when (runtimeType) {
                "FAAListTemplate" -> getListTemplate(data, false)

                "FAAPaneTemplate" -> getPaneTemplate(data, false)

                else -> null
            }

            if (template == null) {
                result.error(
                    "Unsupported template type",
                    "Template type: $runtimeType is not supported",
                    null,
                )
            } else {
                currentTemplate = template
                currentTemplateElementId = elementId
                currentScreen?.invalidate()
                result.success(true)
            }
        }
    }

    private fun updatePaneTemplate(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val data = call.argument<Map<String, Any?>>("template")
        if (data == null) {
            result.error("Missing template", "A pane template payload is required", null)
            return
        }

        val elementId = data["_elementId"] as? String ?: ""
        if (elementId.isEmpty()) {
            result.error("Missing elementId", "The pane template must have an element id", null)
            return
        }

        pluginScope.launch {
            val isRootTemplate = currentTemplateElementId == elementId
            val template = getPaneTemplate(data, !isRootTemplate)

            if (isRootTemplate) {
                currentTemplate = template
                currentScreen?.invalidate()
                result.success(true)
                return@launch
            }

            val screen = pushedScreens[elementId]
            if (screen == null) {
                result.error(
                    "No screen found",
                    "No pushed pane template found for element id: $elementId",
                    null
                )
                return@launch
            }

            pushedTemplates[elementId] = template
            screen.invalidate()
            result.success(true)
        }
    }

    private suspend fun getListTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean = true
    ): Template {
        val carContext = AndroidAutoService.session?.carContext
        val template = FAAListTemplate.fromJson(data)
        val listTemplateBuilder =
            ListTemplate.Builder().setTitle(template.title)

        if (template.sections.size == 0) {
            listTemplateBuilder.setLoading(true)
        } else {
            listTemplateBuilder.setLoading(false)
            val isSingleList =
                template.sections.size == 1 && template.sections.first().title.isEmpty()

            if (isSingleList) {
                val sectionItems = template.sections.first().items
                listTemplateBuilder.setSingleList(buildItemList(carContext, sectionItems))
            } else {
                for (section in template.sections) {
                    val sectionedItemList = SectionedItemList.create(
                        buildItemList(carContext, section.items), section.title ?: ""
                    )
                    listTemplateBuilder.addSectionedList(sectionedItemList)
                }
            }
        }

        if (addBackButton) {
            listTemplateBuilder.setHeaderAction(Action.BACK)
        }

        return listTemplateBuilder.build()
    }

    private suspend fun getPaneTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean = true
    ): Template {
        val carContext = AndroidAutoService.session?.carContext
        val template = FAAPaneTemplate.fromJson(data)
        val paneBuilder = Pane.Builder()

        val isLoading = template.isLoading || template.items.isEmpty()
        paneBuilder.setLoading(isLoading)
        if (!isLoading) {
            for (item in template.items) {
                paneBuilder.addRow(createPaneRowFromItem(carContext, item))
            }

            val imageIcon = makeCarIconFromBytes(template.imageData, template.imageTint)
            if (imageIcon != null) {
                paneBuilder.setImage(imageIcon)
            } else if (carContext != null && template.imageUrl != null) {
                resolveCarIcon(carContext, null, template.imageUrl, template.imageTint)?.let { carIcon ->
                    paneBuilder.setImage(carIcon)
                }
            }

            for (action in template.actions) {
                paneBuilder.addAction(createPaneAction(carContext, action))
            }
        }

        val paneTemplateBuilder = PaneTemplate.Builder(paneBuilder.build()).setTitle(template.title)

        if (addBackButton) {
            paneTemplateBuilder.setHeaderAction(Action.BACK)
        }

        return paneTemplateBuilder.build()
    }

    private suspend fun buildItemList(carContext: CarContext?, items: List<FAAListItem>): ItemList {
        val itemListBuilder = ItemList.Builder()
        for (item in items) {
            itemListBuilder.addItem(createRowFromItem(carContext, item))
        }
        return itemListBuilder.build()
    }

    // Helper function to create a Row from an FAAListItem, avoiding code duplication
    private suspend fun createRowFromItem(carContext: CarContext?, item: FAAListItem): Row {
        val rowBuilder = Row.Builder().setTitle(CarText.create(item.title))

        item.subtitle?.let { rowBuilder.addText(CarText.create(it)) }

        val imageIcon = makeCarIconFromBytes(item.imageData, item.imageTint)
        if (imageIcon != null) {
            rowBuilder.setImage(imageIcon, if (item.imageTint != null) Row.IMAGE_TYPE_ICON else Row.IMAGE_TYPE_SMALL)
        } else if (carContext != null && item.imageUrl != null) {
            resolveCarIcon(carContext, null, item.imageUrl, item.imageTint)?.let { carIcon ->
                rowBuilder.setImage(carIcon, if (item.imageTint != null) Row.IMAGE_TYPE_ICON else Row.IMAGE_TYPE_SMALL)
            }
        }

        val trailingIcon = makeCarIconFromBytes(item.trailingImageData, item.trailingImageTint)
            ?: if (carContext != null && item.trailingImage != null) {
                resolveCarIcon(carContext, null, item.trailingImage, item.trailingImageTint)
            } else {
                null
            }
        if (trailingIcon != null) {
            rowBuilder.addAction(Action.Builder().setIcon(trailingIcon).build())
        }

        if (item.isOnPressListenerActive) {
            rowBuilder.setOnClickListener {
                sendEvent(
                    type = FAAChannelTypes.onListItemSelected.name,
                    data = mapOf("elementId" to item.elementId)
                )
            }
        }
        return rowBuilder.build()
    }

    private suspend fun createPaneRowFromItem(carContext: CarContext?, item: FAAPaneItem): Row {
        val rowBuilder = Row.Builder().setTitle(CarText.create(item.title))

        item.detail?.let { rowBuilder.addText(CarText.create(it)) }

        val imageIcon = makeCarIconFromBytes(item.imageData, item.imageTint)
        if (imageIcon != null) {
            rowBuilder.setImage(imageIcon, if (item.imageTint != null) Row.IMAGE_TYPE_ICON else Row.IMAGE_TYPE_SMALL)
        } else if (carContext != null && item.imageUrl != null) {
            resolveCarIcon(carContext, null, item.imageUrl, item.imageTint)?.let { carIcon ->
                rowBuilder.setImage(carIcon, if (item.imageTint != null) Row.IMAGE_TYPE_ICON else Row.IMAGE_TYPE_SMALL)
            }
        }

        return rowBuilder.build()
    }

    private suspend fun createPaneAction(carContext: CarContext?, action: FAAPaneAction): Action {
        val actionBuilder = Action.Builder().setTitle(action.title)

        val imageIcon = makeCarIconFromBytes(action.imageData, action.imageTint)
        if (imageIcon != null) {
            actionBuilder.setIcon(imageIcon)
        } else if (carContext != null && action.imageUrl != null) {
            resolveCarIcon(carContext, null, action.imageUrl, action.imageTint)?.let { carIcon ->
                actionBuilder.setIcon(carIcon)
            }
        }

        if (action.isPrimary) {
            actionBuilder.setFlags(Action.FLAG_PRIMARY)
        }

        if (action.isOnPressListenerActive) {
            actionBuilder.setOnClickListener {
                sendEvent(
                    type = FAAChannelTypes.onPaneActionPressed.name,
                    data = mapOf("elementId" to action.elementId)
                )
            }
        }

        return actionBuilder.build()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        FlutterAndroidAutoPlugin.events = events
    }

    override fun onCancel(arguments: Any?) {
        events?.endOfStream()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
