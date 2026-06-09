package com.oguzhnatly.flutter_android_auto

import androidx.car.app.CarContext
import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.CarText
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.LongMessageTemplate
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
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
        private val templatesByElementId = mutableMapOf<String, Template>()
        private val screensByElementId = mutableMapOf<String, Screen>()

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

                    FAAChannelTypes.updatePaneTemplate.name -> updatePaneTemplate(
                        call, result
                    )

                    FAAChannelTypes.updateMessageTemplate.name -> updateMessageTemplate(
                        call, result
                    )

                    FAAChannelTypes.updateLongMessageTemplate.name -> updateLongMessageTemplate(
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

                "FAAPaneTemplate" -> getPaneTemplate(data)

                "FAAMessageTemplate" -> getMessageTemplate(data)

                "FAALongMessageTemplate" -> getLongMessageTemplate(data)

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
                        } ?: templatesByElementId[elementId]
                        ?: template

                    init {
                        lifecycle.addObserver(object : LifecycleEventObserver {
                            override fun onStateChanged(
                                source: LifecycleOwner, event: Lifecycle.Event
                            ) {
                                when (event) {
                                    Lifecycle.Event.ON_DESTROY -> {
                                        listTemplateData.remove(elementId)
                                        listTemplateBackButtons.remove(elementId)
                                        listTemplateScreens.remove(elementId)
                                        templatesByElementId.remove(elementId)
                                        screensByElementId.remove(elementId)
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

                if (runtimeType == "FAAListTemplate") {
                    listTemplateData[elementId] = data.toMutableMap()
                    listTemplateBackButtons[elementId] = true
                    listTemplateScreens[elementId] = newScreen
                }
                templatesByElementId[elementId] = template
                screensByElementId[elementId] = newScreen

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

                "FAAPaneTemplate" -> getPaneTemplate(data, false)

                "FAAMessageTemplate" -> getMessageTemplate(data, false)

                "FAALongMessageTemplate" -> getLongMessageTemplate(data, false)

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
                templatesByElementId[elementId] = template
                currentScreen?.let { screensByElementId[elementId] = it }
                if (runtimeType == "FAAListTemplate") {
                    listTemplateData[elementId] = data.toMutableMap()
                    listTemplateBackButtons[elementId] = false
                    currentScreen?.let { listTemplateScreens[elementId] = it }
                }
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
            val isRootTemplate = currentRootTemplateElementId == elementId
            val template = getPaneTemplate(data, !isRootTemplate)
            templatesByElementId[elementId] = template

            if (isRootTemplate) {
                currentTemplate = template
                currentScreen?.let {
                    screensByElementId[elementId] = it
                    it.invalidate()
                }
                result.success(true)
                return@launch
            }

            val screen = screensByElementId[elementId]
            if (screen == null) {
                result.error(
                    "No screen found",
                    "No Android Auto screen found for pane template id: $elementId",
                    null,
                )
                return@launch
            }

            screen.invalidate()
            result.success(true)
        }
    }

    private fun updateMessageTemplate(
        call: MethodCall, result: MethodChannel.Result
    ) {
        updateMessageTemplate(
            call,
            result,
            "message",
            ::getMessageTemplate,
        )
    }

    private fun updateLongMessageTemplate(
        call: MethodCall, result: MethodChannel.Result
    ) {
        updateMessageTemplate(
            call,
            result,
            "long message",
            ::getLongMessageTemplate,
        )
    }

    private fun updateMessageTemplate(
        call: MethodCall,
        result: MethodChannel.Result,
        templateType: String,
        buildTemplate: (Map<String, Any?>, Boolean) -> Template,
    ) {
        val templateElementId = call.argument<String>("elementId") ?: ""
        if (templateElementId.isEmpty()) {
            result.error(
                "Missing elementId",
                "elementId is required to update a $templateType template",
                null,
            )
            return
        }

        val title = call.argument<String>("title") ?: ""
        val message = call.argument<String>("message") ?: ""
        val isRootTemplate = templateElementId == currentRootTemplateElementId
        val updatedTemplate = buildTemplate(
            mapOf(
                "_elementId" to templateElementId,
                "title" to title,
                "message" to message,
            ),
            !isRootTemplate,
        )

        templatesByElementId[templateElementId] = updatedTemplate
        if (isRootTemplate) {
            currentTemplate = updatedTemplate
            currentScreen?.let {
                screensByElementId[templateElementId] = it
                it.invalidate()
            }
            result.success(true)
            return
        }

        val screen = screensByElementId[templateElementId]
        if (screen == null) {
            result.error(
                "No screen found",
                "No Android Auto screen found for template id: $templateElementId",
                null,
            )
            return
        }

        screen.invalidate()
        result.success(true)
    }

    private fun getMessageTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean = true,
    ): Template = buildMessageTemplate(
        data,
        addBackButton,
        createBuilder = { MessageTemplate.Builder(it) },
        setTitle = { title -> setTitle(title) },
        setHeaderAction = { action -> setHeaderAction(action) },
        build = { build() },
    )

    private fun getLongMessageTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean = true,
    ): Template = buildMessageTemplate(
        data,
        addBackButton,
        createBuilder = { LongMessageTemplate.Builder(it) },
        setTitle = { title -> setTitle(title) },
        setHeaderAction = { action -> setHeaderAction(action) },
        build = { build() },
    )

    private fun <Builder> buildMessageTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean,
        createBuilder: (String) -> Builder,
        setTitle: Builder.(String) -> Unit,
        setHeaderAction: Builder.(Action) -> Unit,
        build: Builder.() -> Template,
    ): Template {
        val template = FAAMessageTemplate.fromJson(data)
        val builder = createBuilder(template.message)
        builder.setTitle(template.title)

        if (addBackButton) {
            builder.setHeaderAction(Action.BACK)
        }

        return builder.build()
    }

    private suspend fun getPaneTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean = true,
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
                ?: if (carContext != null && template.imageUrl != null) {
                    resolveCarIcon(carContext, null, template.imageUrl, template.imageTint)
                } else {
                    null
                }
            if (imageIcon != null) {
                paneBuilder.setImage(imageIcon)
            }

            for (action in template.actions) {
                paneBuilder.addAction(createPaneAction(carContext, action))
            }
        }

        val paneTemplateBuilder =
            PaneTemplate.Builder(paneBuilder.build()).setTitle(template.title)

        if (addBackButton) {
            paneTemplateBuilder.setHeaderAction(Action.BACK)
        }

        return paneTemplateBuilder.build()
    }

    private suspend fun createPaneRowFromItem(
        carContext: CarContext?,
        item: FAAPaneItem,
    ): Row {
        val rowBuilder = Row.Builder().setTitle(CarText.create(item.title))

        item.detail?.let { rowBuilder.addText(CarText.create(it)) }

        val imageIcon = makeCarIconFromBytes(item.imageData, item.imageTint)
            ?: if (carContext != null && item.imageUrl != null) {
                resolveCarIcon(carContext, null, item.imageUrl, item.imageTint)
            } else {
                null
            }
        if (imageIcon != null) {
            rowBuilder.setImage(
                imageIcon,
                if (item.imageTint != null) Row.IMAGE_TYPE_ICON else Row.IMAGE_TYPE_SMALL,
            )
        }

        return rowBuilder.build()
    }

    private suspend fun createPaneAction(
        carContext: CarContext?,
        action: FAAPaneAction,
    ): Action {
        val actionBuilder = Action.Builder().setTitle(action.title)

        val imageIcon = makeCarIconFromBytes(action.imageData, action.imageTint)
            ?: if (carContext != null && action.imageUrl != null) {
                resolveCarIcon(carContext, null, action.imageUrl, action.imageTint)
            } else {
                null
            }
        if (imageIcon != null) {
            actionBuilder.setIcon(imageIcon)
        }

        if (action.isPrimary) {
            actionBuilder.setFlags(Action.FLAG_PRIMARY)
        }

        if (action.isOnPressListenerActive) {
            actionBuilder.setOnClickListener {
                sendEvent(
                    type = FAAChannelTypes.onPaneActionPressed.name,
                    data = mapOf("elementId" to action.elementId),
                )
            }
        }

        return actionBuilder.build()
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
