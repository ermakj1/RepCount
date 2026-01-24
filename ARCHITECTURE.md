# RepCount Architecture

A cross-platform workout rep counter app for iOS, watchOS, and Android.

## Overview

RepCount helps users track workout reps with:
- Configurable rep targets and rest periods
- Automatic rest timer between sets
- Progress tracking toward total rep goal
- Elapsed time tracking
- Workout summary with stats

## Platforms

| Platform | Language | UI Framework | Min Version |
|----------|----------|--------------|-------------|
| iOS | Swift | SwiftUI | iOS 17+ |
| watchOS | Swift | SwiftUI | watchOS 10+ |
| Android | Kotlin | Jetpack Compose | API 26 (Android 8.0) |
| Wear OS | Kotlin | Compose for Wear OS | API 30 (Wear OS 3.0) |

## Project Structure

```
RepCount/
├── RepCount/                    # iOS app
│   ├── RepCountApp.swift        # App entry point
│   ├── ContentView.swift        # Main tab navigation
│   ├── CounterView.swift        # Workout UI (Setup, Active, Rest, Summary)
│   ├── WorkoutManager.swift     # State management & timers
│   ├── WatchConnectivityManager.swift  # iPhone-Watch sync
│   ├── Models.swift             # Data models
│   ├── IntervalTimerView.swift  # HIIT/Tabata timer
│   └── HistoryView.swift        # Workout history
│
├── RepCount Watch Watch App/    # watchOS app
│   ├── RepCount_Watch_Watch_AppApp.swift  # App entry point
│   ├── ContentView.swift        # Watch UI (Setup, Active, Rest, Summary)
│   ├── WatchWorkoutManager.swift    # State management & timers
│   └── PhoneConnectivityManager.swift   # Watch-iPhone sync
│
└── RepCountAndroid/             # Android app
    ├── app/src/main/java/com/repcount/android/
    │   ├── MainActivity.kt      # App entry & navigation
    │   ├── WorkoutViewModel.kt  # State management & timers
    │   └── ui/screens/
    │       ├── SetupScreen.kt
    │       ├── ActiveWorkoutScreen.kt
    │       ├── RestTimerScreen.kt
    │       └── SummaryScreen.kt
    │
    └── wear/src/main/java/com/repcount/android/wear/  # Wear OS app
        ├── MainActivity.kt          # App entry & navigation
        ├── WearWorkoutViewModel.kt  # State management & timers
        └── ui/
            ├── Theme.kt
            ├── WearSetupScreen.kt
            ├── WearActiveScreen.kt
            ├── WearRestScreen.kt
            └── WearSummaryScreen.kt
```

## Architecture Patterns

### iOS & watchOS
- **MVVM** with `ObservableObject`
- `@Published` properties for reactive UI updates
- `@EnvironmentObject` for dependency injection
- `Timer` for countdown/elapsed time
- `UserDefaults` for persistence
- `WatchConnectivity` for iPhone-Watch sync

### Android
- **MVVM** with `ViewModel` + `StateFlow`
- Immutable `data class` for UI state
- Kotlin Coroutines for async timers
- `SharedPreferences` for persistence
- Jetpack Compose for declarative UI

### Wear OS
- **MVVM** with `ViewModel` + `StateFlow` (same as Android)
- Compose for Wear OS (`wear.compose.material3`)
- `ScalingLazyColumn` for scrollable content
- Optimized for round displays
- `SharedPreferences` for persistence

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                      User Input                          │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              ViewModel / Manager                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   State     │  │   Timers    │  │ Persistence │     │
│  │  (Published │  │  (Elapsed,  │  │ (UserDefs/  │     │
│  │   /Flow)    │  │   Rest)     │  │  SharedPref)│     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                    UI Layer                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │  Setup   │ │  Active  │ │   Rest   │ │ Summary  │   │
│  │  Screen  │ │ Workout  │ │  Timer   │ │  Screen  │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │
└─────────────────────────────────────────────────────────┘
```

## State Model

All platforms share the same conceptual state:

```
WorkoutState:
  # Setup
  - targetReps: Int          # Reps per set (default: 10)
  - restSeconds: Int         # Rest duration (default: 60)
  - targetTotalReps: Int     # Goal total reps (default: 100)

  # Workout
  - currentScreen: enum      # SETUP | ACTIVE | REST | SUMMARY
  - currentSetNumber: Int    # Current set (1-based)
  - completedSets: [Int]     # Reps per completed set
  - elapsedSeconds: Int      # Total workout time

  # Rest Timer
  - restTimeRemaining: Int   # Countdown seconds

  # Summary
  - summaryTotalReps: Int
  - summaryElapsedTime: Int
  - summarySetsCompleted: Int

  # Computed
  - completedReps: Int       # Sum of completedSets
  - progressPercent: Float   # completedReps / targetTotalReps
  - isGoalComplete: Bool     # completedReps >= targetTotalReps
```

## Screen Flow

```
┌─────────┐     Start      ┌─────────┐    Complete    ┌─────────┐
│  Setup  │ ─────────────▶ │ Active  │ ─────────────▶ │  Rest   │
│         │                │ Workout │      Set       │  Timer  │
└─────────┘                └─────────┘                └─────────┘
     ▲                          │                          │
     │                          │ End                      │ Timer Done
     │                          │ Workout                  │ or Skip
     │                          ▼                          │
     │                    ┌─────────┐                      │
     │◀─── Dismiss ────── │ Summary │ ◀────────────────────┘
                          └─────────┘        (increments set)
```

## iPhone-Watch Sync (iOS/watchOS only)

Uses `WatchConnectivity` framework:

**iPhone → Watch:**
- Settings sync via `sendMessage()` (if reachable) or `updateApplicationContext()` (background)
- Triggered on settings change and via "Sync to Watch" button

**Watch → iPhone:**
- Workout data via `transferUserInfo()` (guaranteed delivery) + `sendMessage()` (if reachable)
- Sent when workout ends

## Key Features

### Screen Stay Awake
- **iOS:** `UIApplication.shared.isIdleTimerDisabled = true`
- **Android:** `WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON`
- Enabled during workout, disabled when returning to setup

### Haptic Feedback
- **iOS:** `UIImpactFeedbackGenerator` (medium/heavy)
- **watchOS:** `WKInterfaceDevice.current().play()` with `WKHapticType`
- **Android:** Not implemented (could use `Vibrator` service)

### Persistence
- Settings saved: targetReps, restSeconds, targetTotalReps
- **iOS/watchOS:** `UserDefaults`
- **Android:** `SharedPreferences`

## Testing

### Android
- **Unit Tests:** `WorkoutViewModelTest.kt` (25 tests)
  - State management, timers, persistence, formatting
  - Uses Robolectric + Coroutines Test
- **UI Tests:** `RepCountUITest.kt` (12 tests)
  - Compose screen rendering and interactions

### iOS/watchOS
- No tests implemented yet

## Dependencies

### iOS/watchOS
- SwiftUI (built-in)
- WatchConnectivity (built-in)
- Combine (built-in)

### Android
- Jetpack Compose (BOM 2024.09.00)
- Material3
- Material Icons Extended
- Lifecycle ViewModel Compose 2.6.1
- Coroutines Test 1.7.3 (test)
- Robolectric 4.11.1 (test)

### Wear OS
- Wear Compose Material3 1.0.0-alpha24
- Wear Compose Foundation 1.4.0
- Wear Compose Navigation 1.4.0
- Lifecycle ViewModel Compose 2.6.1
- Material Icons Extended
