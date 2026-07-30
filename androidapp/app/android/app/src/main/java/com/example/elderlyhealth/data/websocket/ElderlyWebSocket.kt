package com.example.elderlyhealth.data.websocket

import android.util.Log
import com.example.elderlyhealth.data.model.*
import com.google.gson.Gson
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*
import okhttp3.*
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import javax.inject.Inject
import javax.inject.Singleton

sealed class WsEvent {
    data class VitalUpdate(val data: WsVitalUpdate) : WsEvent()
    data class AlarmNotify(val data: WsAlarmNotify) : WsEvent()
    data class AlarmUpdated(val alarmId: String, val status: String) : WsEvent()
    data class SigninNotify(val data: WsSigninNotify) : WsEvent()
    data class DeviceStatus(val data: WsDeviceStatus) : WsEvent()
    data class DashboardRefresh(val communityId: String) : WsEvent()
    data object Connected : WsEvent()
    data object Disconnected : WsEvent()
    data class Error(val message: String) : WsEvent()
}

@Singleton
class ElderlyWebSocket @Inject constructor(
    private val gson: Gson,
    private val client: OkHttpClient
) {
    companion object {
        private const val TAG = "ElderlyWebSocket"
        private const val RECONNECT_DELAY_MS = 5000L
        private const val PING_INTERVAL_MS = 30000L
    }

    private var webSocket: WebSocket? = null
    @Volatile private var currentToken: String? = null
    private val _events = Channel<WsEvent>(Channel.BUFFERED)
    val events: Flow<WsEvent> = _events.receiveAsFlow()

    private var reconnectJob: java.util.Timer? = null
    private val shouldReconnect = AtomicBoolean(false)

    fun connect(token: String) {
        currentToken = token
        shouldReconnect.set(true)
        doConnect(token)
    }

    private fun doConnect(token: String) {
        val wsClient = client.newBuilder()
            .pingInterval(PING_INTERVAL_MS, TimeUnit.MILLISECONDS)
            .build()

        val request = Request.Builder()
            .url("${com.example.elderlyhealth.BuildConfig.WS_URL}?token=$token")
            .build()

        webSocket = wsClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.d(TAG, "WebSocket connected")
                _events.trySend(WsEvent.Connected)
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                handleMessage(text)
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "WebSocket closing: $code $reason")
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "WebSocket closed: $code $reason")
                _events.trySend(WsEvent.Disconnected)
                scheduleReconnect()
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "WebSocket failure: ${t.message}", t)
                _events.trySend(WsEvent.Error(t.message ?: "Unknown error"))
                scheduleReconnect()
            }
        })
    }

    private fun handleMessage(text: String) {
        try {
            val msg = gson.fromJson(text, WsMessage::class.java)
            val payload = msg.payload

            when (msg.type) {
                "VITAL_UPDATE" -> {
                    val data = gson.fromJson(
                        gson.toJson(payload), WsVitalUpdate::class.java
                    )
                    _events.trySend(WsEvent.VitalUpdate(data))
                }
                "ALARM_NOTIFY" -> {
                    val data = gson.fromJson(
                        gson.toJson(payload), WsAlarmNotify::class.java
                    )
                    _events.trySend(WsEvent.AlarmNotify(data))
                }
                "ALARM_UPDATED" -> {
                    val alarmId = payload["alarm_id"] as? String ?: return
                    val status = payload["status"] as? String ?: return
                    _events.trySend(WsEvent.AlarmUpdated(alarmId, status))
                }
                "SIGNIN_NOTIFY" -> {
                    val data = gson.fromJson(
                        gson.toJson(payload), WsSigninNotify::class.java
                    )
                    _events.trySend(WsEvent.SigninNotify(data))
                }
                "DEVICE_STATUS" -> {
                    val data = gson.fromJson(
                        gson.toJson(payload), WsDeviceStatus::class.java
                    )
                    _events.trySend(WsEvent.DeviceStatus(data))
                }
                "DASHBOARD_REFRESH" -> {
                    val communityId = payload["community_id"] as? String ?: return
                    _events.trySend(WsEvent.DashboardRefresh(communityId))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse WS message: ${e.message}")
        }
    }

    fun subscribe(topic: String) {
        val msg = WsSubscribeRequest("subscribe", topic)
        val sent = webSocket?.send(gson.toJson(msg))
        if (sent != null && !sent) {
            Log.w(TAG, "subscribe($topic) failed, reconnecting...")
            currentToken?.let { doConnect(it) }
        }
    }

    fun unsubscribe(topic: String) {
        val msg = WsSubscribeRequest("unsubscribe", topic)
        webSocket?.send(gson.toJson(msg))
    }

    fun subscribeFamilyVital(elderlyId: String) {
        subscribe("vital:$elderlyId")
    }

    fun subscribeCommunityAlarm(communityId: String) {
        subscribe("alarm:community:$communityId")
    }

    fun disconnect() {
        shouldReconnect.set(false)
        reconnectJob?.cancel()
        reconnectJob = null
        webSocket?.close(1000, "User disconnected")
        webSocket = null
    }

    private fun scheduleReconnect() {
        if (!shouldReconnect.get()) return
        reconnectJob?.cancel()
        val timer = java.util.Timer()
        timer.schedule(object : java.util.TimerTask() {
            override fun run() {
                if (!shouldReconnect.get()) return
                val token = currentToken ?: return
                if (shouldReconnect.get()) doConnect(token)
            }
        }, RECONNECT_DELAY_MS)
        reconnectJob = timer
    }
}
