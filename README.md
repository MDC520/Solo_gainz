<!-- ─── SOLO GAINZ ─────────────────────────────────────────────────────── -->

<br>

```
   ▄████████  ▄██████▄   ▄█          ▄████████       ▄████████ ▄██   ▄      ▄████████ ███▄▄▄▄   
  ███    ███ ███    ███ ███         ███    ███      ███    ███ ███   ██▄   ███    ███ ███▀▀▀██▄ 
  ███    █▀  ███    ███ ███         ███    █▀       ███    ███ ███▄▄▄███   ███    █▀  ███   ███ 
  ███        ███    ███ ███        ▄███▄▄▄         ▄███▄▄▄▄██▀ ▀▀▀▀▀▀███  ▄███▄▄▄     ███   ███ 
  ███        ███    ███ ███       ▀▀███▀▀▀        ▀▀███▀▀▀▀▀   ▄██   ███ ▀▀███▀▀▀     ███   ███ 
  ███    █▄  ███    ███ ███         ███    █▄       ███    ███ ███   ███   ███    █▄  ███   ███ 
  ███    ███ ███    ███ ███▌    ▄   ███    ███      ███    ███ ███   ███   ███    ███ ███   ███ 
  ████████▀   ▀██████▀  █████▄▄██   ██████████      ███    █▀   ▀█████▀    ██████████  ▀█   █▀  
                        ▀                                                                       
```

<p align="center">
  <strong>A hybrid fitness tracker and combat dungeon game.</strong><br>
  <em>Train your body. Level up your character. Conquer the dungeon — all in one app.</em>
</p>

<br>

---

