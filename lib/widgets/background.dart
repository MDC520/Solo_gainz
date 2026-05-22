import 'dart:math' as math;
import '../ui/theme.dart';

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
  int _completedCycles = 0;

  double get _effectiveT => _completedCycles + _ctrl.value;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completedCycles++;
      }
    });
    if (widget.isMoving) {
      _ctrl.repeat();
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
                  t: _effectiveT,
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

  // Cached particle data — generated once for deterministic behaviour across frames
  static final List<_ParticleData> _particles = List.generate(30, (i) {
    final rng = math.Random(12345 + i);
    return _ParticleData(
      speed: 0.04 + rng.nextDouble() * 0.14,
      radius: 1.5 + rng.nextDouble() * 4.5,
      startX: rng.nextDouble(),
      startY: rng.nextDouble(),
      wobbleAmp: 8.0 + rng.nextDouble() * 20.0,
      wobbleFreq: 1.0 + rng.nextDouble() * 3.0,
      hueShift: rng.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Shifting Cosmic Aura / Nebulas ──
    _drawDeepAura(canvas, size);

    // ── 2. Sweeping Cinematic Light Rays / God Rays ──
    _drawCinematicRays(canvas, size);

    // ── 3. Floating Dust Motes (added for extra depth) ──
    _drawDustMotes(canvas, size);

    // ── 4. Shifting Atmospheric Veils ──
    if (isDark) {
      _drawAura(canvas, size, color: AppTheme.accent, offset: 0.0);
      _drawAura(canvas, size, color: AppTheme.purple, offset: 0.5);
    } else {
      _drawVeil(canvas, size, speed: 0.03, opacity: 0.015, color: Colors.black);
      _drawVeil(canvas, size, speed: 0.05, opacity: 0.01, color: const Color(0xFF1D4ED8));
    }

    // ── 5. Drifting Power Particles / Embers (cached) ──
    _drawCachedParticles(canvas, size);

    // ── 6. Horizon & Breathing Core ──
    _drawHorizon(canvas, size);
    _drawBreathingCore(canvas, size);
  }

  // ── paint helpers ──

  Alignment _offsetToAlignment(Offset pos, Size size) => Alignment(
    (pos.dx / size.width) * 2 - 1,
    (pos.dy / size.height) * 2 - 1,
  );

  void _drawDeepAura(Canvas canvas, Size size) {
    final center1 = Offset(
      size.width * (0.5 + 0.3 * math.sin(t * 2 * math.pi)),
      size.height * (0.4 + 0.2 * math.cos(t * math.pi)),
    );
    final center2 = Offset(
      size.width * (0.5 - 0.25 * math.cos(t * 2 * math.pi)),
      size.height * (0.6 - 0.2 * math.sin(t * math.pi)),
    );
    final center3 = Offset(
      size.width * (0.3 + 0.2 * math.cos(t * 1.5 * math.pi)),
      size.height * (0.8 - 0.15 * math.sin(t * 1.3 * math.pi)),
    );

    void drawNebula(Offset center, Color color, double peakAlpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          center: _offsetToAlignment(center, size),
          radius: 1.5,
          colors: [color.withValues(alpha: peakAlpha), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }

    drawNebula(center1, isDark ? AppTheme.accent : const Color(0xFF00E676), isDark ? 0.16 : 0.06);
    drawNebula(center2, isDark ? AppTheme.purple : const Color(0xFFD500F9), isDark ? 0.16 : 0.06);
    drawNebula(center3, isDark ? AppTheme.cyan : const Color(0xFF00BCD4), isDark ? 0.10 : 0.04);
  }

  void _drawCinematicRays(Canvas canvas, Size size) {
    final double angle = math.pi / 4;
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

  void _drawDustMotes(Canvas canvas, Size size) {
    final int count = 12;
    for (int i = 0; i < count; i++) {
      final double phase = (t + i * 0.08) % 1.0;
      final double x = size.width * (0.1 + 0.8 * ((phase * 1.7 + i * 0.13) % 1.0));
      final double y = size.height * (0.1 + 0.7 * ((phase * 0.9 + i * 0.21) % 1.0));
      final double alpha = 0.02 + 0.03 * math.sin(phase * math.pi * 2);
      final paint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  void _drawCachedParticles(Canvas canvas, Size size) {
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final double yPos = (p.startY * size.height - (t * p.speed * size.height)) % size.height;
      final double xPos = (p.startX * size.width + math.sin(t * 2 * math.pi * p.wobbleFreq + p.hueShift * math.pi * 2) * p.wobbleAmp) % size.width;

      double opacity = 0.10 + 0.15 * math.sin(t * math.pi * 2 + i);
      final centerDist = (Offset(xPos, yPos) - Offset(size.width / 2, size.height / 2)).distance;
      final maxDist = math.sqrt(size.width * size.width + size.height * size.height) / 2;
      opacity *= (1.0 - (centerDist / maxDist).clamp(0.0, 0.8));

      final particlePaint = Paint()
        ..color = (i % 2 == 0 ? AppTheme.accent : AppTheme.purple).withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.5);

      canvas.drawCircle(Offset(xPos, yPos), p.radius, particlePaint);
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
          Colors.transparent,
          isDark ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.01),
          isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
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
  bool shouldRepaint(_CinematicDepthPainter old) => old.t != t || old.isDark != isDark;
}

class _ParticleData {
  final double speed;
  final double radius;
  final double startX;
  final double startY;
  final double wobbleAmp;
  final double wobbleFreq;
  final double hueShift;
  const _ParticleData({
    required this.speed,
    required this.radius,
    required this.startX,
    required this.startY,
    required this.wobbleAmp,
    required this.wobbleFreq,
    required this.hueShift,
  });
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

      final int plankIdx = (y / plankHeight).floor();
      final bool isEven = plankIdx % 2 == 0;
      final double xOffset = isEven ? 0 : 150;

      // ── Vertical plank dividers + studs ──
      for (double x = xOffset; x < size.width; x += 300) {
        canvas.drawLine(Offset(x, y), Offset(x, y + plankHeight), plankPaint);

        final studPaint = Paint()..color = Colors.black.withValues(alpha: 0.2);
        canvas.drawCircle(Offset(x - 4, y + 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x + 4, y + 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x - 4, y + plankHeight - 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x + 4, y + plankHeight - 6), 1.2, studPaint);
      }

      // ── Natural sine-wave grain lines ──
      for (int i = 0; i < 4; i++) {
        final double grainY = y + (plankHeight / 5) * (i + 1);
        final double amp = isEven ? 5.0 : 7.0;
        final double freq = isEven ? 0.03 : 0.025 + (i * 0.005);

        final Path path = Path();
        path.moveTo(0, grainY);

        for (double x = 0; x < size.width; x += 10) {
          path.lineTo(x, grainY + math.sin(x * freq + plankIdx * 1.5) * amp);
        }
        canvas.drawPath(path, grainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
