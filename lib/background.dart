import 'dart:math' as math;
import 'theme/theme.dart';

/// LivelyBackground — "Cinematic Depth"
/// 
/// A high-premium, immersive background for Solo Gainz.
/// • Replaced glowing blobs with atmospheric veils.
/// • Removed random grid lines for a cleaner, deeper aesthetic.
/// • Uses multi-layered parallax gradients to create a sense of vast space.
class LivelyBackground extends StatefulWidget {
  final Widget child;
  final bool isMoving;

  const LivelyBackground({super.key, required this.child, this.isMoving = true});

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
      },
    );
  }
}

class _CinematicDepthPainter extends CustomPainter {
  final double t;
  final bool isDark;
  _CinematicDepthPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      // Dark Mode: Neon Auras
      _drawAura(canvas, size, color: AppTheme.accent, offset: 0.0);
      _drawAura(canvas, size, color: AppTheme.purple, offset: 0.5);
    } else {
      // Light Mode: Ink Washes
      _drawVeil(canvas, size, angle: 0.4, speed: 0.03, opacity: 0.015, color: Colors.black);
      _drawVeil(canvas, size, angle: -0.2, speed: 0.05, opacity: 0.01, color: const Color(0xFF1D4ED8));
    }

    _drawHorizon(canvas, size);
    _drawBreathingCore(canvas, size);
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
          color.withValues(alpha: 0.05 + (pulse * 0.1)),
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