## 📋 Table of Contents
- [Overview](#-overview)
- [Features](#-features)
- [Screenshots & Demo](#-screenshots--demo)
- [Quick Start](#-quick-start)
- [Screens](#-screens)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Installation](#-installation)
- [Game Controls](#-game-controls)
- [Building & Deployment](#-building--deployment)
- [Development](#-development)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

---

## ✦ Overview

**Solo Gainz** is a Flutter mobile app that gamifies your fitness journey. Complete daily quests, earn XP and gold, open loot chests, and take your character into a real-time combat training arena. The more you train in real life, the stronger your in-game avatar becomes.

### 🔒 Privacy First
All data is stored **100% locally on-device** — no account needed, no cloud sync, full privacy.

### 🎮 Game Philosophy
- **Reward real fitness** — Your workouts directly improve your character's stats
- **No pay-to-win** — All content accessible through normal gameplay
- **Solo experience** — Play entirely offline or compete with friends via LAN
- **Pixel-perfect UI** — Retro aesthetic with modern UX

---

## ✦ Features

### 🏋️ Fitness Tracking
| Feature | Description |
|---|---|
| **Daily Quests** | Add, edit, complete, and track custom daily workout goals |
| **Weekly Progress** | 7-day streak calendar with visual history (up to 3 weeks) |
| **XP & Leveling** | Gain XP from quests, level up your character rank |
| **Rank System** | Ascend from E → D → C → B → A → S → SS rank |
| **Notifications** | Daily reminders to keep your streak alive |
| **Statistics** | Track XP earned, quests completed, streak data |

### ⚔️ Combat Dungeon
| Feature | Description |
|---|---|
| **Training Arena** | Real-time 2D physics engine — run, jump, punch, kick |
| **Clone Battle** | Fight an AI-driven clone with dynamic combos |
| **Collider Editor** | Debug and edit hitbox frames in real-time during training |
| **PVP Mode** | Local LAN multiplayer via TCP — host a room or join over WiFi |
| **Story Campaign** | Chapter-based boss fights with escalating difficulty |
| **24+ Animations** | Idle, Walk, Run, Jump, Punch (3 types), Kick (3 types), Hit, Roll, Slide, and more |

### 🎒 Progression Systems
| Feature | Description |
|---|---|
| **Loot Chests** | Wooden, Iron, Gold, and Mysterious chest tiers with open animations |
| **Shop & Premium** | Buy boosts, cosmetics, chests with in-game gold and gems |
| **Inventory** | View and manage all owned items, keys, and chests |
| **Achievements** | Built-in achievement system tracking milestones |
| **Profile** | Custom avatar, username, goals, and stats screen |

### 🎨 Design
- **Dark-first UI** with toggleable light/dark theme
- **Pixel-art sprite animations** — frame-by-frame PNG animation system
- **Cyberpunk aesthetic** — neon accents, grid overlays, glowing gradients
- **Responsive layout** — adapts to phones and tablets

---

## ✦ Screenshots & Demo

| Screen | Description |
|---|---|
| **Home** | Dashboard with stats, daily quests, and weekly streak calendar |
| **Combat Arena** | Real-time 2D training with physics-based combat |
| **Shop** | Buy cosmetics, chests, and premium items |
| **Inventory** | Manage items, chests, and rewards |
| **Profile** | Avatar customization and character stats |
| **PVP** | Local LAN multiplayer fights |

---

## ✦ Quick Start

```bash
# Clone the repository
git clone https://github.com/MDC520/Solo_gainz.git
cd Solo_gainz

# Install dependencies
flutter pub get

# Run the app on a connected device or emulator
flutter run

# Watch for changes during development
flutter run --verbose
```

---

## ✦ Screens

| Screen | Purpose |
|---|---|
| `SplashScreen` | Animated loading with system initialization |
| `HomePage` | Dashboard — stats panel, weekly calendar, weekend dialogue |
| `QuestPage` | Daily quest list — add, edit, check-off, delete, reorder |
| `DungeonPage` | Mode select — Training, Story Campaign, PVP Arena |
| `TrainingScreen` | Real-time 2D arena with clone AI + collider debug editor |
| `EngineScreen` | Combat engine configuration and frame-data inspector |
| `StoryScreen` | Chapter-based boss campaign with stages |
| `PvpScreen` | LAN lobby (host/browse) + real-time 2-player fighting |
| `ShopScreen` | Boosts, Premium, Cosmetics, Chests tabs |
| `BuyScreen` | Purchase flow for gold/gem packs |
| `InventoryScreen` | All items, keys, chests grid |
| `OpenScreen` | Chest-opening animation with rewards |
| `ProfileScreen` | Avatar, rank, stats, goals, settings access |
| `HistoryScreen` | Weekly progress history with XP charts |
| `SettingsScreen` | Theme toggle, data management, about |
| `OnboardingScreen` | First-launch tutorial flow |

---

## ✦ Architecture

```
lib/
├── engine/              # Game physics & combat engine
│   ├── combat_engine.dart    # Frame data, colliders, helpers
│   └── training_engine.dart  # Training mode AI and state machine
├── models/              # Data models & storage
│   ├── achievements.dart     # Achievement definitions and logic
│   ├── storage.dart          # Hive-based local storage wrapper
│   └── storage.g.dart        # Auto-generated Hive adapter
├── screens/             # 16 UI screens (see table above)
├── services/            # Platform services
│   ├── notifications.dart    # Local push notification scheduling
│   ├── profile_image_crop.dart  # Avatar image cropping
│   └── security_service.dart    # Encryption / secure storage
├── ui/                  # Design system
│   ├── theme.dart            # AppTheme — colors, typography, text styles
│   └── responsive.dart       # Screen-size breakpoints utilities
├── widgets/             # Reusable components
│   ├── background.dart       # Animated scrolling background painter
│   ├── chest.dart            # Animated loot chest widget
│   ├── player.dart           # Pixel-art sprite animation player
│   └── weekly_day_square.dart  # Calendar day tile
└── main.dart            # App entry point, init, navigation shell

assets/
├── Chests/              # Loot chest animation frames
│   ├── Wooden Chest/
│   ├── Iron Chest/
│   ├── Gold Chest/
│   └── Mysterious Chest/
└── Player Model/        # 24+ character animation sets
    ├── Idle/
    ├── Walk/
    ├── Run/
    ├── Jump/
    ├── Punch01-03/
    └── ... (20+ more animations)
```

---

## ✦ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x + Dart 3.x |
| **Local Storage** | Hive + Hive Flutter |
| **Secure Storage** | flutter_secure_storage |
| **Encryption** | `crypto` + `encrypt` packages |
| **Typography** | Google Fonts (Press Start 2P, Outfit, Space Mono) |
| **Icons** | Material Design Icons |
| **Notifications** | flutter_local_notifications + timezone |
| **Image Picking** | image_picker + image_cropper |
| **Permissions** | permission_handler |
| **Networking** | Raw TCP/UDP sockets (dart:io) for LAN PVP |
| **State Management** | Flutter setState + ValueNotifier + Hive listeners |
| **Animation** | Flutter Ticker + AnimationController |
| **Physics** | Custom 2D physics engine |

---

## ✦ Installation

### Prerequisites
- **Flutter** 3.0.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart** 3.0.0+ (comes with Flutter)
- **Android Studio** or **Xcode** for device/emulator
- **Git** for version control

### Step-by-Step

```bash
# 1. Clone the repository
git clone https://github.com/MDC520/Solo_gainz.git
cd Solo_gainz

# 2. Install dependencies
flutter pub get

# 3. Run code generation (for Hive adapters)
flutter pub run build_runner build

# 4. Run the app
flutter run

# 5. (Optional) Run with verbose logging
flutter run --verbose
```

### Platform-Specific Notes

#### Android
- Minimum SDK: API 21+
- Requires permissions: CAMERA, SCHEDULE_EXACT_ALARM, POST_NOTIFICATIONS
- Secure storage uses Android Keystore

#### iOS
- Minimum deployment target: iOS 11.0+
- Requires permissions: Camera
- Secure storage uses Keychain

> **Note:** The app is designed for mobile (Android/iOS). Desktop/web may have limited functionality due to platform-specific plugins (secure storage, notifications, TCP sockets).

---

## ✦ Game Controls (Training / PVP)

```
┌─────────────────────────────────────────────────┐
│                      ARENA                      │
│                                                 │
│                  ╔═══════════╗                  │
│                  ║  PLAYER   ║                  │
│                  ╚═══════════╝                  │
│                                                 │
│  ◄──── ────►                                    │
│  Left   Right     Punch Kick Jump               │
│                                                 │
│  • Double-tap Left/Right = Sprint / Run         │
│  • Punch/Kick during run = special attack       │
│  • Jump + Punch = aerial attack                 │
└─────────────────────────────────────────────────┘
```

### Combat System
- **Hit Detection**: Frame-by-frame collider checking
- **Damage Scaling**: Combos deal increasing damage
- **Knockback**: Physics-based collision responses
- **AI Behavior**: Clone mimics player movements with slight delays

---

## ✦ Building & Deployment

### Debug Build
```bash
flutter run --debug
```

### Release Builds

#### Android APK
```bash
flutter build apk --release

# Output: build/app/outputs/flutter-app.apk
```

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS IPA
```bash
flutter build ios --release

# Output: build/ios/iphoneos/Runner.app
# Use Xcode to archive and export for App Store or Ad Hoc distribution
```

### Icon Generation
```bash
flutter pub run flutter_launcher_icons
```

### Code Generation
```bash
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch
```

---

## ✦ Development

### Hot Reload
During development, use hot reload to see changes instantly:

```bash
# In the running app's terminal, press 'r'
r           # Hot reload (maintains app state)
R           # Hot restart (clears state)
q           # Quit
```

### Project Structure Best Practices
- **Keep screens isolated**: Each screen should be self-contained
- **Reuse widgets**: Place common UI components in `widgets/`
- **Service layer**: Platform integrations go in `services/`
- **Model separation**: Business logic in `models/`, UI state in screens

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/storage_test.dart

# Run with coverage
flutter test --coverage
```

### Code Analysis
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/

# Fix common issues
dart fix --apply
```

---

## ✦ Contributing

Contributions are welcome! To contribute:

1. **Fork** the repository
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit changes** (`git commit -m 'Add amazing feature'`)
4. **Push to branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

---

## ✦ License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

You are free to:
- ✓ Use this project commercially
- ✓ Modify and distribute
- ✓ Use privately

---

## ✦ Contact

**Created by:** MDC520  
**Repository:** [https://github.com/MDC520/Solo_gainz](https://github.com/MDC520/Solo_gainz)

### Support
- 📧 Open an issue on GitHub for bug reports and feature requests
- 💬 Discussions available on GitHub for general questions
- 🎮 Share your achievements and gameplay videos!

---

## ✦ Acknowledgments

- **Flutter Team** for the amazing framework
- **Hive Database** for local data persistence
- **Community Contributors** for feedback and support
- **Pixel Art Community** for inspiration

---

**Made with ❤️ for fitness enthusiasts who love gaming**

---

## ✦ Contributing

Contributions are welcome! Open an issue or submit a PR for:
- New quest types or achievement milestones
- Additional combat animations or collider data
- UI polish or accessibility improvements
- Bug fixes and performance optimizations

---

## ✦ License

```
MIT License

Copyright (c) 2025 Solo Gainz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files...
```

---

<p align="center">
  <strong>Solo Gainz</strong> — <em>Your fitness. Your character. Your journey.</em><br>
  <sub>Built with Flutter · Powered by your daily grind</sub>
</p>
