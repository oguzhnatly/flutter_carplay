package com.oguzhnatly.flutter_android_auto

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.ScreenManager
import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.CarIcon
import androidx.car.app.model.CarText
import androidx.car.app.model.GridItem
import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.LongMessageTemplate
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.SectionedItemList
import androidx.car.app.model.Tab
import androidx.car.app.model.TabContents
import androidx.car.app.model.TabTemplate
import androidx.car.app.model.Template
import androidx.car.app.model.Toggle
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class FlutterAndroidAutoPlugin : FlutterPlugin, EventChannel.StreamHandler {
    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    lateinit var channel: MethodChannel
    lateinit var eventChannel: EventChannel

    companion object {
        var events: EventChannel.EventSink? = null
        var currentTemplate: Template? = null
        var currentScreen: Screen? = null
        var currentAlertScreen: Screen? = null

        private var currentRootTemplateElementId: String? = null
        private var currentTabBarData: FAATabBarTemplate? = null
        private var activeTabContentId: String? = null
        private var pendingTemplateElementId: String? = null

        private val templateDataByElementId = mutableMapOf<String, MutableMap<String, Any?>>()
        private val templateRuntimeTypes = mutableMapOf<String, String>()
        private val templateBackButtons = mutableMapOf<String, Boolean>()
        private val templatesByElementId = mutableMapOf<String, Template>()
        private val screensByElementId = mutableMapOf<String, Screen>()

        fun sendEvent(type: String, data: Map<String, Any>) {
            events?.success(mapOf("type" to type, "data" to data))
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
                    FAAChannelTypes.forceUpdateRootTemplate.name -> forceUpdateRootTemplate(call, result)
                    FAAChannelTypes.setRootTemplate.name -> setRootTemplate(call, result)
                    FAAChannelTypes.pushTemplate.name -> pushTemplate(call, result)
                    FAAChannelTypes.popTemplate.name -> popTemplate(call, result)
                    FAAChannelTypes.popToRootTemplate.name -> popToRootTemplate(call, result)
                    FAAChannelTypes.updateListTemplateSections.name -> updateListTemplateSections(call, result)
                    FAAChannelTypes.updatePaneTemplate.name -> updatePaneTemplate(call, result)
                    FAAChannelTypes.updateMessageTemplate.name -> updateMessageTemplate(call, result)
                    FAAChannelTypes.updateLongMessageTemplate.name -> updateLongMessageTemplate(call, result)
                    FAAChannelTypes.onListItemSelectedComplete.name -> onListItemSelectedComplete(call, result)
                    FAAChannelTypes.onGridButtonSelectedComplete.name -> onGridButtonSelectedComplete(call, result)
                    FAAChannelTypes.setAlert.name -> setAlert(call, result)
                    FAAChannelTypes.closePresent.name -> closePresent(call, result)
                    FAAChannelTypes.updateTabBarTemplates.name -> updateTabBarTemplates(call, result)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                e.printStackTrace()
                result.error("Error: $e", null, null)
            }
        }
        eventChannel.setStreamHandler(this)
    }

    private fun forceUpdateRootTemplate(call: MethodCall, result: MethodChannel.Result) {
        currentScreen?.let {
            it.invalidate()
            result.success(true)
        } ?: result.error("No screen found", "You must set a RootTemplate first", null)
    }

    private fun popTemplate(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) {
            result.error("No car context", "Android Auto is not connected", null)
            return
        }

        val screenManager = carContext.getCarService(ScreenManager::class.java)
        if (screenManager.stackSize > 1) {
            screenManager.pop()
            result.success(true)
        } else {
            result.error("No screens to pop", "You are at root screen", null)
        }
    }

    private fun popToRootTemplate(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) {
            result.error("No car context", "Android Auto is not connected", null)
            return
        }

        val screenManager = carContext.getCarService(ScreenManager::class.java)
        if (screenManager.stackSize > 1) {
            screenManager.popToRoot()
            result.success(true)
        } else {
            result.error("No screens to pop", "You are at root screen", null)
        }
    }

    private fun onListItemSelectedComplete(call: MethodCall, result: MethodChannel.Result) {
        rebuildPendingTemplate(result)
    }

    private fun onGridButtonSelectedComplete(call: MethodCall, result: MethodChannel.Result) {
        rebuildPendingTemplate(result)
    }

    private fun rebuildPendingTemplate(result: MethodChannel.Result) {
        val elementId = pendingTemplateElementId
        pendingTemplateElementId = null
        if (elementId == null) {
            result.success(true)
            return
        }
        rebuildElementTemplate(elementId, result)
    }

    private fun setAlert(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) {
            result.error("No car context", "Android Auto is not connected", null)
            return
        }

        val data = call.argument<Map<String, Any?>>("template")
        if (data == null) {
            result.error("Missing template", "template argument is required", null)
            return
        }

        pluginScope.launch {
            val alertTemplate = FAAAlertTemplate.fromJson(data)
            val messageTemplate = buildAlertMessageTemplate(alertTemplate)

            val alertScreen = object : Screen(carContext) {
                override fun onGetTemplate(): Template = messageTemplate

                init {
                    lifecycle.addObserver(object : LifecycleEventObserver {
                        override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
                            if (event == Lifecycle.Event.ON_DESTROY) {
                                currentAlertScreen = null
                                sendEvent(
                                    type = FAAChannelTypes.onPresentStateChanged.name,
                                    data = mapOf(
                                        "elementId" to alertTemplate.elementId,
                                        "completed" to false,
                                    )
                                )
                            }
                        }
                    })
                }
            }

            currentAlertScreen = alertScreen
            carContext.getCarService(ScreenManager::class.java).push(alertScreen)
            result.success(true)
        }
    }

    private fun buildAlertMessageTemplate(alert: FAAAlertTemplate): Template {
        val body = alert.message?.takeIf { it.isNotBlank() } ?: " "
        val title = alert.title.takeIf { it.isNotBlank() } ?: " "
        val builder = MessageTemplate.Builder(body).setTitle(title)

        for (action in alert.actions) {
            val actionBuilder = Action.Builder()
                .setTitle(action.title)
                .setOnClickListener {
                    sendEvent(
                        type = FAAChannelTypes.onAlertActionPressed.name,
                        data = mapOf("elementId" to action.elementId)
                    )
                }

            if (action.style == "destructive") {
                actionBuilder.setBackgroundColor(CarColor.RED)
            }

            builder.addAction(actionBuilder.build())
        }
        return builder.build()
    }

    private fun closePresent(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) {
            result.error("No car context", "Android Auto is not connected", null)
            return
        }
        val alertScreen = currentAlertScreen
        if (alertScreen == null) {
            result.error("No modal", "No modal template is currently presented", null)
            return
        }
        carContext.getCarService(ScreenManager::class.java).pop()
        currentAlertScreen = null
        result.success(true)
    }

    private fun updateTabBarTemplates(call: MethodCall, result: MethodChannel.Result) {
        val data = call.argument<Map<String, Any?>>("template")
        if (data == null) {
            result.error("Missing template", "template argument is required", null)
            return
        }

        pluginScope.launch {
            val tabBarTemplate = FAATabBarTemplate.fromJson(data)
            currentTabBarData = tabBarTemplate
            storeTemplateData(tabBarTemplate.elementId, "FAATabBarTemplate", data, false, currentScreen)
            storeTabData(tabBarTemplate)
            if (tabBarTemplate.tabs.none { it.elementId == activeTabContentId }) {
                activeTabContentId = tabBarTemplate.tabs.firstOrNull()?.elementId
            }
            currentTemplate = buildNativeTabTemplate(tabBarTemplate)
            currentScreen?.invalidate()
            result.success(true)
        }
    }

    private fun updateListTemplateSections(call: MethodCall, result: MethodChannel.Result) {
        val elementId = call.argument<String>("elementId") ?: ""
        val sections = call.argument<List<Map<String, Any?>>>("sections") ?: emptyList()
        val data = templateDataByElementId[elementId]
        if (data == null) {
            result.error("No template found", "AAListTemplate not found with elementId: $elementId", null)
            return
        }

        data["sections"] = sections
        rebuildElementTemplate(elementId, result)
    }

    private fun updatePaneTemplate(call: MethodCall, result: MethodChannel.Result) {
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

        storeTemplateData(elementId, "FAAPaneTemplate", data, templateBackButtons[elementId] ?: true, screensByElementId[elementId])
        rebuildElementTemplate(elementId, result)
    }

    private fun updateMessageTemplate(call: MethodCall, result: MethodChannel.Result) {
        updateMessageTemplate(call, result, "message", "FAAMessageTemplate")
    }

    private fun updateLongMessageTemplate(call: MethodCall, result: MethodChannel.Result) {
        updateMessageTemplate(call, result, "long message", "FAALongMessageTemplate")
    }

    private fun updateMessageTemplate(
        call: MethodCall,
        result: MethodChannel.Result,
        templateType: String,
        runtimeType: String,
    ) {
        val elementId = call.argument<String>("elementId") ?: ""
        if (elementId.isEmpty()) {
            result.error("Missing elementId", "elementId is required to update a $templateType template", null)
            return
        }

        val data = mutableMapOf<String, Any?>(
            "_elementId" to elementId,
            "title" to (call.argument<String>("title") ?: ""),
            "message" to (call.argument<String>("message") ?: ""),
        )
        storeTemplateData(elementId, runtimeType, data, templateBackButtons[elementId] ?: true, screensByElementId[elementId])
        rebuildElementTemplate(elementId, result)
    }

    private fun pushTemplate(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext
        if (carContext == null) {
            result.error("No car context", "Android Auto is not connected", null)
            return
        }

        val runtimeType = call.argument<String>("runtimeType") ?: ""
        val data = call.argument<Map<String, Any?>>("template")
        if (data == null) {
            result.error("Missing template", "template argument is required", null)
            return
        }
        val elementId = data["_elementId"] as? String ?: ""

        pluginScope.launch {
            val newScreen = object : Screen(carContext) {
                override fun onGetTemplate(): Template = templatesByElementId[elementId]
                    ?: getTemplateBlocking(runtimeType, data, true, this)

                init {
                    lifecycle.addObserver(object : LifecycleEventObserver {
                        override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
                            if (event == Lifecycle.Event.ON_DESTROY) {
                                removeTemplateData(elementId)
                                sendEvent(
                                    type = FAAChannelTypes.onScreenBackButtonPressed.name,
                                    data = mapOf("elementId" to elementId)
                                )
                            }
                        }
                    })
                }
            }

            val template = buildTemplateForType(runtimeType, data, true, newScreen, result)
            if (template == null) return@launch

            storeTemplateData(elementId, runtimeType, data, true, newScreen)
            templatesByElementId[elementId] = template
            carContext.getCarService(ScreenManager::class.java).push(newScreen)
            result.success(true)
        }
    }

    private fun setRootTemplate(call: MethodCall, result: MethodChannel.Result) {
        val runtimeType = call.argument<String>("runtimeType") ?: ""
        val data = call.argument<Map<String, Any?>>("template")
        if (data == null) {
            result.error("Missing template", "template argument is required", null)
            return
        }
        val elementId = data["_elementId"] as? String ?: ""

        pluginScope.launch {
            val template = buildTemplateForType(runtimeType, data, false, currentScreen, result)
            if (template == null) return@launch

            currentRootTemplateElementId = elementId
            currentTemplate = template
            storeTemplateData(elementId, runtimeType, data, false, currentScreen)
            templatesByElementId[elementId] = template
            currentScreen?.invalidate()
            result.success(true)
        }
    }

    private fun rebuildElementTemplate(elementId: String, result: MethodChannel.Result) {
        val runtimeType = templateRuntimeTypes[elementId]
        val data = templateDataByElementId[elementId]
        if (runtimeType == null || data == null) {
            result.error("No template found", "No Android Auto template found with elementId: $elementId", null)
            return
        }

        pluginScope.launch {
            val template = if (currentTabBarData != null && currentTabBarData!!.tabs.any { it.elementId == elementId }) {
                buildNativeTabTemplate(currentTabBarData!!)
            } else {
                buildTemplateForType(
                    runtimeType,
                    data,
                    templateBackButtons[elementId] ?: true,
                    screensByElementId[elementId],
                    result,
                )
            }
            if (template == null) return@launch

            if (currentTabBarData != null && currentTabBarData!!.tabs.any { it.elementId == elementId }) {
                currentTemplate = template
                currentScreen?.invalidate()
            } else {
                templatesByElementId[elementId] = template
                if (currentRootTemplateElementId == elementId) {
                    currentTemplate = template
                    currentScreen?.invalidate()
                } else {
                    screensByElementId[elementId]?.invalidate()
                }
            }
            result.success(true)
        }
    }

    private fun storeTemplateData(
        elementId: String,
        runtimeType: String,
        data: Map<String, Any?>,
        addBackButton: Boolean,
        screen: Screen?,
    ) {
        if (elementId.isEmpty()) return
        templateDataByElementId[elementId] = data.toMutableMap()
        templateRuntimeTypes[elementId] = runtimeType
        templateBackButtons[elementId] = addBackButton
        if (screen != null) screensByElementId[elementId] = screen
    }

    private fun removeTemplateData(elementId: String) {
        templateDataByElementId.remove(elementId)
        templateRuntimeTypes.remove(elementId)
        templateBackButtons.remove(elementId)
        templatesByElementId.remove(elementId)
        screensByElementId.remove(elementId)
    }

    private fun storeTabData(tabBar: FAATabBarTemplate) {
        for (tab in tabBar.tabs) {
            storeTemplateData(tab.elementId, tab.runtimeType, tab.templateData, false, currentScreen)
        }
    }

    private fun getTemplateBlocking(
        runtimeType: String,
        data: Map<String, Any?>,
        addBackButton: Boolean,
        owningScreen: Screen?,
    ): Template = kotlinx.coroutines.runBlocking {
        buildTemplateForType(runtimeType, data, addBackButton, owningScreen, null)
            ?: ListTemplate.Builder().setLoading(true).build()
    }

    private suspend fun buildTemplateForType(
        runtimeType: String,
        data: Map<String, Any?>,
        addBackButton: Boolean = true,
        owningScreen: Screen? = null,
        result: MethodChannel.Result? = null,
    ): Template? = when (runtimeType) {
        "FAAListTemplate" -> getListTemplate(data, addBackButton, owningScreen)
        "FAAGridTemplate" -> getGridTemplate(data, addBackButton, owningScreen)
        "FAATabBarTemplate" -> {
            val tabBarTemplate = FAATabBarTemplate.fromJson(data)
            currentTabBarData = tabBarTemplate
            storeTabData(tabBarTemplate)
            if (activeTabContentId == null || tabBarTemplate.tabs.none { it.elementId == activeTabContentId }) {
                activeTabContentId = tabBarTemplate.tabs.firstOrNull()?.elementId
            }
            buildNativeTabTemplate(tabBarTemplate)
        }
        "FAAPaneTemplate" -> getPaneTemplate(data, addBackButton)
        "FAAMessageTemplate" -> getMessageTemplate(data, addBackButton)
        "FAALongMessageTemplate" -> getLongMessageTemplate(data, addBackButton)
        else -> {
            result?.error("Unsupported template type", "Template type: $runtimeType is not supported", null)
            null
        }
    }

    private suspend fun buildNativeTabTemplate(tabBar: FAATabBarTemplate): Template {
        val activeId = activeTabContentId ?: tabBar.tabs.firstOrNull()?.elementId
        val activeTab = tabBar.tabs.find { it.elementId == activeId }
            ?: tabBar.tabs.firstOrNull()
            ?: return ListTemplate.Builder().setLoading(true).build()

        val carContext = AndroidAutoService.session?.carContext
        val supportsTabTemplate = carContext != null && carContext.getCarAppApiLevel() >= 6

        if (tabBar.tabs.size < 2 || !supportsTabTemplate) {
            return buildInnerTemplateForTab(activeTab, false)
        }

        val cappedTabs = tabBar.tabs.take(4)
        val resolvedActiveTab = if (cappedTabs.contains(activeTab)) activeTab else cappedTabs.first()

        val tabCallback = object : TabTemplate.TabCallback {
            override fun onTabSelected(tabContentId: String) {
                pluginScope.launch {
                    activeTabContentId = tabContentId
                    currentTabBarData?.let {
                        currentTemplate = buildNativeTabTemplate(it)
                        currentScreen?.invalidate()
                    }
                    sendEvent(
                        type = FAAChannelTypes.onTabBarItemSelected.name,
                        data = mapOf("elementId" to tabContentId)
                    )
                }
            }
        }

        val builder = TabTemplate.Builder(tabCallback)
        builder.setHeaderAction(Action.APP_ICON)
        builder.setActiveTabContentId(resolvedActiveTab.elementId)

        for (tab in cappedTabs) {
            builder.addTab(
                Tab.Builder()
                    .setTitle(resolveTabTitle(tab))
                    .setIcon(resolveTabIcon(carContext, tab))
                    .setContentId(tab.elementId)
                    .build()
            )
        }

        val innerTemplate = buildInnerTemplateForTab(resolvedActiveTab, false)
        builder.setTabContents(TabContents.Builder(innerTemplate).build())
        return builder.build()
    }

    private suspend fun buildInnerTemplateForTab(
        tab: FAATabBarItem,
        addBackButton: Boolean,
    ): Template {
        val data = templateDataByElementId[tab.elementId] ?: tab.templateData
        val runtimeType = templateRuntimeTypes[tab.elementId] ?: tab.runtimeType
        return buildTemplateForType(runtimeType, data, addBackButton, currentScreen, null)
            ?: ListTemplate.Builder().setLoading(true).build()
    }

    private fun resolveTabTitle(tab: FAATabBarItem): String {
        val data = templateDataByElementId[tab.elementId] ?: tab.templateData
        return data["tabTitle"] as? String ?: data["title"] as? String ?: tab.tabTitle
    }

    private suspend fun resolveTabIcon(carContext: CarContext?, tab: FAATabBarItem): CarIcon {
        val data = templateDataByElementId[tab.elementId] ?: tab.templateData
        val iconUrl = data["iconUrl"] as? String ?: tab.iconUrl
        if (carContext != null && !iconUrl.isNullOrBlank()) {
            resolveCarIcon(carContext, null, iconUrl)?.let { return it }
        }

        val systemIcon = data["systemIcon"] as? String ?: tab.systemIcon
        if (carContext != null && !systemIcon.isNullOrBlank()) {
            val value = systemIcon.trim()
            if (value.startsWith("http") || value.startsWith("file://") || value.contains("/") || value.contains(".")) {
                resolveCarIcon(carContext, null, value)?.let { return it }
            }
        }

        return when (systemIcon?.lowercase()) {
            "map", "map.fill", "location", "location.fill", "navigation", "navigation.fill",
            "location.north", "location.north.fill" -> CarIcon.PAN
            "exclamationmark", "exclamationmark.triangle", "exclamationmark.triangle.fill",
            "alert", "bell", "bell.fill" -> CarIcon.ALERT
            "pencil", "pencil.circle", "compose", "square.and.pencil", "message",
            "message.fill", "bubble.left", "bubble.right" -> CarIcon.COMPOSE_MESSAGE
            "chevron.backward", "chevron.left", "arrow.backward", "back", "arrow.left",
            "arrowshape.backward", "arrowshape.backward.fill" -> CarIcon.BACK
            "xmark.circle", "xmark", "multiply", "error", "exclamationmark.circle" -> CarIcon.ERROR
            "hand.draw", "hand.point.up", "pan" -> CarIcon.PAN
            else -> CarIcon.COMPOSE_MESSAGE
        }
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
        if (addBackButton) builder.setHeaderAction(Action.BACK)
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
                } else null
            if (imageIcon != null) paneBuilder.setImage(imageIcon)

            for (action in template.actions) {
                paneBuilder.addAction(createPaneAction(carContext, action))
            }
        }

        val paneTemplateBuilder = PaneTemplate.Builder(paneBuilder.build()).setTitle(template.title)
        if (addBackButton) paneTemplateBuilder.setHeaderAction(Action.BACK)
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
            } else null
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
            } else null
        if (imageIcon != null) actionBuilder.setIcon(imageIcon)
        if (action.isPrimary) actionBuilder.setFlags(Action.FLAG_PRIMARY)
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
        addBackButton: Boolean = true,
        owningScreen: Screen? = null,
    ): Template {
        val carContext = AndroidAutoService.session?.carContext
        val template = FAAListTemplate.fromJson(data)
        val builder = ListTemplate.Builder().setTitle(template.title)
        val emptyMessage = template.emptyViewTitleVariants.firstOrNull()
        val isEmpty = template.sections.isEmpty() || template.sections.all { it.items.isEmpty() }

        if (isEmpty) {
            if (emptyMessage != null) {
                builder.setLoading(false)
                builder.setSingleList(ItemList.Builder().setNoItemsMessage(emptyMessage).build())
            } else {
                builder.setLoading(true)
            }
        } else {
            builder.setLoading(false)
            val isSingleList = template.sections.size == 1 && template.sections.first().title.isEmpty()
            if (isSingleList) {
                builder.setSingleList(
                    createItemListFromSection(carContext, template.sections.first(), template.elementId, "FAAListTemplate", owningScreen)
                )
            } else {
                for (section in template.sections) {
                    builder.addSectionedList(
                        SectionedItemList.create(
                            createItemListFromSection(carContext, section, template.elementId, "FAAListTemplate", owningScreen),
                            section.title,
                        )
                    )
                }
            }
        }

        if (addBackButton) builder.setHeaderAction(Action.BACK)
        return builder.build()
    }

    private suspend fun createItemListFromSection(
        carContext: CarContext?,
        section: FAAListSection,
        templateElementId: String,
        runtimeType: String,
        owningScreen: Screen?,
    ): ItemList {
        val itemListBuilder = ItemList.Builder()
        val useSelectionListener = section.isOnSelectedListenerActive || section.selectedIndex != null

        for (item in section.items) {
            itemListBuilder.addItem(
                createRowFromItem(
                    carContext,
                    item,
                    templateElementId,
                    runtimeType,
                    owningScreen,
                    enableOnClick = !useSelectionListener,
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
                            "selectedIndex" to selectedIndex,
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

    private suspend fun createRowFromItem(
        carContext: CarContext?,
        item: FAAListItem,
        templateElementId: String,
        runtimeType: String,
        owningScreen: Screen?,
        enableOnClick: Boolean = true,
    ): Row {
        val rowBuilder = Row.Builder().setTitle(CarText.create(item.title))
        item.subtitle?.let { rowBuilder.addText(CarText.create(it)) }

        val imageIcon = makeCarIconFromBytes(item.imageData, item.imageTint)
            ?: if (carContext != null && item.imageUrl != null) {
                resolveCarIcon(carContext, null, item.imageUrl, item.imageTint)
            } else null
        if (imageIcon != null) {
            rowBuilder.setImage(
                imageIcon,
                if (item.imageTint != null) Row.IMAGE_TYPE_ICON else Row.IMAGE_TYPE_SMALL,
            )
        }

        val trailingIcon = makeCarIconFromBytes(item.trailingImageData, item.trailingImageTint)
            ?: if (carContext != null && item.trailingImage != null) {
                resolveCarIcon(carContext, null, item.trailingImage, item.trailingImageTint)
            } else null
        if (trailingIcon != null) {
            rowBuilder.addAction(Action.Builder().setIcon(trailingIcon).build())
        }

        item.isBrowsable?.let { rowBuilder.setBrowsable(it) }

        item.toggle?.let { toggle ->
            val toggleBuilder = Toggle.Builder { checked ->
                if (toggle.isOnCheckedChangeListenerActive) {
                    sendEvent(
                        type = FAAChannelTypes.onToggleCheckedChange.name,
                        data = mapOf(
                            "elementId" to item.elementId,
                            "checked" to checked,
                        )
                    )
                }
            }.setChecked(toggle.isChecked)
            toggle.isEnabled?.let { toggleBuilder.setEnabled(it) }
            rowBuilder.setToggle(toggleBuilder.build())
        }

        if (enableOnClick && item.isOnPressListenerActive) {
            rowBuilder.setOnClickListener {
                showLoadingForTemplate(templateElementId, runtimeType, item.loadingMessage)
                sendEvent(
                    type = FAAChannelTypes.onListItemSelected.name,
                    data = mapOf("elementId" to item.elementId)
                )
            }
        }
        return rowBuilder.build()
    }

    private suspend fun getGridTemplate(
        data: Map<String, Any?>,
        addBackButton: Boolean = true,
        owningScreen: Screen? = null,
    ): Template {
        val carContext = AndroidAutoService.session?.carContext
        val template = FAAGridTemplate.fromJson(data)
        val builder = GridTemplate.Builder().setTitle(template.title)
        val emptyMessage = template.emptyViewTitleVariants.firstOrNull()

        if (template.buttons.isEmpty()) {
            if (emptyMessage != null) {
                builder.setLoading(false)
                builder.setSingleList(ItemList.Builder().setNoItemsMessage(emptyMessage).build())
            } else {
                builder.setLoading(true)
            }
        } else {
            builder.setLoading(false)
            val itemListBuilder = ItemList.Builder()
            for (button in template.buttons) {
                itemListBuilder.addItem(
                    createGridItemFromButton(carContext, button, template.elementId, "FAAGridTemplate", owningScreen)
                )
            }
            builder.setSingleList(itemListBuilder.build())
        }

        if (addBackButton) builder.setHeaderAction(Action.BACK)
        return builder.build()
    }

    private suspend fun createGridItemFromButton(
        carContext: CarContext?,
        button: FAAGridButton,
        templateElementId: String,
        runtimeType: String,
        owningScreen: Screen?,
    ): GridItem {
        val itemBuilder = GridItem.Builder().setTitle(button.title)
        val carIcon = makeCarIconFromBytes(button.imageData)
            ?: if (carContext != null && button.image != null) {
                resolveCarIcon(carContext, null, button.image)
            } else null

        itemBuilder.setImage(carIcon ?: CarIcon.COMPOSE_MESSAGE)

        if (button.isOnPressListenerActive) {
            itemBuilder.setOnClickListener {
                showLoadingForTemplate(templateElementId, runtimeType, button.loadingMessage)
                sendEvent(
                    type = FAAChannelTypes.onGridButtonPressed.name,
                    data = mapOf("elementId" to button.elementId)
                )
            }
        }
        return itemBuilder.build()
    }

    private fun showLoadingForTemplate(
        templateElementId: String,
        runtimeType: String,
        loadingMessage: String? = null,
    ) {
        pendingTemplateElementId = templateElementId
        val loading = buildLoadingTemplate(runtimeType, loadingMessage, templateBackButtons[templateElementId] ?: false)

        if (currentTabBarData != null && currentTabBarData!!.tabs.any { it.elementId == templateElementId }) {
            currentTemplate = loading
            currentScreen?.invalidate()
            return
        }

        templatesByElementId[templateElementId] = loading
        if (currentRootTemplateElementId == templateElementId) {
            currentTemplate = loading
            currentScreen?.invalidate()
        } else {
            screensByElementId[templateElementId]?.invalidate()
        }
    }

    private fun buildLoadingTemplate(
        runtimeType: String,
        loadingMessage: String?,
        addBackButton: Boolean,
    ): Template {
        return if (runtimeType == "FAAGridTemplate") {
            GridTemplate.Builder()
                .setLoading(true)
                .apply {
                    if (!loadingMessage.isNullOrBlank()) setTitle(loadingMessage)
                    if (addBackButton) setHeaderAction(Action.BACK)
                }
                .build()
        } else {
            ListTemplate.Builder()
                .setLoading(true)
                .apply {
                    if (!loadingMessage.isNullOrBlank()) setTitle(loadingMessage)
                    if (addBackButton) setHeaderAction(Action.BACK)
                }
                .build()
        }
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
