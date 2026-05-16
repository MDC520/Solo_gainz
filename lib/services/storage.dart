import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import '../models/user_stats.dart';
import 'security_service.dart';

class Storage {
  static const String boxName = 'solo_gainz_box';
  
  // Keys
  static const String userStatsKey = 'user_stats';
  static const String dailyQuestsKey = 'daily_quests';
  static const String dailyTemplatesKey = 'daily_quest_templates';
  static const String customQuestsKey = 'custom_quests';
  static const String inventoryKey = 'inventory_slots';
  static const String maxSlotsKey = 'max_slots';
  static const String appIconKey = 'app_icon_name';

  static late final Box _box;
  static bool _isInit = false;

  // Initialization
  static Future<void> init() async {
    if (_isInit) return;
    
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserStatsAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DailyQuestAdapter());

    final cipher = await SecurityService.getHiveCipher();

    try {
      _box = await Hive.openBox(boxName, encryptionCipher: cipher);
    } catch (_) {
      // Migrate unencrypted data if present
      _box = await Hive.openBox(boxName);
      final oldData = {for (var k in _box.keys) k: _box.get(k)};
      await _box.close();
      await Hive.deleteBoxFromDisk(boxName);
      
      _box = await Hive.openBox(boxName, encryptionCipher: cipher);
      await _box.putAll(oldData);
    }

    if (!_box.containsKey(userStatsKey)) {
      await _box.put(userStatsKey, UserStats());
    }
    
