# Solo Gainz

> 🏋️‍♂️ Fitness + RPG + Dungeon Combat in one Flutter app.
>
> 🚀 Train, collect rewards, open loot, and battle in a polished mobile experience.
>
> 🔒 Offline-first design: all user data is stored locally.

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Screens](#screens)
- [Mechanics](#mechanics)
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

Solo Gainz is a Flutter mobile app that blends fitness habit tracking with RPG-style progression and action combat.
Complete daily training quests to earn XP, coins, ranks, and loot chests, then enter engaging combat and campaign modes.
All progress is saved locally on the device using Hive storage.

> ⚠️ Note: the `build/` folder is excluded from GitHub via `.gitignore`.

---

## Features

### 🏋️ Fitness
- Track and complete daily workout quests
- Add custom exercises and habit goals
- Gain XP, gold, and rank progression
- Weekly performance history and streak monitoring
- Daily reminder scheduling using local notifications

### ⚔️ Combat
- Immersive 2D training arena with real-time controls
- Punch, kick, jump, run, grab, push, and pull
- Physics-driven clone opponent with hit detection
- Local LAN PVP lobby and socket-based nearby multiplayer

### 🎁 Rewards
- Tiered loot chests with randomized coin rewards
- Drag-and-drop inventory management in the Vault
- Premium coin shop and instant purchase bundles
- Achievements, milestones, and rank titles

---

## Screens

### Main App Flow

- `SplashScreen`
  - App startup, initial data loading, and onboarding gating.

- `OnboardingScreen`
  - First-time setup: choose a player name, avatar, notification schedule, and starting exercises.
  - Create custom quests and save the initial daily training template.

- `HomeScreen`
  - Main dashboard with current player stats, rank title, avatar, and interactive guidance bubbles.
  - Displays weekly progress, quest completion status, vault access, and profile shortcuts.

- `QuestScreen`
  - Daily quest management and progress tracking.
  - Automatically refreshes quests on a new day, supports custom and template quests, and awards XP when completed.
  - Updates lifetime stats and achievement progress.

- `DungeonScreen`
  - Gateway to combat content: training mode and PVP mode.
  - Shows campaign stages, arena combo visuals, and entry points for gameplay.

- `TrainingScreen`
  - Immersive landscape combat training with `TrainingEngine` physics.
  - Control movement, sprint (double-tap), jump, punch, kick, and box interaction.
  - Includes collision-based damage, clone enemy reactions, and debug collider editing.

- `StoryScreen`
  - Campaign chapters and narrative stages.
  - Sequential stage unlocking, story progression tracking, and rewards like XP, coins, and chests.

- `ShopScreen`
  - Buy chests using earned gold coins.
  - Opens a confirmation flow, checks inventory slots, and deducts currency.
  - Includes links to the `BuyScreen` coin bundle shop.

- `BuyScreen`
  - Premium-style coin bundles for fast progression.
  - Adds virtual coins directly to the player wallet.

- `InventoryScreen`
  - Vault-style chest inventory and slot management.
  - Timers refresh chest unlock status every second.
  - Supports drag-and-drop reordering, unlock, skip, and open actions.

- `OpenScreen`
  - Animated chest reveal with reward generation based on chest tier.
  - Claim coins and remove the chest from inventory.

- `ProfileScreen`
  - Player profile view with avatar photo picker, rank title, level, XP, currency, and achievements.
  - Access to settings and logout functionality.

- `HistoryScreen`
  - Weekly quest completion history and streak review.
  - Shows up to several past weeks using daily progress squares.

- `SettingsScreen`
  - Theme selection, navigation mode, notifications, and app preferences.
  - Choose floating or normal bottom navigation and configure daily reminder time.

- `EngineScreen`
  - Developer-facing combat engine inspector.
  - Frame-by-frame animation preview and collider editor for player, punch, kick, box, clone, and clone attacks.

- `PvpScreen`
  - Local multiplayer lobby for hosting and browsing nearby games.
  - Uses UDP discovery and TCP sockets to connect devices over LAN.
  - Includes join code generation from local IP and a 60 FPS local game loop.

---

## Mechanics

### Daily Quest System
- Uses `Storage` to persist daily templates, quests, and quest history.
- `QuestScreen` generates fresh quests on a new day using `lastDailyRefresh`.
- Quests support `reps` or `timer` systems and track `currentProgress`, `maxGoal`, and completion state.
- Completing quests awards XP, updates lifetime stats, and can unlock achievements.

### Rank & XP
- Player XP is earned from quest completion and story stage rewards.
- `RankSystem` controls quest reward scaling and maximum reps per rank/level.
- Level and rank are persisted in local storage and reflected in `ProfileScreen` titles.

### Chests & Vault
- Chest types include `wooden`, `iron`, `gold`, and `mysterious`.
- Each chest tier has a probability distribution for coin payouts and rare jackpot outcomes.
- `ShopScreen` purchases chests by cost and requires free inventory slots.
- `InventoryScreen` handles locked, unlocking, and openable states with timers and skip options.
- `OpenScreen` animates the reward reveal and adds coins to the player balance.

### Combat Engine
- `TrainingEngine` handles movement, running, jumping, gravity, friction, and world bounds.
- Attack collision detection uses `CombatData` frame collider metadata for `Punch01` and `Kick01` impact frames.
- Physics also supports box grabbing, pushing, pulling, and environmental collisions.
- Clone enemy behavior includes hit, knockback, recovery, and reactive attacks.
- `TrainingScreen` offers debug visualization of hitboxes and a collider editor for balancing.

### Local Multiplayer (PVP)
- `PvpScreen` can host or join nearby matches using local network discovery.
- Hosts advertise rooms over UDP and players join via generated join codes.
- The PVP module simulates two-player combat with shared controls, damage numbers, and local network sockets.

### Notifications & Services
- `NotificationService` schedules daily training reminders and chest unlock alerts.
- Settings allow permission requests, enabling/disabling reminders, and choosing reminder time.
- Profile picture selection and storage are handled with local file persistence.

### Storage
- Uses Hive and secure storage for user stats, quests, inventory, story progress, achievements, and settings.
- All app data is fully local and offline-ready.

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
- **Tap chest slots** → unlock / open rewards

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
Solo Gainz هو تطبيق Flutter يجمع بين تتبع اللياقة والقتال بطريقة RPG.
اكمل المهام اليومية لكسب الخبرة والذهب والصناديق، ثم ادخل ساحة القتال لتدريب مهاراتك.
كل التقدم يخزن محليًا على الجهاز.

### الميزات

#### 🏋️ اللياقة
- تتبع المهام اليومية ومراقبة التقدم
- إضافة مهام مخصصة وجلسات تمارين جديدة
- ربح XP وذهب وتقدم في الرتب
- عرض الأداء الأسبوعي وتتبع الاستمرارية
- تذكيرات يومية محلية

#### ⚔️ القتال
- وضع تدريب 2D مع تحكمات فورية
- اضرب، اركل، اقفز، اجرِ، امسك، ادفع، واسحب
- محاكاة فيزيائية للخصم المستنسخ وضربات تعتمد على الكوليدر
- دعم PVP محلي عبر الشبكة المحلية

#### 🎁 المكافآت
- فتح صناديق غنائم متعددة المستويات
- إدارة المخزون عن طريق السحب والإفلات
- شراء وحدات عملات بسرعة من المتجر
- إنجازات وترقيات وألقاب شخصية

---

## الشاشات

- `SplashScreen`
  - بداية التطبيق وتحميل البيانات والتهيئة.

- `OnboardingScreen`
  - واجهة البداية لاختيار اسم اللاعب، الصورة الرمزية، وتنظيم التذكيرات.
  - إنشاء مهام يومية مبدئية ومهام مخصصة.

- `HomeScreen`
  - لوحة معلومات رئيسية تعرض الإحصائيات الحالية، التقدم، والرؤية الأسبوعية.
  - وصول سريع إلى المخزون والملف الشخصي.

- `QuestScreen`
  - إدارة المهام اليومية ومتابعة التقدم.
  - تجديد المهام تلقائيًا عند بدء يوم جديد.
  - يمنح خبرة عند الإكمال ويحدث الإنجازات.

- `DungeonScreen`
  - بوابة القتال إلى وضع التدريب وPVP.
  - يعرض الخيارات السردية وأسلوب اللعب.

- `TrainingScreen`
  - تدريب قتالي واقعي في الوضع الأفقي.
  - تحكم بالجري، القفز، اللكم، الركل، ودفع/سحب الصناديق.
  - يتضمن محرر تصادم وتصحيح الكوليدر.

- `StoryScreen`
  - فصول القصة ومراحل الحملة.
  - تقدم متسلسل ومكافآت XP وذهب وصناديق.

- `ShopScreen`
  - شراء الصناديق بالذهب.
  - تأكيد الشراء ومراقبة سعة المخزون.

- `BuyScreen`
  - شراء رزم العملات الافتراضية بسرعة.

- `InventoryScreen`
  - خزانة الصناديق وإدارة الفتح.
  - دعم السحب والإفلات، والتخطي، وفتح الصناديق.

- `OpenScreen`
  - فتح الصندوق وعرض المكافآت المتولدة.
  - استلام العملات وإزالة الصندوق من المخزون.

- `ProfileScreen`
  - عرض ملف اللاعب، الصورة الرمزية، الترتيب، والإنجازات.
  - الوصول إلى الإعدادات وتحديث البيانات.

- `HistoryScreen`
  - سجل الأسبوع، إكمال المهام، والاستمرارية.

- `SettingsScreen`
  - تبديل الثيم، وضع التنقل، وتنبيهات التذكير.

- `EngineScreen`
  - أداة فحص محرك القتال وإدارة كوليدرات الإطارات.

- `PvpScreen`
  - لبيئة اللعب الجماعي المحلي عبر الشبكة.
  - استضافة والانضمام إلى مباريات قريبة.

---

## الآليات

### نظام المهام اليومية
- يحفظ القوالب والمهام وسجل الإكمال محليًا.
- `QuestScreen` يُجدد المهام يوميًا باستخدام `lastDailyRefresh`.
- يدعم نظام `reps` و `timer` وتتبع التقدم والإنجاز.
- يكسب XP عند الإكمال ويحدث الإحصائيات الدائمة.

### الرتب وXP
- يحصل اللاعب على XP من المهام ومكافآت قصة المراحل.
- يتحكم `RankSystem` بمكافآت المهام وأقصى التكرارات لكل رتبة.
- يتم حفظ المستوى والرتبة محليًا ويعرضان في الملف الشخصي.

### الصناديق والخزنة
- تشمل أنواع الصناديق: `wooden`, `iron`, `gold`, `mysterious`.
- لكل صندوق احتمالات خاصة بالمكافأة ومعدلات الجوائز.
- `ShopScreen` يشتري الصناديق بالذهب ويتحقق من أماكن المخزون.
- `InventoryScreen` يدير حالات القفل والفتح والتخطي.
- `OpenScreen` يعرض المكافآت ويوفر العملات عند الاستلام.

### محرك القتال
- `TrainingEngine` يدير الحركة، الجري، القفز، الجاذبية، والاحتكاك.
- تعتمد ضربات اللكم والركل على بيانات الكوليدر في إطار التأثير.
- يدعم الإمساك بالصناديق، الدفع، السحب، وتصادم الكائنات.
- يتضمن خصمًا مستنسخًا مع ردود فعل إصابة وصدمة.
- يوفر `TrainingScreen` عرضًا وتصحيحًا للكوليدرات.

### اللعب الجماعي المحلي (PVP)
- `PvpScreen` يستضيف أو ينضم إلى مباريات قريبة عبر الشبكة المحلية.
- يعلن المضيف غرفًا باستخدام UDP وتنضم الأجهزة عبر كود الاتصال.
- يعمل المحرك المحلي بدقة 60 إطارًا في الثانية.

### الإشعارات والخدمات
- `NotificationService` يجدول تذكيرات التدريب اليومية وتنبيهات فتح الصناديق.
- تتيح الإعدادات طلب إذن الإخطارات وتحديد وقت التذكير.
- يتم حفظ صورة الملف الشخصي وبياناتها محليًا.

### التخزين
- يستخدم Hive وflutter_secure_storage لحفظ البيانات المحلية.
- يخزن إحصائيات المستخدم والمهام والمخزون والقصة والإنجازات والإعدادات.
- يعمل التطبيق بالكامل دون اتصال.

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

## ضوابط اللعبة

- **يسار / يمين** → التحرك
- **القفز** → القفز
- **اللكم / الركل** → الهجوم
- **النقر المزدوج** → الركض / التسارع
- **نقر فتح الصندوق** → استلام الغنائم

---

## البناء والإصدار

```bash
# وضع التصحيح
flutter run --debug

# ملف APK لأندرويد
flutter build apk --release

# حزمة التطبيق لأندرويد
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

- استخدم hot reload: اضغط `r`
- استخدم hot restart: اضغط `R`
- اجعل الودجت قابلة لإعادة الاستخدام ومقسمة
- ضع كود النظام الأساسي في `services/`
- احتفظ بالمنطق الخاص باللعبة داخل `engine/`

---

## المساهمة

1. فرع المشروع
2. أنشئ فرعًا: `git checkout -b feature/your-feature`
3. قم بالتزام التغييرات
4. ادفع وابدأ طلب سحب

> 💡 المساهمات بالإنجليزية والعربية مرحب بها.

---

## الرخصة

هذا المشروع مرخَّص بموجب **MIT License**.

---

## التواصل

- GitHub: [https://github.com/MDC520/Solo_gainz](https://github.com/MDC520/Solo_gainz)
- القضايا: [https://github.com/MDC520/Solo_gainz/issues](https://github.com/MDC520/Solo_gainz/issues)
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
