 ______   ____   _      ____    ____   ______   _   _   ______
|  ____| / __ \ | |    / __ \  / __ \ |  ____| | \ | | |  ____|
| |__   | |  | || |   | |  | || |  | || |__    |  \| | | |__
|  __|  | |  | || |   | |  | || |  | ||  __|   | . ` | |  __|
| |____ | |__| || |___| |__| || |__| || |____  | |\  | | |____
|______| \____/ |______\____/  \____/ |______| |_| \_| |______/

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
**Solo Gainz** هو تطبيق فلاتر يدمج بين التدريب اليومي والقتال في عالم ألعاب ممتع. اكسب نقاط خبرة، افتح صناديق، وطور شخصيتك مع كل تمرين تكمله.

### لماذا هذا التطبيق؟
- التمارين الحقيقية تؤثر على قوة شخصيتك في اللعبة
- يعمل بالكامل بدون حساب، محليًا على الجهاز
- الخصوصية محمية، دون مزامنة عبر السحابة
- تجربة لعب تجمع بين اللياقة والقتال

> ⚠️ ملاحظة: مجلد `build/` مستبعد من GitHub باستخدام `.gitignore`. يتم حفظ ملفات المصدر والأصول والوثائق فقط.

---

## الميزات

### 🏋️ اللياقة والتقدم
- إنشاء وتعديل وإكمال مهام اللياقة اليومية
- اكسب XP وذهب وارتقِ في رتبتك
- تتبع السجلات والأداء الأسبوعي
- تذكيرات يومية للحفاظ على الاستمرارية

### ⚔️ القتال والزنازين
- ساحة قتالية ثنائية الأبعاد مع فيزياء واقعية
- اركل، اضرب، اقفز، وتجنب الهجمات
- قتال ضد نسخة ذكية تتعلم أسلوبك
- وضع PVP محلي عبر الشبكة للأصدقاء القريبين

### 🎁 المكافآت والتطوير
- افتح صناديق غنائم من درجات مختلفة
- اشترِ تعزيزات وأزياء ومفاتيح
- اكسب الإنجازات والبطولات
- طور ملفك الشخصي وإحصائياتك

---

## الشاشات

| الشاشة | الغرض |
|---|---|
| `SplashScreen` | بدء التطبيق والتهيئة |
| `HomeScreen` | لوحة التحكم والإحصائيات |
| `QuestScreen` | إدارة مهام اللياقة اليومية |
| `DungeonScreen` | اختيار نمط التدريب أو الحملة |
| `ShopScreen` | شراء التعزيزات والأزياء والصناديق |
| `InventoryScreen` | مراجعة العناصر والمكافآت |
| `OpenScreen` | فتح الصناديق وعرض المكافآت |
| `ProfileScreen` | إحصائيات اللاعب وتخصيصه |
| `HistoryScreen` | متابعة التقدم والتاريخ |
| `SettingsScreen` | إعدادات التطبيق |
| `OnboardingScreen` | شرح التشغيل الأولي |

---

## البنية

```
lib/
├── engine/              # محرك الفيزياء والقتال
│   ├── combat_engine.dart
│   └── training_engine.dart
├── models/              # نماذج البيانات والتخزين باستخدام Hive
│   ├── achievements.dart
│   ├── storage.dart
│   └── storage.g.dart
├── screens/             # شاشات واجهة المستخدم
├── services/            # الخدمات المساعدة للمنصة
│   ├── notifications.dart
│   └── security_service.dart
├── ui/                  # النمط والتصميم
└── widgets/             # المكونات القابلة لإعادة الاستخدام
```

الأصول/
- `Chests/` — إطارات رسوم متحركة للخزائن
- `Player Model/` — نماذج رسوم متحركة للاعب

---

## التقنيات

| الطبقة | الأدوات |
|---|---|
| الإطار | Flutter 3.x + Dart 3.x |
| التخزين | Hive + Hive Flutter |
| الأمان | flutter_secure_storage |
| التشفير | crypto + encrypt |
| الواجهة | google_fonts + Material Icons |
| الوسائط | image_picker + image_cropper |
| الإشعارات | flutter_local_notifications + timezone |
| الأذونات | permission_handler |
| الشبكات | dart:io TCP sockets |

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

## تحكم اللعبة

- **يمين / يسار** → الحركة
- **القفز** → القفز
- **اللكم / الركل** → الهجوم
- **النقر المزدوج** → الركض / الانقضاض
- **الصندوق** → فتح الغنائم

---

## البناء والنشر

```bash
# وضع التصحيح
flutter run --debug

# إصدار APK لأندرويد
flutter build apk --release

# حزمة App Bundle لمتجر Play
flutter build appbundle --release

# إصدار iOS
flutter build ios --release
```

### أوامر مفيدة

```bash
flutter pub run flutter_launcher_icons
flutter pub run build_runner build
flutter analyze
dart format .
```

---

## التطوير

- استخدم hot reload أثناء التطوير: اضغط `r`
- استخدم hot restart لتحديث الحالة: اضغط `R`
- اجعل الودجات قابلة لإعادة الاستخدام
- ضع خدمات المنصة في `services/`
- احتفظ بمنطق اللعبة في `engine/`

---

## المساهمة

1. Fork المستودع
2. أنشئ فرعًا جديدًا: `git checkout -b feature/your-feature`
3. قم بتثبيت التغييرات
4. ادفع وافتح Pull Request

> 💡 المساهمات مرحب بها باللغتين العربية والإنجليزية.

---

## الترخيص

هذا المشروع مرخّص بموجب **MIT License**.

---

## التواصل

- GitHub: [https://github.com/MDC520/Solo_gainz](https://github.com/MDC520/Solo_gainz)
- Issues: [https://github.com/MDC520/Solo_gainz/issues](https://github.com/MDC520/Solo_gainz/issues)
- Flutter: [https://flutter.dev](https://flutter.dev)
