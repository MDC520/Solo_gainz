import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import '../services/security_service.dart';
import '../services/notifications.dart';
import 'achievements.dart';

part 'storage.g.dart';

@HiveType(typeId: 0)
class UserStats {
  @HiveField(0)
  String rank;

  @HiveField(1)
  int level;

  @HiveField(2)
  int xp;

  @HiveField(3)
  int coins;

  @HiveField(4)
  int progress;

  @HiveField(5)
  DateTime lastDailyRefresh;

  @HiveField(8)
  DateTime? lastActiveDate;

  @HiveField(9)
  List<String> achievements;

  @HiveField(10)
  Map<String, int> lifetimeStats;

  UserStats({
    this.rank = 'E',
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.progress = 0,
    this.lastActiveDate,
    List<String>? achievements,
    Map<String, int>? lifetimeStats,
    DateTime? lastDailyRefresh,
  }) : achievements = achievements ?? [],
       lifetimeStats = lifetimeStats ?? {},
       lastDailyRefresh = lastDailyRefresh ?? DateTime.now();
}

@HiveType(typeId: 1)
class DailyQuest {
  @HiveField(0)
  String questName;

  @HiveField(1)
  String questType;

  @HiveField(2)
  int maxGoal;

  @HiveField(3)
  int currentProgress;

  @HiveField(4)
  int xpReward;

  @HiveField(5)
  bool completed;

  @HiveField(6)
  DateTime createdDate;

  @HiveField(7)
  String system;

  @HiveField(8)
  DateTime? lastEditDate;

