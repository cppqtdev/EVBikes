package com.evbikes.bridge

import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

// Kotlin twin of src/core/nav/PhoneLinkProtocol.h. Keep both in sync.
object PhoneLinkCodec {
    private const val SOF = 0xA5
    private const val VERSION = 1
    private const val MAX_TEXT = 48

    const val NAV_UPDATE = 0x01
    const val NAV_STOP = 0x02
    const val CALL_STATE = 0x10
    const val MEDIA_STATE = 0x11
    const val NOTIFICATION = 0x12
    const val TIME_SYNC = 0x20
    const val PHONE_STATUS = 0x21
    const val HEARTBEAT = 0x30
    const val MEDIA_COMMAND = 0x40
    const val CALL_COMMAND = 0x41

    enum class Maneuver(val code: Int) {
        NONE(0), STRAIGHT(1), SLIGHT_LEFT(2), LEFT(3), SHARP_LEFT(4), SLIGHT_RIGHT(5), RIGHT(6),
        SHARP_RIGHT(7), UTURN_LEFT(8), UTURN_RIGHT(9), ROUNDABOUT_ENTER(10), ROUNDABOUT_EXIT(11),
        FORK_LEFT(12), FORK_RIGHT(13), MERGE_LEFT(14), MERGE_RIGHT(15), DESTINATION(16)
    }

    data class NavUpdate(
        val maneuver: Maneuver,
        val roundaboutExit: Int,
        val distanceToManeuverM: Int,
        val distanceRemainingM: Int,
        val etaMinutes: Int,
        val laneMask: Int,
        val recommendedLaneMask: Int,
        val roadName: String,
    )

    fun crc16(data: ByteArray, from: Int, len: Int): Int {
        var crc = 0xFFFF
        for (i in from until from + len) {
            crc = crc xor ((data[i].toInt() and 0xFF) shl 8)
            repeat(8) {
                crc = if (crc and 0x8000 != 0) ((crc shl 1) xor 0x1021) and 0xFFFF else (crc shl 1) and 0xFFFF
            }
        }
        return crc
    }

    fun frame(type: Int, payload: ByteArray = ByteArray(0)): ByteArray {
        val out = ByteBuffer.allocate(5 + payload.size + 2).order(ByteOrder.LITTLE_ENDIAN)
        out.put(SOF.toByte())
        out.put(VERSION.toByte())
        out.put(type.toByte())
        out.putShort(payload.size.toShort())
        out.put(payload)
        val bytes = out.array()
        val crc = crc16(bytes, 1, 4 + payload.size)
        bytes[5 + payload.size] = (crc and 0xFF).toByte()
        bytes[6 + payload.size] = (crc shr 8).toByte()
        return bytes
    }

    private fun text(value: String): ByteArray {
        var raw = value.toByteArray(Charsets.UTF_8)
        if (raw.size > MAX_TEXT) {
            var cut = MAX_TEXT
            while (cut > 0 && (raw[cut].toInt() and 0xC0) == 0x80) cut--
            raw = raw.copyOf(cut)
        }
        return byteArrayOf(raw.size.toByte()) + raw
    }

    fun navUpdate(n: NavUpdate): ByteArray {
        val body = ByteBuffer.allocate(14).order(ByteOrder.LITTLE_ENDIAN)
            .put(n.maneuver.code.toByte())
            .put(n.roundaboutExit.toByte())
            .putInt(n.distanceToManeuverM)
            .putInt(n.distanceRemainingM)
            .putShort(n.etaMinutes.toShort())
            .put(n.laneMask.toByte())
            .put(n.recommendedLaneMask.toByte())
            .array()
        return frame(NAV_UPDATE, body + text(n.roadName))
    }

    fun timeSync(unixSeconds: Long, utcOffsetMinutes: Int): ByteArray {
        val body = ByteBuffer.allocate(6).order(ByteOrder.LITTLE_ENDIAN)
            .putInt(unixSeconds.toInt())
            .putShort(utcOffsetMinutes.toShort())
            .array()
        return frame(TIME_SYNC, body)
    }

    fun phoneStatus(batteryPercent: Int, signalBars: Int, internet: Boolean): ByteArray =
        frame(PHONE_STATUS, byteArrayOf(batteryPercent.toByte(), signalBars.toByte(), if (internet) 1 else 0))

    fun callState(status: Int, caller: String): ByteArray = frame(CALL_STATE, byteArrayOf(status.toByte()) + text(caller))

    fun notification(appId: Int, sender: String, message: String): ByteArray =
        frame(NOTIFICATION, byteArrayOf(appId.toByte()) + text(sender) + text(message))

    // Stream parser for cluster -> phone commands (MEDIA_COMMAND / CALL_COMMAND).
    class Parser(private val onFrame: (type: Int, payload: ByteArray) -> Unit) {
        private val buf = ByteArrayOutputStream()

        fun feed(bytes: ByteArray) {
            for (b in bytes) {
                if (buf.size() == 0 && (b.toInt() and 0xFF) != SOF) continue
                buf.write(b.toInt())
                process()
            }
        }

        private fun process() {
            val data = buf.toByteArray()
            if (data.size < 5) return
            val len = (data[3].toInt() and 0xFF) or ((data[4].toInt() and 0xFF) shl 8)
            if (data[1].toInt() != VERSION || len > 160) { buf.reset(); return }
            if (data.size < 7 + len) return
            val rx = (data[5 + len].toInt() and 0xFF) or ((data[6 + len].toInt() and 0xFF) shl 8)
            if (rx == crc16(data, 1, 4 + len)) onFrame(data[2].toInt() and 0xFF, data.copyOfRange(5, 5 + len))
            buf.reset()
        }
    }
}
