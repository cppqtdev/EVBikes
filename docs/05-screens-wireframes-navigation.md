# 05 · Screens, wireframes and navigation flow

> **Update:** the UI now follows the wide 1280 × 480 reference design. The current screen list, flow and controls are in `15-ui-design-implementation.md`. The 800 × 480 wireframes below are kept as the original concept.

Design size: **800 × 480** (7-inch landscape). Change `Theme.screenWidth / screenHeight` for other panels.

## Fixed layout zones

```
 x→ 0        100                                   700       800
 y  ┌─────────────────────────────────────────────────────────┐
 16 │ BT ▪ 27°C      ◀  ≡D  ≡D  (!)  (ABS) [+-] ⚲  ▶     1:11pm │  TopStatus + TelltaleBar
 64 ├────┬─────────────────────────────────────────────┬──────┤
    │MAX │                                             │ ×1000│
    │ ▰  │                                             │  ▰   │
    │ ▰  │            CENTRE  (600 × 270)              │  ▰   │  SegmentBar (AMP)  |  SegmentBar (RPM)
    │ ▰  │      one page at a time + overlays          │  ▰   │
    │ ▱  │                                             │  ▱   │
    │AMP │                                             │ RPM  │
332 │    │ RANGE 98 km                   ODO 12356 km  │      │  InfoRow
    │    │ ▮ 82% ████████░░        ██████░░ 34°C 🌡    │      │
412 └────┴──────┐                         ┌────────────┴──────┘
    │ P R N [D]  ➤ │      ECO / SPORTS      │ 🔔  ● ━ ● ●   ⚙ │  BottomBar
480 └──────────────┴────────────────────────┴───────────────────┘
```

## Pages (centre zone)

Left / Right on the joystick cycles pages. The dots in the bottom bar show where you are.

### 0 · Ride (default)
```
┌──────────────────────────────────────────────┐
│                          ___/‾‾‾‾\__          │
│   ╱ 57 ╱ KPH            (o)══════(o)          │
│  (soft accent glow)      ➤ 850 m             │  ← mini turn hint when navigating
└──────────────────────────────────────────────┘
```

### 1 · Navigate
```
┌──────────────────────────────────────────────┐
│ ┃ ↱     850 m                        57       │
│ ┃       Turn right                   KPH      │
│ ┃       MG Road                ETA 9 min      │
│                                  3.4 km to go │
│      ░░░ perspective road grid ░░░            │
│           [ ↑ ][ ↑ ][▣↑]  lane guide          │
└──────────────────────────────────────────────┘
No route → "Start a route in the app" / "Connect your phone to navigate"
```

### 2 · Media
```
┌──────────────────────────────────────────────┐
│ ┌────────┐   NOW PLAYING                      │
│ │   ♫    │   Dandelions                       │
│ │        │   Ruth B.                          │
│ └────────┘   ━━━━━━━━━━░░░░░░░░░              │
│              1:02   ⏮   ⏯   ⏭   3:53          │
└──────────────────────────────────────────────┘
OK = play/pause, Up = next, Down = previous
```

### 3 · Summary
```
┌──────────────────────────────────────────────┐
│                  SUMMARY                      │
│  ┌ Travelled ──────┐  ┌ Fuel savings ───┐     │
│  │ 12356 km        │  │ ₹ 37068         │     │
│  └─────────────────┘  └─────────────────┘     │
│  ┌ Trip ───────────┐  ┌ CO₂ saved ──────┐     │
│  │ 9.0 km          │  │ 556 kg          │     │
│  └─────────────────┘  └─────────────────┘     │
└──────────────────────────────────────────────┘
```

### 4 · Tyre pressure
```
┌──────────────────────────────────────────────┐
│    REAR                          FRONT        │
│   26.5 psi (red if low)        32.0 psi       │
│            (o)══════════(o)                   │
│            Recommended 32 psi                 │
└──────────────────────────────────────────────┘
```

## Overlays (drawn above pages)

| Overlay | Trigger | Dismiss |
|---|---|---|
| **AlertPopup** | `AlertData.popupVisible` (warning / critical) | OK for warnings. **Critical cannot be dismissed** (crash, overheat, system fault, side stand while moving) |
| **CallBanner** | `PhoneData.callStatus != Idle` | OK = answer, Back = reject |
| **NotificationToast** | new notification | auto-hides after 4 s. Message **text only shown when speed = 0** |
| **SettingsPage** | OK on Ride/Nav/Summary/Tyre page, **only when speed ≤ 5 km/h** | Back / Left, or bike starts moving |
| **LockScreen** | `SystemData.locked` at start | correct PIN. 3 wrong tries → locked, unlock from app |
| **SplashScreen** | power on | fades after 1.8 s |

## Alert examples (from the design)

```
┌──────── WARNING ────────┐     ┌──────── WARNING ────────┐
│        (tyre)           │     │        (sos)            │
│   REAR TYRE PSI LOW     │     │    CRASH DETECTED       │
│ Tyre inflation required │     │ SOS sent to emergency   │
│  Press OK to dismiss    │     │ contacts                │
└─────────────────────────┘     └─────────────────────────┘
```

## Navigation flow

```
 Power on
    │
    ▼
 Splash (1.8 s) ──► Lock screen ──(PIN ok)──► Ride page
                        │                         │  ◀ Left / Right ▶
                        │ 3 wrong                 ▼
                        ▼                  Ride ⇄ Navigate ⇄ Media ⇄ Summary ⇄ Tyre ⇄ (Ride)
                  "Bike locked,                    │
                   unlock from app"                │ OK (speed ≤ 5)
                                                   ▼
                                               Settings
                                   Theme · Brightness · Clock · Demo
                                                   │ Back / moving
                                                   ▼
                                               last page

 Any time: alert → AlertPopup on top · call → CallBanner on top · M key → next demo scenario
```

## Button map (5-way switch)

| Button | Short press | Long press |
|---|---|---|
| Left / Right | previous / next page | — |
| Up / Down | media next / previous, menu move, PIN digit | — |
| OK | open settings, play/pause, answer call, dismiss warning | — |
| Back | close menu, reject call, go to Ride page | — |
| Mode | (VCU handles ride mode) | next demo scenario (desktop: M key) |

## Menu tree (roadmap, from the task-flow diagram)

```
Settings
├── Display: Theme (Day/Night) · Brightness (manual/auto) · Speedo style · Clock format · Time zone
├── Connectivity: Bluetooth pairing · Phone info · Notifications on/off · Quick replies
├── Navigation: Favourites · Offline maps (Pattern C)
├── Motorcycle status: Tyre pressure · Power use · Range · Battery temp · Error codes
├── Documents: Registration / insurance (view only when stopped)
├── Accessibility: Font size · Language · Units (km / miles)
└── General: Bike info · Software update (OTA) · Factory reset
```
Implemented now: Theme, Brightness, Clock format, Demo mode.
