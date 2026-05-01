import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_stats.dart';
import 'security_service.dart';

class Storage {
  static const String boxName = 'solo_gainz_box';
  
  // ── Keys ──────────────────────────────────────────────────────────
  static const String userStatsKey = 'user_stats';
  static const String dailyQuestsKey = 'daily_quests';
  static const String dailyTemplatesKey = 'daily_quest_templates';
  static const String customQuestsKey = 'custom_quests';
  static const String inventoryKey = 'inventory_slots';
  static const String maxSlotsKey = 'max_slots';

  static late final Box _box;
  static bool _isInit = false;

  // ── Initialization ────────────────────────────────────────────────
  static Future<void> init() async {
    if (_isInit) return;
    
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserStatsAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DailyQuestAdapter());

    // Securely retrieve the hardware-backed AES-256 cipher from SecurityService
    final cipher = await SecurityService.getHiveCipher();

    try {
      // Open box with unbreakable military-grade encryption
      _box = await Hive.openBox(boxName, encryptionCipher: cipher);
    } catch (e) {
      // If the box exists but is unencrypted (e.g. from an older version of the app),
      // we gracefully migrate the data without breaking or losing anything.
      _box = await Hive.openBox(boxName);
      final keys = _box.keys.toList();
      final Map<dynamic, dynamic> oldData = {};
      for (var k in keys) {
        oldData[k] = _box.get(k);
      }
      await _box.close();
      await Hive.deleteBoxFromDisk(boxName);
      
      // Re-open fresh with encryption and restore the user's data!
      _box = await Hive.openBox(boxName, encryptionCipher: cipher);
      await _box.putAll(oldData);
    }

    // Initialize default user stats if not present
    if (!_box.containsKey(userStatsKey)) {
      await _box.put(userStatsKey, UserStats());
    }
    