    _isInit = true;
  }

  // Generic Data Operations
  static Future<void> saveData(String key, dynamic value) => _box.put(key, value);
  static dynamic getData(String key, {dynamic defaultValue}) => _isInit ? _box.get(key, defaultValue: defaultValue) : defaultValue;
  static Future<void> deleteData(String key) => _box.delete(key);
  static Future<void> clearAll() => _box.clear();
  static ValueListenable<Box> watch(dynamic key) => 
      key is String ? _box.listenable(keys: [key]) : (key is List<String> ? _box.listenable(keys: key) : _box.listenable());

  // User Stats
  static UserStats getUserStats() {
    final stats = _box.get(userStatsKey) ?? UserStats();
    stats.achievements = List<String>.from(stats.achievements);
    stats.lifetimeStats = Map<String, int>.from(stats.lifetimeStats);
    return stats;
  }

  static Future<void> saveUserStats(UserStats stats) => _box.put(userStatsKey, stats);

  static Future<void> addCoins(int amount) async {
    final stats = getUserStats()..coins += amount;
    await saveUserStats(stats);
  }

  static Future<void> addXp(int amount) async {
    final stats = getUserStats()..xp += amount;
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

  // Daily Rewards & Progress
  static Future<void> checkDailyLoginReward() async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final lastStr = getData('last_daily_reward_date');
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    
    if (last == null || today.isAfter(last)) {
      await addCoins(30);
      await saveData('last_daily_reward_date', today.toIso8601String());
    }
  }

  static int getProgress() => getData('progress', defaultValue: 0);
  static Future<void> setProgress(int value) => saveData('progress', value);

  // Quests
  static List<DailyQuest> getDailyQuests() => (_box.get(dailyQuestsKey) as List?)?.cast<DailyQuest>().toList() ?? [];
  static Future<void> saveDailyQuests(List<DailyQuest> quests) async {
    await _box.put(dailyQuestsKey, quests);
    await _updateHomeWidget(quests);
  }
  
  static Future<void> _updateHomeWidget(List<DailyQuest> quests) async {
    try {
      final total = quests.length;
      final completed = quests.where((q) => q.completed).length;
      
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      
      await HomeWidget.saveWidgetData<bool>('all_completed', total > 0 && total == completed);
      await HomeWidget.saveWidgetData<String>('quest_progress', '$completed / $total');
      await HomeWidget.saveWidgetData<int>('quest_percent', total == 0 ? 0 : ((completed / total) * 100).toInt());
      await HomeWidget.saveWidgetData<int>('refresh_time_ms', tomorrow.millisecondsSinceEpoch);
      
      // Save up to 4 individual quests
      for (int i = 0; i < 4; i++) {
        if (i < total) {
          final q = quests[i];
          await HomeWidget.saveWidgetData<String>('quest_${i}_name', q.questName);
          await HomeWidget.saveWidgetData<int>('quest_${i}_progress', q.progressPct);
          await HomeWidget.saveWidgetData<bool>('quest_${i}_visible', true);
        } else {
          await HomeWidget.saveWidgetData<bool>('quest_${i}_visible', false);
        }
      }

      await HomeWidget.updateWidget(name: 'QuestWidgetProvider', androidName: 'QuestWidgetProvider');
    } catch (e) {
      debugPrint('HomeWidget error: $e');
    }
  }
  static Future<void> updateDailyQuest(int index, DailyQuest quest) async {
    final quests = getDailyQuests();
    if (index >= 0 && index < quests.length) {
      quests[index] = quest;
      await saveDailyQuests(quests);
    }
  }

  static List<DailyQuest> getDailyTemplates() => (_box.get(dailyTemplatesKey) as List?)?.cast<DailyQuest>().toList() ?? [];
  static Future<void> saveDailyTemplates(List<DailyQuest> templates) => _box.put(dailyTemplatesKey, templates);

  static List<DailyQuest> getCustomQuests() => (_box.get(customQuestsKey) as List?)?.cast<DailyQuest>().toList() ?? [];
  static Future<void> saveCustomQuests(List<DailyQuest> quests) => _box.put(customQuestsKey, quests);
  static Future<void> updateCustomQuest(int index, DailyQuest quest) async {
    final quests = getCustomQuests();
    if (index >= 0 && index < quests.length) {
      quests[index] = quest;
      await saveCustomQuests(quests);
    }
  }

  // Inventory System
  static int get maxSlots => _box.get(maxSlotsKey, defaultValue: 20);

  static Future<void> addMaxSlots(int count) async {
    await _box.put(maxSlotsKey, maxSlots + count);
    final slots = getInventorySlots();
    while (slots.length < maxSlots) {
      slots.add(null);
    }
    await saveInventorySlots(slots);
  }

  static List<Map<String, dynamic>?> getInventorySlots() {
    final raw = _box.get(inventoryKey) as List? ?? [];
    final slots = raw.map((e) => e == null ? null : Map<String, dynamic>.from(e as Map)).toList();
    while (slots.length < maxSlots) {
      slots.add(null);
    }
    return slots.length > maxSlots ? slots.sublist(0, maxSlots) : slots;
  }

  static Future<void> saveInventorySlots(List<Map<String, dynamic>?> slots) => _box.put(inventoryKey, slots);
  static bool hasEmptySlot() => getInventorySlots().any((s) => s == null);

  static Future<int> addChestToInventory(String chestType) async {
    final slots = getInventorySlots();
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] == null) {
        slots[i] = {'type': chestType, 'status': 'locked', 'unlockStartTime': null};
        await saveInventorySlots(slots);
        return i;
      }
    }
    return -1;
  }

  static Future<void> startUnlocking(int slotIndex) async {
    final slots = getInventorySlots();
    if (slotIndex < 0 || slotIndex >= slots.length || slots[slotIndex] == null) return;
    slots[slotIndex]!['status'] = 'unlocking';
    slots[slotIndex]!['unlockStartTime'] = DateTime.now().toIso8601String();
    await saveInventorySlots(slots);
  }

  static Duration getUnlockDuration(String chestType) {
    if (chestType == 'wooden_chest') return const Duration(hours: 2);
    if (chestType == 'iron_chest') return const Duration(hours: 4);
    if (chestType == 'gold_chest') return const Duration(hours: 8);
    return const Duration(hours: 2);
  }

  static Future<void> refreshInventoryStatuses() async {
    final slots = getInventorySlots();
    bool changed = false;
    final now = DateTime.now();
    for (var slot in slots) {
      if (slot != null && slot['status'] == 'unlocking' && slot['unlockStartTime'] != null) {
        final start = DateTime.parse(slot['unlockStartTime']);
        final duration = getUnlockDuration(slot['type'] as String);
        if (now.isAfter(start.add(duration))) {
          slot['status'] = 'ready';
          changed = true;
        }
      }
    }
    if (changed) await saveInventorySlots(slots);
  }

  static Duration getRemainingUnlockTime(int slotIndex) {
    final slots = getInventorySlots();
    if (slotIndex < 0 || slotIndex >= slots.length || slots[slotIndex] == null) return Duration.zero;
    final slot = slots[slotIndex]!;
    if (slot['status'] != 'unlocking' || slot['unlockStartTime'] == null) return Duration.zero;
    final end = DateTime.parse(slot['unlockStartTime']).add(getUnlockDuration(slot['type'] as String));
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Future<void> removeFromInventory(int slotIndex) async {
    final slots = getInventorySlots();
    if (slotIndex >= 0 && slotIndex < slots.length) {
      slots.removeAt(slotIndex);
      while (slots.length < maxSlots) {
        slots.add(null);
      }
      await saveInventorySlots(slots);
    }
  }

  // App Settings & Auth
  static bool isLoggedIn() => true;
  static bool isOnboarded() => getData('is_onboarded', defaultValue: false);
  static String? getCurrentUser() => getData('player_name', defaultValue: 'Player');
  static Future<void> setPlayerName(String name) => saveData('player_name', name);
  static String? getProfileImage() => getData('profile_image');
  static Future<void> setProfileImage(String path) => saveData('profile_image', path);
  static bool isNavbarFloating() => getData('is_navbar_floating', defaultValue: true);
  static Future<void> setNavbarFloating(bool value) => saveData('is_navbar_floating', value);
  static bool isNavbarHidden() => getData('is_navbar_hidden', defaultValue: false);
  static Future<void> setNavbarHidden(bool value) => saveData('is_navbar_hidden', value);
  static String getAppIcon() => getData(appIconKey, defaultValue: 'DarkIcon');
  static Future<void> setAppIcon(String value) => saveData(appIconKey, value);

  // Backup & Restore
  static const int _dataVersion = 1;

  static String encodeAllData() {
    final stats = getUserStats();
    return jsonEncode({
      'version': _dataVersion,
      'rank': stats.rank,
      'level': stats.level,
      'xp': stats.xp,
      'coins': stats.coins,
      'progress': stats.progress,
      'last_daily_refresh': stats.lastDailyRefresh.toIso8601String(),
      'last_active_date': stats.lastActiveDate?.toIso8601String(),
      'achievements': stats.achievements,
      'lifetime_stats': stats.lifetimeStats,
      'is_onboarded': isOnboarded(),
      'quests': getDailyQuests().map(_questToMap).toList(),
      'templates': getDailyTemplates().map(_questToMap).toList(),
      'custom_quests': getCustomQuests().map(_questToMap).toList(),
      'inventory_slots': getInventorySlots().map((s) => s != null ? Map<String, dynamic>.from(s) : null).toList(),
      'max_slots': maxSlots,
      'avatar_url': getData('profile_image_path', defaultValue: ''),
      'settings': {
        'navbar_floating': isNavbarFloating(),
        'navbar_hidden': isNavbarHidden(),
        'avatar_style': getData('avatar_style', defaultValue: 'circle'),
        'notifications_enabled': getData('notifications_enabled', defaultValue: true),
        'daily_goal': getData('daily_goal', defaultValue: 'medium'),
        'last_daily_reward_date': getData('last_daily_reward_date'),
        'is_dark_mode': getData('is_dark_mode', defaultValue: true),
        'app_icon_name': getAppIcon(),
      },
    });
  }

  static Future<void> decodeAndApplyData(String jsonStr) async {
    if (jsonStr.isEmpty || jsonStr == '{}') return;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      await saveUserStats(UserStats(
        rank: map['rank'] as String? ?? 'E',
        level: (map['level'] as num?)?.toInt() ?? 1,
        xp: (map['xp'] as num?)?.toInt() ?? 0,
        coins: (map['coins'] as num?)?.toInt() ?? 0,
        progress: (map['progress'] as num?)?.toInt() ?? 0,
        achievements: _castStringList(map['achievements']),
        lifetimeStats: _castIntMap(map['lifetime_stats']),
        lastDailyRefresh: _parseDate(map['last_daily_refresh']),
        lastActiveDate: map['last_active_date'] != null ? DateTime.tryParse(map['last_active_date']) : null,
      ));

      await saveDailyQuests(_parseQuests(map['quests']));
      await saveDailyTemplates(_parseQuests(map['templates']));
      await saveCustomQuests(_parseQuests(map['custom_quests']));

      if (map['inventory_slots'] != null) {
        await saveInventorySlots((map['inventory_slots'] as List).map((s) => s != null ? Map<String, dynamic>.from(s) : null).toList());
      }
      
      if (map['max_slots'] != null) await _box.put(maxSlotsKey, (map['max_slots'] as num).toInt());
      if (map['avatar_url']?.toString().isNotEmpty == true) await saveData('profile_image_path', map['avatar_url']);
      if (map['is_onboarded'] != null) await saveData('is_onboarded', map['is_onboarded'] == true);

      final settings = map['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        await saveData('is_navbar_floating', settings['navbar_floating'] ?? true);
        await saveData('is_navbar_hidden', settings['navbar_hidden'] ?? false);
        await saveData('avatar_style', settings['avatar_style'] ?? 'circle');
        await saveData('notifications_enabled', settings['notifications_enabled'] ?? true);
        await saveData('daily_goal', settings['daily_goal'] ?? 'medium');
        if (settings['last_daily_reward_date'] != null) await saveData('last_daily_reward_date', settings['last_daily_reward_date']);
        if (settings['is_dark_mode'] != null) await saveData('is_dark_mode', settings['is_dark_mode']);
        if (settings['app_icon_name'] != null) await setAppIcon(settings['app_icon_name']);
      }
    } catch (_) {}
  }

  static Map<String, dynamic> _questToMap(DailyQuest q) => {
    'questName': q.questName, 'questType': q.questType, 'maxGoal': q.maxGoal,
    'currentProgress': q.currentProgress, 'xpReward': q.xpReward,
    'completed': q.completed, 'system': q.system,
    'createdDate': q.createdDate.toIso8601String(), 'lastEditDate': q.lastEditDate?.toIso8601String(),
  };

  static List<DailyQuest> _parseQuests(dynamic raw) => (raw as List?)?.map((e) {
    final m = e as Map<String, dynamic>;
    return DailyQuest(
      questName: m['questName'] as String? ?? '', questType: m['questType'] as String? ?? '',
      maxGoal: (m['maxGoal'] as num?)?.toInt() ?? 10, currentProgress: (m['currentProgress'] as num?)?.toInt() ?? 0,
      xpReward: (m['xpReward'] as num?)?.toInt() ?? 10, completed: m['completed'] as bool? ?? false,
      system: m['system'] as String? ?? 'reps', createdDate: _parseDate(m['createdDate']),
      lastEditDate: m['lastEditDate'] != null ? DateTime.tryParse(m['lastEditDate']) : null,
    );
  }).toList() ?? [];

  static List<String> _castStringList(dynamic raw) => (raw as List?)?.map((e) => e.toString()).toList() ?? [];
  static Map<String, int> _castIntMap(dynamic raw) => (raw as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {};
  static DateTime _parseDate(dynamic raw) => raw != null ? (DateTime.tryParse(raw.toString()) ?? DateTime.now()) : DateTime.now();
}
