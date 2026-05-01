import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';

class QuestPage extends StatefulWidget {
  const QuestPage({super.key});
  @override
  State<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends State<QuestPage> with TickerProviderStateMixin {
  List<DailyQuest> _quests = [];
  List<DailyQuest> _customQuests = [];
  UserStats? _stats;
  List<AnimationController> _anims = [];
  List<AnimationController> _customAnims = [];
  int _tab = 0;
  bool _isShattering = false;

  static final _qColors = [
    AppTheme.accent,
    AppTheme.red,
    AppTheme.cyan,
    AppTheme.amber,
  ];

  ValueListenable<Box>? _dailyQuestsListenable;
  ValueListenable<Box>? _customQuestsListenable;

  @override
  void initState() {
    super.initState();
    _anims = [];
    _customAnims = [];
    _init(checkNewDay: true);

    // Store listeners to ensure they can be removed in dispose
    _dailyQuestsListenable = Storage.watch(Storage.dailyQuestsKey);
    _customQuestsListenable = Storage.watch(Storage.customQuestsKey);

    _dailyQuestsListenable?.addListener(_onStorageChange);
    _customQuestsListenable?.addListener(_onStorageChange);

    _syncAnims();
  }

  void _syncAnims() {
    try {
      // Scale daily animations
      if (_anims.length != _quests.length) {
        for (var c in _anims) {
          c.dispose();
        }
        _anims = List.generate(
          _quests.length,
          (i) => AnimationController(
            duration: Duration(milliseconds: 300 + i * 80),
            vsync: this,
          )..forward(),
        );
      }

      // Scale custom animations
      if (_customAnims.length != _customQuests.length) {
        for (var c in _customAnims) {
          c.dispose();
        }
        _customAnims = List.generate(
          _customQuests.length,
          (i) => AnimationController(
            duration: Duration(milliseconds: 300 + i * 80),
            vsync: this,
          )..forward(),
        );
      }
    } catch (e) {
      debugPrint('SyncAnims error: $e');
    }
  }

  void _onStorageChange() {
    if (mounted) {
      setState(() {
        _init(checkNewDay: false);
        // Regenerate anims if length changed to prevent RangeError
        _syncAnims();
      });
    }
  }

  @override
  void dispose() {
    _dailyQuestsListenable?.removeListener(_onStorageChange);
    _customQuestsListenable?.removeListener(_onStorageChange);
    for (var c in _anims) {
      c.dispose();
    }
    for (var c in _customAnims) {
      c.dispose();
    }
    super.dispose();
  }

  void _init({bool checkNewDay = false, bool isRealTimeRefresh = false}) {
    try {
      _stats = Storage.getUserStats();
      final now = DateTime.now();
      final last = _stats?.lastDailyRefresh ?? now;
      final isNewDay = last.day != now.day ||
          last.month != now.month ||
          last.year != now.year;

      if ((checkNewDay && isNewDay) || isRealTimeRefresh) {
        _newQuests();
        _customQuests = Storage.getCustomQuests();
        _customQuests
            .removeWhere((q) => q.questType == "custom_onetime" && q.completed);
        for (var q in _customQuests) {
          if (q.questType.startsWith("custom_daily")) {
            q.currentProgress = 0;
            q.completed = false;
          }
        }
        Storage.saveCustomQuests(_customQuests);
      } else {
        _quests = Storage.getDailyQuests();
        if (_quests.isEmpty) _newQuests();
        _customQuests = Storage.getCustomQuests();
      }
    } catch (e) {
      debugPrint('Quest screen init error: $e');
      _quests = [];
      _customQuests = [];
    }
  }

  void _triggerRealTimeRefresh() {
    if (_isShattering) return;
    setState(() {
      _isShattering = true;
    });

    // Wait for glass shatter drop simulation
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _init(isRealTimeRefresh: true);
          _isShattering = false;
        });
      }
    });
  }

  void _newQuests() {
    final stats = _stats ?? Storage.getUserStats();
    final templates = Storage.getDailyTemplates();
    final max = RankSystem.getMaxReps(stats.rank, stats.level);

    final reward = RankSystem.getQuestXpReward(stats.rank);

    if (templates.isNotEmpty) {
      _quests = templates
          .map((t) => DailyQuest(
                questName: t.questName,
                questType: t.questType,
                maxGoal: t.system == "timer" ? max * 6 : max,
                xpReward: reward,
                system: t.system,
              ))
          .toList();
    } else {
      _quests = [
        DailyQuest(
          questName: 'Push-ups',
          questType: 'pushups',
          maxGoal: max,
          xpReward: reward,
          system: 'reps',
        ),
        DailyQuest(
          questName: 'Sit-ups',
          questType: 'situps',
          maxGoal: max,
          xpReward: reward,
          system: 'reps',
        ),
        DailyQuest(
          questName: 'Squats',
          questType: 'squats',
          maxGoal: max,
          xpReward: reward,
          system: 'reps',
        ),
        DailyQuest(
          questName: 'Running',
          questType: 'running',
          maxGoal: max * 6,
          xpReward: reward,
          system: 'timer',
        ),
      ];
      Storage.saveDailyTemplates(_quests);
    }

    Storage.saveDailyQuests(_quests);
    if (_stats != null) {
      _stats!.lastDailyRefresh = DateTime.now();
      Storage.saveUserStats(_stats!);
    }
  }

  Future<void> _updateReps(int i, int delta) async {
    final q = _quests[i];
    if (q.completed) return;
    q.currentProgress = (q.currentProgress + delta).clamp(0, q.maxGoal);
    await Storage.updateDailyQuest(i, q);

    if (delta > 0) {
      await Storage.addLifetimeStat(q.questType, delta);
      _checkAchievements();
    }

    setState(() {});
  }

  Future<void> _completeQuest(int i) async {
    final q = _quests[i];
    if (q.completed || q.currentProgress < q.maxGoal) return;
    q.completed = true;
    await Storage.updateDailyQuest(i, q);
    if (_stats != null) {
      _stats!.xp += q.xpReward;
      _levelUp();
      _handleChestDrop();
      await Storage.addLifetimeStat('total_completed', 1);
      _checkAchievements();
    }
    setState(() {});
    _xpDialog(q.xpReward);
  }

  void _checkAchievements() async {
    final s = Storage.getUserStats();
    final pushups = s.lifetimeStats['pushups'] ?? 0;
    if (pushups >= 100 && !s.achievements.contains('pushup_master')) {
      await Storage.unlockAchievement('pushup_master');
      _achievementDialog('Push-up Novice', 'Completed 100 push-ups!');
    }

    final total = s.lifetimeStats['total_completed'] ?? 0;
    if (total >= 50 && !s.achievements.contains('quest_master')) {
      await Storage.unlockAchievement('quest_master');
      _achievementDialog('Quest Master', 'Completed 50 daily missions!');
    }
  }

  void _achievementDialog(String title, String desc) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Achievement Unlocked!',
            style: AppTheme.h2(color: AppTheme.amber)),
        content: Column(
          children: [
            Icon(Icons.workspace_premium, size: 48, color: AppTheme.amber),
            const SizedBox(height: 8),
            Text(title, style: AppTheme.h3()),
            const SizedBox(height: 4),
            Text(desc, style: AppTheme.caption()),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child:
                Text('Awesome', style: AppTheme.label(color: AppTheme.accent)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCustomReps(int i, int delta) async {
    final q = _customQuests[i];
    if (q.completed) return;
    q.currentProgress = (q.currentProgress + delta).clamp(0, q.maxGoal);
    await Storage.updateCustomQuest(i, q);
    setState(() {});
  }

  Future<void> _completeCustomQuest(int i) async {
    final q = _customQuests[i];
    if (q.completed || q.currentProgress < q.maxGoal) return;
    q.completed = true;
    await Storage.updateCustomQuest(i, q);
    if (_stats != null) {
      _stats!.xp += q.xpReward;
      _levelUp();
      _handleChestDrop();
      await Storage.addLifetimeStat('total_completed', 1);
      _checkAchievements();
    }
    setState(() {});
    _xpDialog(q.xpReward);
  }

  void _handleChestDrop() {
    // 35% chance to drop a chest
    Timer.run(() async {
      final rand = DateTime.now().millisecond % 100;
      if (rand < 35) {
        final type = (rand < 10) ? 'iron_chest' : 'wooden_chest';
        if (Storage.hasEmptySlot()) {
          Storage.addChestToInventory(type);
          _chestFoundDialog(type);
        }
      }
    });
  }

  void _chestFoundDialog(String type) {
    if (!mounted) return;
    final isIron = type == 'iron_chest';
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Chest Found!',
            style: AppTheme.h2(color: isIron ? AppTheme.cyan : AppTheme.amber)),
        content: Text(
            'You earned a ${isIron ? "Iron" : "Wooden"} chest for your hard work!',
            style: AppTheme.body()),
        actions: [
          CupertinoDialogAction(
            child: Text('Visit Inventory',
                style: AppTheme.label(color: AppTheme.accent)),
            onPressed: () {
              Navigator.pop(ctx);
              // Navigation can be added here if needed
            },
          ),
          CupertinoDialogAction(
            child: Text('Nice', style: AppTheme.label()),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _levelUp() {
    if (_stats == null) return;
    final need = RankSystem.getXpNeededForNextLevel(_stats!.rank);
    if (_stats!.xp >= need) {
      _stats!.xp -= need;
      _stats!.level++;
      if (RankSystem.canPromoteRank(_stats!.rank, _stats!.level)) {
        final next = RankSystem.getNextRank(_stats!.rank);
        if (next != null) {
          _stats!.rank = next;
          // Level remains continuous
          _rankDialog();
        }
      }
    }
    Storage.saveUserStats(_stats!);
  }

  void _xpDialog(int xp) => showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('+$xp XP', style: AppTheme.h2(color: AppTheme.amber)),
          content: Text('Mission accomplished.', style: AppTheme.body()),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Continue',
                style: AppTheme.label(color: AppTheme.accent),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );

  void _rankDialog() => showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Promotion', style: AppTheme.h3()),
          content: Text(
            'You have achieved Rank ${_stats?.rank ?? "E"}!\nYour training goals have increased.',
            style: AppTheme.body(),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Understood',
                style: AppTheme.label(color: AppTheme.accent),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );

  void _showCreateCustomQuestSheet() {
    String name = '';
    String system = 'reps';
    String recur = 'Daily';
    int goal = 10;
    int selectedIcon = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(top: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3), width: 1.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Forge Mission', style: AppTheme.h1()),
                      SGTouchable(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: AppTheme.text2, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('MISSION NAME', style: AppTheme.label(color: AppTheme.accent)),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    style: AppTheme.body(color: Colors.white),
                    placeholder: 'e.g., Heavy Deadlifts',
                    placeholderStyle: AppTheme.body(color: AppTheme.muted),
                    cursorColor: AppTheme.accent,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.line, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TYPE', style: AppTheme.label(color: AppTheme.accent)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.line),
                              ),
                              child: Row(
                                children: [
                                  _typeBtn('reps', 'Reps', system == 'reps', () => setModalState(() => system = 'reps')),
                                  _typeBtn('timer', 'Timer', system == 'timer', () => setModalState(() => system = 'timer')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(system == 'reps' ? 'GOAL' : 'SECONDS', style: AppTheme.label(color: AppTheme.accent)),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              style: AppTheme.body(color: Colors.white),
                              keyboardType: TextInputType.number,
                              placeholder: '10',
                              placeholderStyle: AppTheme.body(color: AppTheme.muted),
                              cursorColor: AppTheme.accent,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.line, width: 1.5),
                              ),
                              padding: const EdgeInsets.all(12),
                              onChanged: (v) => goal = int.tryParse(v) ?? 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('RECURRENCE', style: AppTheme.label(color: AppTheme.accent)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: Row(
                      children: [
                        _typeBtn('Daily', 'Daily', recur == 'Daily', () => setModalState(() => recur = 'Daily')),
                        _typeBtn('One Time', 'One Time', recur == 'One Time', () => setModalState(() => recur = 'One Time')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('ICON', style: AppTheme.label(color: AppTheme.accent)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(6, (i) {
                        final idx = i + 1;
                        final isSelected = selectedIcon == idx;
                        return SGTouchable(
                          onTap: () => setModalState(() => selectedIcon = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.accent : AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppTheme.accent : AppTheme.line,
                                width: 2,
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 10)] : null,
                            ),
                            child: Icon(
                              _getCustomQuestIcon(idx),
                              color: isSelected ? Colors.black : AppTheme.text2,
                              size: 24,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SGTouchable(
                    onTap: () {
                      if (name.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      _addCustomQuest(name.trim(), system, goal, recur, selectedIcon);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 12)],
                      ),
                      child: Center(
                        child: Text(
                          'FORGE MISSION',
                          style: AppTheme.label(color: Colors.black).copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _typeBtn(String id, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.label(color: active ? Colors.black : AppTheme.text2).copyWith(fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _removeCustomQuest(int i) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Delete Mission?', style: AppTheme.h3()),
        content: Text('This action cannot be undone.', style: AppTheme.body()),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.body(color: AppTheme.text2)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Delete', style: AppTheme.label(color: AppTheme.red)),
            onPressed: () {
              setState(() {
                _customQuests.removeAt(i);
                if (i < _customAnims.length) {
                  _customAnims[i].dispose();
                  _customAnims.removeAt(i);
                }
              });
              Storage.saveCustomQuests(_customQuests);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _addCustomQuest(
      String name, String system, int goal, String recur, int iconIndex) {
    if (_customQuests.length >= 3) return;
    if (goal <= 0) goal = 10;

    final q = DailyQuest(
      questName: name,
      questType: recur == 'Daily'
          ? 'custom_daily_$iconIndex'
          : 'custom_onetime_$iconIndex',
      maxGoal: goal,
      xpReward: 100, // Fixed solid reward for custom quests
      system: system,
    );
    setState(() {
      _customQuests.add(q);
      _customAnims.add(AnimationController(
          duration: const Duration(milliseconds: 300), vsync: this)
        ..forward());
    });
    Storage.saveCustomQuests(_customQuests);
  }

  int get _doneCount => _quests.where((q) => q.completed).length;
  bool get _allDone => _doneCount == _quests.length;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Missions', style: AppTheme.h1()),
                          const SizedBox(height: 4),
                          Text(
                            'Complete your daily grind.',
                            style: AppTheme.caption(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(2), // Space for the border
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.silver, width: 1.5),
                    ),
                    child: CupertinoSlidingSegmentedControl<int>(
                      backgroundColor: AppTheme.surface,
                      thumbColor: AppTheme.accent, // Make the selector green
                      groupValue: _tab,
                      onValueChanged: (v) {
                        if (v != null) setState(() => _tab = v);
                      },
                      children: {
                        0: _buildTab('Daily Quests', _tab == 0),
                        1: _buildTab('Custom Quests', _tab == 1),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: _tab == 0 ? _buildDailyList() : _buildCustomList(),
        ),
      ],
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        style: AppTheme.label(
          color: isSelected ? Colors.black : AppTheme.text2,
        ).copyWith(fontSize: 13),
      ),
    );
  }

  Widget _buildDailyList() {
    return SliverList(
      delegate: SliverChildListDelegate([
        ...List.generate(
          _quests.length,
          (i) {
            // Safety check for animation controller to prevent RangeError
            if (i >= _anims.length) return const SizedBox.shrink();

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _anims[i],
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _QuestCard(
                  questIndex: i,
                  quest: _quests[i],
                  color: _qColors[i % _qColors.length],
                  onUpdate: (delta) => _updateReps(i, delta),
                  onComplete: () => _completeQuest(i),
                  isShattering: _quests[i].completed && _isShattering,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _allDone
              ? ShatterWidget(
                  isShattered: _isShattering,
                  child: _CelebrationCard(
                    onTimerZero: _triggerRealTimeRefresh,
                  ),
                )
              : _HintCard(),
        ),
      ]),
    );
  }

  Widget _buildCustomList() {
    if (_customQuests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large blurred background icon for premium feel
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome,
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    size: 80,
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          blurRadius: 15,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      color: AppTheme.accent,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Forge Your Path', style: AppTheme.h2()),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Create custom missions tailored to your unique training style.',
                  style: AppTheme.caption(),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              SGTouchable(
                onTap: _showCreateCustomQuestSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CREATE MISSION',
                        style: AppTheme.label(color: Colors.black).copyWith(letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        ...List.generate(
          _customQuests.length,
          (i) {
            // Safety check for animation controller to prevent RangeError
            if (i >= _customAnims.length) return const SizedBox.shrink();

            return SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
                      .animate(
                CurvedAnimation(
                    parent: _customAnims[i], curve: Curves.easeOutCubic),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    _QuestCard(
                      questIndex: i,
                      quest: _customQuests[i],
                      color: AppTheme.cyan,
                      onUpdate: (delta) => _updateCustomReps(i, delta),
                      onComplete: () => _completeCustomQuest(i),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeCustomQuest(i),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete_outline,
                              color: AppTheme.red.withValues(alpha: 0.8),
                              size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_customQuests.length < 3)
          SGTouchable(
            onTap: _showCreateCustomQuestSheet,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppTheme.text1, size: 20),
                  const SizedBox(width: 8),
                  Text('ADD CUSTOM MISSION',
                      style: AppTheme.label().copyWith(letterSpacing: 1)),
                ],
              ),
            ),
          ),
      ]),
    );
  }
}

IconData _getCustomQuestIcon(int idx) {
  switch (idx) {
    case 1:
      return Icons.fitness_center;
    case 2:
      return Icons.directions_run;
    case 3:
      return Icons.local_fire_department;
    case 4:
      return Icons.sports_martial_arts;
    case 5:
      return Icons.bolt;
    default:
      return Icons.star;
  }
}

class _QuestCard extends StatefulWidget {
  final int questIndex;
  final DailyQuest quest;
  final Color color;
  final Function(int) onUpdate;
  final VoidCallback onComplete;
  final bool isShattering;

  const _QuestCard({
    required this.questIndex,
    required this.quest,
    required this.color,
    required this.onUpdate,
    required this.onComplete,
    this.isShattering = false,
  });

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  Timer? _timer;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (widget.quest.currentProgress < widget.quest.maxGoal) {
          widget.onUpdate(1);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  String _formatTime(int sec) {
    if (sec < 60) return '${sec}s';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _confirmCompletion() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Complete Mission?', style: AppTheme.h2()),
        content: Text(
          'Are you ready to claim your rewards for ${widget.quest.questName}?',
          style: AppTheme.body(),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.label(color: AppTheme.text2)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'Confirm',
              style: AppTheme.label(color: AppTheme.accent),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onComplete();
            },
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(_QuestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quest.completed && _isRunning) {
      _timer?.cancel();
      _isRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final done = quest.completed;
    final pct = quest.maxGoal == 0
        ? 1.0
        : (quest.currentProgress / quest.maxGoal).clamp(0.0, 1.0);
    final isTimer = quest.system == "timer";

    int iconIndex = 0;
    if (quest.questType.startsWith('custom_')) {
      final parts = quest.questType.split('_');
      if (parts.length > 2) {
        iconIndex = int.tryParse(parts[2]) ?? 0;
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
        );
      },
      child: done
          ? ShatterWidget(
              isShattered: widget.isShattering,
              child: Container(
                key: const ValueKey('done'),
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.green, Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (ctx, val, child) => Transform.scale(
                          scale: val,
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              key: const ValueKey('active'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line, width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.color.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: iconIndex > 0
                              ? Icon(
                                  _getCustomQuestIcon(iconIndex),
                                  color: widget.color,
                                  size: 20,
                                )
                              : Text(
                                  '${widget.questIndex + 1}',
                                  style: AppTheme.h2(color: widget.color),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quest.questName, style: AppTheme.h3()),
                            const SizedBox(height: 2),
                            Text(
                              isTimer
                                  ? '${_formatTime(quest.currentProgress)} / ${_formatTime(quest.maxGoal)}'
                                  : '${quest.currentProgress} / ${quest.maxGoal} reps',
                              style: AppTheme.caption(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isTimer)
                        _ActionButton(
                          icon: _isRunning ? Icons.pause : Icons.play_arrow,
                          onTap: _toggleTimer,
                          active: _isRunning,
                        )
                      else ...[
                        _ActionButton(
                          icon: Icons.remove,
                          onTap: () => widget.onUpdate(-1),
                          disabled: quest.currentProgress == 0,
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.add,
                          onTap: () => widget.onUpdate(1),
                          disabled: quest.currentProgress == quest.maxGoal,
                        ),
                      ],
                      const SizedBox(width: 16),
                      Expanded(
                        child: _LinearProgress(pct: pct, color: widget.color),
                      ),
                      if (quest.currentProgress >= quest.maxGoal) ...[
                        const SizedBox(width: 16),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(20 * (1 - value), 0),
                                child: child,
                              ),
                            );
                          },
                          child: SGTouchable(
                            onTap: _confirmCompletion,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.accent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accent.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.check,
                                  color: AppTheme.accent, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _LinearProgress extends StatelessWidget {
  final double pct;
  final Color color;

  const _LinearProgress({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              height: 4,
              width: constraints.maxWidth * pct,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;
  final bool active;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
    this.active = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!widget.disabled) {
        widget.onTap();
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startTimer(),
      onLongPressEnd: (_) => _stopTimer(),
      onLongPressCancel: () => _stopTimer(),
      child: SGTouchable(
        onTap: widget.onTap,
        disabled: widget.disabled,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.active ? AppTheme.accent : AppTheme.elevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.active
                  ? AppTheme.accent
                  : (widget.disabled ? AppTheme.line : AppTheme.muted),
            ),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: widget.active
                ? Colors.white
                : (widget.disabled ? AppTheme.muted : AppTheme.text1),
          ),
        ),
      ),
    );
  }
}

class _CelebrationCard extends StatefulWidget {
  final VoidCallback onTimerZero;
  const _CelebrationCard({required this.onTimerZero});

  @override
  State<_CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<_CelebrationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _anim = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _getCountdown() {
    final now = DateTime.now();
    final nextReset = DateTime(now.year, now.month, now.day + 1);
    final d = nextReset.difference(now);

    if (d.inSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTimerZero();
      });
      return '00:00:00';
    }

    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (ctx, child) {
              return Transform.rotate(
                angle: _anim.value,
                child: child,
              );
            },
            child: Icon(Icons.emoji_events, size: 28, color: AppTheme.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DAILY MISSIONS COMPLETE',
                    style: AppTheme.h3(color: AppTheme.green)
                        .copyWith(fontSize: 12)),
                Text('Next reset', style: AppTheme.caption()),
              ],
            ),
          ),
          StreamBuilder<int>(
            stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
            builder: (context, snapshot) {
              return Text(
                _getCountdown(),
                style: AppTheme.mono(color: AppTheme.text1, size: 16),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 14, color: AppTheme.muted),
          const SizedBox(width: 8),
          Text(
            'Complete all missions for daily bonus.',
            style: AppTheme.caption(),
          ),
        ],
      ),
    );
  }
}

class ShatterWidget extends StatefulWidget {
  final Widget child;
  final bool isShattered;
  const ShatterWidget(
      {super.key, required this.child, required this.isShattered});

  @override
  State<ShatterWidget> createState() => _ShatterWidgetState();
}

class _ShatterWidgetState extends State<ShatterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.isShattered) _ctrl.forward();
  }

  @override
  void didUpdateWidget(ShatterWidget old) {
    super.didUpdateWidget(old);
    if (!old.isShattered && widget.isShattered) {
      _ctrl.forward();
    } else if (old.isShattered && !widget.isShattered) {
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildPiece(Alignment align) {
    final xOff = align.x * 300;
    final rot = align.x * 2.5;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        final t = _ctrl.value;
        final flyY = -200 * t + 1200 * t * t;
        final flyX = xOff * t;
        final rotation = rot * t;

        return Transform(
          transform: Matrix4.translationValues(flyX, flyY, 0.0)
            ..rotateZ(rotation),
          alignment: align,
          child: Opacity(
            opacity: 1.0 - (t * 1.5).clamp(0.0, 1.0),
            child: ClipRect(
              child: Align(
                alignment: align,
                widthFactor: 0.5,
                heightFactor: 0.5,
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isShattered) return widget.child;

    return Stack(
      children: [
        _buildPiece(Alignment.topLeft),
        _buildPiece(Alignment.topRight),
        _buildPiece(Alignment.bottomLeft),
        _buildPiece(Alignment.bottomRight),
      ],
    );
  }
}
