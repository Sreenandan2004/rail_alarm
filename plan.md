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

## Remaining Development Phases

### Phase 2: Adaptive GPS Polling & Battery Engine 🔋
* **Objective**: Ensure the app consumes $< 5\%$ battery over an 8–10 hour journey.
* **Key Deliverables**:
  1. **Dynamic "Safe Sleep" Algorithm**: Compute adaptive polling intervals dynamically based on remaining distance and vehicle velocity:
     $$\Delta t_{\text{sleep}} = \frac{D - D_{\text{alarm}}}{V_{\text{max}}}$$
  2. **Multi-Tier Accuracy Switching**: Use zero-battery cellular tower/network coarse location when $> 15\text{ km}$ away; switch to high-accuracy GNSS only on approach.
  3. **Stationary / Traffic Back-off**: Pause or lengthen polling when vehicle speed drops to $\approx 0\text{ km/h}$ (traffic jams, station halts).
  4. **Configurable Lead Distance**: Allow custom trigger distances (e.g., $2\text{ km}$ for city buses/cars, $5\text{ km} - 10\text{ km}$ for highways and express trains).

---

### Phase 3: The Dedicated Ringer / Wake-Up Screen ⏰
* **Objective**: Provide a sleep-resistant, full-screen UI when the alarm rings.
* **Key Deliverables**:
  1. **Full-Screen Ringing Route**: Match the reference design with *"You are About to Reach"*, destination name, and bottom nav indicator.
  2. **High-Affordance Controls**: Large pill-shaped **SNOOZE** and **STOP** buttons designed for sleepy travelers.
  3. **Smart Snooze Logic**: Cap snooze intervals (e.g., 3 minutes) based on vehicle speed so users don't overshoot their stop.

---

### Phase 4: Audio, Haptics & DND Override Engine 🔊
* **Objective**: Guarantee the alarm awakens deep sleepers even if the phone is set to Silent or Do Not Disturb.
* **Key Deliverables**:
  1. **Hardware Alarm Stream (`STREAM_ALARM`)**: Route alert audio through the system alarm stream rather than media volume.
  2. **Vibration Patterns**: Heavy intermittent pulses that cut through pockets and berths even with earplugs on.
  3. **Gradual Volume Ramp-Up (Crescendo)**: Optional gentle wake-up to avoid startling fellow coach passengers.

---

### Phase 5: Background Resilience & OS Wake Locks 🛡️
* **Objective**: Keep tracking alive when the phone screen is off and the OS enters deep sleep (Doze Mode).
* **Key Deliverables**:
  1. **Persistent Foreground Service**: Android notification displaying real-time distance and ETA (*"34 km to Palakkad • Next check in 8 min"*).
  2. **Screen Wake & Turn-On Intent**: Request `FLAG_TURN_SCREEN_ON` and `FLAG_SHOW_WHEN_LOCKED` so the screen lights up automatically when the threshold is reached.
  3. **Battery Optimization Whitelist Prompt**: One-tap dialog guiding users to exclude the app from aggressive manufacturer battery killers.

---

### Phase 6: Testing, Polish & Release Readiness 🚀
* **Objective**: Field-ready stability and store release.
* **Key Deliverables**:
  1. **Simulated Route Testing**: Mock GPS track playback to verify transitions across all distance tiers.
  2. **Offline Fallback Validation**: Verify operation through simulated complete cellular dead zones.
  3. **Android APK & iOS Release Builds**: Permission audits and production signing.
