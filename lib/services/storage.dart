import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_stats.dart';

class Storage {
  static const String boxName = 'solo_gainz_box';
  static const String userStatsKey = 'user_stats';
  static const String dailyQuestsKey = 'daily_quests';
  static const String dailyTemplatesKey = 'daily_quest_templates';
  static late Box _box;
  static bool _isInit = false;

  // Initialize Hive
  static Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DailyQuestAdapter());
    }

    _box = await Hive.openBox(boxName);
    
    // Initialize default user stats if not exists
    if (!_box.containsKey(userStatsKey)) {
      final defaultStats = UserStats();
      await _box.put(userStatsKey, defaultStats);
    }

    // Default user info for no-login mode
    if (!_box.containsKey('current_user')) {
      await _box.put('current_user', 'Player');
    }
    if (!_box.containsKey('current_country')) {
      await _box.put('current_country', 'Earth');
    }
    if (!_box.containsKey('is_logged_in')) {
      await _box.put('is_logged_in', true);
    }
    
    _isInit = true;
  }

  // Save data
  static Future<void> saveData(String key, dynamic value) async {
    await _box.put(key, value);
  }

  // Get data
  static dynamic getData(String key, {dynamic defaultValue}) {
    if (!_isInit) return defaultValue;
    return _box.get(key, defaultValue: defaultValue);
  }

  // Delete data
  static Future<void> deleteData(String key) async {
    await _box.delete(key);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _box.clear();
  }

  // User Stats
  static UserStats getUserStats() {
    return _box.get(userStatsKey) ?? UserStats();
  }

  static Future<void> saveUserStats(UserStats stats) async {
    await _box.put(userStatsKey, stats);
  }



  static Future<void> checkDailyLoginReward() async {
    final stats = getUserStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastRewardStr = getData('last_daily_reward_date');
    DateTime? lastReward;
    if (lastRewardStr != null) lastReward = DateTime.parse(lastRewardStr);

    if (lastReward == null || today.isAfter(lastReward)) {
      const reward = 30; // Fixed daily bonus
      await addCoins(reward);
      await saveData('last_daily_reward_date', today.toIso8601String());
    }
  }

  // --- Achievement & Lifetime Stats ---
  static Future<void> addLifetimeStat(String key, int amount) async {
    final stats = getUserStats();
    final current = stats.lifetimeStats[key] ?? 0;
    // We need to create a new map because Hive doesn't always track internal map mutations correctly if not reassigned
    final newMap = Map<String, int>.from(stats.lifetimeStats);
    newMap[key] = current + amount;
    stats.lifetimeStats = newMap;
    await saveUserStats(stats);
  }

  static Future<void> unlockAchievement(String id) async {
    final stats = getUserStats();
    if (!stats.achievements.contains(id)) {
      final newList = List<String>.from(stats.achievements);
      newList.add(id);
      stats.achievements = newList;
      await saveUserStats(stats);
    }
  }

  static const String customQuestsKey = 'custom_quests';

  // Daily Quests
  static List<DailyQuest> getDailyQuests() {
    final quests = _box.get(dailyQuestsKey) as List?;
    return quests?.cast<DailyQuest>().toList() ?? [];
  }

  static Future<void> saveDailyQuests(List<DailyQuest> quests) async {
    await _box.put(dailyQuestsKey, quests);
  }

  static Future<void> updateDailyQuest(int index, DailyQuest quest) async {
    final quests = getDailyQuests();
    if (index >= 0 && index < quests.length) {
      quests[index] = quest;
      await saveDailyQuests(quests);
    }
  }

  // Daily Quest Templates
  static List<DailyQuest> getDailyTemplates() {
    final templates = _box.get(dailyTemplatesKey) as List?;
    return templates?.cast<DailyQuest>().toList() ?? [];
  }

  static Future<void> saveDailyTemplates(List<DailyQuest> templates) async {
    await _box.put(dailyTemplatesKey, templates);
  }

  // Custom Quests
  static List<DailyQuest> getCustomQuests() {
    final quests = _box.get(customQuestsKey) as List?;
    return quests?.cast<DailyQuest>().toList() ?? [];
  }

  static Future<void> saveCustomQuests(List<DailyQuest> quests) async {
    await _box.put(customQuestsKey, quests);
  }

  static Future<void> updateCustomQuest(int index, DailyQuest quest) async {
    final quests = getCustomQuests();
    if (index >= 0 && index < quests.length) {
      quests[index] = quest;
      await saveCustomQuests(quests);
    }
  }

  // Add coins (updates UserStats object)
  static Future<void> addCoins(int amount) async {
    final stats = getUserStats();
    stats.coins += amount;
    await saveUserStats(stats);
  }

  // Add XP (updates UserStats object and handles level/rank up)
  static Future<void> addXp(int amount) async {
    final stats = getUserStats();
    stats.xp += amount;
    
    // Level up loop
    while (true) {
      final need = RankSystem.getXpNeededForNextLevel(stats.rank);
      if (stats.xp >= need) {
        stats.xp -= need;
        stats.level++;
        
        // Rank promotion check
        if (RankSystem.canPromoteRank(stats.rank, stats.level)) {
          final next = RankSystem.getNextRank(stats.rank);
          if (next != null) {
            stats.rank = next;
            // Level remains continuous
          }
        }
      } else {
        break;
      }
    }
    await saveUserStats(stats);
  }

  // Get progress
  static int get maxSlots => _box.get('max_slots', defaultValue: 24);

  static Future<void> addMaxSlots(int count) async {
    await _box.put('max_slots', maxSlots + count);
    
    // Expand list if needed
    final List<dynamic> current = _box.get('inventory_slots', defaultValue: []);
    final updated = List<Map<String, dynamic>?>.from(current);
    while (updated.length < (maxSlots)) {
      updated.add(null);
    }
    await _box.put('inventory_slots', updated);
  }

  static int getProgress() {
    return getData('progress', defaultValue: 0);
  }

  // Update progress
  static Future<void> setProgress(int value) async {
    await saveData('progress', value);
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return true;
  }

  // Get current user
  static String? getCurrentUser() {
    return getData('current_user', defaultValue: 'Player');
  }

  // ── Inventory System ─────────────────────────────────────────
  static const String inventoryKey = 'inventory_slots';

  /// Get all inventory slots. Each slot is either null (empty) or a Map.
  /// Map keys: 'type' (wooden_chest/iron_chest), 'status' (locked/unlocking/ready),
  /// 'unlockStartTime' (ISO8601 string or null)
  static List<Map<String, dynamic>?> getInventorySlots() {
    final raw = _box.get(inventoryKey);
    final List<dynamic> list = raw as List<dynamic>? ?? [];
    
    // Ensure it's exactly maxSlots long
    final slots = list.map<Map<String, dynamic>?>((e) {
      if (e == null) return null;
      return Map<String, dynamic>.from(e as Map);
    }).toList();

    while (slots.length < maxSlots) {
      slots.add(null);
    }
    if (slots.length > maxSlots) {
      return slots.sublist(0, maxSlots);
    }
    return slots;
  }

  /// Save the full inventory slots list.
  static Future<void> saveInventorySlots(List<Map<String, dynamic>?> slots) async {
    await _box.put(inventoryKey, slots);
  }

  /// Check if there's at least one empty slot.
  static bool hasEmptySlot() {
    final slots = getInventorySlots();
    return slots.any((s) => s == null);
  }

  /// Add a chest to the first available empty slot.
  /// Returns the slot index, or -1 if full.
  static Future<int> addChestToInventory(String chestType) async {
    final slots = getInventorySlots();
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] == null) {
        slots[i] = {
          'type': chestType,
          'status': 'locked',
          'unlockStartTime': null,
        };
        await saveInventorySlots(slots);
        return i;
      }
    }
    return -1;
  }

  /// Start the unlock timer for a slot.
  static Future<void> startUnlocking(int slotIndex) async {
    final slots = getInventorySlots();
    if (slotIndex < 0 || slotIndex >= slots.length || slots[slotIndex] == null) return;
    slots[slotIndex]!['status'] = 'unlocking';
    slots[slotIndex]!['unlockStartTime'] = DateTime.now().toIso8601String();
    await saveInventorySlots(slots);
  }

  /// Get the unlock duration for a chest type.
  static Duration getUnlockDuration(String chestType) {
    if (chestType == 'wooden_chest') return const Duration(hours: 2);
    if (chestType == 'iron_chest') return const Duration(hours: 4);
    return const Duration(hours: 2);
  }

  /// Refresh statuses: check if any unlocking chests have finished.
  static Future<void> refreshInventoryStatuses() async {
    final slots = getInventorySlots();
    bool changed = false;
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] != null && slots[i]!['status'] == 'unlocking') {
        final startStr = slots[i]!['unlockStartTime'] as String?;
        if (startStr != null) {
          final start = DateTime.parse(startStr);
          final duration = getUnlockDuration(slots[i]!['type'] as String);
          if (DateTime.now().isAfter(start.add(duration))) {
            slots[i]!['status'] = 'ready';
            changed = true;
          }
        }
      }
    }
    if (changed) await saveInventorySlots(slots);
  }

  /// Get remaining time for an unlocking chest. Returns Duration.zero if ready.
  static Duration getRemainingUnlockTime(int slotIndex) {
    final slots = getInventorySlots();
    if (slotIndex < 0 || slotIndex >= slots.length || slots[slotIndex] == null) {
      return Duration.zero;
    }
    final slot = slots[slotIndex]!;
    if (slot['status'] != 'unlocking') return Duration.zero;
    final startStr = slot['unlockStartTime'] as String?;
    if (startStr == null) return Duration.zero;
    final start = DateTime.parse(startStr);
    final duration = getUnlockDuration(slot['type'] as String);
    final end = start.add(duration);
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Remove a chest from an inventory slot.
  static Future<void> removeFromInventory(int slotIndex) async {
    final slots = getInventorySlots();
    if (slotIndex < 0 || slotIndex >= slots.length) return;
    slots[slotIndex] = null;
    await saveInventorySlots(slots);
  }

  // Navbar Style
  static bool isNavbarFloating() {
    return getData('is_navbar_floating', defaultValue: true);
  }

  static Future<void> setNavbarFloating(bool value) async {
    await saveData('is_navbar_floating', value);
  }

  static bool isNavbarHidden() => getData('is_navbar_hidden', defaultValue: false);
  static Future<void> setNavbarHidden(bool value) async {
    await saveData('is_navbar_hidden', value);
  }




  static ValueListenable<Box> watch(dynamic key) {
    if (key is String) {
      return _box.listenable(keys: [key]);
    } else if (key is List<String>) {
      return _box.listenable(keys: key);
    }
    return _box.listenable();
  }
}
