package com.oguzhnatly.flutter_android_auto

import android.content.Intent
import android.os.Looper
import androidx.car.app.AppManager
import androidx.car.app.Screen
import androidx.car.app.ScreenManager
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.MessageTemplate
import androidx.car.app.testing.SessionController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.FlutterException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.nio.ByteBuffer
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.doThrow
import org.mockito.Mockito.mock
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

/** Runs the real channel handler, codec, Android main dispatcher and Car App builders. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@LooperMode(LooperMode.Mode.PAUSED)
class FlutterAndroidAutoMethodChannelTest {
    private lateinit var plugin: FlutterAndroidAutoPlugin
    private lateinit var messenger: RecordingMessenger
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding
    private lateinit var carContext: TestCarContext

    @Before
    fun setUp() {
        resetTemplateState()
        carContext = TestCarContext.createCarContext(RuntimeEnvironment.getApplication())
        carContext.updateHandshakeInfo(androidx.car.app.HandshakeInfo("test.host", 8))
        val session = AndroidAutoSession()
        SessionController(session, carContext, Intent()).moveToState(Lifecycle.State.RESUMED)
        androidx.car.app.testing.ScreenController(FlutterAndroidAutoPlugin.currentScreen!!)
            .moveToState(Lifecycle.State.RESUMED)
        AndroidAutoService.session = session
        messenger = RecordingMessenger()
        binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        org.mockito.Mockito.`when`(binding.binaryMessenger).thenReturn(messenger)
        plugin = FlutterAndroidAutoPlugin()
        plugin.onAttachedToEngine(binding)
    }

    @After
    fun tearDown() {
        scope().coroutineContext[Job]?.cancel()
        idle()
        plugin.onDetachedFromEngine(binding)
        AndroidAutoService.session = null
        resetTemplateState()
    }

    @Test
    fun `setRootTemplate unsupported type returns one error on main`() {
        invoke("setRootTemplate", root("unsupported")).assertError("android_auto_error", "not supported")
    }

    @Test
    fun `setRootTemplate native construction failure returns one error on main`() {
        invoke("setRootTemplate", root(message = "")).assertError("android_auto_error")
    }

    @Test
    fun `setRootTemplate succeeds without a connected screen`() {
        AndroidAutoService.session = null
        FlutterAndroidAutoPlugin.currentScreen = null
        invoke("setRootTemplate", root()).assertSuccess()
        assertTrue(FlutterAndroidAutoPlugin.currentTemplate is MessageTemplate)
    }

    @Test
    fun `pushTemplate succeeds using the native screen manager`() {
        invoke("pushTemplate", root()).assertSuccess()
        assertEquals(2, carContext.getCarService(ScreenManager::class.java).stackSize)
    }

    @Test
    fun `pushTemplate unsupported type returns one error on main`() {
        invoke("pushTemplate", root("unsupported")).assertError("android_auto_error", "not supported")
    }

    @Test
    fun `pushTemplate navigation failure returns one error on main`() {
        failNavigation()
        invoke("pushTemplate", root()).assertError("android_auto_error", "Navigation failed")
    }

    @Test
    fun `setAlert succeeds using the native screen manager`() {
        invoke("setAlert", alert()).assertSuccess()
        assertNotNull(FlutterAndroidAutoPlugin.currentAlertScreen)
        assertEquals(2, carContext.getCarService(ScreenManager::class.java).stackSize)
    }

    @Test
    fun `setAlert native action limit failure returns one error on main`() {
        val template = (alert()["template"] as Map<String, Any?>).toMutableMap()
        template["actions"] = (1..3).map { mapOf("_elementId" to "action-$it", "title" to "Action $it") }
        invoke("setAlert", mapOf("template" to template)).assertError("android_auto_error")
    }

    @Test
    fun `setAlert navigation failure returns one error on main`() {
        failNavigation()
        invoke("setAlert", alert()).assertError("android_auto_error", "Navigation failed")
    }

    @Test
    fun `updateTabBarTemplates empty tabs completes with a loading template`() {
        invoke("updateTabBarTemplates", tabs(emptyList())).assertSuccess()
        assertTrue((FlutterAndroidAutoPlugin.currentTemplate as ListTemplate).isLoading)
    }

    @Test
    fun `updateTabBarTemplates inner construction failure returns one error on main`() {
        invoke("updateTabBarTemplates", tabs(listOf(messageTab(message = "")))).assertError("android_auto_error")
    }

    @Test
    fun `updateTabBarTemplates succeeds for a valid inner template`() {
        invoke("updateTabBarTemplates", tabs(listOf(messageTab()))).assertSuccess()
        assertTrue(FlutterAndroidAutoPlugin.currentTemplate is MessageTemplate)
    }

    @Test
    fun `rebuildElementTemplate construction failure reaches its caller`() {
        invoke("setRootTemplate", root()).assertSuccess()
        invoke("updateMessageTemplate", mapOf("elementId" to "root", "title" to "Title", "message" to ""))
            .assertError("android_auto_error")
    }

    @Test
    fun `rebuildElementTemplate succeeds for updated content`() {
        invoke("setRootTemplate", root()).assertSuccess()
        invoke("updateMessageTemplate", mapOf("elementId" to "root", "title" to "Title", "message" to "Updated"))
            .assertSuccess()
        assertEquals("Updated", (FlutterAndroidAutoPlugin.currentTemplate as MessageTemplate).message.toString())
    }

    @Test
    fun `rebuildPendingTemplate with no pending element completes once`() {
        invoke("onListItemSelectedComplete").assertSuccess()
        invoke("onGridButtonSelectedComplete").assertSuccess()
    }

    @Test
    fun `rebuildElementTemplate missing stored template returns one error`() {
        setState("pendingTemplateElementId", "missing")
        invoke("onListItemSelectedComplete").assertError("No template found")
        invoke("onListItemSelectedComplete").assertSuccess()
    }

    @Test
    fun `missing template arguments complete without launching work`() {
        for (method in listOf("setAlert", "updateTabBarTemplates", "pushTemplate", "setRootTemplate")) {
            invoke(method).assertError("Missing template")
        }
    }

    @Test
    fun `disconnected navigation handlers complete without launching work`() {
        AndroidAutoService.session = null
        invoke("setAlert", alert()).assertError("No car context")
        invoke("pushTemplate", root()).assertError("No car context")
    }

    @Test
    fun `unknown method completes notImplemented exactly once on main`() {
        val reply = invoke("unknown")
        assertEquals(1, reply.buffers.size)
        assertNull(reply.buffers.single())
    }

    @Test
    fun `invalidating a native screen failure reaches root caller`() {
        failInvalidation()
        invoke("setRootTemplate", root()).assertError("android_auto_error", "Invalidation failed")
    }

    @Test
    fun `invalidating a native screen failure reaches tab caller`() {
        failInvalidation()
        invoke("updateTabBarTemplates", tabs(listOf(messageTab()))).assertError("android_auto_error", "Invalidation failed")
    }

    @Test
    fun `invalidating a native screen failure reaches rebuild caller`() {
        invoke("setRootTemplate", root()).assertSuccess()
        failInvalidation()
        invoke("updateMessageTemplate", mapOf("elementId" to "root", "message" to "Updated"))
            .assertError("android_auto_error", "Invalidation failed")
    }

    @Test
    fun `failed coroutine does not cancel a sibling call`() {
        val failed = dispatch("setRootTemplate", root("unsupported"))
        val successful = dispatch("setRootTemplate", root())
        idle()
        failed.assertError("android_auto_error")
        successful.assertSuccess()
    }

    @Test
    fun `engine detach cancels a queued call without changing templates`() {
        val reply = dispatch("setRootTemplate", root())
        plugin.onDetachedFromEngine(binding)
        idle()
        reply.assertError("operation_cancelled")
        assertNull(FlutterAndroidAutoPlugin.currentTemplate)
        assertNull(messenger.handlers[FAAHelpers.makeFCPChannelId("")])
    }

    @Test
    fun `engine detach cancels a suspended call exactly once on main`() {
        val reply = MainThreadResult()
        var started = false
        val job = scope().launchMethodCall(reply) {
            started = true
            awaitCancellation()
        }
        idle()
        assertTrue(started)
        plugin.onDetachedFromEngine(binding)
        idle()
        assertTrue(job.isCompleted)
        assertEquals(listOf("operation_cancelled"), reply.errors)
        assertEquals(1, reply.count)
    }

    @Test
    fun `engine reattach accepts calls in a fresh scope`() {
        plugin.onDetachedFromEngine(binding)
        plugin.onAttachedToEngine(binding)
        assertTrue(scope().coroutineContext[Job]!!.isActive)
        invoke("setRootTemplate", root()).assertSuccess()
    }

    @Test
    fun `cancellation from a worker thread still completes on Android main`() {
        val reply = MainThreadResult()
        val job = scope().launchMethodCall(reply) { awaitCancellation() }
        idle()
        Thread { job.cancel() }.apply { start(); join() }
        idle()
        assertEquals(listOf("operation_cancelled"), reply.errors)
        assertEquals(1, reply.count)
    }

    private fun failNavigation() {
        val manager = mock(ScreenManager::class.java)
        doThrow(IllegalStateException("Navigation failed")).`when`(manager).push(org.mockito.ArgumentMatchers.any(Screen::class.java))
        carContext.overrideCarService(ScreenManager::class.java, manager)
    }

    private fun failInvalidation() {
        val manager = mock(AppManager::class.java)
        doThrow(IllegalStateException("Invalidation failed")).`when`(manager).invalidate()
        carContext.overrideCarService(AppManager::class.java, manager)
    }

    private fun root(type: String = "FAAMessageTemplate", message: String = "Message") = mapOf(
        "runtimeType" to type,
        "template" to mapOf("_elementId" to "root", "title" to "Title", "message" to message),
    )

    private fun alert() = mapOf("template" to mapOf("_elementId" to "alert", "title" to "Title", "message" to "Message"))

    private fun messageTab(message: String = "Message") = mapOf(
        "elementId" to "tab", "runtimeType" to "FAAMessageTemplate",
        "template" to mapOf("_elementId" to "tab", "title" to "Title", "message" to message),
    )

    private fun tabs(tabs: List<Map<String, Any?>>) = mapOf("template" to mapOf("_elementId" to "tabs", "tabs" to tabs))

    private fun dispatch(method: String, arguments: Any? = null): ChannelReply = messenger.dispatch(method, arguments)

    private fun invoke(method: String, arguments: Any? = null): ChannelReply = dispatch(method, arguments).also { idle() }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun scope(): CoroutineScope = FlutterAndroidAutoPlugin::class.java.getDeclaredField("pluginScope").let {
        it.isAccessible = true
        it.get(plugin) as CoroutineScope
    }

    private fun setState(name: String, value: Any?) {
        FlutterAndroidAutoPlugin::class.java.getDeclaredField(name).apply { isAccessible = true }.set(null, value)
    }

    private fun resetTemplateState() {
        FlutterAndroidAutoPlugin.events = null
        FlutterAndroidAutoPlugin.currentTemplate = null
        FlutterAndroidAutoPlugin.currentScreen = null
        FlutterAndroidAutoPlugin.currentAlertScreen = null
        for (name in listOf("currentRootTemplateElementId", "currentTabBarData", "activeTabContentId", "pendingTemplateElementId")) {
            setState(name, null)
        }
        for (name in listOf("templateDataByElementId", "templateRuntimeTypes", "templateBackButtons", "templatesByElementId", "screensByElementId")) {
            FlutterAndroidAutoPlugin::class.java.getDeclaredField(name).apply { isAccessible = true }
                .let { (it.get(null) as MutableMap<*, *>).clear() }
        }
    }
}

private class MainThreadResult : MethodChannel.Result {
    var count = 0
    val errors = mutableListOf<String>()
    override fun success(result: Any?) { checkMain(); count++ }
    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) { checkMain(); count++; errors.add(errorCode) }
    override fun notImplemented() { checkMain(); count++ }
    private fun checkMain() = assertSame(Looper.getMainLooper(), Looper.myLooper())
}

private class ChannelReply {
    val buffers = mutableListOf<ByteBuffer?>()
    fun record(buffer: ByteBuffer?) {
        assertSame(Looper.getMainLooper(), Looper.myLooper())
        buffers.add(buffer?.duplicate()?.apply { flip() })
    }
    fun assertSuccess() {
        assertEquals(1, buffers.size)
        assertEquals(true, StandardMethodCodec.INSTANCE.decodeEnvelope(buffers.single()!!))
    }
    fun assertError(code: String, message: String? = null) {
        assertEquals(1, buffers.size)
        val exception = assertThrows(FlutterException::class.java) {
            StandardMethodCodec.INSTANCE.decodeEnvelope(buffers.single()!!)
        }
        assertEquals(code, exception.code)
        if (message != null) assertTrue(exception.message!!.contains(message))
    }
}

private class RecordingMessenger : BinaryMessenger {
    val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler?>()
    override fun send(channel: String, message: ByteBuffer?) = Unit
    override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) = Unit
    override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) { handlers[channel] = handler }
    fun dispatch(method: String, arguments: Any?): ChannelReply {
        val reply = ChannelReply()
        val buffer = StandardMethodCodec.INSTANCE.encodeMethodCall(MethodCall(method, arguments)).apply { flip() }
        handlers[FAAHelpers.makeFCPChannelId("")]!!.onMessage(buffer, reply::record)
        return reply
    }
}
