import 'dart:math' as math;
import 'theme.dart';

enum LivelyBackgroundMode { normal, wood }

/// LivelyBackground — "Cinematic Depth"
/// 
/// A high-premium, immersive background for Solo Gainz.
/// Supports both the standard cinematic aura mode and a premium wood texture mode for the Vault.
class LivelyBackground extends StatefulWidget {
  final Widget child;
  final bool isMoving;
  final LivelyBackgroundMode mode;

  const LivelyBackground({
    super.key, 
    required this.child, 
    this.isMoving = true,
    this.mode = LivelyBackgroundMode.normal,
  });

  @override
  State<LivelyBackground> createState() => _LivelyBackgroundState();
}

class _LivelyBackgroundState extends State<LivelyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );
    if (widget.isMoving) {
      _ctrl.repeat();
    } else {
      _ctrl.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(LivelyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving != oldWidget.isMoving) {
      if (widget.isMoving) {
        _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkNotifier,
      builder: (context, isDark, _) {
        if (widget.mode == LivelyBackgroundMode.wood) {
          return _buildWoodBackground(isDark);
        }
        return _buildNormalBackground(isDark);
      },
    );
  }

  Widget _buildNormalBackground(bool isDark) {
    return Stack(
      children: [
        // ── 1. Foundation ──
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppTheme.black),
          ),
        ),
        if (!isDark)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF1F5F9), // Slate 100
                    AppTheme.black,          // Slate 200 (Silver Light)
                    AppTheme.dark,           // Slate 300 (Silver Dark)
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

        // ── 2. Cinematic Layers ──
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: _CinematicDepthPainter(
                  t: _ctrl.value,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ),

        // ── 3. Edge Voids ──
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.transparent,
                    isDark ? Colors.black.withValues(alpha: 0.4) : AppTheme.text1.withValues(alpha: 0.05),
                    isDark ? Colors.black.withValues(alpha: 0.8) : AppTheme.text1.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // ── 4. Content ──
        RepaintBoundary(child: widget.child),
      ],
    );
  }

  Widget _buildWoodBackground(bool isDark) {
    final List<Color> woodColors = isDark 
      ? [
          const Color(0xFF2D1B18), // Deep Mahogany
          const Color(0xFF3E2723), // Dark Coffee
          const Color(0xFF2B1A17), // Charcoal Wood
        ]
      : [
          const Color(0xFFD7B899), // Light Oak
          const Color(0xFFEBC9A0), // Pine
          const Color(0xFFC19A6B), // Golden Wood
        ];

    return Stack(
      children: [
        // 1. Base wood gradient foundation
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: woodColors,
              ),
            ),
          ),
        ),
        
        // 2. Wood Planks and Grain Layer
        Positioned.fill(
          child: CustomPaint(
            painter: _WoodGrainPainter(isDark: isDark),
          ),
        ),

        // 3. Ambient Occlusion / Vignette
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.4,
                  colors: [
                    Colors.transparent,
                    isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.2),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 4. Subtle Top Light highlight
        Positioned(
          top: 0, left: 0, right: 0,
          height: 150,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // 5. The Content
        RepaintBoundary(child: widget.child),
      ],
    );
  }
}

class _CinematicDepthPainter extends CustomPainter {
  final double t;
  final bool isDark;
  _CinematicDepthPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Shifting Cosmic Aura / Nebulas ──
    _drawDeepAura(canvas, size);

    // ── 2. Sweeping Cinematic Light Rays / God Rays ──
    _drawCinematicRays(canvas, size);

    // ── 3. Shifting Atmospheric Veils (for Light/Dark mode contrasts) ──
    if (isDark) {
      _drawAura(canvas, size, color: AppTheme.accent, offset: 0.0);
      _drawAura(canvas, size, color: AppTheme.purple, offset: 0.5);
    } else {
      _drawVeil(canvas, size, angle: 0.4, speed: 0.03, opacity: 0.015, color: Colors.black);
      _drawVeil(canvas, size, angle: -0.2, speed: 0.05, opacity: 0.01, color: const Color(0xFF1D4ED8));
    }

    // ── 4. Mysterious Drifting Power Particles / Embers ──
    _drawMysteriousParticles(canvas, size);

