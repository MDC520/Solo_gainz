import 'dart:convert';
import '../models/user_stats.dart';
import 'storage.dart';

/// DataSerializer — Encodes ALL app state to a single JSON string
/// and decodes it back. Used by AuthService.syncData() and login.
///
/// The JSON is encrypted by SecurityService before going to Supabase.
class DataSerializer {
  DataSerializer._();

  static const int _version = 1;

  // ── Encode ─────────────────────────────────────────────────────
  /// Reads everything from local Storage and produces a JSON string.
  static String encodeAllData() {
    final stats = Storage.getUserStats();
    final quests = Storage.getDailyQuests();
    final templates = Storage.getDailyTemplates();
    final customQuests = Storage.getCustomQuests();
    final inventorySlots = Storage.getInventorySlots();

    final questsList = quests.map((q) => _questToMap(q)).toList();
    final templatesList = templates.map((q) => _questToMap(q)).toList();
    final customList = customQuests.map((q) => _questToMap(q)).toList();

    final inventoryList = inventorySlots
        .map((s) => s == null ? null : Map<String, dynamic>.from(s))
        .toList();

    final map = <String, dynamic>{
      'version': _version,
      // ── Player stats ──────────────────────────────────────────
      'rank': stats.rank,
      'level': stats.level,
      'xp': stats.xp,
      'coins': stats.coins,
      'progress': stats.progress,
      'last_daily_refresh': stats.lastDailyRefresh.toIso8601String(),
      'last_active_date': stats.lastActiveDate?.toIso8601String(),
      'achievements': stats.achievements,
      'lifetime_stats': stats.lifetimeStats,
      'is_onboarded': Storage.isOnboarded(),
      // ── Quests ────────────────────────────────────────────────
      'quests': questsList,
      'templates': templatesList,
      'custom_quests': customList,
      // ── Inventory ─────────────────────────────────────────────
      'inventory_slots': inventoryList,
      'max_slots': Storage.maxSlots,
      // ── Profile ───────────────────────────────────────────────
      'avatar_url': Storage.getData('profile_image_path', defaultValue: ''),
      // ── Settings ──────────────────────────────────────────────
      'settings': {
        'navbar_floating': Storage.isNavbarFloating(),
        'navbar_hidden': Storage.isNavbarHidden(),
        'avatar_style': Storage.getData('avatar_style', defaultValue: 'circle'),
        'notifications_enabled': Storage.getData('notifications_enabled', defaultValue: true),
        'daily_goal': Storage.getData('daily_goal', defaultValue: 'medium'),
        'last_daily_reward_date': Storage.getData('last_daily_reward_date'),
      },
    };

    return jsonEncode(map);
  }

  // ── Decode ─────────────────────────────────────────────────────
  /// Parses a JSON string and writes everything back to local Storage.
  static Future<void> decodeAndApplyData(String jsonStr) async {
    if (jsonStr.isEmpty || jsonStr == '{}') return;

    Map<String, dynamic> map;
    try {
      map = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return; // corrupt data — skip
    }

    // ── Player stats ────────────────────────────────────────────
    final stats = UserStats(
      rank: map['rank'] as String? ?? 'E',
      level: (map['level'] as num?)?.toInt() ?? 1,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      achievements: _castStringList(map['achievements']),
      lifetimeStats: _castIntMap(map['lifetime_stats']),
      lastDailyRefresh: _parseDate(map['last_daily_refresh']),
      lastActiveDate: map['last_active_date'] != null
          ? DateTime.tryParse(map['last_active_date'] as String)
          : null,
    );
    await Storage.saveUserStats(stats);

    // ── Quests ──────────────────────────────────────────────────
    final quests = _parseQuests(map['quests']);
    final templates = _parseQuests(map['templates']);
    final customQuests = _parseQuests(map['custom_quests']);
    await Storage.saveDailyQuests(quests);
    await Storage.saveDailyTemplates(templates);
    await Storage.saveCustomQuests(customQuests);

    // ── Inventory ────────────────────────────────────────────────
    final rawSlots = map['inventory_slots'] as List?;
    if (rawSlots != null) {
      final slots = rawSlots
          .map<Map<String, dynamic>?>((s) => s == null
              ? null
              : Map<String, dynamic>.from(s as Map))
          .toList();
      await Storage.saveInventorySlots(slots);
    }
    if (map['max_slots'] != null) {
      await Storage.saveData('max_slots', (map['max_slots'] as num).toInt());
    }

    // ── Profile ──────────────────────────────────────────────────
    final avatar = map['avatar_url'] as String?;
    if (avatar != null && avatar.isNotEmpty) {
      await Storage.saveData('profile_image_path', avatar);
    }

    if (map['is_onboarded'] != null) {
      await Storage.saveData('is_onboarded', map['is_onboarded'] == true);
    }

    // ── Settings ─────────────────────────────────────────────────
    final settings = map['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      await Storage.saveData('is_navbar_floating', settings['navbar_floating'] ?? true);
      await Storage.saveData('is_navbar_hidden', settings['navbar_hidden'] ?? false);
      await Storage.saveData('avatar_style', settings['avatar_style'] ?? 'circle');
      await Storage.saveData('notifications_enabled', settings['notifications_enabled'] ?? true);
      await Storage.saveData('daily_goal', settings['daily_goal'] ?? 'medium');
      if (settings['last_daily_reward_date'] != null) {
        await Storage.saveData('last_daily_reward_date', settings['last_daily_reward_date']);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────
  static Map<String, dynamic> _questToMap(DailyQuest q) => {
        'questName': q.questName,
        'questType': q.questType,
        'maxGoal': q.maxGoal,
        'currentProgress': q.currentProgress,
        'xpReward': q.xpReward,
        'completed': q.completed,
        'system': q.system,
        'createdDate': q.createdDate.toIso8601String(),
        'lastEditDate': q.lastEditDate?.toIso8601String(),
      };

  static List<DailyQuest> _parseQuests(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((e) {
      final m = e as Map<String, dynamic>;
      return DailyQuest(
        questName: m['questName'] as String? ?? '',
        questType: m['questType'] as String? ?? '',
        maxGoal: (m['maxGoal'] as num?)?.toInt() ?? 10,
        currentProgress: (m['currentProgress'] as num?)?.toInt() ?? 0,
        xpReward: (m['xpReward'] as num?)?.toInt() ?? 10,
        completed: m['completed'] as bool? ?? false,
        system: m['system'] as String? ?? 'reps',
        createdDate: _parseDate(m['createdDate']),
        lastEditDate: m['lastEditDate'] != null
            ? DateTime.tryParse(m['lastEditDate'] as String)
            : null,
      );
    }).toList();
  }

  static List<String> _castStringList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((e) => e.toString()).toList();
  }

  static Map<String, int> _castIntMap(dynamic raw) {
    if (raw == null) return {};
    return (raw as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }
}
