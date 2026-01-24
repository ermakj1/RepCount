# RepCount

A cross-platform workout rep counter for iOS, Apple Watch, and Android.

## Features

- Set target reps per set and total rep goal
- Configurable rest timer between sets
- Progress tracking with visual indicator
- Elapsed time display during workout
- Workout summary with total reps, duration, and sets
- Screen stays on during workout
- Settings persistence

## Platforms

| Platform | Status | Location |
|----------|--------|----------|
| iOS | ✅ Complete | `RepCount/` |
| watchOS | ✅ Complete | `RepCount Watch Watch App/` |
| Android | ✅ Complete | `RepCountAndroid/app/` |
| Wear OS | ✅ Complete | `RepCountAndroid/wear/` |

## iOS/watchOS

Open `RepCount.xcodeproj` in Xcode.

**Requirements:**
- Xcode 15+
- iOS 17+ / watchOS 10+

## Android

Open `RepCountAndroid/` folder in Android Studio.

**Requirements:**
- Android Studio Hedgehog+
- Android 8.0+ (API 26)

**Build & Run:**
1. Open Android Studio
2. File → Open → select `RepCountAndroid` folder
3. Wait for Gradle sync
4. Click Run (▶️)

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

## Sync (iOS ↔ watchOS)

- Settings automatically sync from iPhone to Watch
- Completed workouts sync from Watch to iPhone history
- Use "Sync to Watch" button on iPhone to push settings
