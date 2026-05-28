# Solo Gainz

> 🏋️‍♂️ Fitness + RPG + Dungeon Combat in one Flutter app.
> 
> 🚀 Train, collect rewards, open loot, and battle in a rich mobile experience.
> 
> 🔒 Data stays local — no cloud sync required.

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Screens](#screens)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Game Controls](#game-controls)
- [Build & Release](#build--release)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [العربية](#العربية)

---

## Overview

Solo Gainz is a Flutter mobile app that turns fitness into game progression.
Complete daily training quests, earn XP and rewards, open loot chests, and fight in a combat arena.
The app is designed for offline play and stores all data locally on the device.

> ⚠️ Note: the `build/` folder is excluded from GitHub via `.gitignore`.

---

## Features

### 🏋️ Fitness
- Track and complete daily workout quests
- Gain XP, gold, and rank progression
- Weekly performance history and streak tracking
- Daily reminders to stay on track

### ⚔️ Combat
- Real-time 2D combat arena with responsive controls
- Punch, kick, jump, and dodge
- AI clone battles with adaptive behavior
- Local LAN PVP support for nearby multiplayer

### 🎁 Rewards
- Open loot chests with tiered rewards
- Buy boosts, cosmetics, and keys in the shop
- Complete achievements and milestones
- Manage inventory and items

---

## Screens

| Screen | Description |
|---|---|
| `SplashScreen` | App launch and initialization |
| `HomeScreen` | Main dashboard and stats |
| `QuestScreen` | Manage daily workout quests |
| `DungeonScreen` | Enter combat and campaign modes |
| `ShopScreen` | Buy boosts, cosmetics, and chests |
| `InventoryScreen` | View and manage items and rewards |
| `OpenScreen` | Open loot chests and reveal prizes |
| `ProfileScreen` | Player profile, stats, and rank |
| `HistoryScreen` | Progress history and XP charts |
| `SettingsScreen` | App settings and preferences |
| `OnboardingScreen` | First launch tutorial flow |

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
- **Open chest** → collect loot and rewards

---

## Build & Release

```bash
# Debug mode
flutter run --debug

# Android APK
flutter build apk --release

# Android App Bundle
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

- Use hot reload: press `r`
- Use hot restart: press `R`
- Keep widgets reusable and components separate
- Place platform code in `services/`
- Keep game logic inside `engine/`

---

## Contributing

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature`
3. Commit your changes
4. Push and open a pull request

> 💡 Contributions in English and Arabic are welcome.

---

## License

This project is licensed under the **MIT License**.

---

## Contact

- GitHub: [https://github.com/MDC520/Solo_gainz](https://github.com/MDC520/Solo_gainz)
- Issues: [https://github.com/MDC520/Solo_gainz/issues](https://github.com/MDC520/Solo_gainz/issues)

---

## العربية

### نظرة عامة
Solo Gainz هو تطبيق Flutter يجمع بين التدريب اليومي والقتال في لعبة واحدة.
اكمل المهام اليومية، اكسب الخبرة، افتح صناديق الغنائم، وادخل ساحة القتال.

### الميزات

#### 🏋️ اللياقة
- تتبع مهمة اللياقة اليومية وإكمالها
- اكسب نقاط خبرة وذهب وتقدم في الرتب
- تتبع الأداء الأسبوعي والسجلات
- تذكيرات يومية للحفاظ على الاستمرارية

#### ⚔️ القتال
- ساحة قتال ثنائية الأبعاد مع تحكم فوري
- اضرب، اركل، اقفز، وتجنب
- معارك ضد نسخة ذكية تتعلم استراتيجيتك
- دعم PVP عبر الشبكة المحلية

#### 🎁 المكافآت
- افتح صناديق غنائم متعددة المستويات
- اشترِ التعزيزات والأزياء والمفاتيح
- اكمل الإنجازات والمهام الخاصة
- ادير العناصر والمخزون

---

## الشاشات

| الشاشة | الوصف |
|---|---|
| `SplashScreen` | بدء التطبيق والتهيئة |
| `HomeScreen` | لوحة التحكم والإحصائيات |
| `QuestScreen` | إدارة مهام اللياقة اليومية |
| `DungeonScreen` | دخول وضع القتال أو الحملة |
| `ShopScreen` | شراء التعزيزات والأزياء والصناديق |
| `InventoryScreen` | عرض وإدارة العناصر والمكافآت |
| `OpenScreen` | فتح الصناديق وكشف الجوائز |
| `ProfileScreen` | ملف اللاعب والإحصائيات |
| `HistoryScreen` | سجل التقدم والإنجازات |
| `SettingsScreen` | إعدادات التطبيق |
| `OnboardingScreen` | شرح التشغيل الأولي |

---

## التثبيت

### المتطلبات
- Flutter 3.0+
- Dart 3.0+
- Android Studio أو Xcode
- Git

### الإعداد

```bash
git clone https://github.com/MDC520/Solo_gainz.git
cd Solo_gainz
flutter pub get
flutter pub run build_runner build
flutter run
```

---

## الترخيص

هذا المشروع مرخّص بموجب **MIT License**.

---

## تواصل

- GitHub: [https://github.com/MDC520/Solo_gainz](https://github.com/MDC520/Solo_gainz)
- Issues: [https://github.com/MDC520/Solo_gainz/issues](https://github.com/MDC520/Solo_gainz/issues)
