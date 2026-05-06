package com.oguzhnatly.flutter_android_auto

import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.core.graphics.drawable.IconCompat
import androidx.car.app.model.CarText
import androidx.car.app.model.GridItem
import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.SectionedItemList
import androidx.car.app.model.Row
import androidx.car.app.model.Tab
import androidx.car.app.model.TabContents
import androidx.car.app.model.TabTemplate
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
import kotlinx.coroutines.delay
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
        var currentTabBarData: FAATabBarTemplate? = null
        var activeTabContentId: String? = null
        var currentAlertScreen: Screen? = null
        // Pushed screens: each screen owns a mutable template slot so we can
        // swap it to loading and back without recreating the screen.
        val pushedScreenTemplates: MutableMap<Screen, Template> = mutableMapOf()

        // Tracks which screen/template is being processed by a list-item tap so
        // onListItemSelectedComplete knows what to rebuild.
        var pendingScreen: Screen? = null          // null = root screen
        var pendingRawData: Map<String, Any?>? = null
        var pendingRawType: String? = null
        var pendingAddBackButton: Boolean = false

        private const val HANDLER_TIMEOUT_MS = 15_000L

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
                    FAAChannelTypes.setRootTemplate.name        -> setRootTemplate(call, result)
                    FAAChannelTypes.pushTemplate.name           -> pushTemplate(call, result)
                    FAAChannelTypes.popTemplate.name            -> popTemplate(call, result)
                    FAAChannelTypes.popToRootTemplate.name      -> popToRootTemplate(call, result)
                    FAAChannelTypes.onListItemSelectedComplete.name -> onListItemSelectedComplete(call, result)
                    FAAChannelTypes.onGridButtonSelectedComplete.name -> onGridButtonSelectedComplete(call, result)
                    FAAChannelTypes.setAlert.name               -> setAlert(call, result)
                    FAAChannelTypes.closePresent.name           -> closePresent(call, result)
                    FAAChannelTypes.updateTabBarTemplates.name  -> updateTabBarTemplates(call, result)
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
        val carContext = AndroidAutoService.session?.carContext ?: return
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        if (screenManager.stackSize > 1) {
            screenManager.pop()
            result.success(true)
        } else {
            result.error("No screens to pop", "You are at root screen", null)
        }
    }

    private fun popToRootTemplate(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext ?: return
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        if (screenManager.stackSize > 1) {
            screenManager.popToRoot()
            result.success(true)
        } else {
            result.error("No screens to pop", "You are at root screen", null)
        }
    }


    private fun showLoadingForScreen(
        screen: Screen?,
        rawData: Map<String, Any?>,
        rawType: String,
        addBackButton: Boolean,
        loadingMessage: String? = null,
        timeoutMs: Long? = null,
    ) {
        pendingScreen = screen
        pendingRawData = rawData
        pendingRawType = rawType
        pendingAddBackButton = addBackButton

        val loading: Template = if (rawType == "FAAGridTemplate") {
            GridTemplate.Builder().setLoading(true)
                .apply { if (!loadingMessage.isNullOrBlank()) setTitle(loadingMessage) }
                .build()
        } else {
            ListTemplate.Builder().setLoading(true)
                .apply { if (!loadingMessage.isNullOrBlank()) setTitle(loadingMessage) }
                .build()
        }

        if (screen == null || screen == currentScreen) {
            currentTemplate = loading
            currentScreen?.invalidate()
        } else {
            pushedScreenTemplates[screen] = loading
            screen.invalidate()
        }

        if (timeoutMs != null) {
            pluginScope.launch {
                delay(timeoutMs)
                if (pendingRawData === rawData) {
                    rebuildPendingTemplate()
                }
            }
        }
    }

    private fun rebuildPendingTemplate() {
        val screen  = pendingScreen
        val data    = pendingRawData ?: return
        val type    = pendingRawType ?: return
        val addBack = pendingAddBackButton

        pendingScreen        = null
        pendingRawData       = null
        pendingRawType       = null
        pendingAddBackButton = false

        pluginScope.launch {
            val rebuilt: Template? = if (screen == null && currentTabBarData != null) {
                buildNativeTabTemplate(currentTabBarData!!)
            } else {
                buildTemplateForType(type, data, null, addBackButton = addBack, owningScreen = screen)
            }
            if (rebuilt != null) {
                if (screen == null || screen == currentScreen) {
                    currentTemplate = rebuilt
                    currentScreen?.invalidate()
                } else {
                    pushedScreenTemplates[screen] = rebuilt
                    screen.invalidate()
                }
            }
        }
    }

    private fun onListItemSelectedComplete(call: MethodCall, result: MethodChannel.Result) {
        val screen   = pendingScreen
        val data     = pendingRawData
        val type     = pendingRawType
        val addBack  = pendingAddBackButton

        pendingScreen       = null
        pendingRawData      = null
        pendingRawType      = null
        pendingAddBackButton = false

        if (data == null || type == null) {
            result.success(true)
            return
        }

        pluginScope.launch {
            // Special case: if the root screen is a tab bar, rebuild the whole
            // tab template (which internally rebuilds the active tab's list).
            val rebuilt: Template? = if (screen == null && currentTabBarData != null) {
                buildNativeTabTemplate(currentTabBarData!!)
            } else {
                buildTemplateForType(type, data, null, addBackButton = addBack, owningScreen = screen)
            }

            if (rebuilt != null) {
                if (screen == null || screen == currentScreen) {
                    currentTemplate = rebuilt
                    currentScreen?.invalidate()
                } else {
                    pushedScreenTemplates[screen] = rebuilt
                    screen.invalidate()
                }
            }
            result.success(true)
        }
    }

    private fun onGridButtonSelectedComplete(call: MethodCall, result: MethodChannel.Result) {
        val screen  = pendingScreen
        val data    = pendingRawData
        val type    = pendingRawType
        val addBack = pendingAddBackButton

        pendingScreen        = null
        pendingRawData       = null
        pendingRawType       = null
        pendingAddBackButton = false

        if (data == null || type == null) {
            result.success(true)
            return
        }

        pluginScope.launch {
            val rebuilt: Template? = if (screen == null && currentTabBarData != null) {
                buildNativeTabTemplate(currentTabBarData!!)
            } else {
                buildTemplateForType(type, data, null, addBackButton = addBack, owningScreen = screen)
            }

            if (rebuilt != null) {
                if (screen == null || screen == currentScreen) {
                    currentTemplate = rebuilt
                    currentScreen?.invalidate()
                } else {
                    pushedScreenTemplates[screen] = rebuilt
                    screen.invalidate()
                }
            }
            result.success(true)
        }
    }

    // ─── Alert ───────────────────────────────────────────────────────────────

    private fun setAlert(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext ?: run {
            result.error("No car context", "Android Auto is not connected", null)
            return
        }

        val data = call.argument<Map<String, Any?>>("template") ?: run {
            result.error("Missing template", "template argument is required", null)
            return
        }

        pluginScope.launch {
            val alertTemplate = FAAAlertTemplate.fromJson(data)
            val messageTemplate = buildMessageTemplate(alertTemplate)

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

            if (alertTemplate.hasOnPresent) {
                sendEvent(
                    type = FAAChannelTypes.onPresentStateChanged.name,
                    data = mapOf("elementId" to alertTemplate.elementId, "completed" to true)
                )
            }

            result.success(true)
        }
    }

    private fun buildMessageTemplate(alert: FAAAlertTemplate): Template {
        val body  = alert.message?.takeIf { it.isNotBlank() } ?: " "
        val title = alert.title.takeIf { it.isNotBlank() } ?: " "
        val builder = MessageTemplate.Builder(body).setTitle(title)

        for (action in alert.actions) {
            builder.addAction(
                Action.Builder()
                    .setTitle(action.title)
                    .setOnClickListener {
                        sendEvent(
                            type = FAAChannelTypes.onAlertActionPressed.name,
                            data = mapOf("elementId" to action.elementId)
                        )
                    }
                    .build()
            )
        }
        return builder.build()
    }

    private fun closePresent(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext ?: run {
            result.error("No car context", "Android Auto is not connected", null)
            return
        }
        val alertScreen = currentAlertScreen ?: run {
            result.error("No modal", "No modal template is currently presented", null)
            return
        }
        carContext.getCarService(ScreenManager::class.java).pop()
        currentAlertScreen = null
        result.success(true)
    }

    private fun updateTabBarTemplates(call: MethodCall, result: MethodChannel.Result) {
        val data = call.argument<Map<String, Any?>>("template") ?: run {
            result.error("Missing template", "template argument is required", null)
            return
        }

        pluginScope.launch {
            val tabBarTemplate = FAATabBarTemplate.fromJson(data)
            currentTabBarData = tabBarTemplate

            if (tabBarTemplate.tabs.none { it.elementId == activeTabContentId }) {
                activeTabContentId = tabBarTemplate.tabs.firstOrNull()?.elementId
            }

            currentTemplate = buildNativeTabTemplate(tabBarTemplate)
            currentScreen?.invalidate()
            result.success(true)
        }
    }

    private suspend fun buildNativeTabTemplate(tabBar: FAATabBarTemplate): Template {
        val activeId = activeTabContentId ?: tabBar.tabs.firstOrNull()?.elementId
        val activeTab = tabBar.tabs.find { it.elementId == activeId }
            ?: tabBar.tabs.firstOrNull()
            ?: return ListTemplate.Builder().setLoading(true).build()

        if (tabBar.tabs.size < 2) {
            return buildInnerTemplateForTab(activeTab, addBackButton = false)
        }

        val tabCallback = object : TabTemplate.TabCallback {
            override fun onTabSelected(tabContentId: String) {
                pluginScope.launch {
                    activeTabContentId = tabContentId
                    val latest = currentTabBarData ?: return@launch
                    currentTemplate = buildNativeTabTemplate(latest)
                    currentScreen?.invalidate()
                    sendEvent(
                        type = FAAChannelTypes.onTabBarItemSelected.name,
                        data = mapOf("elementId" to tabContentId)
                    )
                }
            }
        }

        val builder = TabTemplate.Builder(tabCallback)
        builder.setHeaderAction(Action.APP_ICON)
        builder.setActiveTabContentId(activeTab.elementId)

        for (tab in tabBar.tabs) {
            builder.addTab(
                Tab.Builder()
                    .setTitle(tab.tabTitle)
                    .setIcon(resolveTabIcon(tab))
                    .setContentId(tab.elementId)
                    .build()
            )
        }

        val innerTemplate = buildInnerTemplateForTab(activeTab, addBackButton = false)
        builder.setTabContents(TabContents.Builder(innerTemplate).build())
        return builder.build()
    }

    private suspend fun buildInnerTemplateForTab(
        tab: FAATabBarItem,
        addBackButton: Boolean = true,
    ): Template = when (tab.runtimeType) {
        "FAAListTemplate" -> getListTemplate(
            result = null,
            data = tab.templateData,
            addBackButton = addBackButton,
            owningScreen = null,    // tab items belong to the root screen
            rawType = "FAAListTemplate",
        )
        "FAAGridTemplate" -> getGridTemplate(
            result = null,
            data = tab.templateData,
            addBackButton = addBackButton,
            owningScreen = null,    // tab items belong to the root screen
            rawType = "FAAGridTemplate",
        )
        else -> ListTemplate.Builder().setLoading(true).build()
    }

    private suspend fun resolveTabIcon(tab: FAATabBarItem): CarIcon {
        tab.iconUrl?.let { url ->
            loadCarImageAsync(url)?.let { return it }
        }

        tab.systemIcon?.let { icon ->
            loadCarImageAsync(icon)?.let { return it }
        }

        return when (tab.systemIcon?.lowercase()) {
            "map", "map.fill", "location", "location.fill", "navigation", "navigation.fill",
            "location.north", "location.north.fill" -> CarIcon.PAN

            "exclamationmark", "exclamationmark.triangle",
            "exclamationmark.triangle.fill", "alert", "bell", "bell.fill" -> CarIcon.ALERT

            "pencil", "pencil.circle", "compose", "square.and.pencil",
            "message", "message.fill", "bubble.left", "bubble.right" -> CarIcon.COMPOSE_MESSAGE

            "chevron.backward", "chevron.left", "arrow.backward", "back",
            "arrow.left", "arrowshape.backward", "arrowshape.backward.fill" -> CarIcon.BACK

            "xmark.circle", "xmark", "multiply", "error", "exclamationmark.circle" -> CarIcon.ERROR

            "hand.draw", "hand.point.up", "pan" -> CarIcon.PAN

            else -> CarIcon.COMPOSE_MESSAGE
        }
    }

    private fun pushTemplate(call: MethodCall, result: MethodChannel.Result) {
        val carContext = AndroidAutoService.session?.carContext ?: return

        val runtimeType = call.argument<String>("runtimeType") ?: ""
        val data        = call.argument<Map<String, Any?>>("template")!!
        val elementId   = data["_elementId"] as? String ?: ""

        pluginScope.launch {

            val newScreen = object : Screen(carContext) {
                override fun onGetTemplate(): Template =
                    pushedScreenTemplates[this]
                        ?: ListTemplate.Builder().setLoading(true).build()

                init {
                    val self = this
                    lifecycle.addObserver(object : LifecycleEventObserver {
                        override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
                            if (event == Lifecycle.Event.ON_DESTROY) {
                                pushedScreenTemplates.remove(self)
                                sendEvent(
                                    type = FAAChannelTypes.onScreenBackButtonPressed.name,
                                    data = mapOf("elementId" to elementId)
                                )
                            }
                        }
                    })
                }
            }

            val template = buildTemplateForType(
                runtimeType, data, result,
                addBackButton = true,
                owningScreen = newScreen,
            ) ?: return@launch

            pushedScreenTemplates[newScreen] = template
            carContext.getCarService(ScreenManager::class.java).push(newScreen)
            result.success(true)
        }
    }

    private fun setRootTemplate(call: MethodCall, result: MethodChannel.Result) {
        val runtimeType = call.argument<String>("runtimeType") ?: ""
        val data        = call.argument<Map<String, Any?>>("template")!!

        pluginScope.launch {
            when (runtimeType) {
                "FAATabBarTemplate" -> {
                    val tabBarTemplate = FAATabBarTemplate.fromJson(data)
                    currentTabBarData = tabBarTemplate
                    activeTabContentId = tabBarTemplate.tabs.firstOrNull()?.elementId
                    currentTemplate = buildNativeTabTemplate(tabBarTemplate)
                }
                else -> {
                    currentTabBarData  = null
                    activeTabContentId = null
                    val template = buildTemplateForType(runtimeType, data, result, addBackButton = false)
                        ?: return@launch
                    currentTemplate = template
                }
            }

            currentScreen?.invalidate()
            result.success(true)
        }
    }

    private suspend fun buildTemplateForType(
        runtimeType: String,
        data: Map<String, Any?>,
        result: MethodChannel.Result?,
        addBackButton: Boolean = true,
        owningScreen: Screen? = null,
    ): Template? = when (runtimeType) {
        "FAAListTemplate" -> getListTemplate(
            result = result,
            data = data,
            addBackButton = addBackButton,
            owningScreen = owningScreen,
            rawType = runtimeType,
        )
        "FAAGridTemplate" -> getGridTemplate(
            result = result,
            data = data,
            addBackButton = addBackButton,
            owningScreen = owningScreen,
            rawType = runtimeType,
        )
        "FAATabBarTemplate" -> {
            val tabBarTemplate = FAATabBarTemplate.fromJson(data)
            currentTabBarData = tabBarTemplate
            if (activeTabContentId == null ||
                tabBarTemplate.tabs.none { it.elementId == activeTabContentId }
            ) {
                activeTabContentId = tabBarTemplate.tabs.firstOrNull()?.elementId
            }
            buildNativeTabTemplate(tabBarTemplate)
        }
        else -> {
            result?.error("Unsupported template type", "Template type: $runtimeType is not supported", null)
            null
        }
    }


    private suspend fun getListTemplate(
        result: MethodChannel.Result?,
        data: Map<String, Any?>,
        addBackButton: Boolean = true,
        owningScreen: Screen? = null,
        rawType: String = "FAAListTemplate",
    ): Template {
        val template = FAAListTemplate.fromJson(data)
        val builder  = ListTemplate.Builder().setTitle(template.title)

        val emptyMessage = template.emptyViewTitleVariants.firstOrNull()
        val isEmpty      = template.sections.isEmpty() || template.sections.all { it.items.isEmpty() }

        if (isEmpty) {
            if (emptyMessage != null) {
                builder.setLoading(false)
                builder.setSingleList(ItemList.Builder().setNoItemsMessage(emptyMessage).build())
            } else {
                builder.setLoading(true)
            }
        } else {
            builder.setLoading(false)
            val isSingleList = template.sections.size == 1 && template.sections.first().title.isNullOrEmpty()

            if (isSingleList) {
                val itemListBuilder = ItemList.Builder()
                for (item in template.sections.first().items) {
                    itemListBuilder.addItem(
                        createRowFromItem(item, owningScreen, data, rawType, addBackButton)
                    )
                }
                builder.setSingleList(itemListBuilder.build())
            } else {
                for (section in template.sections) {
                    val itemListBuilder = ItemList.Builder()
                    for (item in section.items) {
                        itemListBuilder.addItem(
                            createRowFromItem(item, owningScreen, data, rawType, addBackButton)
                        )
                    }
                    builder.addSectionedList(
                        SectionedItemList.create(itemListBuilder.build(), section.title ?: "")
                    )
                }
            }
        }

        if (addBackButton) builder.setHeaderAction(Action.BACK)
        return builder.build()
    }

    /**
     * Builds a [Row] for a single list item.
     *
     * When the row is tapped, the owning screen enters loading state and the
     * raw data required to rebuild it is stored for [onListItemSelectedComplete].
     */
    private suspend fun createRowFromItem(
        item: FAAListItem,
        owningScreen: Screen?,
        rawData: Map<String, Any?>,
        rawType: String,
        addBackButton: Boolean,
    ): Row {
        val rowBuilder = Row.Builder().setTitle(CarText.create(item.title))

        item.subtitle?.let { rowBuilder.addText(CarText.create(it)) }

        item.image?.let {
            loadCarImageAsync(it)?.let { carIcon -> rowBuilder.setImage(carIcon) }
        }

        if (item.isOnPressListenerActive) {
            rowBuilder.setOnClickListener {
                if (events == null) return@setOnClickListener
                showLoadingForScreen(
                    owningScreen, rawData, rawType, addBackButton,
                    item.loadingMessage,
                    item.onPressTimeoutMs,
                )
                sendEvent(
                    type = FAAChannelTypes.onListItemSelected.name,
                    data = mapOf("elementId" to item.elementId)
                )
            }
        }
        return rowBuilder.build()
    }


    // ─── Grid ────────────────────────────────────────────────────────────────

    private suspend fun getGridTemplate(
        result: MethodChannel.Result?,
        data: Map<String, Any?>,
        addBackButton: Boolean = true,
        owningScreen: Screen? = null,
        rawType: String = "FAAGridTemplate",
    ): Template {
        val template = FAAGridTemplate.fromJson(data)
        val builder  = GridTemplate.Builder().setTitle(template.title)

        val emptyMessage = template.emptyViewTitleVariants.firstOrNull()
        val isEmpty      = template.buttons.isEmpty()

        if (isEmpty) {
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
                    createGridItemFromButton(button, owningScreen, data, rawType, addBackButton)
                )
            }
            builder.setSingleList(itemListBuilder.build())
        }

        if (addBackButton) builder.setHeaderAction(Action.BACK)
        return builder.build()
    }

    /**
     * Builds a [GridItem] for a single grid button.
     *
     * The image is loaded asynchronously from [FAAGridButton.imageUrl]. When no
     * URL is provided, or the load fails, [CarIcon.COMPOSE_MESSAGE] is used as a
     * safe fallback so that [GridItem.Builder.build] never throws a missing-image
     * exception.
     *
     * Tapping the item exibe imediatamente o loading na tela (via [showLoadingForScreen])
     * e dispara [FAAChannelTypes.onGridButtonPressed] para o Dart. O Dart deve
     * chamar [onGridButtonSelectedComplete] para encerrar o loading.
     */
    private suspend fun createGridItemFromButton(
        button: FAAGridButton,
        owningScreen: Screen?,
        rawData: Map<String, Any?>,
        rawType: String,
        addBackButton: Boolean,
    ): GridItem {
        val itemBuilder = GridItem.Builder().setTitle(button.title)

        val carIcon: CarIcon = button.image
            ?.let { loadCarImageAsync(it) }
            ?: CarIcon.COMPOSE_MESSAGE

        itemBuilder.setImage(carIcon)

        if (button.isOnPressListenerActive) {
            itemBuilder.setOnClickListener {
                if (events == null) return@setOnClickListener
                showLoadingForScreen(
                    owningScreen, rawData, rawType, addBackButton,
                    button.loadingMessage,
                    button.onPressTimeoutMs,
                )
                sendEvent(
                    type = FAAChannelTypes.onGridButtonPressed.name,
                    data = mapOf("elementId" to button.elementId)
                )
            }
        }

        return itemBuilder.build()
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
