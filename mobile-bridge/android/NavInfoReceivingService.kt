package com.evbikes.bridge

import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.os.Process
import com.google.android.libraries.mapsplatform.turnbyturn.TurnByTurnManager

// Receives turn-by-turn updates (about 1 per second) from the Google Navigation SDK
// and forwards them to the cluster over BLE. Register it with
// navigator.registerServiceForNavUpdates(packageName, NavInfoReceivingService::class.java.name, 1)
class NavInfoReceivingService : Service() {

    private lateinit var turnByTurnManager: TurnByTurnManager
    private lateinit var incomingMessenger: Messenger

    private inner class IncomingNavStepHandler(looper: Looper) : Handler(looper) {
        override fun handleMessage(msg: Message) {
            if (msg.what != TurnByTurnManager.MSG_NAV_INFO) return
            val info = turnByTurnManager.readNavInfoFromBundle(msg.data)
            val update = GoogleNavMapper.toNavUpdate(info) ?: return
            ClusterBleLink.send(PhoneLinkCodec.navUpdate(update))
        }
    }

    override fun onCreate() {
        super.onCreate()
        turnByTurnManager = TurnByTurnManager.createInstance()
        val thread = HandlerThread("NavInfoReceivingService", Process.THREAD_PRIORITY_DEFAULT)
        thread.start()
        incomingMessenger = Messenger(IncomingNavStepHandler(thread.looper))
    }

    override fun onBind(intent: Intent): IBinder = incomingMessenger.binder

    override fun onUnbind(intent: Intent): Boolean {
        ClusterBleLink.send(PhoneLinkCodec.frame(PhoneLinkCodec.NAV_STOP))
        return super.onUnbind(intent)
    }
}
