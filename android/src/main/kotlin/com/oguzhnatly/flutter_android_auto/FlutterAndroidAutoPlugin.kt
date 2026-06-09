package com.oguzhnatly.flutter_android_auto

import androidx.car.app.CarContext
import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.CarText
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.SectionedItemList
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.model.Toggle
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
        var currentScreen: Screen? = null
        private var currentRootTemplateElementId: String? = null
        private val listTemplateData = mutableMapOf<String, MutableMap<String, Any?>>()
        private val listTemplateBackButtons = mutableMapOf<String, Boolean>()
        private val listTemplateScreens = mutableMapOf<String, Screen>()

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

                    FAAChannelTypes.updateListTemplateSections.name -> updateListTemplateSections(
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

    private fun updateListTemplateSections(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val elementId = call.argument<String>("elementId") ?: ""
        val sections = call.argument<List<Map<String, Any?>>>("sections") ?: emptyList()
        val data = listTemplateData[elementId]

        if (data == null) {
            result.error(
                "No template found",
                "AAListTemplate not found with elementId: $elementId",
                null
            )
            return
        }

        data["sections"] = sections
        val addBackButton = listTemplateBackButtons[elementId] ?: true

        pluginScope.launch {
            val template = getListTemplate(data, addBackButton)
            listTemplateData[elementId] = data
            if (currentRootTemplateElementId == elementId) {
                currentTemplate = template
            }
            listTemplateScreens[elementId]?.invalidate()
            currentScreen?.invalidate()
            result.success(true)
        }
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

                else -> null
            }
            if (template == null) {
                result.error(
                    "Unsupported template type",
                    "Template type: $runtimeType is not supported",
                    null
                )
            } else {
                val newScreen = object : Screen(carContext) {
                    override fun onGetTemplate(): Template =
                        listTemplateData[elementId]?.let {
                            getListTemplateBlocking(it, true)
                        } ?: template

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
                                    }

                                    else -> {}
                                }
                            }
                        })
                    }
                }

                listTemplateData[elementId] = data.toMutableMap()
                listTemplateBackButtons[elementId] = true
                listTemplateScreens[elementId] = newScreen

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

        pluginScope.launch {
            val template = when (runtimeType) {
                "FAAListTemplate" -> getListTemplate(data, false)

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
                val elementId = data["_elementId"] as? String ?: ""
                currentRootTemplateElementId = elementId
                listTemplateData[elementId] = data.toMutableMap()
                listTemplateBackButtons[elementId] = false
                currentScreen?.let { listTemplateScreens[elementId] = it }
                currentScreen?.invalidate()
                result.success(true)
            }
        }
    }

    private suspend fun getListTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean = true
    ): Template {
        return createListTemplate(data, addBackButton)
    }

    private fun getListTemplateBlocking(
        data: Map<String, Any?>,
        addBackButton: Boolean = true
    ): Template {
        return kotlinx.coroutines.runBlocking {
            createListTemplate(data, addBackButton)
        }
    }

    private suspend fun createListTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean = true
    ): Template {
        val title = data["title"] as? String ?: ""
        val sections = (data["sections"] as? List<*>)?.mapNotNull {
            (it as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                ?.let { FAAListSection.fromJson(it) }
        } ?: emptyList()
        val carContext = AndroidAutoService.session?.carContext
        val listTemplateBuilder =
            ListTemplate.Builder().setTitle(title)

        if (sections.isEmpty()) {
            listTemplateBuilder.setLoading(true)
        } else {
            listTemplateBuilder.setLoading(false)
            val isSingleList =
                sections.size == 1 && sections.first().title.isEmpty()

            if (isSingleList) {
                listTemplateBuilder.setSingleList(
                    createItemListFromSection(carContext, sections.first())
                )
            } else {
                for (section in sections) {
                    val sectionedItemList = SectionedItemList.create(
                        createItemListFromSection(carContext, section), section.title ?: ""
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

    private suspend fun createItemListFromSection(
        carContext: CarContext?,
        section: FAAListSection
    ): ItemList {
        val itemListBuilder = ItemList.Builder()
        val useSelectionListener =
            section.isOnSelectedListenerActive || section.selectedIndex != null

        for (item in section.items) {
            itemListBuilder.addItem(
                createRowFromItem(
                    carContext,
                    item,
                    enableOnClick = !useSelectionListener
                )
            )
        }

        if (useSelectionListener) {
            itemListBuilder.setOnSelectedListener { selectedIndex ->
                if (section.isOnSelectedListenerActive) {
                    sendEvent(
                        type = FAAChannelTypes.onListSectionSelected.name,
                        data = mapOf(
                            "elementId" to section.elementId,
                            "selectedIndex" to selectedIndex
                        )
                    )
                }
            }
        }

        section.selectedIndex?.let { selectedIndex ->
            if (selectedIndex >= 0 && selectedIndex < section.items.size) {
                itemListBuilder.setSelectedIndex(selectedIndex)
            }
        }

        return itemListBuilder.build()
    }

    // Helper function to create a Row from an FAAListItem, avoiding code duplication
    private suspend fun createRowFromItem(
        carContext: CarContext?,
        item: FAAListItem,
        enableOnClick: Boolean = true
    ): Row {
        val rowBuilder = Row.Builder().setTitle(CarText.create(item.title))

        item.subtitle?.let { rowBuilder.addText(CarText.create(it)) }

        val imageIcon = makeCarIconFromBytes(item.imageData, item.imageTint)
            ?: if (carContext != null && item.imageUrl != null) {
                resolveCarIcon(carContext, null, item.imageUrl, item.imageTint)
            } else {
                null
            }
        if (imageIcon != null) {
            rowBuilder.setImage(
                imageIcon,
                if (item.imageTint != null) Row.IMAGE_TYPE_ICON else Row.IMAGE_TYPE_SMALL
            )
        }

        val trailingIcon = makeCarIconFromBytes(
            item.trailingImageData,
            item.trailingImageTint
        ) ?: if (carContext != null && item.trailingImage != null) {
            resolveCarIcon(
                carContext,
                null,
                item.trailingImage,
                item.trailingImageTint
            )
        } else {
            null
        }
        if (trailingIcon != null) {
            rowBuilder.addAction(Action.Builder().setIcon(trailingIcon).build())
        }

        item.isBrowsable?.let {
            rowBuilder.setBrowsable(it)
        }

        item.toggle?.let { toggle ->
            val toggleBuilder = Toggle.Builder { checked ->
                if (toggle.isOnCheckedChangeListenerActive) {
                    sendEvent(
                        type = FAAChannelTypes.onToggleCheckedChange.name,
                        data = mapOf(
                            "elementId" to item.elementId,
                            "checked" to checked
                        )
                    )
                }
            }.setChecked(toggle.isChecked)

            toggle.isEnabled?.let { toggleBuilder.setEnabled(it) }
            rowBuilder.setToggle(toggleBuilder.build())
        }

        if (enableOnClick && item.isOnPressListenerActive) {
            rowBuilder.setOnClickListener {
                sendEvent(
                    type = FAAChannelTypes.onListItemSelected.name,
                    data = mapOf("elementId" to item.elementId)
                )
            }
        }
        return rowBuilder.build()
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
