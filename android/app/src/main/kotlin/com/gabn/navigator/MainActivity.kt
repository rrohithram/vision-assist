package com.gabn.navigator

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.SmsManager
import android.telephony.TelephonyManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val GESTURE_CHANNEL = "com.gabn2/gestures"
    private val SMS_CHANNEL = "com.gabn2/sms"
    private val CALL_STATE_CHANNEL = "com.gabn2/call_state"

    // Held so we don't allocate a new channel on every key event.
    private var gestureChannel: MethodChannel? = null
    private var callStateChannel: MethodChannel? = null
    private var telephonyManager: TelephonyManager? = null
    private var callStateListener: PhoneStateListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        gestureChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GESTURE_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    // Volume events are delivered from onKeyDown; nothing to start or stop.
                    "startVolumeButtonListener" -> result.success(true)
                    "stopVolumeButtonListener" -> result.success(true)
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canSendSms" -> result.success(hasSmsPermission())
                    "sendSms" -> {
                        val number = call.argument<String>("phoneNumber")
                        val message = call.argument<String>("message")
                        if (number.isNullOrBlank() || message.isNullOrBlank()) {
                            result.error(
                                "INVALID_ARGS",
                                "phoneNumber and message are required",
                                null
                            )
                        } else {
                            sendSms(number, message, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        callStateChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_STATE_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> result.success(startListeningForCallState())
                    "stopListening" -> {
                        stopListeningForCallState()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /**
     * Watches system-wide call state so the SOS spoken message only starts once the
     * emergency call is actually answered, rather than assuming pickup after a fixed
     * delay - a call that rings out or reaches voicemail used to get talked over anyway.
     *
     * Works regardless of which mechanism placed the call (direct dial or handing off
     * to the system dialler), since TelephonyManager observes device-wide state.
     *
     * Returns false when READ_PHONE_STATE is not granted; the caller falls back to a
     * fixed delay in that case.
     */
    private fun startListeningForCallState(): Boolean {
        if (checkSelfPermission(Manifest.permission.READ_PHONE_STATE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }

        stopListeningForCallState()

        val manager = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager ?: return false
        telephonyManager = manager

        val listener = object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                if (state == TelephonyManager.CALL_STATE_OFFHOOK) {
                    callStateChannel?.invokeMethod("callAnswered", null)
                }
            }
        }
        callStateListener = listener

        @Suppress("DEPRECATION")
        manager.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
        return true
    }

    private fun stopListeningForCallState() {
        val listener = callStateListener ?: return
        @Suppress("DEPRECATION")
        telephonyManager?.listen(listener, PhoneStateListener.LISTEN_NONE)
        callStateListener = null
    }

    override fun onDestroy() {
        stopListeningForCallState()
        super.onDestroy()
    }

    // checkSelfPermission is on Context from API 23; minSdk here is 24.
    private fun hasSmsPermission(): Boolean =
        checkSelfPermission(Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED

    /**
     * Sends an SMS directly, without opening a composer.
     *
     * Emergency payloads carry a Gemini summary plus a maps URL and routinely exceed the
     * 160-character single-part limit, so every message goes out as multipart.
     */
    private fun sendSms(phoneNumber: String, message: String, result: MethodChannel.Result) {
        if (!hasSmsPermission()) {
            result.error("PERMISSION_DENIED", "SEND_SMS permission not granted", null)
            return
        }

        try {
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            if (smsManager == null) {
                result.error("NO_SMS_MANAGER", "SmsManager unavailable on this device", null)
                return
            }

            val parts = smsManager.divideMessage(message)
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            }
            result.success(true)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "SMS send failed: ${e.message}")
            result.error("SEND_FAILED", e.message, null)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            try {
                gestureChannel?.invokeMethod("volumeButtonPressed", null)
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Error sending volume button event: ${e.message}")
            }
            // Return false so normal volume control still works.
            return false
        }
        return super.onKeyDown(keyCode, event)
    }
}
