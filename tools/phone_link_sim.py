#!/usr/bin/env python3
"""Sends phone-link frames (docs/03-protocols.md) to the cluster over a serial port.

Use it on the bench in place of the phone app + BLE module.
  pip install pyserial
  python3 tools/phone_link_sim.py /dev/tty.usbserial-XXXX           # route demo
  python3 tools/phone_link_sim.py --dump                             # print hex only
"""
import argparse
import struct
import sys
import time

SOF = 0xA5
VERSION = 1

NAV_UPDATE, NAV_STOP, CALL_STATE, MEDIA_STATE, NOTIFICATION = 0x01, 0x02, 0x10, 0x11, 0x12
TIME_SYNC, PHONE_STATUS, HEARTBEAT = 0x20, 0x21, 0x30

MANEUVERS = {
    "none": 0, "straight": 1, "slight_left": 2, "left": 3, "sharp_left": 4, "slight_right": 5,
    "right": 6, "sharp_right": 7, "uturn_left": 8, "uturn_right": 9, "roundabout": 10,
    "roundabout_exit": 11, "fork_left": 12, "fork_right": 13, "merge_left": 14,
    "merge_right": 15, "destination": 16,
}


def crc16_ccitt(data, crc=0xFFFF):
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc


def text(s):
    raw = s.encode("utf-8")[:48]
    return bytes([len(raw)]) + raw


def frame(msg_type, payload=b""):
    body = struct.pack("<BBH", VERSION, msg_type, len(payload)) + payload
    return bytes([SOF]) + body + struct.pack("<H", crc16_ccitt(body))


def nav_update(maneuver, dist_m, remaining_m, eta_min, road, exit_no=0, lanes=0, rec=0):
    payload = struct.pack("<BBIIHBB", MANEUVERS[maneuver], exit_no, dist_m, remaining_m, eta_min, lanes, rec)
    return frame(NAV_UPDATE, payload + text(road))


def time_sync(offset_min=330):
    return frame(TIME_SYNC, struct.pack("<Ih", int(time.time()), offset_min))


def phone_status(battery=80, bars=4, internet=True):
    return frame(PHONE_STATUS, struct.pack("<BBB", battery, bars, 1 if internet else 0))


def call_state(status, caller):
    return frame(CALL_STATE, bytes([status]) + text(caller))


def demo_route():
    route = [("right", 400, "MG Road"), ("roundabout", 600, "Silk Board"), ("left", 300, "Hosur Road"),
             ("destination", 120, "Office")]
    total = sum(d for _, d, _ in route)
    for maneuver, dist, road in route:
        for d in range(dist, 0, -50):
            yield nav_update(maneuver, d, total, max(1, total // 400), road, exit_no=2 if maneuver == "roundabout" else 0,
                             lanes=0x07, rec=0x04 if maneuver == "right" else 0x02)
            total -= 50
    yield frame(NAV_STOP)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("port", nargs="?")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--dump", action="store_true")
    ap.add_argument("--period", type=float, default=1.0)
    args = ap.parse_args()

    if args.dump or not args.port:
        for f in [time_sync(), phone_status(), call_state(1, "Anita"), nav_update("right", 250, 12400, 23, "MG Road")]:
            print(f.hex(" "))
        return 0

    import serial  # pyserial

    with serial.Serial(args.port, args.baud) as port:
        port.write(time_sync())
        port.write(phone_status())
        for f in demo_route():
            port.write(f)
            port.write(frame(HEARTBEAT))
            time.sleep(args.period)
    return 0


if __name__ == "__main__":
    sys.exit(main())
