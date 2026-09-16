# Mobile bridge (phone side)

The phone does the heavy work (GPS, route, traffic, internet). The cluster only
shows the result. This folder has **reference Kotlin code** for an Android app.

| File | What it does |
|---|---|
| `android/PhoneLinkCodec.kt` | Builds and parses frames. Twin of `src/core/nav/PhoneLinkProtocol.*` |
| `android/GoogleNavMapper.kt` | Converts Google Navigation SDK `NavInfo` / `StepInfo` to our `NavUpdate` |
| `android/NavInfoReceivingService.kt` | Receives the turn-by-turn data feed (about 1 update per second) |
| `android/ClusterBleLink.kt` | BLE (Bluetooth Low Energy) GATT client that writes frames to the cluster |

## Steps to build the app

- Create an Android project (minSdk 26+), add the Google **Navigation SDK for Android** dependency and an API key with Navigation SDK enabled (it is a paid Google Maps Platform product — check pricing and terms).
- Declare `NavInfoReceivingService` in `AndroidManifest.xml` (`<service android:name=".NavInfoReceivingService" android:exported="false" />`).
- After `Navigator` starts guidance call `navigator.registerServiceForNavUpdates(packageName, NavInfoReceivingService::class.java.name, 1)`.
- Ask for `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` and location permissions, scan for the cluster service UUID, then `ClusterBleLink.connect(...)`.
- Forward calls (`TelephonyManager` / `InCallService`), media (`MediaSessionManager`) and notifications (`NotificationListenerService`) with `PhoneLinkCodec.callState / notification` etc.
- Handle `MEDIA_COMMAND` / `CALL_COMMAND` frames from the cluster in `ClusterBleLink.onCommand`.

## Other options

- **Mapbox Navigation SDK** (Android + iOS) gives the same kind of step data (`BannerInstructions`, `RouteProgress`).
- **iOS**: Google Navigation SDK for iOS also has the turn-by-turn data feed; BLE via CoreBluetooth.
- See `docs/09-maps-and-mobile-app.md` for full-map options.
