import 'storage.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String category;
  final int xpReward;
  final IconType iconType;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.xpReward = 100,
    this.iconType = IconType.trophy,
  });
}

enum IconType { trophy, star, shield, fire, chest, sword, heart, dumbbell, clock, crown }

class AchievementCatalog {
  static const List<Achievement> all = [
    // ── Exercise Milestones ─────────────────────────────────────
    Achievement(id: 'reps_100', title: 'Warm Up', description: 'Complete 100 total reps', category: 'exercise', xpReward: 50, iconType: IconType.dumbbell),
    Achievement(id: 'reps_1000', title: 'Getting Started', description: 'Complete 1,000 total reps', category: 'exercise', xpReward: 100, iconType: IconType.dumbbell),
    Achievement(id: 'reps_10000', title: 'Dedicated', description: 'Complete 10,000 total reps', category: 'exercise', xpReward: 250, iconType: IconType.dumbbell),
    Achievement(id: 'reps_50000', title: 'The Grinder', description: 'Complete 50,000 total reps', category: 'exercise', xpReward: 500, iconType: IconType.dumbbell),
    Achievement(id: 'reps_100000', title: 'Century Club', description: 'Complete 100,000 total reps', category: 'exercise', xpReward: 1000, iconType: IconType.crown),
    Achievement(id: 'pushups_1000', title: 'Push-up Pro', description: 'Complete 1,000 push-ups', category: 'exercise', xpReward: 150, iconType: IconType.dumbbell),
    Achievement(id: 'situps_1000', title: 'Core Strength', description: 'Complete 1,000 sit-ups', category: 'exercise', xpReward: 150, iconType: IconType.dumbbell),
    Achievement(id: 'squats_1000', title: 'Leg Day Believer', description: 'Complete 1,000 squats', category: 'exercise', xpReward: 150, iconType: IconType.dumbbell),

    // ── Rank Milestones ─────────────────────────────────────────
    Achievement(id: 'rank_d', title: 'Rising Star', description: 'Reach D Rank', category: 'rank', xpReward: 100, iconType: IconType.shield),
    Achievement(id: 'rank_c', title: 'Getting Serious', description: 'Reach C Rank', category: 'rank', xpReward: 200, iconType: IconType.shield),
    Achievement(id: 'rank_bb', title: 'Body Builder', description: 'Reach BB Rank', category: 'rank', xpReward: 300, iconType: IconType.shield),
    Achievement(id: 'rank_a', title: 'Alpha', description: 'Reach A Rank', category: 'rank', xpReward: 500, iconType: IconType.shield),
    Achievement(id: 'rank_s', title: 'Superhuman', description: 'Reach S Rank', category: 'rank', xpReward: 800, iconType: IconType.shield),
    Achievement(id: 'rank_ss', title: 'Double S', description: 'Reach SS Rank', category: 'rank', xpReward: 1200, iconType: IconType.crown),
    Achievement(id: 'rank_sg', title: 'Solo Gainz God', description: 'Reach SG Rank', category: 'rank', xpReward: 2000, iconType: IconType.crown),

    // ── Level Milestones ────────────────────────────────────────
    Achievement(id: 'level_10', title: 'Level 10', description: 'Reach level 10', category: 'level', xpReward: 100, iconType: IconType.star),
    Achievement(id: 'level_25', title: 'Quarter Century', description: 'Reach level 25', category: 'level', xpReward: 250, iconType: IconType.star),
    Achievement(id: 'level_50', title: 'Halfway There', description: 'Reach level 50', category: 'level', xpReward: 500, iconType: IconType.star),
    Achievement(id: 'level_100', title: 'Triple Digits', description: 'Reach level 100', category: 'level', xpReward: 1000, iconType: IconType.crown),

    // ── Quest Milestones ────────────────────────────────────────
    Achievement(id: 'quests_10', title: 'Taskmaster', description: 'Complete 10 quests', category: 'quest', xpReward: 100, iconType: IconType.fire),
    Achievement(id: 'quests_50', title: 'Quest Addict', description: 'Complete 50 quests', category: 'quest', xpReward: 250, iconType: IconType.fire),
    Achievement(id: 'quests_100', title: 'Century Quests', description: 'Complete 100 quests', category: 'quest', xpReward: 500, iconType: IconType.fire),
    Achievement(id: 'quests_all_daily', title: 'Daily Devotion', description: 'Complete all daily quests in one day', category: 'quest', xpReward: 200, iconType: IconType.star),

    // ── Coin/Wealth Milestones ──────────────────────────────────
    Achievement(id: 'coins_1000', title: 'First Savings', description: 'Earn 1,000 coins', category: 'wealth', xpReward: 100, iconType: IconType.chest),
    Achievement(id: 'coins_10000', title: 'Well Off', description: 'Earn 10,000 coins', category: 'wealth', xpReward: 300, iconType: IconType.chest),
    Achievement(id: 'coins_100000', title: 'Fortune Builder', description: 'Earn 100,000 coins', category: 'wealth', xpReward: 1000, iconType: IconType.crown),
    Achievement(id: 'spend_5000', title: 'Shopper', description: 'Spend 5,000 coins in the shop', category: 'wealth', xpReward: 150, iconType: IconType.chest),

    // ── Chest / Inventory Milestones ────────────────────────────
    Achievement(id: 'chest_open_1', title: 'Curious', description: 'Open your first chest', category: 'chest', xpReward: 50, iconType: IconType.chest),
    Achievement(id: 'chest_open_25', title: 'Treasure Hunter', description: 'Open 25 chests', category: 'chest', xpReward: 200, iconType: IconType.chest),
    Achievement(id: 'chest_open_100', title: 'Loot Goblin', description: 'Open 100 chests', category: 'chest', xpReward: 500, iconType: IconType.chest),
    Achievement(id: 'chest_gold', title: 'Golden Touch', description: 'Open a gold chest', category: 'chest', xpReward: 150, iconType: IconType.chest),
    Achievement(id: 'chest_mysterious', title: 'Curiosity Killed The Cat', description: 'Open a mysterious chest', category: 'chest', xpReward: 200, iconType: IconType.chest),
    Achievement(id: 'inventory_50', title: 'Collector', description: 'Unlock 50 inventory slots', category: 'chest', xpReward: 300, iconType: IconType.chest),

    // ── Streak Milestones ───────────────────────────────────────
    Achievement(id: 'streak_3', title: 'Consistent', description: '3-day login streak', category: 'streak', xpReward: 50, iconType: IconType.fire),
    Achievement(id: 'streak_7', title: 'Week Warrior', description: '7-day login streak', category: 'streak', xpReward: 150, iconType: IconType.fire),
    Achievement(id: 'streak_30', title: 'Monthly Master', description: '30-day login streak', category: 'streak', xpReward: 500, iconType: IconType.fire),
    Achievement(id: 'streak_100', title: 'Century Streak', description: '100-day login streak', category: 'streak', xpReward: 1000, iconType: IconType.crown),
    Achievement(id: 'streak_365', title: 'One Year Strong', description: '365-day login streak', category: 'streak', xpReward: 5000, iconType: IconType.crown),

    // ── Training / Combat ───────────────────────────────────────
    Achievement(id: 'train_10', title: 'Beginner', description: 'Complete 10 training sessions', category: 'combat', xpReward: 50, iconType: IconType.sword),
    Achievement(id: 'train_50', title: 'Fighter', description: 'Complete 50 training sessions', category: 'combat', xpReward: 200, iconType: IconType.sword),
    Achievement(id: 'train_100', title: 'Warrior', description: 'Complete 100 training sessions', category: 'combat', xpReward: 500, iconType: IconType.sword),
    Achievement(id: 'pvp_win_1', title: 'First Blood', description: 'Win your first PvP match', category: 'combat', xpReward: 100, iconType: IconType.sword),
    Achievement(id: 'pvp_win_10', title: 'Arena Veteran', description: 'Win 10 PvP matches', category: 'combat', xpReward: 300, iconType: IconType.sword),
    Achievement(id: 'pvp_win_50', title: 'Gladiator', description: 'Win 50 PvP matches', category: 'combat', xpReward: 800, iconType: IconType.crown),
    Achievement(id: 'combo_5', title: 'Combo Starter', description: 'Land a 5-hit combo', category: 'combat', xpReward: 100, iconType: IconType.sword),
    Achievement(id: 'combo_20', title: 'Combo Master', description: 'Land a 20-hit combo', category: 'combat', xpReward: 300, iconType: IconType.crown),

    // ── Story Mode ──────────────────────────────────────────────
    Achievement(id: 'story_c1', title: 'The Awakening', description: 'Complete Chapter 1 of Story Mode', category: 'story', xpReward: 200, iconType: IconType.star),
    Achievement(id: 'story_c2', title: 'Shadow Walker', description: 'Complete Chapter 2 of Story Mode', category: 'story', xpReward: 300, iconType: IconType.star),
    Achievement(id: 'story_c3', title: 'Fortress Breaker', description: 'Complete Chapter 3 of Story Mode', category: 'story', xpReward: 500, iconType: IconType.crown),
    Achievement(id: 'story_all', title: 'Campaign Hero', description: 'Complete all Story Mode chapters', category: 'story', xpReward: 2000, iconType: IconType.crown),

    // ── Hidden / Easter Egg ─────────────────────────────────────
    Achievement(id: 'hidden_bg', title: 'Swipe Life', description: 'Change the app theme 10 times', category: 'hidden', xpReward: 100, iconType: IconType.heart),
    Achievement(id: 'hidden_night', title: 'Night Owl', description: 'Open the app at midnight', category: 'hidden', xpReward: 100, iconType: IconType.star),
    Achievement(id: 'hidden_name', title: 'What\'s In A Name', description: 'Change your player name', category: 'hidden', xpReward: 50, iconType: IconType.heart),
    Achievement(id: 'hidden_profile', title: 'Picture Perfect', description: 'Set a profile picture', category: 'hidden', xpReward: 50, iconType: IconType.heart),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Achievement> getByCategory(String category) {
    return all.where((a) => a.category == category).toList();
  }

  static List<Achievement> getLocked(List<String> unlockedIds) {
    return all.where((a) => !unlockedIds.contains(a.id)).toList();
  }

  static List<Achievement> getUnlocked(List<String> unlockedIds) {
    return all.where((a) => unlockedIds.contains(a.id)).toList();
  }

  static int totalCount() => all.length;
}

class AchievementChecker {
  static Future<void> checkOnReps(int totalReps, List<String> currentAchievements) async {
    if (totalReps >= 100000) {
      await _unlock('reps_100000', currentAchievements);
    } else if (totalReps >= 50000) {
      await _unlock('reps_50000', currentAchievements);
    }
    else if (totalReps >= 10000) {
      await _unlock('reps_10000', currentAchievements);
    }
    else if (totalReps >= 1000) {
      await _unlock('reps_1000', currentAchievements);
    }
    else if (totalReps >= 100) {
      await _unlock('reps_100', currentAchievements);
    }
  }

