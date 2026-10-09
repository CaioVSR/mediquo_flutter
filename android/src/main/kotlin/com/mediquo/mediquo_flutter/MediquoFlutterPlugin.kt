package com.mediquo.mediquo_flutter

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import com.mediquo.sdk.MediQuo
import com.mediquo.sdk.MediQuoEventDelegate
import com.mediquo.sdk.MediQuoHostActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.lang.ref.WeakReference
import java.net.URI
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Flutter plugin bridging the native MediQuo Android SDK.
 *
 * Implements the Pigeon-generated [MediquoHostApi] and forwards every call to
 * a [MediQuo] instance, completing each callback with [Result.success] on
 * success or a [FlutterError] whose code matches `MediquoErrorCode` on the
 * Dart side.
 */
class MediquoFlutterPlugin :
    FlutterPlugin,
    ActivityAware,
    MediquoHostApi,
    Application.ActivityLifecycleCallbacks {

    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var scope: CoroutineScope? = null

    private var apiKey: String? = null
    private var mediquo: MediQuo? = null

    // The incoming call currently on screen, so a remote rejection can close it.
    private var activeCallId: String? = null
    private var activeCallLaunchExtras: Map<String, String?>? = null
    private var activeCallActivity: WeakReference<Activity>? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        (binding.applicationContext as? Application)
            ?.registerActivityLifecycleCallbacks(this)
        MediquoHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MediquoHostApi.setUp(binding.binaryMessenger, null)
        (binding.applicationContext as? Application)
            ?.unregisterActivityLifecycleCallbacks(this)
        scope?.cancel()
        scope = null
        mediquo?.eventDelegate = null
        mediquo = null
        clearActiveCall()
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(
        binding: ActivityPluginBinding,
    ) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun isSupported(): Boolean = isDeviceSupported()

    override fun initialize(apiKey: String, callback: (Result<Unit>) -> Unit) {
        if (!isDeviceSupported()) {
            callback(unsupportedDevice())
            return
        }
        if (applicationContext == null) {
            callback(failure(NOT_INITIALIZED, "The plugin is not attached."))
            return
        }
        this.apiKey = apiKey
        callback(Result.success(Unit))
    }

    override fun authenticate(
        clientCode: String,
        callback: (Result<Unit>) -> Unit,
    ) {
        if (!isDeviceSupported()) {
            callback(unsupportedDevice())
            return
        }
        val context = applicationContext
        val key = apiKey
        val coroutineScope = scope
        if (context == null || key == null || coroutineScope == null) {
            callback(
                failure(
                    NOT_INITIALIZED,
                    "Initialise the SDK before authenticating.",
                ),
            )
            return
        }
        coroutineScope.launch {
            val result = runSuspendCatching {
                MediQuo.create(context = context, apiKey = key, userId = clientCode)
            }
            result.onSuccess { instance ->
                mediquo?.eventDelegate = null
                instance.eventDelegate = eventDelegate
                mediquo = instance
                callback(Result.success(Unit))
            }
            result.onFailure {
                callback(failure(AUTHENTICATION_FAILED, it.message))
            }
        }
    }

    override fun openProfessionalList(callback: (Result<Unit>) -> Unit) {
        open(MediQuo.ViewKind.ProfessionalList(), callback)
    }

    override fun deauthenticate(callback: (Result<Unit>) -> Unit) {
        if (!isDeviceSupported()) {
            callback(unsupportedDevice())
            return
        }
        val instance = mediquo
        val coroutineScope = scope
        if (instance == null || coroutineScope == null) {
            callback(notInitialized())
            return
        }
        coroutineScope.launch {
            runSuspendCatching { instance.deauthenticateSDK() }
                .onSuccess {
                    instance.eventDelegate = null
                    if (mediquo === instance) mediquo = null
                    clearActiveCall()
                    callback(Result.success(Unit))
                }
                .onFailure {
                    callback(failure(DEAUTHENTICATION_FAILED, it.message))
                }
        }
    }

    override fun registerPushToken(
        token: String,
        type: PushTokenType,
        callback: (Result<Unit>) -> Unit,
    ) {
        if (!isDeviceSupported()) {
            callback(unsupportedDevice())
            return
        }
        val instance = mediquo
        val coroutineScope = scope
        if (instance == null || coroutineScope == null) {
            callback(notInitialized())
            return
        }
        if (type != PushTokenType.FCM) {
            callback(
                failure(
                    PUSH_REGISTRATION_FAILED,
                    "Only FCM tokens are supported on Android.",
                ),
            )
            return
        }
        coroutineScope.launch {
            runSuspendCatching {
                instance.setPushNotificationToken(
                    MediQuo.NotificationType.Firebase(token),
                )
            }
                .onSuccess { callback(Result.success(Unit)) }
                .onFailure { callback(failure(PUSH_REGISTRATION_FAILED, it.message)) }
        }
    }

    override fun openFromRemoteNotification(
        payload: Map<String, Any?>,
        callback: (Result<Unit>) -> Unit,
    ) {
        val callViewModel = callViewModelFrom(payload)
        if (callViewModel != null) {
            open(MediQuo.ViewKind.Call(callViewModel), callback) { intent ->
                trackActiveCall(callViewModel.id, intent)
            }
            return
        }
        val roomId = payload[ROOM_ID]?.toString()?.toIntOrNull()
        val kind =
            if (roomId != null) {
                MediQuo.ViewKind.Chat(roomId)
            } else {
                MediQuo.ViewKind.ProfessionalList()
            }
        open(kind, callback)
    }

    // Application.ActivityLifecycleCallbacks: follows the MediQuoHostActivity
    // that shows the active call, so didRejectCall can finish it.

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        val extras = activeCallLaunchExtras ?: return
        if (activity is MediQuoHostActivity && activity.intent?.extrasSnapshot() == extras) {
            activeCallActivity = WeakReference(activity)
        }
    }

    override fun onActivityDestroyed(activity: Activity) {
        if (activeCallActivity?.get() === activity && !activity.isChangingConfigurations) {
            clearActiveCall()
        }
    }

    override fun onActivityStarted(activity: Activity) = Unit

    override fun onActivityResumed(activity: Activity) = Unit

    override fun onActivityPaused(activity: Activity) = Unit

    override fun onActivityStopped(activity: Activity) = Unit

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit

    private val eventDelegate =
        object : MediQuoEventDelegate {
            override suspend fun didChangeSocketStatus(
                isConnected: Boolean,
                previousIsConnected: Boolean,
            ) = Unit

            override suspend fun didReceiveCall(call: MediQuo.CallViewModel) {
                withContext(Dispatchers.Main) { presentIncomingCall(call) }
            }

            override suspend fun didRejectCall(callId: String) {
                withContext(Dispatchers.Main) {
                    if (callId.isNotBlank() && callId == activeCallId) {
                        activeCallActivity?.get()?.finish()
                        clearActiveCall()
                    }
                }
            }
        }

    private fun presentIncomingCall(call: MediQuo.CallViewModel) {
        val instance = mediquo ?: return
        if (activeCallId != null) return
        val foreground = activity
        val context = foreground ?: applicationContext ?: return
        val intent = instance.createIntent(context, MediQuo.ViewKind.Call(call))
        if (foreground == null) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { context.startActivity(intent) }
            .onSuccess { trackActiveCall(call.id, intent) }
    }

    private fun open(
        kind: MediQuo.ViewKind,
        callback: (Result<Unit>) -> Unit,
        onStarted: (Intent) -> Unit = {},
    ) {
        if (!isDeviceSupported()) {
            callback(unsupportedDevice())
            return
        }
        val instance = mediquo
        val currentActivity = activity
        if (instance == null) {
            callback(notInitialized())
            return
        }
        if (currentActivity == null) {
            callback(failure(OPEN_FAILED, "No foreground activity available."))
            return
        }
        runCatching {
            val intent = instance.createIntent(currentActivity, kind)
            currentActivity.startActivity(intent)
            intent
        }
            .onSuccess {
                onStarted(it)
                callback(Result.success(Unit))
            }
            .onFailure { callback(failure(OPEN_FAILED, it.message)) }
    }

    private fun trackActiveCall(callId: String, intent: Intent) {
        activeCallId = callId
        activeCallLaunchExtras = intent.extrasSnapshot()
        activeCallActivity = null
    }

    private fun clearActiveCall() {
        activeCallId = null
        activeCallLaunchExtras = null
        activeCallActivity = null
    }

    // createIntent carries a unique launch token as an extra (the key is
    // internal to the SDK), so equal extras identify the activity it started.
    private fun Intent.extrasSnapshot(): Map<String, String?> {
        val bundle = extras ?: return emptyMap()
        return bundle.keySet().associateWith { key ->
            @Suppress("DEPRECATION")
            bundle.get(key)?.toString()
        }
    }

    private fun failure(code: String, message: String?): Result<Unit> =
        Result.failure(FlutterError(code, message, null))

    private fun notInitialized(): Result<Unit> =
        failure(NOT_INITIALIZED, "Authenticate a patient before this operation.")

    private fun unsupportedDevice(): Result<Unit> =
        failure(
            UNSUPPORTED_DEVICE,
            "The MediQuo SDK requires an arm64-v8a device.",
        )

    private companion object {
        const val INITIALIZATION_FAILED = "initialization_failed"
        const val AUTHENTICATION_FAILED = "authentication_failed"
        const val OPEN_FAILED = "open_failed"
        const val DEAUTHENTICATION_FAILED = "deauthentication_failed"
        const val PUSH_REGISTRATION_FAILED = "push_registration_failed"
        const val NOT_INITIALIZED = "not_initialized"
        const val UNSUPPORTED_DEVICE = "unsupported_device"

        // The MediQuo SDK bundles native libraries for this ABI only.
        const val SUPPORTED_ABI = "arm64-v8a"

        // Push payload keys, as documented by the MediQuo Android sample app.
        const val ROOM_ID = "room_id"
        const val TYPE = "type"
        const val CALL_REQUESTED = "call_requested"
        const val CALL_PREFIX = "call_"
        const val CALL_UUID = "call_uuid"
        const val CALL_ROOM_ID = "call_room_id"
        const val CALL_SESSION_ID = "call_session_id"
        const val CALL_TYPE = "call_type"
        const val CALL_TOKEN = "call_token"
        const val PROFESSIONAL_HASH = "professional_hash"
        const val PROFESSIONAL_NAME = "professional_name"
        const val IMAGE = "image"

        fun isDeviceSupported(): Boolean = SUPPORTED_ABI in Build.SUPPORTED_ABIS

        /**
         * Builds the call screen model from an incoming-call push, or returns
         * `null` when [payload] is not a complete video-call request.
         */
        fun callViewModelFrom(payload: Map<String, Any?>): MediQuo.CallViewModel? {
            fun string(key: String): String? = payload[key]?.toString()

            val isCall =
                string(TYPE) == CALL_REQUESTED ||
                    payload.keys.any { it.startsWith(CALL_PREFIX) }
            if (!isCall) return null
            val roomId = string(CALL_ROOM_ID)?.toIntOrNull() ?: return null
            if (!string(CALL_TYPE).equals("video", ignoreCase = true)) return null
            return MediQuo.CallViewModel(
                id = string(CALL_UUID).orEmpty(),
                roomId = roomId,
                sessionId = string(CALL_SESSION_ID).orEmpty(),
                tokenId = string(CALL_TOKEN).orEmpty(),
                type = MediQuo.CallViewModel.CallType.VIDEO,
                professional =
                    MediQuo.CallViewModel.Professional(
                        id = string(PROFESSIONAL_HASH).orEmpty(),
                        avatarURL =
                            string(IMAGE)
                                ?.takeIf { it.isNotBlank() }
                                ?.let { runCatching { URI(it) }.getOrNull() },
                        name = string(PROFESSIONAL_NAME).orEmpty(),
                    ),
            )
        }

        /** Like [runCatching] for suspend blocks, but never swallows cancellation. */
        inline fun <T> runSuspendCatching(block: () -> T): Result<T> =
            try {
                Result.success(block())
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (throwable: Throwable) {
                Result.failure(throwable)
            }
    }
}
