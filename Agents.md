# Agents.md - RailAlarm Development Guide for AI Agents

Welcome to **RailAlarm**, a Flutter-based mobile application crafted for train commuters and long-distance rail passengers. RailAlarm delivers reliable, battery-efficient, location-triggered wake-up alarms to ensure travelers never miss their destination station—even with spotty network coverage, deep sleep, or aggressive OS battery management.

This document serves as the operational guide and project reference for all AI coding agents working on this repository.

---

## 1. Core Principles & Agent Behaviors

1. **Safety & Reliability First**: An alarm that fails to trigger when a user is asleep is a critical defect. All location tracking, wake-lock, and alarm triggering paths must have robust fallbacks (e.g., GPS signal loss fallback to time-based estimation).
2. **Preserve Battery Life**: Continuous high-accuracy GPS on long train journeys drains batteries rapidly. Always implement and adhere to adaptive geofencing and distance-tiered polling intervals.
3. **Offline Resilience**: The app must function seamlessly without active internet once station data or coordinates are loaded. Train journeys frequently traverse cellular dead zones.
4. **Follow Established Conventions**:
   - Write idiomatic Dart according to [Effective Dart](https://dart.dev/effective-dart).
   - Maintain strict null safety and address all `flutter analyze` warnings.
   - Use declarative UI with Flutter widgets and clean architectural separation.
5. **Preserve Documentation**: Keep `Agents.md` and `Design.md` synchronized whenever architectural decisions, dependencies, or conventions change.

---

## 2. Tech Stack & Environment

- **Framework**: Flutter (Channel stable)
- **Language**: Dart (SDK `^3.8.1`)
- **State Management**: Riverpod (`flutter_riverpod` recommended for testability and reactive state)
- **Local Persistence**: `sqflite` / `isar` / `hive` (for offline railway stations and alarm configurations)
- **Geolocation & Sensors**: `geolocator`, `latlong2`
- **Background & Wake Services**: `flutter_local_notifications`, `alarm` / `android_alarm_manager_plus`, `flutter_foreground_task`
- **Audio & Haptics**: `audioplayers` / native alarm stream with volume override and persistent vibration
- **Linting**: `flutter_lints: ^5.0.0` with strict analysis options

---

## 3. Project Structure

The project follows a **Feature-First Clean Architecture**:

```
rail_alarm/
├── android/                   # Native Android configuration & services
├── ios/                       # Native iOS configuration & permissions
├── assets/                    # Audio files, icons, station databases
│   ├── audio/                 # Alarm ringtones
│   └── data/                  # Preloaded station coordinates (JSON/SQLite)
├── lib/
│   ├── main.dart              # Application entrypoint & service initializers
│   └── src/
│       ├── core/              # Shared utilities, theme, constants, error handling
│       │   ├── constants/
│       │   ├── services/      # LocationService, AudioService, NotificationService
│       │   ├── theme/         # Material 3 dark/high-contrast night themes
│       │   └── utils/         # Geo calculations (Haversine formula, ETA)
│       ├── features/          # Feature modules
│       │   ├── alarm/         # Active alarm monitoring, ringing screen, audio control
│       │   │   ├── data/
│       │   │   ├── domain/
│       │   │   └── presentation/
│       │   ├── stations/      # Station search, offline station cache, geo database
│       │   │   ├── data/
│       │   │   ├── domain/
│       │   │   └── presentation/
│       │   └── settings/      # Volume override, lead distance, theme, battery tips
│       └── app.dart           # MaterialApp configuration and routing
├── test/                      # Unit and widget tests
├── Agents.md                  # Agent operating manual & repository guide
└── Design.md                  # Comprehensive system architecture & technical specification
```

---

## 4. Key Development Commands

All agents must execute commands from the root directory (`D:\Development\rail_alarm`):

| Action | Command |
| :--- | :--- |
| **Get Packages** | `flutter pub get` |
| **Run Linter** | `flutter analyze` |
| **Run Unit Tests** | `flutter test` |
| **Run Specific Test** | `flutter test test/path_to_test.dart` |
| **Run Code Generator** *(if using build_runner)* | `dart run build_runner build --delete-conflicting-outputs` |
| **Build Android Debug APK** | `flutter build apk --debug` |

---

## 5. Coding & Testing Standards

### 5.1 Architecture & State Separation
- **Presentation Layer**: UI Widgets, State Notifiers/Controllers, UI state listeners. Avoid direct calls to low-level platform APIs from widgets.
- **Domain Layer**: Pure Dart entities, value objects, and business logic (e.g., distance calculations, alarm trigger conditions). Pure unit tests with zero Flutter dependencies.
- **Data/Infrastructure Layer**: Implementations of repositories, SQLite access, device sensor interfaces, and platform channels.

### 5.2 Background & Platform Channel Rules
- **Foreground Service**: On Android, background tracking requires a persistent foreground service with an active notification (`flutter_foreground_task` or equivalent).
- **Exact Alarm Permissions**: Android 12+ (API 31+) requires `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`.
- **Doze Mode Exemption**: Prompt user to disable battery optimization for RailAlarm so the OS does not throttle location checks while the device is sleeping.
- **Audio Stream**: Use the Alarm audio stream (`STREAM_ALARM`) rather than the Media stream, ensuring the alert rings even if the phone's media volume is muted.

### 5.3 Commit Conventions
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat: add adaptive geofence calculation based on train velocity`
- `fix: handle Android 14 full-screen alarm notification intent`
- `refactor: extract Haversine formula into core geo utils`
- `test: add unit tests for station arrival ETA estimation`
- `docs: update Design.md with audio focus handling strategy`

---

## 6. Agent Workflow & Checklist

When implementing tasks in this codebase:

1. **Review Design.md**: Understand where the feature fits into the overall architecture.
2. **Implement Feature**: Write clean, modular Dart code conforming to repository patterns.
3. **Write Unit/Widget Tests**: Verify edge cases (e.g., negative distance, GPS disabled, missing permissions).
4. **Validate**: Always run `flutter analyze` and `flutter test` before completing a task.
5. **Document**: Update `Design.md` if data schemas, state flows, or hardware assumptions are modified.