  DailyQuest({
    required this.questName,
    required this.questType,
    required this.maxGoal,
    this.currentProgress = 0,
    required this.xpReward,
    this.completed = false,
    this.system = 'reps',
    this.lastEditDate,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  int get progressPct => maxGoal == 0 ? 0 : ((currentProgress / maxGoal) * 100).toInt();
}

class Exercise {
  final String name;
  final String type;
  final String system;
  final int defaultGoal;
  final String description;
  final String youtubeUrl;

  const Exercise({
    required this.name,
    required this.type,
    required this.system,
    required this.defaultGoal,
    this.description = '',
    this.youtubeUrl = '',
  });

  String? get youtubeVideoId {
    if (youtubeUrl.isEmpty) return null;
    final regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(youtubeUrl);
    if (match != null && match.group(7)?.length == 11) {
      return match.group(7);
    }
    return null;
  }

  String? get youtubeThumbnailUrl {
    final id = youtubeVideoId;
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/mqdefault.jpg';
  }
}

class ExerciseLibrary {
  static const List<Exercise> homeExercises = [
    Exercise(
      name: 'Push-ups',
      type: 'pushups',
      system: 'reps',
      defaultGoal: 20,
      description: 'A classic bodyweight movement targeting chest, shoulders, and triceps. Keep your core tight and body in a straight line.',
      youtubeUrl: 'https://www.youtube.com/watch?v=IODxDxX7oi4',
    ),
    Exercise(
      name: 'Diamond Push-ups',
      type: 'diamond_pushups',
      system: 'reps',
      defaultGoal: 15,
      description: 'Push-ups with your hands close together forming a diamond shape. Strongly emphasizes the triceps and inner chest.',
      youtubeUrl: 'https://www.youtube.com/watch?v=J0DnG1_S3Bo',
    ),
    Exercise(
      name: 'Wide Push-ups',
      type: 'wide_pushups',
      system: 'reps',
      defaultGoal: 15,
      description: 'Hands placed wider than shoulder-width. Shifts the focus to your outer chest muscles and shoulders.',
      youtubeUrl: 'https://www.youtube.com/watch?v=rr6eFNNDQdg',
    ),
    Exercise(
      name: 'Pike Push-ups',
      type: 'pike_pushups',
      system: 'reps',
      defaultGoal: 10,
      description: 'Hips elevated in an inverted V-shape. Excellent bodyweight shoulder press progression.',
      youtubeUrl: 'https://www.youtube.com/watch?v=spOS-wKPAas',
    ),
    Exercise(
      name: 'Archer Push-ups',
      type: 'archer_pushups',
      system: 'reps',
      defaultGoal: 8,
      description: 'Slide your body to one side at a time while keeping the opposite arm straight. Focuses on unilateral pushing strength.',
      youtubeUrl: 'https://www.youtube.com/watch?v=zT1J_3_jT0k',
    ),
    Exercise(
      name: 'Sit-ups',
      type: 'situps',
      system: 'reps',
      defaultGoal: 25,
      description: 'Lie on your back, knees bent, and lift your torso to your knees. Exercises the rectus abdominis.',
      youtubeUrl: 'https://www.youtube.com/watch?v=jDwoBqPH0yk',
    ),
    Exercise(
      name: 'Crunches',
      type: 'crunches',
      system: 'reps',
      defaultGoal: 30,
      description: 'Isolate the upper abs by raising only your shoulders off the floor while keeping the lower back flat.',
      youtubeUrl: 'https://www.youtube.com/watch?v=53m_T6qcox0',
    ),
    Exercise(
      name: 'Leg Raises',
      type: 'leg_raises',
      system: 'reps',
      defaultGoal: 15,
      description: 'Lie flat, lift legs straight up to a 90-degree angle. Targets the lower abs and hip flexors.',
      youtubeUrl: 'https://www.youtube.com/watch?v=JB2oyawG9KI',
    ),
    Exercise(
      name: 'Russian Twists',
      type: 'russian_twists',
      system: 'reps',
      defaultGoal: 40,
      description: 'Sit with knees bent, slightly lean back, and rotate your torso side to side to work the obliques.',
      youtubeUrl: 'https://www.youtube.com/watch?v=wkD8rjkSUIY',
    ),
    Exercise(
      name: 'Plank',
      type: 'plank',
      system: 'timer',
      defaultGoal: 60,
      description: 'Hold a forearm push-up position. Excellent static hold for overall core stability and strength.',
      youtubeUrl: 'https://www.youtube.com/watch?v=pSHjTRCQxIw',
    ),
    Exercise(
      name: 'Side Plank (L)',
      type: 'side_plank_l',
      system: 'timer',
      defaultGoal: 45,
      description: 'Support bodyweight on left forearm, keeping body straight. Emphasizes the lateral obliques.',
      youtubeUrl: 'https://www.youtube.com/watch?v=rCxF2e_tmP8',
    ),
    Exercise(
      name: 'Side Plank (R)',
      type: 'side_plank_r',
      system: 'timer',
      defaultGoal: 45,
      description: 'Support bodyweight on right forearm, keeping body straight. Emphasizes the lateral obliques.',
      youtubeUrl: 'https://www.youtube.com/watch?v=rCxF2e_tmP8',
    ),
    Exercise(
      name: 'Squats',
      type: 'squats',
      system: 'reps',
      defaultGoal: 30,
      description: 'Lower hips until thighs are parallel to the floor, then push back up. Develops quads, glutes, and hamstrings.',
      youtubeUrl: 'https://www.youtube.com/watch?v=gcNh17Ckjco',
    ),
    Exercise(
      name: 'Jump Squats',
      type: 'jump_squats',
      system: 'reps',
      defaultGoal: 20,
      description: 'Perform a squat and explosively jump straight up. Great for lower body explosive power and plyometrics.',
      youtubeUrl: 'https://www.youtube.com/watch?v=d_2eGheKpvY',
    ),
    Exercise(
      name: 'Lunges',
      type: 'lunges',
      system: 'reps',
      defaultGoal: 20,
      description: 'Step forward and lower hips until both knees are bent at 90 degrees. Improves balance and single-leg strength.',
      youtubeUrl: 'https://www.youtube.com/watch?v=QOVaHwm-Q6U',
    ),
    Exercise(
      name: 'Bulgarian Split Squats',
      type: 'bulgarian_squats',
      system: 'reps',
      defaultGoal: 12,
      description: 'Place one foot behind on an elevated surface and squat down on the forward leg. Heavy unilateral leg builder.',
      youtubeUrl: 'https://www.youtube.com/watch?v=2C-uNgKwPLE',
    ),
    Exercise(
      name: 'Wall Sit',
      type: 'wall_sit',
      system: 'timer',
      defaultGoal: 60,
      description: 'Press your back against a wall and slide down until knees form a 90-degree angle. Holds tension in the quads.',
      youtubeUrl: 'https://www.youtube.com/watch?v=y-wV4Hp9wGU',
    ),
    Exercise(
      name: 'Mountain Climbers',
      type: 'mountain_climbers',
      system: 'timer',
      defaultGoal: 45,
      description: 'In a push-up position, alternatingly drive knees towards your chest rapidly. Boosts cardiovascular endurance.',
      youtubeUrl: 'https://www.youtube.com/watch?v=cnyTQDSE884',
    ),
    Exercise(
      name: 'Burpees',
      type: 'burpees',
      system: 'reps',
      defaultGoal: 12,
      description: 'A full body conditioning exercise: drop into a push-up, jump up, and jump vertically with hands overhead.',
      youtubeUrl: 'https://www.youtube.com/watch?v=dZgVxmf6jkA',
    ),
    Exercise(
      name: 'Jumping Jacks',
      type: 'jumping_jacks',
      system: 'timer',
      defaultGoal: 60,
      description: 'Jump to a position with legs spread and hands overhead, then return. Classic full-body cardio warmup.',
      youtubeUrl: 'https://www.youtube.com/watch?v=2W4ZNSyWscY',
    ),
    Exercise(
      name: 'High Knees',
      type: 'high_knees',
      system: 'timer',
      defaultGoal: 45,
      description: 'Run in place, driving knees as high as possible. Excellent high-intensity cardio drill.',
      youtubeUrl: 'https://www.youtube.com/watch?v=ZZZoHjV_cE0',
    ),
    Exercise(
      name: 'Shadow Boxing',
      type: 'shadow_boxing',
      system: 'timer',
      defaultGoal: 120,
      description: 'Practice boxing strikes and movements in the air. Enhances shoulder endurance, coordination, and agility.',
      youtubeUrl: 'https://www.youtube.com/watch?v=f-B6XvjK85w',
    ),
    Exercise(
      name: 'Running',
      type: 'running',
      system: 'timer',
      defaultGoal: 300,
      description: 'Run outdoor or on a path. Outstanding cardio workout for endurance and leg conditioning.',
      youtubeUrl: 'https://www.youtube.com/watch?v=gc7h858a7k0',
    ),
    Exercise(
      name: 'Sprints',
      type: 'sprints',
      system: 'timer',
      defaultGoal: 30,
      description: 'Sprint at maximal effort. Builds explosive power, fast-twitch muscle fibers, and metabolic capacity.',
      youtubeUrl: 'https://www.youtube.com/watch?v=Lg6D34nZg78',
    ),
    Exercise(
      name: 'Burpee Broad Jumps',
      type: 'burpee_jumps',
      system: 'reps',
      defaultGoal: 10,
      description: 'Perform a burpee, but instead of jumping straight up, execute a powerful forward broad jump.',
      youtubeUrl: 'https://www.youtube.com/watch?v=cPhJtQ7e810',
    ),
  ];

  static const List<Exercise> gymExercises = [
    Exercise(
      name: 'Bench Press',
      type: 'bench_press',
      system: 'reps',
      defaultGoal: 12,
      description: 'Lie on a flat bench and press a barbell vertically. The ultimate chest, front delt, and tricep compound lift.',
      youtubeUrl: 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
    ),
    Exercise(
      name: 'Incline Press',
      type: 'incline_press',
      system: 'reps',
      defaultGoal: 12,
      description: 'Press barbell on a 30-45 degree incline bench to heavily target the clavicular (upper) head of the pecs.',
      youtubeUrl: 'https://www.youtube.com/watch?v=SrqOu55i-Yg',
    ),
    Exercise(
      name: 'Chest Press Machine',
      type: 'chest_machine',
      system: 'reps',
      defaultGoal: 15,
      description: 'Seated press on a fixed track machine. Great for isolating the chest safely with high tension.',
      youtubeUrl: 'https://www.youtube.com/watch?v=NwzUje3z0qY',
    ),
    Exercise(
      name: 'Pec Deck Fly',
      type: 'pec_deck',
      system: 'reps',
      defaultGoal: 15,
      description: 'Sit in machine and fly arms in a hugging arc. Isolates the pectorals, delivering an intense deep squeeze.',
      youtubeUrl: 'https://www.youtube.com/watch?v=eGjt4lk6gTY',
    ),
    Exercise(
      name: 'Cable Crossover',
      type: 'cable_cross',
      system: 'reps',
      defaultGoal: 15,
      description: 'Perform flyes using cable pulleys. Provides constant peak tension across the entire range of chest motion.',
      youtubeUrl: 'https://www.youtube.com/watch?v=W7B6a2M4Gq0',
    ),
    Exercise(
      name: 'Lat Pulldown',
      type: 'lat_pulldown',
      system: 'reps',
      defaultGoal: 12,
      description: 'Sit and pull weighted bar down to upper chest. Develops latissimus dorsi and general back width.',
      youtubeUrl: 'https://www.youtube.com/watch?v=CAwf7n6Luuc',
    ),
    Exercise(
      name: 'Seated Row',
      type: 'seated_row',
      system: 'reps',
      defaultGoal: 12,
      description: 'Pull cable attachment towards lower rib cage while keeping back straight. Targets mid-back, lats, and rhomboids.',
      youtubeUrl: 'https://www.youtube.com/watch?v=GZbfZ033f74',
    ),
    Exercise(
      name: 'T-Bar Row',
      type: 'tbar_row',
      system: 'reps',
      defaultGoal: 10,
      description: 'Hinge over at hips and pull bar handle towards chest. Heavy compound movement for back thickness.',
      youtubeUrl: 'https://www.youtube.com/watch?v=j3Igk5nyZE4',
    ),
    Exercise(
      name: 'Shoulder Press Machine',
      type: 'shoulder_machine',
      system: 'reps',
      defaultGoal: 12,
      description: 'Press handles vertically in a seated machine. Safely isolates the shoulder complex, primarily anterior delts.',
      youtubeUrl: 'https://www.youtube.com/watch?v=Wqq43d6181E',
    ),
    Exercise(
      name: 'Lateral Raise Machine',
      type: 'lateral_machine',
      system: 'reps',
      defaultGoal: 15,
      description: 'Raise padded levers outwards to the sides. The best way to isolate the lateral delts for broad shoulders.',
      youtubeUrl: 'https://www.youtube.com/watch?v=2SgS4w13vjU',
    ),
    Exercise(
      name: 'Face Pulls',
      type: 'face_pulls',
      system: 'reps',
      defaultGoal: 15,
      description: 'Pull rope attachment from cable tower to face level while flaring elbows. Builds rear delts and rotator cuffs.',
      youtubeUrl: 'https://www.youtube.com/watch?v=V81E3SssxKU',
    ),
    Exercise(
      name: 'Leg Press',
      type: 'leg_press',
      system: 'reps',
      defaultGoal: 15,
      description: 'Push loaded platform away with legs on a 45-degree angle sled. Heavy leg development without lower back fatigue.',
      youtubeUrl: 'https://www.youtube.com/watch?v=CHLg4Vd1124',
    ),
    Exercise(
      name: 'Leg Extension',
      type: 'leg_extension',
      system: 'reps',
      defaultGoal: 15,
      description: 'Sit in machine and extend knees to lift weight. Isolates the quadriceps, perfect for sculpting leg muscles.',
      youtubeUrl: 'https://www.youtube.com/watch?v=m0FOpMEgero',
    ),
    Exercise(
      name: 'Leg Curl',
      type: 'leg_curl',
      system: 'reps',
      defaultGoal: 15,
      description: 'Lie or sit down and pull padded bar under towards glutes. Safely isolates the hamstrings.',
      youtubeUrl: 'https://www.youtube.com/watch?v=F488kYLeGQM',
    ),
    Exercise(
      name: 'Hack Squat',
      type: 'hack_squat',
      system: 'reps',
      defaultGoal: 10,
      description: 'Squat on a guided, angled machine with shoulder supports. Strongly targets the quad sweep.',
      youtubeUrl: 'https://www.youtube.com/watch?v=Ed7GZcahc5s',
    ),
    Exercise(
      name: 'Smith Machine Squat',
      type: 'smith_squat',
      system: 'reps',
      defaultGoal: 12,
      description: 'Squat using a barbell secured on linear steel guides. Allows strict focus on legs with perfect balance.',
      youtubeUrl: 'https://www.youtube.com/watch?v=kYcI4hZzUfU',
    ),
    Exercise(
      name: 'Calf Press',
      type: 'calf_press',
      system: 'reps',
      defaultGoal: 20,
      description: 'Press weight away with balls of your feet on leg press or machine. Builds the gastrocnemius calf muscles.',
      youtubeUrl: 'https://www.youtube.com/watch?v=KxEY7SAH1T8',
    ),
    Exercise(
      name: 'Tricep Pushdown',
      type: 'tricep_pushdown',
      system: 'reps',
      defaultGoal: 15,
      description: 'Pull cable attachment down extending arms fully at the bottom. Great for isolating all three tricep heads.',
      youtubeUrl: 'https://www.youtube.com/watch?v=2-LAMcpzODU',
    ),
    Exercise(
      name: 'Dips Machine',
      type: 'dips_machine',
      system: 'reps',
      defaultGoal: 12,
      description: 'Press seated machine levers downward, mimicking weighted chest dips. Excellent lower pec and tricep builder.',
      youtubeUrl: 'https://www.youtube.com/watch?v=tT8h8w1Bvzo',
    ),
    Exercise(
      name: 'Bicep Curl Machine',
      type: 'bicep_machine',
      system: 'reps',
      defaultGoal: 12,
      description: 'Curl padded levers upwards. Keeps constant mechanical tension on the biceps throughout the curl.',
      youtubeUrl: 'https://www.youtube.com/watch?v=wz_Wsz8Z4S4',
    ),
    Exercise(
      name: 'Preacher Curl',
      type: 'preacher_curl',
      system: 'reps',
      defaultGoal: 12,
      description: 'Curl bar with upper arms supported flat on a sloped pad. Isolates the biceps by preventing momentum/cheating.',
      youtubeUrl: 'https://www.youtube.com/watch?v=fIWP-FRFNU0',
    ),
    Exercise(
      name: 'Deadlift',
      type: 'deadlift',
      system: 'reps',
      defaultGoal: 8,
      description: 'Lift a loaded barbell from the floor to hip height. The king of posterior chain compound lifts.',
      youtubeUrl: 'https://www.youtube.com/watch?v=ytGaGIn3SjY',
    ),
    Exercise(
      name: 'Romanian Deadlift',
      type: 'rdl',
      system: 'reps',
      defaultGoal: 12,
      description: 'Hinge hips backward lowering bar to mid-shin with straight back and minimal knee bend. Hamstrings & glutes builder.',
      youtubeUrl: 'https://www.youtube.com/watch?v=jEy_cxoKSo0',
    ),
    Exercise(
      name: 'Hyperextension',
      type: 'hyperextension',
      system: 'reps',
      defaultGoal: 15,
      description: 'Extend upper body up from a 45-degree angle Roman chair. Strengthens lower back, glutes, and hamstrings.',
      youtubeUrl: 'https://www.youtube.com/watch?v=ph3pddpKzzw',
    ),
    Exercise(
      name: 'Treadmill',
      type: 'treadmill',
      system: 'timer',
      defaultGoal: 600,
      description: 'Walk, jog, or run on a motorized belt machine. Versatile and controllable indoor cardio work.',
      youtubeUrl: 'https://www.youtube.com/watch?v=yYyO7y2Nl1Q',
    ),
    Exercise(
      name: 'Elliptical',
      type: 'elliptical',
      system: 'timer',
      defaultGoal: 600,
      description: 'Cardio training on a low-impact gliding machine. Excellent calorie-burning and joint-friendly conditioning.',
      youtubeUrl: 'https://www.youtube.com/watch?v=d_kH1q_u1Qc',
    ),
    Exercise(
      name: 'Rowing Machine',
      type: 'rower',
      system: 'timer',
      defaultGoal: 300,
      description: 'Perform seated pulls in an active rowing motion. Superior full-body cardio and muscle endurance tool.',
      youtubeUrl: 'https://www.youtube.com/watch?v=Usc8G110mH4',
    ),
  ];

  static List<Exercise> get all => [...homeExercises, ...gymExercises];
}

class RankSystem {
  static const Map<String, int> rankMaxLevel = {
    'E': 8, 'D': 15, 'C': 25, 'BB': 40, 'A': 60, 'S': 80, 'SS': 100, 'SG': 150,
  };

  static const Map<String, int> xpPerLevel = {
    'E': 100, 'D': 250, 'C': 500, 'BB': 1000, 'A': 2000, 'S': 4000, 'SS': 8000, 'SG': 15000,
  };

  static const Map<String, int> questXpReward = {
    'E': 10, 'D': 20, 'C': 40, 'BB': 80, 'A': 160, 'S': 320, 'SS': 640, 'SG': 1000,
  };

  static const List<String> ranks = ['E', 'D', 'C', 'BB', 'A', 'S', 'SS', 'SG'];

  static int getXpNeededForNextLevel(String rank) => xpPerLevel[rank] ?? 100;
  static int getQuestXpReward(String rank) => questXpReward[rank] ?? 50;

  static int getMaxReps(String rank, int level) {
    if (rank == 'E') return 10;
    switch (rank) {
      case 'D': return (20 + (level - 9) * 5).clamp(20, 100); 
      case 'C': return (30 + (level - 16) * 6).clamp(30, 200); 
      case 'BB': return (100 + (level - 26) * 8).clamp(100, 400); 
      case 'A': return (220 + (level - 41) * 10).clamp(220, 700);
      case 'S': return (430 + (level - 61) * 15).clamp(430, 1200);
      case 'SS': return (750 + (level - 81) * 20).clamp(750, 2000);
      case 'SG': return (1200 + (level - 101) * 25).clamp(1200, 5000);
      default: return 10;
    }
  }

  static bool canPromoteRank(String currentRank, int currentLevel) {
    final maxLevel = rankMaxLevel[currentRank] ?? 8;
    return currentLevel >= maxLevel;
  }

  static String? getNextRank(String currentRank) {
    final currentIndex = ranks.indexOf(currentRank);
    if (currentIndex >= 0 && currentIndex < ranks.length - 1) return ranks[currentIndex + 1];
    return null;
  }
}

class Storage {
  static const String boxName = 'solo_gainz_box';
  
  static const String userStatsKey = 'user_stats';
  static const String dailyQuestsKey = 'daily_quests';
  static const String dailyTemplatesKey = 'daily_quest_templates';
  static const String customQuestsKey = 'custom_quests';
  static const String inventoryKey = 'inventory_slots';
  static const String maxSlotsKey = 'max_slots';

  static late final Box _box;
  static bool _isInit = false;

  static Future<void> init() async {
    if (_isInit) return;
    
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserStatsAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DailyQuestAdapter());

    final cipher = await SecurityService.getHiveCipher();

    try {
      _box = await Hive.openBox(boxName, encryptionCipher: cipher);
    } catch (_) {
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

  static Future<void> saveData(String key, dynamic value) => _box.put(key, value);
  static dynamic getData(String key, {dynamic defaultValue}) => _isInit ? _box.get(key, defaultValue: defaultValue) : defaultValue;
  static Future<void> deleteData(String key) => _box.delete(key);
  static Future<void> clearAll() => _box.clear();
  static ValueListenable<Box> watch(dynamic key) => 
      key is String ? _box.listenable(keys: [key]) : (key is List<String> ? _box.listenable(keys: key) : _box.listenable());

  static UserStats getUserStats() {
    final stats = _box.get(userStatsKey) ?? UserStats();
    stats.achievements = List<String>.from(stats.achievements);
    stats.lifetimeStats = Map<String, int>.from(stats.lifetimeStats);
    return stats;
  }

  static Future<void> saveUserStats(UserStats stats) async {
    await _box.put(userStatsKey, stats);
    await _updateHomeWidget(getDailyQuests());
  }

  static Future<void> addCoins(int amount) async {
    final stats = getUserStats()..coins += amount;
    await saveUserStats(stats);
    await AchievementChecker.checkOnCoins(stats.coins, stats.achievements);
  }

  static Future<void> addXp(int amount) async {
    final stats = getUserStats();
    stats.xp += amount;
    bool rankChanged = false;
    bool levelChanged = false;
    while (true) {
      final need = RankSystem.getXpNeededForNextLevel(stats.rank);
      if (stats.xp >= need) {
        stats.xp -= need;
        stats.level++;
        levelChanged = true;
        if (RankSystem.canPromoteRank(stats.rank, stats.level)) {
          final next = RankSystem.getNextRank(stats.rank);
          if (next != null) stats.rank = next;
          rankChanged = true;
        }
      } else {
        break;
      }
    }
    await saveUserStats(stats);

    if (rankChanged) {
      NotificationService.showRankUp(stats.rank);
    } else if (levelChanged) {
      NotificationService.showLevelUp(stats.level);
    }

    await AchievementChecker.checkOnLevel(stats.level, stats.achievements);
    await AchievementChecker.checkOnRank(stats.rank, stats.achievements);
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

  static Future<void> checkDailyLoginReward() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = getData('last_daily_reward_date');
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;

    int streak = getData('login_streak', defaultValue: 0);
    final lastStreakDateStr = getData('last_streak_date');
    final lastStreakDate = lastStreakDateStr != null ? DateTime.tryParse(lastStreakDateStr) : null;

    if (last != null && !today.isAfter(last)) return;

    final yesterday = today.subtract(const Duration(days: 1));
    if (lastStreakDate != null && lastStreakDate == yesterday) {
      streak++;
    } else {
      streak = 1;
    }

    final streakMultiplier = 1.0 + (streak - 1) * 0.15;
    final baseCoins = 30;
    final bonusCoins = (baseCoins * streakMultiplier).round();
    final bonusXp = (streak * 5).round();

    await addCoins(bonusCoins);
    await addXp(bonusXp);
    await saveData('last_daily_reward_date', today.toIso8601String());
    await saveData('last_streak_date', today.toIso8601String());
    await saveData('login_streak', streak);

    await AchievementChecker.checkOnStreak(streak, getUserStats().achievements);
  }

  static int getLoginStreak() => getData('login_streak', defaultValue: 0);
  static double getStreakMultiplier() {
    final streak = getLoginStreak();
    return 1.0 + (streak - 1) * 0.15;
  }

  static int getProgress() => getData('progress', defaultValue: 0);
  static Future<void> setProgress(int value) => saveData('progress', value);

  static List<DailyQuest> getDailyQuests() => (_box.get(dailyQuestsKey) as List?)?.cast<DailyQuest>().toList() ?? [];
  static Future<void> saveDailyQuests(List<DailyQuest> quests) async {
    final oldQuests = getDailyQuests();
    final bool oldAllCompleted = oldQuests.isNotEmpty && oldQuests.every((q) => q.completed);

    await _box.put(dailyQuestsKey, quests);
    await _updateHomeWidget(quests);

    final bool newAllCompleted = quests.isNotEmpty && quests.every((q) => q.completed);
    if (newAllCompleted && !oldAllCompleted) {
      NotificationService.showQuestsCompleted();
    }
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

      if (_box.containsKey(userStatsKey)) {
        final stats = getUserStats();
        await HomeWidget.saveWidgetData<String>('player_rank', stats.rank);
        await HomeWidget.saveWidgetData<int>('player_level', stats.level);
        
        final xpNeeded = RankSystem.getXpNeededForNextLevel(stats.rank);
        await HomeWidget.saveWidgetData<int>('player_xp', stats.xp);
        await HomeWidget.saveWidgetData<int>('player_xp_needed', xpNeeded);
        await HomeWidget.saveWidgetData<int>('player_xp_percent', xpNeeded == 0 ? 0 : (stats.xp / xpNeeded * 100).toInt());
        await HomeWidget.saveWidgetData<int>('player_coins', stats.coins);
      }

      await HomeWidget.updateWidget(name: 'QuestWidgetProvider', androidName: 'QuestWidgetProvider');
      await HomeWidget.updateWidget(name: 'StatsWidgetProvider', androidName: 'StatsWidgetProvider');
      await HomeWidget.updateWidget(name: 'CoinsWidgetProvider', androidName: 'CoinsWidgetProvider');
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
    if (chestType == 'mysterious_chest') return const Duration(hours: 12);
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

  static bool isLoggedIn() => true;
  static bool isOnboarded() => getData('is_onboarded', defaultValue: false);
  static String? getCurrentUser() => getData('player_name', defaultValue: 'Player');
  static Future<void> setPlayerName(String name) => saveData('player_name', name);
  static String? getProfileImage() => getData('profile_image') ?? getData('profile_image_path');
  static Future<String> setProfileImage(String tempPath) async {
    try {
      final file = File(tempPath);
      if (await file.exists()) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final extIndex = tempPath.lastIndexOf('.');
        final extension = extIndex != -1 ? tempPath.substring(extIndex) : '.jpg';
        final newFileName = 'profile_pic_${DateTime.now().millisecondsSinceEpoch}$extension';
        final permanentFile = File('${appDocDir.path}/$newFileName');

        // Copy the file to permanent storage
        await file.copy(permanentFile.path);

        // Delete old profile image if it exists to clean up space
        final oldPath = getProfileImage();
        if (oldPath != null && oldPath.isNotEmpty) {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            try {
              await oldFile.delete();
            } catch (e) {
              debugPrint('Error deleting old profile image: $e');
            }
          }
        }

        // Save the new permanent path
        await saveData('profile_image', permanentFile.path);
        await saveData('profile_image_path', permanentFile.path);
        return permanentFile.path;
      }
    } catch (e) {
      debugPrint('Error saving permanent profile image: $e');
    }

    // Fallback if copy fails
    await saveData('profile_image', tempPath);
    await saveData('profile_image_path', tempPath);
    return tempPath;
  }
  static bool isNavbarFloating() => getData('is_navbar_floating', defaultValue: false);
  static Future<void> setNavbarFloating(bool value) => saveData('is_navbar_floating', value);
  static bool isNavbarHidden() => getData('is_navbar_hidden', defaultValue: false);
  static Future<void> setNavbarHidden(bool value) => saveData('is_navbar_hidden', value);

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
      }
    } catch (e) {
      debugPrint('Storage.decodeAndApplyData error: $e');
    }
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