  static Future<void> checkOnRank(String rank, List<String> currentAchievements) async {
    if (rank == 'SG') {
      await _unlock('rank_sg', currentAchievements);
    } else if (rank == 'SS') {
      await _unlock('rank_ss', currentAchievements);
    }
    else if (rank == 'S') {
      await _unlock('rank_s', currentAchievements);
    }
    else if (rank == 'A') {
      await _unlock('rank_a', currentAchievements);
    }
    else if (rank == 'BB') {
      await _unlock('rank_bb', currentAchievements);
    }
    else if (rank == 'C') {
      await _unlock('rank_c', currentAchievements);
    }
    else if (rank == 'D') {
      await _unlock('rank_d', currentAchievements);
    }
  }

  static Future<void> checkOnLevel(int level, List<String> currentAchievements) async {
    if (level >= 100) {
      await _unlock('level_100', currentAchievements);
    } else if (level >= 50) {
      await _unlock('level_50', currentAchievements);
    }
    else if (level >= 25) {
      await _unlock('level_25', currentAchievements);
    }
    else if (level >= 10) {
      await _unlock('level_10', currentAchievements);
    }
  }

  static Future<void> checkOnQuests(int completedCount, List<String> currentAchievements) async {
    if (completedCount >= 100) {
      await _unlock('quests_100', currentAchievements);
    } else if (completedCount >= 50) {
      await _unlock('quests_50', currentAchievements);
    }
    else if (completedCount >= 10) {
      await _unlock('quests_10', currentAchievements);
    }
  }

