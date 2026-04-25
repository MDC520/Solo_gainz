import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../main.dart';
import '../background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final PageController _categoryPageController = PageController();
  int _currentPage = 0;

  // Level Selection State
  int _selectedLevelIndex = 0;

  // Quest Selection State
  final List<Exercise> _selected = [];
  final List<Exercise> _customExercises = [];
  int _categoryIndex = 0; // 0: Home, 1: Gym, 2: Custom



  @override
  void dispose() {
    _pageController.dispose();
    _categoryPageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutExpo,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutExpo,
      );
    }
  }



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

  IconData _getExerciseIcon(String type) {
    if (type.contains('pushup')) return Icons.fitness_center_rounded;
    if (type.contains('situp') || type.contains('crunch'))
      return Icons.accessibility_new_rounded;
    if (type.contains('plank') || type.contains('twist'))
      return Icons.self_improvement_rounded;
    if (type.contains('squat') || type.contains('lunge'))
      return Icons.directions_walk_rounded;
    if (type.contains('run') ||
        type.contains('sprint') ||
        type.contains('treadmill')) return Icons.directions_run_rounded;
    if (type.contains('press')) return Icons.unfold_more_rounded;
    if (type.contains('row') || type.contains('pull'))
      return Icons.align_vertical_bottom_rounded;
    if (type.contains('machine')) return Icons.settings_input_component_rounded;
    if (type.contains('burpee') || type.contains('jump'))
      return Icons.bolt_rounded;
    if (type.contains('custom')) return Icons.edit_note_rounded;
    return Icons.fitness_center_rounded;
  }

  void _addCustomExercise() {
    final nameCtrl = TextEditingController();
    String system = 'reps';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.fromLTRB(
              30, 20, 30, MediaQuery.of(context).viewInsets.bottom + 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text("Create Custom Quest", style: AppTheme.h2()),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: AppTheme.body(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Exercise Name (e.g. Walking)",
                  hintStyle: AppTheme.body(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildModalTab(
                      active: system == 'reps',
                      label: "REPS",
                      onTap: () => setModalState(() => system = 'reps'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModalTab(
                      active: system == 'timer',
                      label: "TIMER",
                      onTap: () => setModalState(() => system = 'timer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SGButton(
                label: "Create Quest",
                onTap: () {
                  if (nameCtrl.text.isEmpty) return;
                  final ex = Exercise(
                    name: nameCtrl.text,
                    type: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    system: system,
                    defaultGoal: system == 'reps' ? 20 : 300,
                  );
                  setState(() {
                    _customExercises.add(ex);
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

  Widget _buildModalTab(
      {required bool active,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: active ? AppTheme.accent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: AppTheme.label(color: active ? Colors.black : Colors.white)),
      ),
    );
  }

  Future<void> _finish() async {
    // Set Initial Stats based on Level Choice
    String startRank = 'E';
    int startLevel = 1;

    if (_selectedLevelIndex == 1) {
      startRank = 'D';
      startLevel = 9;
    } else if (_selectedLevelIndex == 2) {
      startRank = 'C';
      startLevel = 16;
    }

    final stats = Storage.getUserStats();
    stats.rank = startRank;
    stats.level = startLevel;
    await Storage.saveUserStats(stats);

    final goal = RankSystem.getMaxReps(stats.rank, stats.level);
    final xp = RankSystem.getQuestXpReward(stats.rank);

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

    AppTheme.success();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AppShell(onLogout: () async {}),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LivelyBackground(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildIntroSlide(
                  icon: Icons.auto_awesome_rounded,
                  title: "Welcome to Solo Gainz",
                  subtitle:
                      "The ultimate gamified fitness experience. Level up your body like you level up your character.",
                ),
                _buildIntroSlide(
                  icon: Icons.workspace_premium_rounded,
                  title: "Earn Your Ranks",
                  subtitle:
                      "Complete daily quests, earn XP, and climb from Rank E to the legendary Rank SG.",
                ),
                _buildLevelSlide(),
                _buildSelectionSlide(),
              ],
            ),
            _buildNavigationOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSlide(
      {required IconData icon, required String title, required String subtitle}) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2), width: 2),
                ),
                child: Icon(icon, size: 80, color: AppTheme.accent),
              ),
              const SizedBox(height: 60),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.h1().copyWith(fontSize: 36, letterSpacing: -1),
              ),
              const SizedBox(height: 20),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.body()
                    .copyWith(color: Colors.white70, fontSize: 17),
              ),
              const SizedBox(height: 100), // Space for button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSlide() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 140),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Select Difficulty",
                  style: AppTheme.h1().copyWith(fontSize: 32)),
              const SizedBox(height: 12),
              Text(
                "Your starting rank and stats will be adjusted based on this choice.",
                textAlign: TextAlign.center,
                style: AppTheme.body(color: AppTheme.text2),
              ),
              const SizedBox(height: 48),
              _buildLevelCard(
                index: 0,
                title: "Beginner",
                desc: "Rank E • 10 Reps Baseline",
                icon: Icons.directions_walk_rounded,
              ),
              _buildLevelCard(
                index: 1,
                title: "Expert",
                desc: "Rank D • 20 Reps Baseline",
                icon: Icons.directions_run_rounded,
              ),
              _buildLevelCard(
                index: 2,
                title: "Master",
                desc: "Rank C • 30 Reps Baseline",
                icon: Icons.fitness_center_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(
      {required int index,
      required String title,
      required String desc,
      required IconData icon}) {
    final isSelected = _selectedLevelIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SGTouchable(
        onTap: () => setState(() => _selectedLevelIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accent.withOpacity(0.08)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accent.withOpacity(0.8)
                  : Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected ? AppTheme.accent : Colors.white38,
                  size: 24),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTheme.h3(
                            color: isSelected ? AppTheme.accent : Colors.white)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: AppTheme.caption(
                            color: isSelected
                                ? Colors.white70
                                : Colors.white24)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.radio_button_checked_rounded,
                    color: AppTheme.accent, size: 20),
              if (!isSelected)
                Icon(Icons.radio_button_off_rounded,
                    color: Colors.white.withOpacity(0.1), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSlide() {
    final List<Exercise> exercises;
    if (_categoryIndex == 0) {
      exercises = ExerciseLibrary.homeExercises;
    } else if (_categoryIndex == 1)
      exercises = ExerciseLibrary.gymExercises;
    else
      exercises = _customExercises;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("Your Loadout", style: AppTheme.h1().copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              "Select 4 exercises to begin your training.",
              style: AppTheme.body().copyWith(color: AppTheme.text2),
            ),
            const SizedBox(height: 24),

            // Category Switcher (Sliding Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final tabWidth = constraints.maxWidth / 3;
                    return Stack(
                      children: [
                        // Sliding Indicator
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          left: _categoryIndex * tabWidth,
                          top: 4,
                          bottom: 4,
                          width: tabWidth,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        // Buttons
                        Row(
                          children: [
                            _buildCategoryButton(0, "Home"),
                            _buildCategoryButton(1, "Gym"),
                            _buildCategoryButton(2, "Custom"),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Exercise Grid with separators & sliding PageView
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                ),
                child: PageView(
                  controller: _categoryPageController,
                  onPageChanged: (i) => setState(() => _categoryIndex = i),
                  children: [
                    _buildExerciseGrid(ExerciseLibrary.homeExercises),
                    _buildExerciseGrid(ExerciseLibrary.gymExercises),
                    _buildExerciseGrid(_customExercises, isCustom: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(int index, String label) {
    final active = _categoryIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _categoryPageController.animateToPage(index,
              duration: const Duration(milliseconds: 400),
              curve: SGCurves.smooth);
          setState(() => _categoryIndex = index);
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Text(
              label,
              style: AppTheme.label(
                color: active ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseGrid(List<Exercise> exercises, {bool isCustom = false}) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
      itemCount: exercises.length + (isCustom ? 1 : 0),
      itemBuilder: (context, index) {
        if (isCustom && index == exercises.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SGTouchable(
              onTap: _addCustomExercise,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DottedBorder(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1.5,
                  dashPattern: const [6, 4],
                  radius: const Radius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white24, size: 20),
                        const SizedBox(width: 10),
                        Text("Add Custom",
                            style: AppTheme.label(color: Colors.white24)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final ex = exercises[index];
        final isSelected = _selected.contains(ex);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SGTouchable(
            onTap: () => _toggle(ex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accent.withOpacity(0.08)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accent.withOpacity(0.8)
                      : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getExerciseIcon(ex.type),
                    color: isSelected ? AppTheme.accent : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      ex.name,
                      style: AppTheme.h3(
                        color: isSelected ? AppTheme.accent : Colors.white,
                      ).copyWith(fontSize: 15),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "${_selected.indexOf(ex) + 1}",
                          style: AppTheme.mono(
                            color: Colors.black,
                            size: 12,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (!isSelected)
                    Icon(Icons.radio_button_off_rounded,
                        color: Colors.white.withOpacity(0.1), size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(40, 20, 40, 50),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.9),
              Colors.black,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Page Indicators (Hidden on the last step)
            if (_currentPage < 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _currentPage == index ? 24 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.accent
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            if (_currentPage < 3) const SizedBox(height: 32),
            // Buttons
            Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: SGTouchable(
                      onTap: _back,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Back",
                            style: AppTheme.label(color: Colors.white70)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SGTouchable(
                    onTap: _next,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: _currentPage == 3 && _selected.length < 4
                            ? Colors.white.withOpacity(0.1)
                            : AppTheme.accent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (_currentPage != 3 || _selected.length == 4)
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == 3
                              ? (_selected.length == 4
                                  ? "Begin Training"
                                  : "${_selected.length}/4 Selected")
                              : "Continue",
                          style: AppTheme.h3(
                            color: _currentPage == 3 && _selected.length < 4
                                ? Colors.white38
                                : Colors.black,
                          ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final Radius radius;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.dashPattern = const [3, 1],
    this.radius = Radius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashPattern: dashPattern,
        radius: radius,
      ),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final Radius radius;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), radius));

    final Path dashPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashPattern[draw ? 0 : 1];
        if (draw) {
          dashPath.addPath(
              metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DottedBorderPainter oldDelegate) => false;
}
