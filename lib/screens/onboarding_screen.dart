import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../theme/background.dart';
import '../widgets/player.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;
  static const int _totalPages = 5;
  bool _isFinishing = false;

  // Step 3 — Daily goal
  String _dailyGoal = 'medium'; // light / medium / hard

  // Step 4 — Notifications
  bool _notificationsEnabled = true;

  // Step 5 — Level

  // Step 6 — Loadout
  final List<Exercise> _selected = [];
  final List<Exercise> _custom = [];
  int _catIndex = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────
  void _next() {
    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutExpo);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutExpo);
    }
  }

  bool get _canProceed {
    if (_page == _totalPages - 1) return _selected.length == 4;
    return true;
  }

  // ── Finish ─────────────────────────────────────────────────────
  Future<void> _finish() async {
    setState(() => _isFinishing = true);

    // Play success haptic/sound
    AppTheme.success();

    // Set rank/level based on daily goal
    String rank = 'E';
    int level = 1;
    if (_dailyGoal == 'medium') {
      rank = 'D';
      level = 9;
    } else if (_dailyGoal == 'hard') {
      rank = 'C';
      level = 16;
    }

    // Save daily goal & notifications
    await Storage.saveData('daily_goal', _dailyGoal);
    await Storage.saveData('notifications_enabled', _notificationsEnabled);


    final stats = Storage.getUserStats();
    stats.rank = rank;
    stats.level = level;
    await Storage.saveUserStats(stats);

    // Build quests
    final goal = RankSystem.getMaxReps(rank, level);
    final xp = RankSystem.getQuestXpReward(rank);
    final quests = _selected
        .map((e) => DailyQuest(
              questName: e.name,
              questType: e.type,
              maxGoal: e.system == 'timer' ? goal * 6 : goal,
              xpReward: xp,
              system: e.system,
            ))
        .toList();

    await Storage.saveDailyTemplates(quests);
    await Storage.saveDailyQuests(quests);
    await Storage.saveData('is_onboarded', true);


    // Wait for the animation to feel good (Requested 3.85 seconds)
    // We subtract a bit for the sync time, but keep it roughly 3.85 total if possible
    await Future.delayed(const Duration(milliseconds: 3850));

    if (mounted) widget.onDone();
  }

  // ── Exercise toggle ────────────────────────────────────────────
  void _toggle(Exercise ex) {
    AppTheme.tap();
    setState(() {
      if (_selected.contains(ex)) {
        _selected.remove(ex);
      } else if (_selected.length < 4) {
        _selected.add(ex);
      }
    });
  }

  IconData _icon(String type) {
    if (type.contains('pushup')) return Icons.fitness_center_rounded;
    if (type.contains('situp') || type.contains('crunch')) {
      return Icons.accessibility_new_rounded;
    }
    if (type.contains('plank') || type.contains('twist')) {
      return Icons.self_improvement_rounded;
    }
    if (type.contains('squat') || type.contains('lunge')) {
      return Icons.directions_walk_rounded;
    }
    if (type.contains('run') ||
        type.contains('sprint') ||
        type.contains('treadmill')) {
      return Icons.directions_run_rounded;
    }
    if (type.contains('press')) return Icons.unfold_more_rounded;
    if (type.contains('row') || type.contains('pull')) {
      return Icons.align_vertical_bottom_rounded;
    }
    if (type.contains('machine')) return Icons.settings_input_component_rounded;
    if (type.contains('burpee') || type.contains('jump')) {
      return Icons.bolt_rounded;
    }
    if (type.contains('custom')) return Icons.edit_note_rounded;
    return Icons.fitness_center_rounded;
  }

  // ── Add custom exercise ────────────────────────────────────────
  void _addCustom() {
    final ctrl = TextEditingController();
    String system = 'reps';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppTheme.glassBorder)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.line,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Create Custom Quest', style: AppTheme.h2()),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.line, width: 2.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 44,
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: AppTheme.body(color: AppTheme.text1),
                  decoration: InputDecoration(
                    hintText: 'Exercise name (e.g. Walking)',
                    hintStyle: AppTheme.body(color: AppTheme.text2),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _modalTab('REPS', system == 'reps',
                        () => set(() => system = 'reps'))),
                const SizedBox(width: 10),
                Expanded(
                    child: _modalTab('TIMER', system == 'timer',
                        () => set(() => system = 'timer'))),
              ]),
              const SizedBox(height: 24),
              SGButton(
                label: 'Create Quest',
                onTap: () {
                  if (ctrl.text.isEmpty) return;
                  final ex = Exercise(
                    name: ctrl.text,
                    type: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    system: system,
                    defaultGoal: system == 'reps' ? 20 : 300,
                  );
                  setState(() {
                    _custom.add(ex);
                    if (_selected.length < 4) _selected.add(ex);
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalTab(String label, bool active, VoidCallback onTap) {
    return SGTouchable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppTheme.accent : AppTheme.line),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: AppTheme.label(
                color: active ? AppTheme.black : AppTheme.text2)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: LivelyBackground(
        child: Stack(children: [
          PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _introSlide(
                title: 'Welcome to\nSolo Gainz',
                subtitle:
                    'The ultimate gamified fitness experience.\nLevel up your body like your favourite RPG character.',
                customIcon: const WavingHand(),
              ),
              _introSlide(
                title: 'Earn Your\nRanks',
                subtitle:
                    'Complete daily quests, earn XP, and climb\nfrom Rank E to the legendary Rank SG.',
                customIcon: const RankDeck(),
              ),
              _dailyGoalSlide(),
              _notificationsSlide(),
              _loadoutSlide(),
            ],
          ),
          _navOverlay(),
          if (_isFinishing) _finishingOverlay(),
        ]),
      ),
    );
  }

  Widget _finishingOverlay() {
    String rankFile = 'E Rank.png';
    if (_dailyGoal == 'medium') rankFile = 'D Rank.png';
    if (_dailyGoal == 'hard') rankFile = 'C Rank.png';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, val, child) => Container(
        color: AppTheme.black.withValues(alpha: val),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Opacity(
                  opacity: v,
                  child: Transform.scale(
                    scale: 0.9 + (0.1 * v),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          width: 180,
                          child: Image.asset('Assets/Rank Shields/$rankFile'),
                        ),
                        const SizedBox(height: 40),
                        Text('SYSTEM INITIALIZED',
                            style:
                                AppTheme.label(color: AppTheme.accent).copyWith(
                              letterSpacing: 6,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 16),
                        Text('WELCOME, PLAYER',
                            style: AppTheme.h1().copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Cinematic progress bar
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 3850),
                builder: (context, progress, _) => SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.line.withValues(alpha: 0.1),
                        color: AppTheme.accent,
                        minHeight: 2,
                      ),
                      const SizedBox(height: 8),
                      Text('${(progress * 100).toInt()}%',
                          style: AppTheme.caption(color: AppTheme.accent)
                              .copyWith(fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introSlide(
      {IconData? icon,
      Widget? customIcon,
      required String title,
      required String subtitle,
      bool showIcon = true}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon) ...[
              if (customIcon != null) ...[
                customIcon,
                const SizedBox(height: 52),
              ] else if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        width: 1.5),
                  ),
                  child: Icon(icon, size: 72, color: AppTheme.accent),
                ),
                const SizedBox(height: 52),
              ],
            ],
            Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.h1().copyWith(
                  fontSize: 44,
                  letterSpacing: -2,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.text1,
                )),
            const SizedBox(height: 28),
            // Subtle professional divider
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(color: AppTheme.text2).copyWith(
                    fontSize: 17,
                    height: 1.55,
                    letterSpacing: 0.1,
                  )),
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  // ── Slide 3: Daily Goal ────────────────────────────────────────
  Widget _dailyGoalSlide() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPlayerPreview(),
            const SizedBox(height: 32),
            Text('Daily Training Goal',
                style: AppTheme.h1().copyWith(fontSize: 32, letterSpacing: -1)),
            const SizedBox(height: 12),
            Text('Slide to increase your training intensity',
                textAlign: TextAlign.center,
                style: AppTheme.body(color: AppTheme.text2)
                    .copyWith(fontSize: 16)),
            const SizedBox(height: 48),
            _buildDifficultySlider(),
            const SizedBox(height: 48),
            _buildGoalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySlider() {
    double value = 0;
    if (_dailyGoal == 'medium') value = 1;
    if (_dailyGoal == 'hard') value = 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.line, width: 1.5),
      ),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 6,
          activeTrackColor: _goalColor.withValues(alpha: 0.3),
          inactiveTrackColor: AppTheme.line,
          thumbColor: _goalColor,
          overlayColor: _goalColor.withValues(alpha: 0.1),
          activeTickMarkColor: Colors.transparent,
          inactiveTickMarkColor: Colors.transparent,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 18,
            elevation: 0,
            pressedElevation: 0,
          ),
        ),
        child: Slider(
          value: value,
          min: 0,
          max: 2,
          divisions: 2,
          onChanged: (val) {
            AppTheme.tap();
            setState(() {
              if (val == 0) {
                _dailyGoal = 'light';
              } else if (val == 1) {
                _dailyGoal = 'medium';
              } else {
                _dailyGoal = 'hard';
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildGoalInfo() {
    String title = 'Beginner';
    String desc = '2 quests per day • Casual training';
    if (_dailyGoal == 'medium') {
      title = 'Experienced';
      desc = '4 quests per day • Balanced training';
    } else if (_dailyGoal == 'hard') {
      title = 'Elite';
      desc = '6 quests per day • Intensive training';
    }

    return Column(
      children: [
        Text(title.toUpperCase(),
            style: AppTheme.h2(color: _goalColor).copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            )),
        const SizedBox(height: 8),
        Text(desc, style: AppTheme.body(color: AppTheme.text2)),
      ],
    );
  }

  Color get _goalColor {
    if (_dailyGoal == 'light') return AppTheme.accent;
    if (_dailyGoal == 'medium') return AppTheme.amber;
    return AppTheme.red;
  }

  // ── Slide 4: Notifications ────────────────────────────────────
  Widget _notificationsSlide() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.cyan.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Icon(Icons.notifications_rounded,
                  size: 52, color: AppTheme.cyan),
            ),
            const SizedBox(height: 32),
            Text('Daily Reminders',
                style: AppTheme.h1().copyWith(fontSize: 30)),
            const SizedBox(height: 10),
            Text('Stay consistent. We\'ll remind you to train every day.',
                textAlign: TextAlign.center,
                style: AppTheme.body(color: AppTheme.text2)),
            const SizedBox(height: 40),
            SGCard(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_active_rounded,
                        color: AppTheme.cyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable Notifications', style: AppTheme.h3()),
                      Text('Daily training reminders',
                          style: AppTheme.caption()),
                    ],
                  )),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                    },
                    activeThumbColor: AppTheme.cyan,
                    activeTrackColor: AppTheme.cyan.withValues(alpha: 0.3),
                    inactiveTrackColor: AppTheme.surface,
                    inactiveThumbColor: AppTheme.text2,
                  ),
                ]),
                if (_notificationsEnabled) ...[
                  const SizedBox(height: 16),
                  Divider(color: AppTheme.line, height: 1),
                  const SizedBox(height: 16),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        color: AppTheme.text2, size: 18),
                    const SizedBox(width: 10),
                    Text('Reminder Time',
                        style: AppTheme.body(color: AppTheme.text1)),
                    const Spacer(),
                    Text('8:00 AM',
                        style: AppTheme.label(color: AppTheme.accent)),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Text('You can change this anytime in Profile → Settings.',
                textAlign: TextAlign.center,
                style: AppTheme.caption(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }

  // ── Slide 6: Loadout ──────────────────────────────────────────
  Widget _loadoutSlide() {
    final exercises = _catIndex == 0
        ? ExerciseLibrary.homeExercises
        : _catIndex == 1
            ? ExerciseLibrary.gymExercises
            : _custom;

    return SafeArea(
      child: Column(children: [
        const SizedBox(height: 24),
        Text('Daily Loadout',
            style: AppTheme.h1().copyWith(fontSize: 32, letterSpacing: -1)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Select ', style: AppTheme.body(color: AppTheme.text2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: _selected.length == 4
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _selected.length == 4
                        ? AppTheme.accent
                        : AppTheme.line),
              ),
              child: Text('${_selected.length}/4',
                  style: AppTheme.label(
                      color: _selected.length == 4
                          ? AppTheme.accent
                          : AppTheme.text1)),
            ),
            Text(' exercises for your quest.',
                style: AppTheme.body(color: AppTheme.text2)),
          ],
        ),
        const SizedBox(height: 32),

        // Category switcher (Premium Segmented Control)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line, width: 1.5),
            ),
            child: Row(children: [
              _catBtn(0, 'Home', Icons.home_rounded),
              _catBtn(1, 'Gym', Icons.fitness_center_rounded),
              _catBtn(2, 'Custom', Icons.auto_awesome_rounded),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemCount: exercises.length + (_catIndex == 2 ? 1 : 0),
            itemBuilder: (context, index) {
              if (_catIndex == 2 && index == exercises.length) {
                return _addCustomCard();
              }
              return _exerciseCard(exercises[index]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _exerciseCard(Exercise ex) {
    final sel = _selected.contains(ex);
    final selIndex = _selected.indexOf(ex) + 1;

    return SGTouchable(
      onTap: () => _toggle(ex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              sel ? AppTheme.accent.withValues(alpha: 0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: sel ? AppTheme.accent.withValues(alpha: 0.8) : AppTheme.line,
            width: sel ? 2 : 1,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -2,
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Icon Background
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: sel ? 0.15 : 0.05,
                child: Icon(_icon(ex.type),
                    size: 80, color: sel ? AppTheme.accent : AppTheme.text2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.accent : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? AppTheme.accent : AppTheme.line),
                    ),
                    child: Icon(_icon(ex.type),
                        color: sel ? AppTheme.black : AppTheme.text2, size: 18),
                  ),
                  const Spacer(),
                  Text(ex.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.h3(
                              color: sel ? AppTheme.accent : AppTheme.text1)
                          .copyWith(
                        fontSize: 14,
                        height: 1.2,
                      )),
                ],
              ),
            ),
            if (sel)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text('$selIndex',
                        style: AppTheme.label(color: AppTheme.black)
                            .copyWith(fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addCustomCard() {
    return SGTouchable(
      onTap: _addCustom,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.line, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line, width: 1.5),
              ),
              child: Icon(Icons.add_rounded, color: AppTheme.text2, size: 24),
            ),
            const SizedBox(height: 12),
            Text('Custom', style: AppTheme.label(color: AppTheme.text2)),
          ],
        ),
      ),
    );
  }

  Widget _catBtn(int index, String label, IconData icon) {
    final active = _catIndex == index;
    return Expanded(
      child: SGTouchable(
        onTap: () {
          setState(() => _catIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active
                    ? AppTheme.accent.withValues(alpha: 0.4)
                    : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: active ? AppTheme.accent : AppTheme.text2),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTheme.label(
                      color: active ? AppTheme.accent : AppTheme.text2)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Navigation overlay ────────────────────────────────────────
  Widget _navOverlay() {
    final isLast = _page == _totalPages - 1;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 44),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppTheme.bg.withValues(alpha: 0.92),
              AppTheme.bg,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Column(children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                _totalPages,
                (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: _page == i ? 22 : 6,
                      decoration: BoxDecoration(
                        color: _page == i ? AppTheme.accent : AppTheme.line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(children: [
            if (_page > 0) ...[
              Expanded(
                child: SGButton(
                  label: 'Back',
                  outlined: true,
                  onTap: _back,
                  height: 52,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: SGButton(
                label: isLast
                    ? (_selected.length == 4
                        ? 'Begin Training'
                        : '${_selected.length}/4 Selected')
                    : 'Continue',
                onTap: _canProceed ? _next : null,
                height: 52,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildPlayerPreview() {
    String anim = 'Spin';
    if (_dailyGoal == 'medium') anim = 'Run';
    if (_dailyGoal == 'hard') anim = 'Sprint';

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ground line
          Positioned(
            bottom: 20,
            left: 60,
            right: 60,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.line.withValues(alpha: 0),
                    AppTheme.accent.withValues(alpha: 0.6),
                    AppTheme.line.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Player Model
          Positioned(
            bottom: 20,
            child: Player(
              animation: anim,
              size: 260,
              fps: anim == 'Sprint' ? 14 : 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rank Deck (Pro Redesign) ──────────────────────────────────
class RankDeck extends StatelessWidget {
  const RankDeck({super.key});

  final List<String> _ranks = const [
    'E Rank.png',
    'D Rank.png',
    'C Rank.png',
    'B Rank.png',
    'A Rank.png',
    'S Rank.png',
    'SS Rank.png'
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final centerX = constraints.maxWidth / 2;
      return SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Bottom grounding line (no glow)
            Positioned(
              bottom: 20,
              child: Container(
                width: 200,
                height: 1,
                color: AppTheme.line.withValues(alpha: 0.3),
              ),
            ),
            // The Shields
            ...List.generate(_ranks.length, (i) {
              // We want SS Rank (last) to be in the front, so we order them
              // but for a fan, usually center is front.
              // Let's make it a progressive fan where the right-most (highest ranks)
              // are slightly more prominent or the center is the hero.
              final indexOffset = i - (_ranks.length - 1) / 2;
              final xOffset = indexOffset * 36.0;
              final rotation = indexOffset * 0.14;
              final yOffset = indexOffset.abs() * 12.0;
              final scale = 1.0 - (indexOffset.abs() * 0.05);
              final opacity = 1.0 - (indexOffset.abs() * 0.1);

              return Positioned(
                left: centerX + xOffset - 60,
                top: 20 + yOffset,
                child: Opacity(
                  opacity: opacity.clamp(0.5, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Image.asset(
                        'Assets/Rank Shields/${_ranks[i]}',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

// ── Waving Hand Animation ──────────────────────────────────────
class WavingHand extends StatefulWidget {
  const WavingHand({super.key});
  @override
  State<WavingHand> createState() => _WavingHandState();
}

class _WavingHandState extends State<WavingHand>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Subtle waving motion
        return Transform.rotate(
          angle:
              (math.pi / 10) * (Curves.easeInOut.transform(_ctrl.value) - 0.5),
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(Icons.front_hand_rounded,
            size: 82, color: AppTheme.accent),
      ),
    );
  }
}
