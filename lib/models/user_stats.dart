import 'package:hive/hive.dart';

part 'user_stats.g.dart';

@HiveType(typeId: 0)
class UserStats {
  @HiveField(0)
  String rank; // E, D, C, BB, A, S, SS, SG

  @HiveField(1)
  int level; // 1-8 per rank

  @HiveField(2)
  int xp; // Current XP

  @HiveField(3)
  int coins;

  @HiveField(4)
  int progress; // Daily progress (steps or reps total)

  @HiveField(5)
  DateTime lastDailyRefresh;

  @HiveField(8)
  DateTime? lastActiveDate;

  @HiveField(9)
  List<String> achievements;

  @HiveField(10)
  Map<String, int> lifetimeStats; // e.g., {'pushups': 500, 'running': 3600}

  UserStats({
    this.rank = 'E',
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.progress = 0,
    this.lastActiveDate,
    this.achievements = const [],
    this.lifetimeStats = const {},
    DateTime? lastDailyRefresh,
  }) : lastDailyRefresh = lastDailyRefresh ?? DateTime.now();
}

@HiveType(typeId: 1)
class DailyQuest {
  @HiveField(0)
  String questName;

  @HiveField(1)
  String questType; // Identifier for the exercise

  @HiveField(2)
  int maxGoal; // Reps or Seconds

  @HiveField(3)
  int currentProgress;

  @HiveField(4)
  int xpReward;

  @HiveField(5)
  bool completed;

  @HiveField(6)
  DateTime createdDate;

  @HiveField(7)
  String system; // 'reps' or 'timer'

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

  const Exercise({
    required this.name,
    required this.type,
    required this.system,
    required this.defaultGoal,
  });
}

class ExerciseLibrary {
  static const List<Exercise> homeExercises = [
    Exercise(name: 'Push-ups', type: 'pushups', system: 'reps', defaultGoal: 20),
    Exercise(name: 'Diamond Push-ups', type: 'diamond_pushups', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Wide Push-ups', type: 'wide_pushups', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Pike Push-ups', type: 'pike_pushups', system: 'reps', defaultGoal: 10),
    Exercise(name: 'Archer Push-ups', type: 'archer_pushups', system: 'reps', defaultGoal: 8),
    Exercise(name: 'Sit-ups', type: 'situps', system: 'reps', defaultGoal: 25),
    Exercise(name: 'Crunches', type: 'crunches', system: 'reps', defaultGoal: 30),
    Exercise(name: 'Leg Raises', type: 'leg_raises', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Russian Twists', type: 'russian_twists', system: 'reps', defaultGoal: 40),
    Exercise(name: 'Plank', type: 'plank', system: 'timer', defaultGoal: 60),
    Exercise(name: 'Side Plank (L)', type: 'side_plank_l', system: 'timer', defaultGoal: 45),
    Exercise(name: 'Side Plank (R)', type: 'side_plank_r', system: 'timer', defaultGoal: 45),
    Exercise(name: 'Squats', type: 'squats', system: 'reps', defaultGoal: 30),
    Exercise(name: 'Jump Squats', type: 'jump_squats', system: 'reps', defaultGoal: 20),
    Exercise(name: 'Lunges', type: 'lunges', system: 'reps', defaultGoal: 20),
    Exercise(name: 'Bulgarian Split Squats', type: 'bulgarian_squats', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Wall Sit', type: 'wall_sit', system: 'timer', defaultGoal: 60),
    Exercise(name: 'Mountain Climbers', type: 'mountain_climbers', system: 'timer', defaultGoal: 45),
    Exercise(name: 'Burpees', type: 'burpees', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Jumping Jacks', type: 'jumping_jacks', system: 'timer', defaultGoal: 60),
    Exercise(name: 'High Knees', type: 'high_knees', system: 'timer', defaultGoal: 45),
    Exercise(name: 'Shadow Boxing', type: 'shadow_boxing', system: 'timer', defaultGoal: 120),
    Exercise(name: 'Running', type: 'running', system: 'timer', defaultGoal: 300),
    Exercise(name: 'Sprints', type: 'sprints', system: 'timer', defaultGoal: 30),
    Exercise(name: 'Burpee Broad Jumps', type: 'burpee_jumps', system: 'reps', defaultGoal: 10),
  ];

  static const List<Exercise> gymExercises = [
    Exercise(name: 'Bench Press', type: 'bench_press', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Incline Press', type: 'incline_press', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Chest Press Machine', type: 'chest_machine', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Pec Deck Fly', type: 'pec_deck', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Cable Crossover', type: 'cable_cross', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Lat Pulldown', type: 'lat_pulldown', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Seated Row', type: 'seated_row', system: 'reps', defaultGoal: 12),
    Exercise(name: 'T-Bar Row', type: 'tbar_row', system: 'reps', defaultGoal: 10),
    Exercise(name: 'Shoulder Press Machine', type: 'shoulder_machine', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Lateral Raise Machine', type: 'lateral_machine', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Face Pulls', type: 'face_pulls', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Leg Press', type: 'leg_press', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Leg Extension', type: 'leg_extension', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Leg Curl', type: 'leg_curl', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Hack Squat', type: 'hack_squat', system: 'reps', defaultGoal: 10),
    Exercise(name: 'Smith Machine Squat', type: 'smith_squat', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Calf Press', type: 'calf_press', system: 'reps', defaultGoal: 20),
    Exercise(name: 'Tricep Pushdown', type: 'tricep_pushdown', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Dips Machine', type: 'dips_machine', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Bicep Curl Machine', type: 'bicep_machine', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Preacher Curl', type: 'preacher_curl', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Deadlift', type: 'deadlift', system: 'reps', defaultGoal: 8),
    Exercise(name: 'Romanian Deadlift', type: 'rdl', system: 'reps', defaultGoal: 12),
    Exercise(name: 'Hyperextension', type: 'hyperextension', system: 'reps', defaultGoal: 15),
    Exercise(name: 'Treadmill', type: 'treadmill', system: 'timer', defaultGoal: 600),
    Exercise(name: 'Elliptical', type: 'elliptical', system: 'timer', defaultGoal: 600),
    Exercise(name: 'Rowing Machine', type: 'rower', system: 'timer', defaultGoal: 300),
  ];

  static List<Exercise> get all => [...homeExercises, ...gymExercises];
}

class RankSystem {
  static const Map<String, int> rankMaxLevel = {
    'E': 8,
    'D': 15,
    'C': 25,
    'BB': 40,
    'A': 60,
    'S': 80,
    'SS': 100,
    'SG': 150,
  };

  static const Map<String, int> xpPerLevel = {
    'E': 100,
    'D': 250,
    'C': 500,
    'BB': 1000,
    'A': 2000,
    'S': 4000,
    'SS': 8000,
    'SG': 15000,
  };

  static const Map<String, int> questXpReward = {
    'E': 10,
    'D': 20,
    'C': 40,
    'BB': 80,
    'A': 160,
    'S': 320,
    'SS': 640,
    'SG': 1000,
  };

  static const List<String> ranks = ['E', 'D', 'C', 'BB', 'A', 'S', 'SS', 'SG'];

  static int getXpNeededForNextLevel(String rank) {
    return xpPerLevel[rank] ?? 100;
  }

  static int getQuestXpReward(String rank) {
    return questXpReward[rank] ?? 50;
  }

  static int getMaxReps(String rank, int level) {
    if (rank == 'E') return 10;
    
    // Progressive difficulty for other ranks
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
    if (currentIndex >= 0 && currentIndex < ranks.length - 1) {
      return ranks[currentIndex + 1];
    }
    return null;
  }
}
