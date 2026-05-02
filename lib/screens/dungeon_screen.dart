import 'dart:async';
import '../widgets/player.dart';
import '../theme/theme.dart';
import 'training_screen.dart';

class DungeonPage extends StatefulWidget {
  const DungeonPage({super.key});

  @override
  State<DungeonPage> createState() => _DungeonPageState();
}

class _DungeonPageState extends State<DungeonPage> with SingleTickerProviderStateMixin {
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _startTraining(BuildContext context) async {
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
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Section ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dungeons', style: AppTheme.h1()),
                  const SizedBox(height: 4),
                  Text(
                    'Conquer the abyss and hone your skills.',
                    style: AppTheme.caption(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Content Section ──────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    
                    // Training Card (Notebook Style)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SGTouchable(
                        onTap: () => _startTraining(context),
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A), // Dark Navy Blue
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
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
                                        painter: _NotebookPainter(_bgCtrl.value, isBlueTheme: true),
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
                                                      width: 58,
                                                      height: 58,
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFF795548), Color(0xFF4E342E)],
                                                        ),
                                                        borderRadius: BorderRadius.circular(4),
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
                                                    const Color(0xFF0D1B2A).withValues(alpha: 0),
                                                    const Color(0xFF0D1B2A),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          // The Actual Crate
                                          Transform.translate(
                                            offset: const Offset(20, 0), 
                                            child: Container(
                                              width: 58,
                                              height: 58,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [Color(0xFF795548), Color(0xFF4E342E)],
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFF2D1B18), width: 3),
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

                                // Training Title (White on Dark Blue)
                                Positioned(
                                  top: 14,
                                  left: 20,
                                  child: Text(
                                    'TRAINING',
                                    style: AppTheme.mono(color: Colors.white, size: 11).copyWith(
                                      letterSpacing: 3,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),

                                // Ground Line (Subtle White)
                                Positioned(
                                  bottom: 15,
                                  left: 30,
                                  right: 30,
                                  child: Container(
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.1), // Even more subtle
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Minimal indicator
                                Positioned(
                                  top: 10,
                                  right: 12,
                                  child: Icon(Icons.arrow_outward_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 120), // Bottom padding for navbar
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

class _NotebookPainter extends CustomPainter {
  final double progress;
  final bool isBlueTheme;
  _NotebookPainter(this.progress, {this.isBlueTheme = false});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isBlueTheme 
          ? const Color(0xFF4FC3F7).withValues(alpha: 0.05)
          : Colors.blue.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    // Static Horizontal Lines (Notebook feel)
    const double lineSpacing = 30.0;
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Scrolling Vertical Lines (Creates horizontal movement feel)
    // We scroll them right-to-left to simulate the player running right
    double xOffset = -(progress * lineSpacing * 2); // Faster horizontal scroll
    for (double x = -lineSpacing + (xOffset % lineSpacing); x < size.width + lineSpacing; x += lineSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(_NotebookPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.isBlueTheme != isBlueTheme;
}

class _CratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Main X-Beam
    canvas.drawLine(const Offset(8, 8), Offset(size.width - 8, size.height - 8), framePaint);
    canvas.drawLine(Offset(size.width - 8, 8), Offset(8, size.height - 8), framePaint);

    // Corner Studs (Metal nails)
    final studPaint = Paint()..color = const Color(0xFFBDBDBD).withValues(alpha: 0.3);
    canvas.drawCircle(const Offset(6, 6), 1.5, studPaint);
    canvas.drawCircle(Offset(size.width - 6, 6), 1.5, studPaint);
    canvas.drawCircle(Offset(6, size.height - 6), 1.5, studPaint);
    canvas.drawCircle(Offset(size.width - 6, size.height - 6), 1.5, studPaint);

    // Corner L-Brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    double bSize = 10;
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