    // ── 5. Standard Horizon & Breathing Cores ──
    _drawHorizon(canvas, size);
    _drawBreathingCore(canvas, size);
  }

  void _drawDeepAura(Canvas canvas, Size size) {
    // Shifting colored nebulas at different coordinates
    final center1 = Offset(
      size.width * (0.5 + 0.3 * math.sin(t * 2 * math.pi)),
      size.height * (0.4 + 0.2 * math.cos(t * math.pi)),
    );
    final center2 = Offset(
      size.width * (0.5 - 0.25 * math.cos(t * 2 * math.pi)),
      size.height * (0.6 - 0.2 * math.sin(t * math.pi)),
    );

    final nebula1 = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (center1.dx / size.width) * 2 - 1,
          (center1.dy / size.height) * 2 - 1,
        ),
        radius: 1.5,
        colors: [
          (isDark ? AppTheme.accent : const Color(0xFF00E676)).withValues(alpha: isDark ? 0.16 : 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final nebula2 = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (center2.dx / size.width) * 2 - 1,
          (center2.dy / size.height) * 2 - 1,
        ),
        radius: 1.5,
        colors: [
          (isDark ? AppTheme.purple : const Color(0xFFD500F9)).withValues(alpha: isDark ? 0.16 : 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebula1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebula2);
  }

  void _drawCinematicRays(Canvas canvas, Size size) {
    final double angle = math.pi / 4; // 45 degrees
    
    // Create sweeping light shafts
    for (int i = 0; i < 3; i++) {
      final double phase = (t + (i * 0.33)) % 1.0;
      final double sweepPos = -300.0 + (phase * (size.width + 600.0));
      
      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            (i % 2 == 0 ? AppTheme.accent : AppTheme.purple).withValues(alpha: isDark ? 0.06 : 0.02),
            Colors.transparent,
          ],
          stops: const [0.3, 0.5, 0.7],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
      canvas.save();
      canvas.translate(sweepPos, 0);
      canvas.rotate(angle);
      canvas.drawRect(Rect.fromLTWH(-size.width, -size.height, size.width * 2, size.height * 2), rayPaint);
      canvas.restore();
    }
  }

  void _drawMysteriousParticles(Canvas canvas, Size size) {
    final random = math.Random(12345); // Seeded random for deterministic behavior
    final int particleCount = 20;

    for (int i = 0; i < particleCount; i++) {
      final speed = 0.06 + random.nextDouble() * 0.12;
      final radius = 2.0 + random.nextDouble() * 4.0;
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      
      // Rising position calculation
      final double yPos = (startY - (t * speed * size.height)) % size.height;
      // Subtle horizontal waving motion
      final double xPos = (startX + math.sin(t * 2 * math.pi + (i * 12)) * 18.0) % size.width;
      
      // Pulsing opacity (fade near top and bottom)
      double opacity = 0.10 + 0.15 * math.sin(t * math.pi * 2 + i);
      final centerDist = (Offset(xPos, yPos) - Offset(size.width / 2, size.height / 2)).distance;
      final maxDist = math.sqrt(size.width * size.width + size.height * size.height) / 2;
      opacity = (opacity * (1.0 - (centerDist / maxDist).clamp(0.0, 0.8)));

      final particlePaint = Paint()
        ..color = (i % 2 == 0 ? AppTheme.accent : AppTheme.purple).withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);
      
      canvas.drawCircle(Offset(xPos, yPos), radius, particlePaint);
    }
  }

  void _drawAura(Canvas canvas, Size size, {required Color color, required double offset}) {
    final pulse = (math.sin((t + offset) * 2 * math.pi) + 1) / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          math.sin(t * 2 * math.pi + offset) * 0.5,
          math.cos(t * 2 * math.pi + offset) * 0.5,
        ),
        radius: 1.2,
        colors: [
          color.withValues(alpha: 0.05 + (pulse * 0.08)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawVeil(Canvas canvas, Size size, {
    required double angle, 
    required double speed, 
    required double opacity,
    required Color color,
  }) {
    final offset = (t * speed) % 1.0;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.5 + (offset * 3), -1.0),
        end: Alignment(1.5 + (offset * 3), 1.0),
        colors: [
          Colors.transparent,
          color.withValues(alpha: opacity),
          Colors.transparent,
        ],
        stops: const [0.3, 0.5, 0.7],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawHorizon(Canvas canvas, Size size) {
    final horizonY = size.height * 0.7;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          isDark ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.01),
          isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03),
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY));
    
    canvas.drawRect(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY), paint);
  }

  void _drawBreathingCore(Canvas canvas, Size size) {
    final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          isDark 
            ? AppTheme.accent.withValues(alpha: 0.01 + (pulse * 0.02))
            : Colors.black.withValues(alpha: 0.002 + (pulse * 0.005)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_CinematicDepthPainter old) => true;
}

class _WoodGrainPainter extends CustomPainter {
  final bool isDark;
  _WoodGrainPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final plankPaint = Paint()
      ..color = isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final grainPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const double plankHeight = 90.0;
    
    for (double y = 0; y < size.height; y += plankHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), plankPaint);

      final bool isEven = (y / plankHeight).floor() % 2 == 0;
      final double xOffset = isEven ? 0 : 150;
      for (double x = xOffset; x < size.width; x += 300) {
        canvas.drawLine(Offset(x, y), Offset(x, y + plankHeight), plankPaint);
        
        final studPaint = Paint()..color = Colors.black.withValues(alpha: 0.2);
        canvas.drawCircle(Offset(x - 4, y + 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x + 4, y + 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x - 4, y + plankHeight - 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x + 4, y + plankHeight - 6), 1.2, studPaint);
      }

      for (int i = 0; i < 4; i++) {
        final double grainY = y + (plankHeight / 5) * (i + 1);
        final Path path = Path();
        path.moveTo(0, grainY);
        
        for (double x = 0; x < size.width; x += 100) {
          path.quadraticBezierTo(
            x + 50, 
            grainY + (isEven ? 5 : -5), 
            x + 100, 
            grainY
          );
        }
        canvas.drawPath(path, grainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
