package com.evbikes.bridge

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Build
import java.util.UUID
import java.util.concurrent.ConcurrentLinkedQueue

// Minimal GATT client for the cluster "Phone Link" service (docs/03-protocols.md).
// Production app: add bonding, reconnect back-off, and a foreground service.
@SuppressLint("MissingPermission")
object ClusterBleLink {
    val SERVICE: UUID = UUID.fromString("6f7e0001-7a3c-4f1b-9e2d-45b1c0de0001")
    val RX_CHAR: UUID = UUID.fromString("6f7e0002-7a3c-4f1b-9e2d-45b1c0de0001")
    val TX_CHAR: UUID = UUID.fromString("6f7e0003-7a3c-4f1b-9e2d-45b1c0de0001")
    private val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

    private var gatt: BluetoothGatt? = null
    private var rx: BluetoothGattCharacteristic? = null
    private val queue = ConcurrentLinkedQueue<ByteArray>()
    @Volatile private var busy = false
    private var chunkSize = 20

    var onCommand: ((type: Int, payload: ByteArray) -> Unit)? = null
    private val parser = PhoneLinkCodec.Parser { type, payload -> onCommand?.invoke(type, payload) }

    fun connect(context: Context, device: BluetoothDevice) {
        gatt = device.connectGatt(context, true, callback, BluetoothDevice.TRANSPORT_LE)
    }

    fun send(frame: ByteArray) {
        var offset = 0
        while (offset < frame.size) {
            val end = minOf(frame.size, offset + chunkSize)
            queue.add(frame.copyOfRange(offset, end))
            offset = end
        }
        pump()
    }

    @Synchronized
    private fun pump() {
        if (busy) return
        val g = gatt ?: return
        val c = rx ?: return
        val next = queue.poll() ?: return
        busy = true
        if (Build.VERSION.SDK_INT >= 33) {
            g.writeCharacteristic(c, next, BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE)
        } else {
            @Suppress("DEPRECATION")
            run {
                c.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                c.value = next
                g.writeCharacteristic(c)
            }
        }
    }

    private val callback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                g.requestMtu(185)
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                rx = null
                busy = false
                queue.clear()
            }
        }

        override fun onMtuChanged(g: BluetoothGatt, mtu: Int, status: Int) {
            chunkSize = (mtu - 3).coerceAtLeast(20)
            g.discoverServices()
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
            val service = g.getService(SERVICE) ?: return
            rx = service.getCharacteristic(RX_CHAR)
            val tx = service.getCharacteristic(TX_CHAR) ?: return
            g.setCharacteristicNotification(tx, true)
            val cccd = tx.getDescriptor(CCCD) ?: return
            if (Build.VERSION.SDK_INT >= 33) {
                g.writeDescriptor(cccd, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
            } else {
                @Suppress("DEPRECATION")
                run {
                    cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                    g.writeDescriptor(cccd)
                }
            }
            send(PhoneLinkCodec.timeSync(System.currentTimeMillis() / 1000,
                java.util.TimeZone.getDefault().getOffset(System.currentTimeMillis()) / 60000))
        }

        override fun onCharacteristicWrite(g: BluetoothGatt, c: BluetoothGattCharacteristic, status: Int) {
            busy = false
            pump()
        }

        override fun onCharacteristicChanged(g: BluetoothGatt, c: BluetoothGattCharacteristic, value: ByteArray) {
            if (c.uuid == TX_CHAR) parser.feed(value)
        }
    }
}
