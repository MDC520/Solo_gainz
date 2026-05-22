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

## ✦ Overview

**Solo Gainz** is a Flutter mobile app that gamifies your fitness journey. Complete daily quests, earn XP and gold, open loot chests, and take your character into a real-time combat training arena. The more you train in real life, the stronger your in-game avatar becomes.

All data is stored **100% locally on-device** — no account needed, no cloud sync, full privacy.

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

---

## ✦ Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/solo_gainz.git
cd solo_gainz

# Install dependencies
flutter pub get

# Run the app
flutter run
```

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

---

## ✦ Building

```bash
# Debug build
flutter run --debug

# Release APK (Android)
flutter build apk --release

# Release IPA (iOS)
flutter build ios --release

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Generate Hive adapters
flutter pub run build_runner build
```

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
