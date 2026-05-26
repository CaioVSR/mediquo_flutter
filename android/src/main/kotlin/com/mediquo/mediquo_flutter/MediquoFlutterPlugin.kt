package com.mediquo.mediquo_flutter

import android.app.Activity
import android.content.Context
import com.mediquo.chat.MediquoAuthenticateListener
import com.mediquo.chat.MediquoDeAuthenticateListener
import com.mediquo.chat.MediquoInitListener
import com.mediquo.chat.MediquoSDK
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * Flutter plugin bridging the native MediQuo Android SDK.
 *
 * Implements the Pigeon-generated [MediquoHostApi] and forwards every call to
 * [MediquoSDK], completing each callback with [Result.success] on success or a
 * [FlutterError] whose code matches `MediquoErrorCode` on the Dart side.
 */
class MediquoFlutterPlugin : FlutterPlugin, ActivityAware, MediquoHostApi {

    private var applicationContext: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        MediquoHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = null
        MediquoHostApi.setUp(binding.binaryMessenger, null)
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

    override fun initialize(apiKey: String, callback: (Result<Unit>) -> Unit) {
        val context = applicationContext
        if (context == null) {
            callback(failure(NOT_INITIALIZED, "The plugin is not attached."))
            return
        }
        MediquoSDK.initialize(
            context,
            apiKey,
            object : MediquoInitListener {
                override fun onSuccess() = callback(Result.success(Unit))

                override fun onFailure(message: String?) =
                    callback(failure(INITIALIZATION_FAILED, message))
            },
        )
    }

    override fun authenticate(
        clientCode: String,
        callback: (Result<Unit>) -> Unit,
    ) {
        MediquoSDK.authenticate(
            clientCode,
            object : MediquoAuthenticateListener {
                override fun onSuccess() = callback(Result.success(Unit))

                override fun onFailure(message: String?) =
                    callback(failure(AUTHENTICATION_FAILED, message))
            },
        )
    }

    override fun openProfessionalList(callback: (Result<Unit>) -> Unit) {
        val instance = MediquoSDK.getInstance()
        val currentActivity = activity
        if (instance == null) {
            callback(failure(NOT_INITIALIZED, "Authenticate a patient first."))
            return
        }
        if (currentActivity == null) {
            callback(failure(OPEN_FAILED, "No foreground activity available."))
            return
        }
        runCatching { instance.openProfessionalListActivity(currentActivity) }
            .fold(
                { callback(Result.success(Unit)) },
                { callback(failure(OPEN_FAILED, it.message)) },
            )
    }

    override fun deauthenticate(callback: (Result<Unit>) -> Unit) {
        MediquoSDK.deAuthenticate(
            object : MediquoDeAuthenticateListener {
                override fun onSuccess() = callback(Result.success(Unit))

                override fun onFailure(message: String?) =
                    callback(failure(DEAUTHENTICATION_FAILED, message))
            },
        )
    }

    override fun registerPushToken(
        token: String,
        type: PushTokenType,
        callback: (Result<Unit>) -> Unit,
    ) {
        val instance = MediquoSDK.getInstance()
        if (instance == null) {
            callback(failure(NOT_INITIALIZED, "Authenticate a patient first."))
            return
        }
        runCatching { instance.registerPushToken(token) }
            .fold(
                { callback(Result.success(Unit)) },
                { callback(failure(PUSH_REGISTRATION_FAILED, it.message)) },
            )
    }

    override fun openFromRemoteNotification(
        payload: Map<String, Any?>,
        callback: (Result<Unit>) -> Unit,
    ) {
        val instance = MediquoSDK.getInstance()
        val currentActivity = activity
        if (instance == null) {
            callback(failure(NOT_INITIALIZED, "Authenticate a patient first."))
            return
        }
        if (currentActivity == null) {
            callback(failure(OPEN_FAILED, "No foreground activity available."))
            return
        }
        runCatching { instance.openProfessionalListActivity(currentActivity) }
            .fold(
                { callback(Result.success(Unit)) },
                { callback(failure(OPEN_FAILED, it.message)) },
            )
    }

    private fun failure(code: String, message: String?): Result<Unit> =
        Result.failure(FlutterError(code, message, null))

    private companion object {
        const val INITIALIZATION_FAILED = "initialization_failed"
        const val AUTHENTICATION_FAILED = "authentication_failed"
        const val OPEN_FAILED = "open_failed"
        const val DEAUTHENTICATION_FAILED = "deauthentication_failed"
        const val PUSH_REGISTRATION_FAILED = "push_registration_failed"
        const val NOT_INITIALIZED = "not_initialized"
    }
}
