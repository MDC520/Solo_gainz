import 'dart:async';
import 'player.dart';
import 'theme.dart';
import 'background.dart';
import 'training_screen.dart';
import 'pvp.dart';

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
    // Dynamic styling based on progress
    final Map<int, _CardStyle> styles = {
      0: _CardStyle(
        bg: AppTheme.black, 
        accent: AppTheme.accent,
      ),
      1: _CardStyle(
        bg: const Color(0xFF0F051A), // Dark Purple
        accent: const Color(0xFF7E57C2),
      ),
      2: _CardStyle(
        bg: const Color(0xFF0A1128), // Dark Blue
        accent: Colors.blue,
      ),
      3: _CardStyle(
        bg: const Color(0xFF1A0505), // Deep Red
        accent: Colors.redAccent,
      ),
      4: _CardStyle(
        bg: const Color(0xFF051A1A), // Dark Teal
        accent: Colors.tealAccent,
      ),
      5: _CardStyle(
        bg: const Color(0xFF1A1505), // Dark Gold
        accent: Colors.orangeAccent,
      ),
    };

    final style = styles[0]!;
    final Color accentColor = style.accent;
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
                            color: const Color(0xFF0A221C), // Deep premium dark green/teal
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
                                        painter: _NotebookPainter(_bgCtrl.value, lineColor: AppTheme.accent.withValues(alpha: 0.22)),
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
                                                      child: CustomPaint(painter: _CratePainter()),
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
                                                      painter: _CratePainter(),
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
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          height: Responsive.h(100),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C0A2E), // Deep premium purple/violet
                            borderRadius: BorderRadius.circular(Responsive.r(20)),
                            border: Border.all(
                              color: const Color(0xFFBB86FC), // Purple Accent
                              width: Responsive.dp(2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFBB86FC).withValues(alpha: 0.15),
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
                                        painter: _NotebookPainter(
                                          _bgCtrl.value, 
                                          lineColor: const Color(0xFFBB86FC).withValues(alpha: 0.22),
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
                                        style: AppTheme.mono(color: const Color(0xFFBB86FC), size: 10).copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      SizedBox(width: Responsive.w(4)),
                                      Icon(Icons.arrow_outward_rounded, color: const Color(0xFFBB86FC), size: Responsive.icon(18)),
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
                            color: const Color(0xFF280B0B), // Deep premium red/crimson
                            borderRadius: BorderRadius.circular(Responsive.r(20)),
                            border: Border.all(
                              color: Colors.redAccent, 
                              width: Responsive.dp(2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.15),
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
                                        painter: _NotebookPainter(
                                          _bgCtrl.value, 
                                          lineColor: Colors.redAccent.withValues(alpha: 0.22),
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
                                        style: AppTheme.mono(color: Colors.redAccent, size: 10).copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      SizedBox(width: Responsive.w(4)),
                                      Icon(Icons.arrow_outward_rounded, color: Colors.redAccent, size: Responsive.icon(18)),
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

class _CardStyle {
  final Color bg;
  final Color accent;
  _CardStyle({required this.bg, required this.accent});
}

class _NotebookPainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  _NotebookPainter(this.progress, {required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = Responsive.dp(1.0);

    // Static Horizontal Lines (Notebook feel)
    final double lineSpacing = Responsive.h(30.0);
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Scrolling Vertical Lines
    double xOffset = -(progress * lineSpacing * 2);
    for (double x = -lineSpacing + (xOffset % lineSpacing); x < size.width + lineSpacing; x += lineSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(_NotebookPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.lineColor != lineColor;
}

class _CratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.6)
      ..strokeWidth = Responsive.dp(4.0)
      ..style = PaintingStyle.stroke;

    // Main X-Beam
    final o8 = Responsive.w(8.0);
    canvas.drawLine(Offset(o8, o8), Offset(size.width - o8, size.height - o8), framePaint);
    canvas.drawLine(Offset(size.width - o8, o8), Offset(o8, size.height - o8), framePaint);

    // Corner Studs (Metal nails)
    final studPaint = Paint()..color = const Color(0xFFBDBDBD).withValues(alpha: 0.3);
    final o6 = Responsive.w(6.0);
    final r1_5 = Responsive.dp(1.5);
    canvas.drawCircle(Offset(o6, o6), r1_5, studPaint);
    canvas.drawCircle(Offset(size.width - o6, o6), r1_5, studPaint);
    canvas.drawCircle(Offset(o6, size.height - o6), r1_5, studPaint);
    canvas.drawCircle(Offset(size.width - o6, size.height - o6), r1_5, studPaint);

    // Corner L-Brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.8)
      ..strokeWidth = Responsive.dp(2.0)
      ..style = PaintingStyle.stroke;
    
    double bSize = Responsive.w(10.0);
    // Top-Left
    canvas.drawLine(Offset.zero, Offset(bSize, 0), bracketPaint);
    canvas.drawLine(Offset.zero, Offset(0, bSize), bracketPaint);
    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - bSize, 0), bracketPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, bSize), bracketPaint);
    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(bSize, size.height), bracketPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - bSize), bracketPaint);
    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - bSize, size.height), bracketPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - bSize), bracketPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
