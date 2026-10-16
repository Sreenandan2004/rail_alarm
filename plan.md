# RailAlarm Development Plan & Roadmap

RailAlarm is an offline-first, battery-efficient, location-triggered wake-up companion app for train, bus, and road passengers.

---

## Current Status & Completed Work

### Phase 1: Core Architecture & UI Alignment ✅
- **Visual Design & Theming**: Clean glassmorphic design featuring organic wavy backdrop (`background.jpg`), frosted glass containers, ultra-light headers (`GoogleFonts.urbanist`), and monospace captions (`GoogleFonts.victorMono`).
- **Custom Bottom Navigation**: Pill capsule with circular buttons matching design reference. Active states use solid white circles with dark icons; inactive states use greyed-out icons (`Icons.account_circle` and `Icons.alarm`, without strike-throughs).
- **Multi-Modal Location Support**:
  - Offline station search across 8,000+ Indian Railways stations.
  - Custom location search for road and bus trips (addresses, stops, landmarks) via geocoding.
  - Direct coordinate entry support (latitude, longitude).
- **Center Graphic**: Exact transport asset (`assets/images/bus_railway.png`) centered on the home screen.
- **Alarm Management Screen**: Frosted-glass alarm cards, active tracking toggle, delete support, and author attribution footer (`App Developed by Sreenandan S`).
- **Web & Desktop Compatibility**: Cross-platform support including Microsoft Edge with in-memory persistence fallback for Isar and 64-bit integer JS bounds adjustments.

---

### Phase 2: Adaptive GPS Polling & Battery Engine ✅
- **Dynamic "Safe Sleep" Algorithm**: Implemented dynamic interval computation ($\Delta t_{\text{sleep}} = \frac{D - D_{\text{alarm}}}{V_{\text{max}}}$) in `AdaptiveLocationService`.
- **Distance-Tiered Accuracy**: Tier switching across Far (>50km / Low Power), Approaching (15-50km / Balanced), Near (<15km / High GPS), and Alarm Range.
- **Stationary Traffic Back-off**: Automatically backs off polling intervals to tier maximums when vehicle speed drops below 3 km/h.
- **Configurable Lead Distance**: Multi-modal travel presets for Bus/Car (2 km), Road/Town (5 km), and Express Train (10 km) on home search and alarm cards.
- **Unit Test Coverage**: Comprehensive suite of 11 unit tests covering Haversine formula, ETA calculation, tier classification, and safe-sleep bounds.

---

### Phase 3: Native System Alarm & Arrival Dispatch Engine ✅
- **Dedicated AlarmDispatchService**: Native Android `SET_ALARM` intent handler with structured parameters (`EXTRA_MESSAGE`, `EXTRA_HOUR`, `EXTRA_MINUTES`, `EXTRA_SKIP_UI`, `EXTRA_VIBRATE`).
- **Instant "Test System Alarm" Trigger**: Quick-action test button on each alarm card for travelers to test their phone's clock response anytime.
- **Glassmorphic Arrival Dialog**: Brand-aligned frosted-glass arrival modal displaying location name and arrival notice.
- **Unit Test Coverage**: Unit tests covering native alarm dispatch and test triggers.

---

## Target Development Phases

### Phase 4: Background Resilience & Persistent Trip Status 🛡️
* **Objective**: Keep tracking alive when the phone screen is off and modern Android OS enters deep sleep (Doze Mode).
* **Key Deliverables**:
  1. **Native Permissions Audit**: Configure Android permissions (`SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `ACCESS_BACKGROUND_LOCATION`).
  2. **Live Trip Status HUD**: Persistent status card and notification displaying real-time distance and next check interval (*"34 km to Palakkad • Next check in 8 min"*).
  3. **Battery Optimization Helper**: In-app prompt and guidance to whitelist RailAlarm from aggressive OEM battery savers (Xiaomi, Samsung, OnePlus).

---

### Phase 5: Release Readiness & Platform Polish 🚀
* **Objective**: Production readiness, code cleanup, and distribution audit.
* **Key Deliverables**:
  1. **Release Configuration**: App naming, icons, metadata, and production manifest sanitization.
  2. **Simulated Route Testing**: Verification of the full lifecycle across simulated movement and threshold triggers.
  3. **Codebase & Architecture Documentation**: Final audit of `Design.md` and `Agents.md`.
