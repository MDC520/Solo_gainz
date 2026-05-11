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
    return Stack(
      children: [
        // ── 1. Deep Void Foundation ──
        Positioned.fill(
          child: const DecoratedBox(
            decoration: BoxDecoration(color: AppTheme.black),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Deep Navy
                  AppTheme.black,
                  Color(0xFF0A0C10), // Midnight
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // ── 2. Atmospheric Veils & Depth ──
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: _CinematicDepthPainter(t: _ctrl.value),
              ),
            ),
          ),
        ),

        // ── 3. Interaction Shadow (Vignette) ──
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.transparent,
                    AppTheme.black.withValues(alpha: 0.2),
                    AppTheme.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
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
}

class _CinematicDepthPainter extends CustomPainter {
  final double t;
  _CinematicDepthPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Layer 1: Slow, massive diagonal veil (Nebula-like drift)
    _drawVeil(canvas, size, 
      angle: 0.4, 
      speed: 0.05, 
      opacity: 0.04, 
      color: AppTheme.accent
    );

    // Layer 2: Subtle counter-drift veil
    _drawVeil(canvas, size, 
      angle: -0.2, 
      speed: 0.08, 
      opacity: 0.02, 
      color: AppTheme.cyan
    );

    // Layer 3: Distant Depth (Soft horizontal floor gradient)
    _drawHorizon(canvas, size);

    // Layer 4: Vertical Light Pulse (Breathing effect)
    _drawBreathingCore(canvas, size);
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
          AppTheme.accent.withValues(alpha: 0.02),
          AppTheme.black.withValues(alpha: 0.2),
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
          AppTheme.accent.withValues(alpha: 0.005 + (pulse * 0.01)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_CinematicDepthPainter old) => true;
}

