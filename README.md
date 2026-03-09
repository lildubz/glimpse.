# glimpse.

> *one sentence. every day. forever.*

A minimal micro-journal for iOS and Android built with Flutter. No word counts, no prompts you have to follow, no pressure — just one sentence capturing a glimpse of your day, every day.

---

## Features

- **One sentence a day** — write a single glimpse into your day, no more, no less
- **Daily writing prompts** — 10 rotating prompts to spark your thought
- **Streak tracking** — stay consistent and watch your chain grow
- **Entry history** — scroll back through recent days in a clean feed
- **Calendar view** — see every day you wrote, marked with a gold dot
- **Edit anytime** — tap any past entry to update it
- **Swipe to delete** — remove entries with a swipe and confirmation
- **Persisted locally** — everything saved on-device via SharedPreferences, no account needed

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Local storage | `shared_preferences` |
| Calendar | `table_calendar` |
| Platform | iOS & Android |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- Xcode (for iOS)
- Android Studio (for Android)

### Setup

```bash
# Clone the repo
git clone https://github.com/yourusername/glimpse.git
cd glimpse

# Install dependencies
flutter pub get

# Run on iOS simulator
open -a Simulator
flutter run

# Run on Android emulator
# (boot emulator from Android Studio first)
flutter run

# Run on both at once
flutter run -d all
```

---

## Project Structure

```
glimpse/
├── lib/
│   └── main.dart          # entire app — models, screens, widgets
├── ios/
│   └── Runner/
│       └── Info.plist     # CFBundleName set to "glimpse."
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml  # android:label set to "glimpse."
└── pubspec.yaml
```

---

## pubspec.yaml dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  table_calendar: ^3.1.0
```

---

## App Name Note

The internal package name is `glimpse` (Dart identifiers don't allow punctuation). The display name shown on the home screen — `glimpse.` with the dot — is set separately in `Info.plist` (iOS) and `AndroidManifest.xml` (Android).

---

## Design

glimpse. uses a warm editorial dark theme throughout:

- **Background** `#0C0A08` — near-black with a warm undertone
- **Accent** `#C8973E` — aged gold for dates, dots, and highlights
- **Text** `#F0EAE0` — warm cream
- **Typography** — Georgia serif, italic for all entry text

---

## License

MIT — do whatever you want with it.