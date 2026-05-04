import 'dart:math' as math;
import 'theme/theme.dart';

/// LivelyBackground — "Simple & Alive" Breathing Aura
/// 
/// Inspired by modern clean UI:
/// • Solid, deep background with a rich tint.
/// • Large, soft "Breathing" radial auras that provide life.
/// • Extremely subtle moving perspective grid for grounded motion.
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
      duration: const Duration(seconds: 15),
    );
    if (widget.isMoving) {
      _ctrl.repeat();
    } else {
      _ctrl.value = 0.5; // Static nice state
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
        // ── Base Solid Tint ──
        Positioned.fill(
          child: const DecoratedBox(
            decoration: BoxDecoration(color: AppTheme.black),
          ),
        ),
        Positioned.fill(
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Deep Navy
                  AppTheme.black,
                ],
              ),
            ),
          ),
        ),

        // ── Breathing Auras ──
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: _SimpleAlivePainter(t: _ctrl.value),
              ),
            ),
          ),
        ),

        // ── Content ──
        RepaintBoundary(child: widget.child),
      ],
    );
  }
}

class _SimpleAlivePainter extends CustomPainter {
  final double t;
  _SimpleAlivePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    _drawAuras(canvas, size);
    _drawSubtleGrid(canvas, size);
  }

  void _drawAuras(Canvas canvas, Size size) {
    // Large, soft, breathing blobs of color
    final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final moveX = math.sin(t * 2 * math.pi) * 30;
    final moveY = math.cos(t * 2 * math.pi) * 20;

    // Aura 1: Top Left (Accent Blue)
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accent.withValues(alpha: 0.10 + (pulse * 0.05)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2 + moveX, size.height * 0.2 + moveY),
        radius: size.width * 0.7,
      ));
    canvas.drawCircle(Offset(size.width * 0.2 + moveX, size.height * 0.2 + moveY), size.width * 0.7, paint1);

    // Aura 2: Bottom Right (Cyan/Mint)
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.cyan.withValues(alpha: 0.08 + ((1 - pulse) * 0.04)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8 - moveX, size.height * 0.8 - moveY),
        radius: size.width * 0.6,
      ));
    canvas.drawCircle(Offset(size.width * 0.8 - moveX, size.height * 0.8 - moveY), size.width * 0.6, paint2);
  }

  void _drawSubtleGrid(Canvas canvas, Size size) {
    final horizonY = size.height * 0.75;
    final gridSpeed = 2.0;
    final offset = (t * gridSpeed) % 1.0;

    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    // Horizontal moving lines (Linear for speed, less perspective distortion but faster)
    for (int i = 0; i < 6; i++) {
      final frac = (i + offset) / 6;
      final y = horizonY + (size.height - horizonY) * frac;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical vanishing lines
    final vanishX = size.width / 2;
    for (int i = 0; i <= 8; i++) {
      final xFrac = i / 8;
      final bottomX = xFrac * size.width;
      canvas.drawLine(Offset(vanishX, horizonY), Offset(bottomX, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_SimpleAlivePainter old) => true;
}