  static Future<void> checkOnCoins(int totalCoins, List<String> currentAchievements) async {
    if (totalCoins >= 100000) {
      await _unlock('coins_100000', currentAchievements);
    } else if (totalCoins >= 10000) {
      await _unlock('coins_10000', currentAchievements);
    }
    else if (totalCoins >= 1000) {
      await _unlock('coins_1000', currentAchievements);
    }
  }

  static Future<void> checkOnStreak(int streakDays, List<String> currentAchievements) async {
    if (streakDays >= 365) {
      await _unlock('streak_365', currentAchievements);
    } else if (streakDays >= 100) {
      await _unlock('streak_100', currentAchievements);
    }
    else if (streakDays >= 30) {
      await _unlock('streak_30', currentAchievements);
    }
    else if (streakDays >= 7) {
      await _unlock('streak_7', currentAchievements);
    }
    else if (streakDays >= 3) {
      await _unlock('streak_3', currentAchievements);
    }
  }

  static Future<void> checkOnChestOpened(String chestType, int totalOpened, List<String> currentAchievements) async {
    if (chestType == 'mysterious_chest') {
      await _unlock('chest_mysterious', currentAchievements);
    }
    if (chestType == 'gold_chest') {
      await _unlock('chest_gold', currentAchievements);
    }
    if (totalOpened >= 100) {
      await _unlock('chest_open_100', currentAchievements);
    } else if (totalOpened >= 25) {
      await _unlock('chest_open_25', currentAchievements);
    }
    else if (totalOpened >= 1) {
      await _unlock('chest_open_1', currentAchievements);
    }
  }

  static Future<void> checkOnStoryChapter(int chapterIndex, List<String> currentAchievements) async {
    if (chapterIndex >= 3) {
      await _unlock('story_all', currentAchievements);
      await _unlock('story_c3', currentAchievements);
    }
    if (chapterIndex >= 2) {
      await _unlock('story_c2', currentAchievements);
    }
    if (chapterIndex >= 1) {
      await _unlock('story_c1', currentAchievements);
    }
  }

  static Future<void> _unlock(String id, List<String> currentAchievements) async {
    if (!currentAchievements.contains(id)) {
      final achievement = AchievementCatalog.getById(id);
      if (achievement != null) {
        await Storage.addXp(achievement.xpReward);
      }
      await Storage.unlockAchievement(id);
    }
  }
}
