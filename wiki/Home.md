# Solo Gainz Wiki

Welcome to the Solo Gainz project wiki. This hub page introduces the app, explains the main systems, and provides quick links for contributors and developers.

## Overview

Solo Gainz is a Flutter mobile app that blends fitness habit tracking with RPG-style progression and action combat.

Players complete daily workout quests, earn XP, coins, and loot chests, and train in an immersive combat arena.

The app is designed to work offline and store all progress locally using Hive.

## Core Systems

### Fitness & Quest System
- Daily quests are generated and refreshed each day.
- Quests support `reps` and `timer` progress types.
- Completing quests awards XP and updates lifetime stats.
- The `QuestScreen` is the main hub for tracking and completing workout tasks.

### Combat & Training
- A dedicated `TrainingScreen` uses `TrainingEngine` for movement, jumping, punching, kicking, and physics interactions.
- Combat hit detection is driven by frame-based collider data stored in `CombatData`.
- Players can grab, push, and pull boxes while navigating the training arena.
- The `EngineScreen` exposes an inspector for animation frames and collider editing.

### Reward Economy
- The app features tiered chests: `wooden`, `iron`, `gold`, and `mysterious`.
- `ShopScreen` allows buying chests with coins.
- `InventoryScreen` manages chest slots, unlock states, and drag/drop reorder.
- `OpenScreen` reveals randomized rewards based on chest rarity.

### Story & Progress
- The campaign is structured as chapters and stages in `StoryScreen`.
- Each stage rewards XP, coins, and occasional chests.
- Story progress is saved locally under `story_progress`.

### Local Multiplayer
- `PvpScreen` enables LAN-based multiplayer using UDP discovery and TCP sockets.
- Players can host or browse rooms and join using generated join codes.

### Profile & Settings
- `ProfileScreen` shows player stats, rank, achievements, and avatar controls.
- `SettingsScreen` manages theme mode, navigation mode, notifications, and reminder scheduling.

## Project Layout

- `lib/screens/` — all user-facing screens.
- `lib/engine/` — gameplay logic and physics simulation.
- `lib/models/` — data models and storage helpers.
- `lib/services/` — platform services like notifications and secure storage.
- `lib/widgets/` — reusable UI components.

## Quick Start

```bash
git clone https://github.com/MDC520/Solo_gainz.git
cd Solo_gainz
flutter pub get
flutter pub run build_runner build
flutter run
```

## Development Notes

- Keep reusable UI widgets in `lib/widgets/`.
- Keep game logic isolated in `lib/engine/`.
- Use `services/` for platform-specific features and notification handling.
- The `build/` folder is excluded from GitHub.

## Contribution

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature`.
3. Commit your changes.
4. Push and open a pull request.

## First Wiki Page Purpose

This page is the landing page for the Solo Gainz wiki. It should help new contributors and users understand the app quickly and navigate to deeper documentation in future wiki pages.
