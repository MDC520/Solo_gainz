import 'dart:async';
import '../widgets/player.dart';
import '../ui/theme.dart';
import '../widgets/background.dart';
import 'training_screen.dart';
import 'pvp.dart';
import '../engine/combat_engine.dart';
import 'story_screen.dart';

class DungeonPage extends StatefulWidget {
  const DungeonPage({super.key});

  @override
  State<DungeonPage> createState() => _DungeonPageState();
}

class _DungeonPageState extends State<DungeonPage> with SingleTickerProviderStateMixin {
  late AnimationController _bgCtrl;
  
  // Combo Animation States
  int _comboIdx = 0;

  final List<String> _combo0 = ['Kick01', 'Punch01', 'Kick02'];
  final List<String> _combo1 = ['Kick03', 'Punch02', 'Punch03'];
  
  // Arena Combo States
  int _arenaIdx = 0;
  final List<String> _arenaShocks = ['ShockLight', 'ShockHeavy'];

  void _nextArenaCombo() {
    if (!mounted) return;
    setState(() {
      _arenaIdx = (_arenaIdx + 1) % _arenaShocks.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }


  List<String> _getCurrentAnimations() {
    return [..._combo0, ..._combo1];
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _startTraining() async {
    // 1. Request orientation change first
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // 2. Wait for the OS to rotate
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // 3. Navigate and ensure it resets when returning
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrainingScreen(isLoading: true),
      ),
    ).then((_) {
      if (!mounted) return;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  void _startPvp() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PvpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentAnimations = _getCurrentAnimations();

    // Safety check for index out of bounds when switching lists
    if (_comboIdx >= currentAnimations.length) {
      _comboIdx = 0;
    }

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: LivelyBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Header Section ───────────────────
          Padding(
            padding: Responsive.fromLTRB(20, 40, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dungeons', style: AppTheme.h1()),
                  SizedBox(height: Responsive.h(4)),
                  Text(
                    'Conquer the abyss and hone your skills.',
                    style: AppTheme.caption(color: AppTheme.text2),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(24)),

            // ── Content Section ──────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: Responsive.h(12)),
                    
                    // 1. Training Card (Full Width)
                    Padding(
                      padding: Responsive.symmetric(horizontal: 20),
                      child: SGTouchable(
                        onTap: _startTraining,
                        child: Container(
                          width: double.infinity,
                          height: Responsive.h(100),
                          decoration: BoxDecoration(
                            color: AppTheme.black,
                            borderRadius: BorderRadius.circular(Responsive.r(20)),
                            border: Border.all(color: AppTheme.accent, width: Responsive.dp(2)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                // Animated Notebook Pattern
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _bgCtrl,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: NotebookPainter(_bgCtrl.value, lineColor: AppTheme.accent.withValues(alpha: 0.22)),
                                      );
                                    },
                                  ),
                                ),


                                // Centered, zoomed-in model pushing a box
                                Center(
                                  child: OverflowBox(
                                    maxHeight: 200, 
                                    child: Transform.translate(
                                      offset: const Offset(0, -50),
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          // Reflections (Mirrored)
                                          Opacity(
                                            opacity: 0.15,
                                            child: Transform.scale(
                                              scaleY: -1,
                                              alignment: Alignment.bottomCenter,
                                              child: Stack(
                                                alignment: Alignment.bottomCenter,
                                                children: [
                                                  Transform.translate(
                                                    offset: const Offset(20, 0),
                                                    child: Container(
                                                      width: Responsive.w(58),
                                                      height: Responsive.w(58),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFF795548), Color(0xFF4E342E)],
                                                        ),
                                                        borderRadius: BorderRadius.circular(Responsive.r(4)),
                                                      ),
                                                      child: CustomPaint(painter: CratePainter()),
                                                    ),
                                                  ),
                                                  Transform.translate(
                                                    offset: const Offset(-25, 0),
                                                    child: const Player(animation: 'Push', size: 160),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Ground Fade (Over reflections)
                                          Positioned(
                                            bottom: -50,
                                            left: -100,
                                            right: -100,
                                            height: 100,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppTheme.black.withValues(alpha: 0),
                                                    AppTheme.black,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          // The Actual Crate
                                          Transform.translate(
                                            offset: const Offset(20, 0), 
                                            child: Container(
                                              width: Responsive.w(58),
                                              height: Responsive.w(58),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [Color(0xFF795548), Color(0xFF4E342E)],
                                                ),
                                                borderRadius: BorderRadius.circular(Responsive.r(4)),
                                                border: Border.all(color: const Color(0xFF2D1B18), width: Responsive.dp(3)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.5),
                                                    blurRadius: 6,
                                                    offset: const Offset(2, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: CustomPaint(
                                                      painter: CratePainter(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // The Actual Player
                                          Transform.translate(
                                            offset: const Offset(-25, 0),
                                            child: const Player(
                                              animation: 'Push', 
                                              size: 160,
                                              fps: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Ground Line (Subtle Accent)
                                Positioned(
                                  bottom: Responsive.h(15),
                                  left: Responsive.w(30),
                                  right: Responsive.w(30),
                                  child: Container(
                                    height: Responsive.dp(1.5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.15), 
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Minimal indicator
                                Positioned(
                                  top: Responsive.h(10),
                                  right: Responsive.w(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'TRAINING',
                                        style: AppTheme.mono(color: AppTheme.accent, size: 10).copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      SizedBox(width: Responsive.w(4)),
                                      Icon(Icons.arrow_outward_rounded, color: AppTheme.accent, size: Responsive.icon(18)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Dashed Separator
                    Padding(
                      padding: Responsive.symmetric(vertical: 20, horizontal: 40),
                      child: Row(
                        children: List.generate(40, (index) => Expanded(
                          child: Container(
                            height: Responsive.dp(2),
                            margin: EdgeInsets.symmetric(horizontal: Responsive.w(2)),
                            decoration: BoxDecoration(
                              color: AppTheme.text1.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(Responsive.r(2)),
                            ),
                          ),
                        )),
                      ),
                    ),

                    // 2. Story Mode Card (Full Width)
                    Padding(
                      padding: Responsive.symmetric(horizontal: 20),
                      child: SGTouchable(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryScreen()));
                        },
                        child: Container(
                          width: double.infinity,
                          height: Responsive.h(100),
                          decoration: BoxDecoration(
                            color: AppTheme.black,
                            borderRadius: BorderRadius.circular(Responsive.r(20)),
                            border: Border.all(
                              color: AppTheme.accent,
                              width: Responsive.dp(2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Responsive.r(18)),
                            child: Stack(
                              children: [
                                // Animated Background Pattern
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _bgCtrl,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: NotebookPainter(
                                          _bgCtrl.value, 
                                          lineColor: AppTheme.accent.withValues(alpha: 0.22),
                                        ),
                                      );
                                    },
                                  ),
                                ),


                                // Dynamic Player (Running)
                                Center(
                                  child: OverflowBox(
                                    maxHeight: 200, 
                                    child: Transform.translate(
                                      offset: const Offset(0, -50),
                                      child: const Player(
                                        key: ValueKey('Combo_Story_Run'),
                                        animation: 'Run',
                                        size: 160,
                                        loop: true,
                                        fps: 12,
                                      ),
                                    ),
                                  ),
                                ),

                                // Minimal indicator
                                Positioned(
                                  top: Responsive.h(10),
                                  right: Responsive.w(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'STORY',
                                        style: AppTheme.mono(color: AppTheme.accent, size: 10).copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      SizedBox(width: Responsive.w(4)),
                                      Icon(Icons.arrow_outward_rounded, color: AppTheme.accent, size: Responsive.icon(18)),
                                    ],
                                  ),
                                ),

                                // Ground Line (Subtle White)
                                Positioned(
                                  bottom: Responsive.h(15),
                                  left: Responsive.w(30),
                                  right: Responsive.w(30),
                                  child: Container(
                                    height: Responsive.dp(1.5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.15), 
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Combat Arena Card (Full Width)
                    Padding(
                      padding: Responsive.symmetric(horizontal: 20, vertical: 10),
                      child: SGTouchable(
                        onTap: _startPvp,
                        child: Container(
                          width: double.infinity,
                          height: Responsive.h(100),
                          decoration: BoxDecoration(
                            color: AppTheme.black,
                            borderRadius: BorderRadius.circular(Responsive.r(20)),
                            border: Border.all(
                              color: AppTheme.accent,
                              width: Responsive.dp(2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Responsive.r(18)),
                            child: Stack(
                              children: [
                                // Animated Background Pattern
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _bgCtrl,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: NotebookPainter(
                                          _bgCtrl.value, 
                                          lineColor: AppTheme.accent.withValues(alpha: 0.22),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Single Player Animation (Cycling Shocks)
                                Center(
                                  child: OverflowBox(
                                    maxHeight: 200, 
                                    child: Transform.translate(
                                      offset: const Offset(0, -50),
                                      child: Player(
                                        key: ValueKey('Arena_Shock_$_arenaIdx'),
                                        animation: _arenaShocks[_arenaIdx],
                                        size: 160,
                                        loop: false,
                                        fps: 8,
                                        onComplete: _nextArenaCombo,
                                      ),
                                    ),
                                  ),
                                ),

                                // Minimal indicator
                                Positioned(
                                  top: Responsive.h(10),
                                  right: Responsive.w(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'PVP',
                                        style: AppTheme.mono(color: AppTheme.accent, size: 10).copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      SizedBox(width: Responsive.w(4)),
                                      Icon(Icons.arrow_outward_rounded, color: AppTheme.accent, size: Responsive.icon(18)),
                                    ],
                                  ),
                                ),

                                // Ground Line (Subtle White)
                                Positioned(
                                  bottom: Responsive.h(15),
                                  left: Responsive.w(30),
                                  right: Responsive.w(30),
                                  child: Container(
                                    height: Responsive.dp(1.5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.15), 
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: Responsive.h(120)), // Bottom padding for navbar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}