    _isInit = true;
  }

  // ── Generic Data Methods ──────────────────────────────────────────
  static Future<void> saveData(String key, dynamic value) => _box.put(key, value);

  static dynamic getData(String key, {dynamic defaultValue}) {
    if (!_isInit) return defaultValue;
    return _box.get(key, defaultValue: defaultValue);
  }

  static Future<void> deleteData(String key) => _box.delete(key);

  static Future<void> clearAll() => _box.clear();

  // ── User Stats ────────────────────────────────────────────────────
  static UserStats getUserStats() {
    return _box.get(userStatsKey) ?? UserStats();
  }

  static Future<void> saveUserStats(UserStats stats) => _box.put(userStatsKey, stats);

  static Future<void> addCoins(int amount) async {
    final stats = getUserStats();
    stats.coins += amount;
    await saveUserStats(stats);
  }

  static Future<void> addXp(int amount) async {
    final stats = getUserStats();
    stats.xp += amount;
    
    // Process level ups
    while (true) {
      final need = RankSystem.getXpNeededForNextLevel(stats.rank);
      if (stats.xp >= need) {
        stats.xp -= need;
        stats.level++;
        if (RankSystem.canPromoteRank(stats.rank, stats.level)) {
          final next = RankSystem.getNextRank(stats.rank);
          if (next != null) stats.rank = next;
        }
      } else {
        break;
      }
    }
    
    await saveUserStats(stats);
  }

  static Future<void> addLifetimeStat(String key, int amount) async {
    final stats = getUserStats();
    // Direct map modification is faster and cleaner
    stats.lifetimeStats[key] = (stats.lifetimeStats[key] ?? 0) + amount;
    await saveUserStats(stats);
  }

  static Future<void> unlockAchievement(String id) async {
    final stats = getUserStats();
    if (!stats.achievements.contains(id)) {
      stats.achievements.add(id);
      await saveUserStats(stats);
    }
  }

  // ── Daily Rewards & Progress ──────────────────────────────────────
  static Future<void> checkDailyLoginReward() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = getData('last_daily_reward_date');
    
    DateTime? last;
    if (lastStr != null) last = DateTime.tryParse(lastStr);
    
    if (last == null || today.isAfter(last)) {
      await addCoins(30);
      await saveData('last_daily_reward_date', today.toIso8601String());
    }
  }

  static int getProgress() => getData('progress', defaultValue: 0);
  static Future<void> setProgress(int value) => saveData('progress', value);

  // ── Quests Management ─────────────────────────────────────────────
  
  // Daily Quests
  static List<DailyQuest> getDailyQuests() => 
      (_box.get(dailyQuestsKey) as List?)?.cast<DailyQuest>().toList() ?? [];

  static Future<void> saveDailyQuests(List<DailyQuest> quests) => 
      _box.put(dailyQuestsKey, quests);

  static Future<void> updateDailyQuest(int index, DailyQuest quest) async {
    final quests = getDailyQuests();
    if (index >= 0 && index < quests.length) {
      quests[index] = quest;
      await saveDailyQuests(quests);
    }
  }

  // Templates
  static List<DailyQuest> getDailyTemplates() => 
      (_box.get(dailyTemplatesKey) as List?)?.cast<DailyQuest>().toList() ?? [];

  static Future<void> saveDailyTemplates(List<DailyQuest> templates) => 
      _box.put(dailyTemplatesKey, templates);

  // Custom Quests
  static List<DailyQuest> getCustomQuests() => 
      (_box.get(customQuestsKey) as List?)?.cast<DailyQuest>().toList() ?? [];

  static Future<void> saveCustomQuests(List<DailyQuest> quests) => 
      _box.put(customQuestsKey, quests);

  static Future<void> updateCustomQuest(int index, DailyQuest quest) async {
    final quests = getCustomQuests();
    if (index >= 0 && index < quests.length) {
      quests[index] = quest;
      await saveCustomQuests(quests);
    }
  }

  // ── Inventory System ──────────────────────────────────────────────
  static int get maxSlots => _box.get(maxSlotsKey, defaultValue: 24);

  static Future<void> addMaxSlots(int count) async {
    await _box.put(maxSlotsKey, maxSlots + count);
    
    final slots = getInventorySlots();
    while (slots.length < maxSlots) {
      slots.add(null);
    }
    await saveInventorySlots(slots);
  }

  static List<Map<String, dynamic>?> getInventorySlots() {
    final raw = _box.get(inventoryKey) as List<dynamic>? ?? [];
    
    final slots = raw.map<Map<String, dynamic>?>((e) {
      if (e == null) return null;
      return Map<String, dynamic>.from(e as Map);
    }).toList();
    
    while (slots.length < maxSlots) {
      slots.add(null);
    }
    
    return slots.length > maxSlots ? slots.sublist(0, maxSlots) : slots;
  }

  static Future<void> saveInventorySlots(List<Map<String, dynamic>?> slots) => 
      _box.put(inventoryKey, slots);

  static bool hasEmptySlot() => getInventorySlots().any((s) => s == null);

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

  static Future<void> startUnlocking(int slotIndex) async {
    final slots = getInventorySlots();
    if (slotIndex < 0 || slotIndex >= slots.length || slots[slotIndex] == null) {
      return;
    }
    slots[slotIndex]!['status'] = 'unlocking';
    slots[slotIndex]!['unlockStartTime'] = DateTime.now().toIso8601String();
    await saveInventorySlots(slots);
  }

  static Duration getUnlockDuration(String chestType) {
    if (chestType == 'wooden_chest') return const Duration(hours: 2);
    if (chestType == 'iron_chest') return const Duration(hours: 4);
    return const Duration(hours: 2);
  }

  static Future<void> refreshInventoryStatuses() async {
    final slots = getInventorySlots();
    bool changed = false;
    
    final now = DateTime.now();
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if (slot != null && slot['status'] == 'unlocking') {
        final startStr = slot['unlockStartTime'] as String?;
        if (startStr != null) {
          final start = DateTime.parse(startStr);
          final duration = getUnlockDuration(slot['type'] as String);
          
          if (now.isAfter(start.add(duration))) {
            slot['status'] = 'ready';
            changed = true;
          }
        }
      }
    }
    
    if (changed) await saveInventorySlots(slots);
  }

  static Duration getRemainingUnlockTime(int slotIndex) {
    final slots = getInventorySlots();
    if (slotIndex < 0 || slotIndex >= slots.length || slots[slotIndex] == null) {
      return Duration.zero;
    }
    
    final slot = slots[slotIndex]!;
    if (slot['status'] != 'unlocking') return Duration.zero;
    
    final startStr = slot['unlockStartTime'] as String?;
    if (startStr == null) return Duration.zero;
    
    final end = DateTime.parse(startStr).add(getUnlockDuration(slot['type'] as String));
    final remaining = end.difference(DateTime.now());
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Future<void> removeFromInventory(int slotIndex) async {
    final slots = getInventorySlots();
    if (slotIndex >= 0 && slotIndex < slots.length) {
      slots[slotIndex] = null;
      await saveInventorySlots(slots);
    }
  }

  // ── Auth & Session (Bypassed) ─────────────────────────────────────
  static bool isLoggedIn() => true;
  static bool isOnboarded() => true;
  static String? getCurrentUser() => 'Player';

  // ── Navbar Settings ───────────────────────────────────────────────
  static bool isNavbarFloating() => getData('is_navbar_floating', defaultValue: true);
  static Future<void> setNavbarFloating(bool value) => saveData('is_navbar_floating', value);

  static bool isNavbarHidden() => getData('is_navbar_hidden', defaultValue: false);
  static Future<void> setNavbarHidden(bool value) => saveData('is_navbar_hidden', value);

  // ── State Watcher ─────────────────────────────────────────────────
  static ValueListenable<Box> watch(dynamic key) {
    if (key is String) return _box.listenable(keys: [key]);
    if (key is List<String>) return _box.listenable(keys: key);
    return _box.listenable();
  }
}
