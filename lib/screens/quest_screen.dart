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
    int selectedIcon = 0;

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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppTheme.line)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Create Mission', style: AppTheme.h2()),
                      IconButton(
                          icon: Icon(Icons.close, color: AppTheme.text2),
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Mission Name', style: AppTheme.label()),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    style: AppTheme.body(color: Colors.white),
                    placeholder: 'e.g., 100 Pull-ups',
                    placeholderStyle: AppTheme.body(color: AppTheme.muted),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.line, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(12),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type', style: AppTheme.label()),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoSlidingSegmentedControl<String>(
                                backgroundColor: AppTheme.surface,
                                thumbColor: AppTheme.elevated,
                                groupValue: system,
                                onValueChanged: (v) =>
                                    setModalState(() => system = v!),
                                children: {
                                  'reps': Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Text('Reps',
                                          style: AppTheme.caption(
                                              color: system == 'reps'
                                                  ? AppTheme.text1
                                                  : AppTheme.text2))),
                                  'timer': Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Text('Timer',
                                          style: AppTheme.caption(
                                              color: system == 'timer'
                                                  ? AppTheme.text1
                                                  : AppTheme.text2))),
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(system == 'reps' ? 'Amount' : 'Seconds',
                                style: AppTheme.label()),
                            const SizedBox(height: 8),
                            CupertinoTextField(
                              style: AppTheme.body(color: Colors.white),
                              keyboardType: TextInputType.number,
                              placeholder: 'e.g., 10',
                              placeholderStyle:
                                  AppTheme.body(color: AppTheme.muted),
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
                  const SizedBox(height: 16),
                  Text('Recurrence', style: AppTheme.label()),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      backgroundColor: AppTheme.surface,
                      thumbColor: AppTheme.elevated,
                      groupValue: recur,
                      onValueChanged: (v) => setModalState(() => recur = v!),
                      children: {
                        'Daily': Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Everyday',
                                style: AppTheme.caption(
                                    color: recur == 'Daily'
                                        ? AppTheme.text1
                                        : AppTheme.text2))),
                        'One Time': Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('One Time Only',
                                style: AppTheme.caption(
                                    color: recur == 'One Time'
                                        ? AppTheme.text1
                                        : AppTheme.text2))),
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Icon', style: AppTheme.label()),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(6, (i) {
                        final isSelected = selectedIcon == i;
                        return SGTouchable(
                          onTap: () => setModalState(() => selectedIcon = i),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accent
                                      : AppTheme.line,
                                  width: isSelected ? 2 : 1),
                            ),
                            child: Center(
                              child: i == 0
                                  ? Text('123',
                                      style: AppTheme.h3(
                                              color: isSelected
                                                  ? AppTheme.accent
                                                  : AppTheme.text2)
                                          .copyWith(fontSize: 14))
                                  : Icon(
                                      _getCustomQuestIcon(i),
                                      color: isSelected
                                          ? AppTheme.accent
                                          : AppTheme.text2,
                                      size: 24,
                                    ),
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
                      _addCustomQuest(
                          name.trim(), system, goal, recur, selectedIcon);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text('CREATE MISSION',
                              style: AppTheme.label(color: Colors.white)
                                  .copyWith(letterSpacing: 1))),
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.line, width: 1.5),
                ),
                child: Icon(
                  Icons.add_task,
                  color: AppTheme.muted,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text('No Custom Missions', style: AppTheme.h3()),
              const SizedBox(height: 8),
              Text(
                'Create your own training targets.',
                style: AppTheme.caption(),
              ),
              const SizedBox(height: 32),
              SGTouchable(
                onTap: _showCreateCustomQuestSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.line, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: AppTheme.text1, size: 20),
                      const SizedBox(width: 8),
                      Text('CREATE FIRST MISSION',
                          style: AppTheme.label().copyWith(letterSpacing: 1)),
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
                child: _QuestCard(
                  questIndex: i,
                  quest: _customQuests[i],
                  color: AppTheme.cyan,
                  onUpdate: (delta) => _updateCustomReps(i, delta),
                  onComplete: () => _completeCustomQuest(i),
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
                          color: AppTheme.elevated,
                          borderRadius: BorderRadius.circular(10),
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
                        SGTouchable(
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

class _ActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SGTouchable(
      onTap: onTap,
      disabled: disabled,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? AppTheme.accent : AppTheme.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppTheme.accent
                : (disabled ? AppTheme.line : AppTheme.muted),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active
              ? Colors.white
              : (disabled ? AppTheme.muted : AppTheme.text1),
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
