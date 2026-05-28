01010011 01101111 01101100 01101111  01000111 01100001 01101001 01101110 01111010

   _____   ____   _      ____    ____   ___   _   _   _____
  / ____| / __ \ | |    / __ \  / __ \ / _ \ | \ | | |  __ \
 | (___  | |  | || |   | |  | || |  | | | | ||  \| | | |  | |
  \___ \ | |  | || |   | |  | || |  | | | | || . ` | | |  | |
  ____) || |__| || |___| |__| || |__| | |_| || |\  | | |__| |
 |_____/  \____/ |______\____/  \____/  \___/ |_| \_| |_____/

# Solo Gainz

> 🎮 A hybrid fitness tracker and combat dungeon game.
> 
> 🏋️‍♂️ Train your body, earn rewards, and battle in a retro-style arena.
> 
> 🔐 All data stays locally on your device.

---

## 📌 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Screens](#screens)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Game Controls](#game-controls)
- [Build & Deployment](#build--deployment)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [العربية](#العربية)

---

## Overview

**Solo Gainz** is a Flutter app that turns your fitness routine into a game. Complete daily workout quests, gain XP, open loot chests, and fight in a live combat arena.

### Why this app?
- Real workouts increase in-game power
- Offline-first: no account required
- Local data only, privacy preserved
- Fun combat, progression, and reward loops

> ⚠️ Note: The `build/` folder is excluded from GitHub via `.gitignore`. Only source code, assets, and documentation are committed.

---

## Features

### 🏋️ Fitness & Progression
- Add, edit, and complete daily quests
- Earn XP, gold, and rank progress
- Track streaks and weekly performance
- Receive daily reminder notifications

### ⚔️ Combat & Dungeon
- Live 2D combat arena with physics
- Punch, kick, jump, and dodge attacks
- AI clone battle with adaptive behavior
- Local LAN PVP mode for nearby multiplayer

### 🎁 Rewards & Growth
- Open chests of different tiers
- Shop for boosts, cosmetics, and keys
- Collect achievements and milestones
- Upgrade profile, stats, and avatar

---

## Screens

| Screen | Purpose |
|---|---|
| `SplashScreen` | App startup and initialization |
| `HomeScreen` | Main dashboard and stats |
| `QuestScreen` | Manage daily workout quests |
| `DungeonScreen` | Select training or campaign mode |
| `ShopScreen` | Buy boosts, cosmetics, and chests |
| `InventoryScreen` | Review owned items and rewards |
| `OpenScreen` | Chest opening sequence |
| `ProfileScreen` | Player stats and customization |
| `HistoryScreen` | Track progress and XP history |
| `SettingsScreen` | Configure app preferences |
| `OnboardingScreen` | First launch tutorial flow |

---

## Architecture

```
lib/
├── engine/              # Combat physics and training engine
│   ├── combat_engine.dart
│   └── training_engine.dart
├── models/              # Data models and Hive storage
│   ├── achievements.dart
│   ├── storage.dart
│   └── storage.g.dart
├── screens/             # App screens and UI pages
├── services/            # Platform services and helpers
│   ├── notifications.dart
│   └── security_service.dart
├── ui/                  # Theme and styling
└── widgets/             # Reusable UI components
```

assets/
- `Chests/` — chest animation frames
- `Player Model/` — sprite animations and movement sets

---

## Tech Stack

| Layer | Tools |
|---|---|
| Framework | Flutter 3.x + Dart 3.x |
| Storage | Hive + Hive Flutter |
| Security | flutter_secure_storage |
| Encryption | crypto + encrypt |
| UI | google_fonts + Material Icons |
| Media | image_picker + image_cropper |
| Notifications | flutter_local_notifications + timezone |
| Permissions | permission_handler |
| Networking | dart:io TCP sockets |

---

## Installation

### Requirements
- Flutter 3.0+
- Dart 3.0+
- Android Studio or Xcode
- Git

### Setup

```bash
git clone https://github.com/MDC520/Solo_gainz.git
cd Solo_gainz
flutter pub get
flutter pub run build_runner build
flutter run
```

---

## Game Controls

- **Left / Right** → move
- **Jump** → jump
- **Punch / Kick** → attack
- **Double-tap** → sprint / dash
- **Chest** → open loot and rewards

---

## Build & Deployment

```bash
# Debug mode
flutter run --debug

# Android release APK
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release

# iOS release
flutter build ios --release
```

### Helpful commands

```bash
flutter pub run flutter_launcher_icons
flutter pub run build_runner build
flutter analyze
dart format .
```

---

## Development

- Use hot reload during development: press `r`
- Use hot restart to refresh state: press `R`
- Keep widgets reusable and services separated
- Store platform code in `services/`
- Keep game logic inside `engine/`

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Commit your changes
4. Push and open a pull request

> 💡 Contributions in both English and Arabic are welcome.

---

## License

This project is licensed under the **MIT License**.

---

## Contact

- GitHub: [https://github.com/MDC520/Solo_gainz](https://github.com/MDC520/Solo_gainz)
- Issues: [https://github.com/MDC520/Solo_gainz/issues](https://github.com/MDC520/Solo_gainz/issues)
- Flutter: [https://flutter.dev](https://flutter.dev)

---

## العربية

### نظرة عامة
تطبيق **Solo Gainz** يحول تمارينك اليومية إلى لعبة. أكمل المهام، اكسب الخبرة، افتح الصناديق، وقاتل في ساحة تدريب تفاعلية.

### الميزات
- تتبع مهام اللياقة اليومية
- نظام تقدم ودرجات شخصية
- قتال في ساحة ثنائية الأبعاد
- خزائن غنائم ومكافآت
- وضع تعدد اللاعبين عبر شبكة محلية

### التثبيت
```bash
flutter pub get
flutter pub run build_runner build
flutter run
```

### ملاحظات
- يتم حفظ جميع البيانات محلياً
- مجلد `build/` غير محفوظ في GitHub
- يدعم Android و iOS

---

## الإبداع

> هذه الوثيقة مصممة لتكون مرتبة وجميلة، مع محتوى ثنائي اللغة ومظهر احترافي للمستودع.
