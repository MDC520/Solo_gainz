import 'dart:async';
import 'dart:math';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';

class DungeonWorkoutScreen extends StatefulWidget {
  const DungeonWorkoutScreen({super.key});

  @override
  State<DungeonWorkoutScreen> createState() => _DungeonWorkoutScreenState();
}

class _DungeonWorkoutScreenState extends State<DungeonWorkoutScreen> {
  late UserStats _s;
  List<DailyQuest> _floorQuests = [];
  int _currentIdx = 0;
  bool _finished = false;

  // Timer for time-based exercises
  Timer? _timer;
  int _secondsLeft = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _s = Storage.getUserStats();
    _generateFloor();
  }

  void _generateFloor() {
    final rand = Random();
    final allExercises = ExerciseLibrary.all;

    // Create 3-5 random exercises for the floor based on rank
    int count = 3;
    if (_s.rank == 'C' || _s.rank == 'D') count = 4;
    if (_s.rank.contains('S') || _s.rank == 'A') count = 5;

    final List<DailyQuest> quests = [];
    final selected = <String>{};

    while (quests.length < count) {
      final ex = allExercises[rand.nextInt(allExercises.length)];
      if (selected.contains(ex.type)) continue;
      selected.add(ex.type);

      final goal = RankSystem.getMaxReps(_s.rank, _s.level);
      quests.add(DailyQuest(
        questName: ex.name,
        questType: ex.type,
        maxGoal: ex.system == 'timer' ? ex.defaultGoal : goal,
        xpReward: RankSystem.getQuestXpReward(_s.rank),
        system: ex.system,
      ));
    }

    setState(() => _floorQuests = quests);
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _secondsLeft = seconds;
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        setState(() => _isTimerRunning = false);
        AppTheme.success();
      }
    });
  }

  void _next() {
    if (_currentIdx < _floorQuests.length - 1) {
      setState(() => _currentIdx++);
    } else {
      _completeFloor();
    }
  }

  Future<void> _completeFloor() async {
    setState(() => _finished = true);

    // Multi-reward for clearing a floor
    final bonusXp = RankSystem.getQuestXpReward(_s.rank) * 2;
    final bonusCoins = 50 + (Random().nextInt(50));

    await Storage.addXp(bonusXp);
    await Storage.addCoins(bonusCoins);

    // Chance for a chest
    if (Random().nextDouble() < 0.3) {
      final chestType = Random().nextBool() ? 'wooden_chest' : 'iron_chest';
      await Storage.addChestToInventory(chestType);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildFinished();

    final q = _floorQuests[_currentIdx];
    final isTimer = q.system == 'timer';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.15),
                    Colors.transparent
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DUNGEON FLOOR CLEAR',
                              style: AppTheme.label(color: AppTheme.accent)),
                          Text(
                              'STAGE ${_currentIdx + 1}/${_floorQuests.length}',
                              style: AppTheme.h1()),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Text('${_currentIdx + 1}',
                            style: AppTheme.mono(
                                color: AppTheme.accent, size: 14)),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Central Card
                  SGCard(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTimer
                                ? Icons.timer_rounded
                                : Icons.fitness_center_rounded,
                            size: 48,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(q.questName.toUpperCase(),
                            style: AppTheme.h2(), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(
                          isTimer ? 'HOLD FOR' : 'COMPLETE',
                          style: AppTheme.label(color: AppTheme.muted),
                        ),
                        Text(
                          '${q.maxGoal}${isTimer ? "s" : ""}',
                          style: AppTheme.h1(color: AppTheme.white).copyWith(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (isTimer)
                          _isTimerRunning
                              ? Text('$_secondsLeft',
                                  style: AppTheme.h1(color: AppTheme.amber)
                                      .copyWith(fontSize: 48))
                              : SGButton(
                                  label: 'START TIMER',
                                  onTap: () => _startTimer(q.maxGoal),
                                )
                        else
                          SGButton(
                            label: 'FINISHED',
                            onTap: _next,
                          ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Exit early
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('RETREAT FROM DUNGEON',
                        style: AppTheme.label(color: AppTheme.red)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded,
                    size: 80, color: AppTheme.green),
              ),
              const SizedBox(height: 32),
              Text('FLOOR CLEARED!', style: AppTheme.h1(color: AppTheme.green)),
              const SizedBox(height: 8),
              Text(
                'You have successfully conquered this dungeon floor. Rewards have been added to your account.',
                style: AppTheme.body(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SGButton(
                label: 'RETURN TO FOYER',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
