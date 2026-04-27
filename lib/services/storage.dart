import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_stats.dart';
import 'auth_service.dart';

class Storage {
  static const String boxName = 'solo_gainz_box';
  static const String userStatsKey = 'user_stats';
  static const String dailyQuestsKey = 'daily_quests';
  static const String dailyTemplatesKey = 'daily_quest_templates';
  static const String customQuestsKey = 'custom_quests';
  static late Box _box;
  static bool _isInit = false;

  // ── Init ───────────────────────────────────────────────────────
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserStatsAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DailyQuestAdapter());

    _box = await Hive.openBox(boxName);

    if (!_box.containsKey(userStatsKey)) {
      await _box.put(userStatsKey, UserStats());
    }
    _isInit = true;
  }

  // ── Generic read/write ─────────────────────────────────────────
  static Future<void> saveData(String key, dynamic value) async {
    await _box.put(key, value);
    _triggerSync();
  }

  static dynamic getData(String key, {dynamic defaultValue}) {
    if (!_isInit) return defaultValue;
    return _box.get(key, defaultValue: defaultValue);
  }

  static Future<void> deleteData(String key) async {
    await _box.delete(key);
    _triggerSync();
  }

  static Future<void> clearAll() async {
    await _box.clear();
  }

  // ── Auto-sync trigger ──────────────────────────────────────────
  /// Schedule a debounced cloud sync after any data change.
  static void _triggerSync() {
    if (isLoggedIn()) {
      AuthService().scheduleSyncData();
    }
  }

  // ── UserStats ──────────────────────────────────────────────────
  static UserStats getUserStats() {
    return _box.get(userStatsKey) ?? UserStats();
  }

  static Future<void> saveUserStats(UserStats stats) async {
    await _box.put(userStatsKey, stats);
    _triggerSync();
  }

  // ── Auth state ─────────────────────────────────────────────────
  static bool isLoggedIn() {
    return _box.get('is_logged_in', defaultValue: false) == true;
  }

  static bool isOnboarded() {
    return _box.get('is_onboarded', defaultValue: false) == true;
  }

  static String? getCurrentUser() {
    return getData('current_user');
  }

  // ── Daily reward ───────────────────────────────────────────────
  static Future<void> checkDailyLoginReward() async {
    final stats = getUserStats();
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

  // ── Achievements & lifetime stats ──────────────────────────────
  static Future<void> addLifetimeStat(String key, int amount) async {
    final stats = getUserStats();
    final newMap = Map<String, int>.from(stats.lifetimeStats);
    newMap[key] = (newMap[key] ?? 0) + amount;
    stats.lifetimeStats = newMap;
    await saveUserStats(stats);
  }

  static Future<void> unlockAchievement(String id) async {
    final stats = getUserStats();
    if (!stats.achievements.contains(id)) {
      final newList = List<String>.from(stats.achievements)..add(id);
      stats.achievements = newList;
      await saveUserStats(stats);
    }
  }

  // ── Daily quests ───────────────────────────────────────────────
  static List<DailyQuest> getDailyQuests() {
    final quests = _box.get(dailyQuestsKey) as List?;
    return quests?.cast<DailyQuest>().toList() ?? [];
  }

  static Future<void> saveDailyQuests(List<DailyQuest> quests) async {
    await _box.put(dailyQuestsKey, quests);
    _triggerSync();
  }

  static Future<void> updateDailyQuest(int index, DailyQuest quest) async {
    final quests = getDailyQuests();
    if (index >= 0 && index < quests.length) {
      quests[index] = quest;
      await saveDailyQuests(quests);
    }
  }

  // ── Templates ──────────────────────────────────────────────────
  static List<DailyQuest> getDailyTemplates() {
    final t = _box.get(dailyTemplatesKey) as List?;
    return t?.cast<DailyQuest>().toList() ?? [];
  }

  static Future<void> saveDailyTemplates(List<DailyQuest> templates) async {
    await _box.put(dailyTemplatesKey, templates);
    _triggerSync();
  }

  // ── Custom quests ──────────────────────────────────────────────
  static List<DailyQuest> getCustomQuests() {
    final q = _box.get(customQuestsKey) as List?;
    return q?.cast<DailyQuest>().toList() ?? [];
  }

  static Future<void> saveCustomQuests(List<DailyQuest> quests) async {
    await _box.put(customQuestsKey, quests);
    _triggerSync();
  }

  static Future<void> updateCustomQuest(int index, DailyQuest quest) async {
    final quests = getCustomQuests();
    if (index >= 0 && index < quests.length) {
      quests[index] = quest;
      await saveCustomQuests(quests);
    }
  }

  // ── Coins & XP ────────────────────────────────────────────────
  static Future<void> addCoins(int amount) async {
    final stats = getUserStats();
    stats.coins += amount;
    await saveUserStats(stats);
  }

  static Future<void> addXp(int amount) async {
    final stats = getUserStats();
    stats.xp += amount;
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

  // ── Progress ───────────────────────────────────────────────────
  static int getProgress() => getData('progress', defaultValue: 0);
  static Future<void> setProgress(int value) => saveData('progress', value);

  // ── Inventory ──────────────────────────────────────────────────
  static const String inventoryKey = 'inventory_slots';
  static int get maxSlots => _box.get('max_slots', defaultValue: 24);

  static Future<void> addMaxSlots(int count) async {
    await _box.put('max_slots', maxSlots + count);
    final current = _box.get(inventoryKey, defaultValue: []) as List;
    final updated = List<Map<String, dynamic>?>.from(current
        .map((e) => e == null ? null : Map<String, dynamic>.from(e as Map)));
    while (updated.length < maxSlots) {
      updated.add(null);
    }
    await _box.put(inventoryKey, updated);
    _triggerSync();
  }

  static List<Map<String, dynamic>?> getInventorySlots() {
    final raw = _box.get(inventoryKey);
    final list = (raw as List<dynamic>?) ?? [];
    final slots = list.map<Map<String, dynamic>?>((e) {
      if (e == null) return null;
      return Map<String, dynamic>.from(e as Map);
    }).toList();
    while (slots.length < maxSlots) {
      slots.add(null);
    }
    if (slots.length > maxSlots) return slots.sublist(0, maxSlots);
    return slots;
  }

  static Future<void> saveInventorySlots(
      List<Map<String, dynamic>?> slots) async {
    await _box.put(inventoryKey, slots);
    _triggerSync();
  }

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
    if (slotIndex < 0 ||
        slotIndex >= slots.length ||
        slots[slotIndex] == null) {
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
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] != null && slots[i]!['status'] == 'unlocking') {
        final startStr = slots[i]!['unlockStartTime'] as String?;
        if (startStr != null) {
          final start = DateTime.parse(startStr);
          final dur = getUnlockDuration(slots[i]!['type'] as String);
          if (DateTime.now().isAfter(start.add(dur))) {
            slots[i]!['status'] = 'ready';
            changed = true;
          }
        }
      }
    }
    if (changed) await saveInventorySlots(slots);
  }

  static Duration getRemainingUnlockTime(int slotIndex) {
    final slots = getInventorySlots();
    if (slotIndex < 0 ||
        slotIndex >= slots.length ||
        slots[slotIndex] == null) {
      return Duration.zero;
    }
    final slot = slots[slotIndex]!;
    if (slot['status'] != 'unlocking') return Duration.zero;
    final startStr = slot['unlockStartTime'] as String?;
    if (startStr == null) return Duration.zero;
    final end =
        DateTime.parse(startStr).add(getUnlockDuration(slot['type'] as String));
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Future<void> removeFromInventory(int slotIndex) async {
    final slots = getInventorySlots();
    if (slotIndex < 0 || slotIndex >= slots.length) return;
    slots[slotIndex] = null;
    await saveInventorySlots(slots);
  }

  // ── Navbar ────────────────────────────────────────────────────
  static bool isNavbarFloating() =>
      getData('is_navbar_floating', defaultValue: true);

  static Future<void> setNavbarFloating(bool value) =>
      saveData('is_navbar_floating', value);

  static bool isNavbarHidden() =>
      getData('is_navbar_hidden', defaultValue: false);

  static Future<void> setNavbarHidden(bool value) =>
      saveData('is_navbar_hidden', value);

  // ── Watcher ───────────────────────────────────────────────────
  static ValueListenable<Box> watch(dynamic key) {
    if (key is String) return _box.listenable(keys: [key]);
    if (key is List<String>) return _box.listenable(keys: key);
    return _box.listenable();
  }
}
