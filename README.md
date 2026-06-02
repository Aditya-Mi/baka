# Baka

A warm, private journaling app. Write freely — everything stays on your device.

---

## Features

- **Daily journaling** — write entries with mood, tags, location, weather, and photo anchors
- **Streak tracking** — stay consistent with a year-view heatmap and daily streak counter
- **Tag system** — colour-coded tags with per-tag entry filtering
- **Mood insights** — mood chart and tap-through to entries by mood
- **Biometric lock** — protect your journal with fingerprint, PIN, or both
- **Daily reminders** — gentle nudge at your chosen time
- **Custom fonts** — pick your writing font from 6 options
- **Light & dark mode** — warm Aged Paper and Midnight Ink themes
- **Export / import** — full JSON backup and restore
- **OTA updates** — UI and bug fixes delivered silently via Shorebird

## Privacy

No accounts. No cloud. No analytics. No tracking.  
All data lives in SQLite on your device. Photos stay in app storage.  
Biometric credentials never leave your phone.

## Download

Grab the latest APK from [Releases](../../releases/latest).

> Requires Android 6.0+. Install via sideload (enable *Install unknown apps* for your browser or file manager).

## Building from source

```bash
# Prerequisites: Flutter stable, Android SDK

git clone https://github.com/Aditya-Mi/Baka.git
cd Baka
flutter pub get
flutter run
```

## Tech stack

| Layer | Library |
|-------|---------|
| Framework | Flutter |
| State | Riverpod + flutter_hooks |
| Database | SQLite (sqflite) |
| Navigation | go_router |
| Auth | local_auth + flutter_secure_storage |
| Notifications | flutter_local_notifications |
| OTA | Shorebird |

---

*Made for your thoughts.*
