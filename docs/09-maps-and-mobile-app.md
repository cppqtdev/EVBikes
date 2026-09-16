# 09 · Maps and the mobile app

## Level 1 — Turn-by-turn (implemented)

```
Phone app ──(Google Navigation SDK turn-by-turn feed, ~1 update/s)──► map to NavUpdate
          ──(BLE write, ~30 bytes)──► cluster ──► NavigationData ──► TurnCard / LaneGuide / mini hint
```

- Google **Navigation SDK for Android / iOS** has a "turn-by-turn data feed" made for small displays such as **two-wheeler clusters**. It gives: manoeuvre type, distance to the step, road name, lanes (with the recommended lane), remaining time and distance. It can also give a pre-drawn manoeuvre bitmap (we don't need it — we use our own arrow icons).
- Mapping from Google `Maneuver` constants to our 16 codes is in `mobile-bridge/android/GoogleNavMapper.kt`.
- Alternative: **Mapbox Navigation SDK** (banner instructions + route progress), or **HERE SDK** (TVS iQube uses HERE Maps).
- Licensing: all these SDKs are commercial. Read the terms for showing directions on a vehicle display before production.

## Level 2 — Full map on the cluster (optional, stronger board)

Qt for MCUs 2.10+ has `QtLocation.Map` for MCUs.

- Enable modules: `ModuleFiles { MCU.qulModules: ["Location", "Positioning"] }`.
- You must write a **tile fetcher**: subclass `Qul::MapTileFetcher`, implement `getTileImage(...)`, register with `Qul::Application::addMapTileFetcher(&fetcher)`. Tiles usually come from **SD card / eMMC** (offline, pre-rendered PNG/JPEG in Web-Mercator z/x/y layout).
- Position: subclass `Qul::GeoPositionSource` (GPS module on UART, or position sent by the phone) and register with `Qul::Application::registerGeoPositionSource(...)`. QML uses `PositionSource`.
- Map projection is Pseudo-Mercator (EPSG:3857). Properties: `center`, `zoomLevel`, `bearing`, `minimumZoomLevel`, `maximumZoomLevel`, method `pan()`.
- Needs: image decoder (hardware JPEG is best), fast external storage, more RAM for the tile cache.
- Qt + Infineon **Navia** reference solution shows offline maps, turn-by-turn and POI (points of interest) on TRAVEO T2G.
- Tile data licensing: OpenStreetMap data is ODbL (attribution needed); Google / Mapbox tiles have their own terms (offline caching is usually restricted).

Sketch (not built by default):

```qml
import QtQuick
import QtLocation
import QtPositioning

Item {
    PositionSource { id: gps; active: true }
    Map {
        anchors.fill: parent
        center: gps.position.coordinate
        zoomLevel: 16
        bearing: 0
    }
}
```

## Level 3 — Phone-projected map (not recommended for v1)

- Like Royal Enfield Tripper Dash: phone renders the map, sends compressed frames over **Wi-Fi Direct / SoftAP**.
- Cluster needs Wi-Fi, JPEG/H.264 decode, and an `Image` with a runtime source.
- Riders report phone heating, battery drain, and drops. Only do this if the phone app is very solid.

## Phone app feature list

| Feature | Android API | Message |
|---|---|---|
| Navigation | Google Navigation SDK (turn-by-turn feed) | NavUpdate / NavStop |
| Calls | `TelephonyManager` / `InCallService`, `TelecomManager.acceptRingingCall()` | CallState, CallCommand |
| Music | `MediaSessionManager` + `MediaController.TransportControls` | MediaState, MediaCommand |
| Notifications | `NotificationListenerService` | Notification |
| Time | `System.currentTimeMillis()`, `TimeZone` | TimeSync |
| Phone status | `BatteryManager`, `TelephonyManager.signalStrength` | PhoneStatus |
| Bike data in app | subscribe to a TX "vehicle status" message (future) | — |
| Emergency contacts / SOS | app gets crash flag (future message) → SMS + location | — |
| Charging stations | Places API / OCM (Open Charge Map) → navigation destination | — |
| Documents | store in app; show QR on cluster when stopped (future) | — |
