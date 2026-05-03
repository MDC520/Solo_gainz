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
    )..repeat();
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
          child: Container(
            color: AppTheme.black,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A), // Deep Navy
                  AppTheme.black,
                ],
              ),
            ),
          ),
        ),

        // ── Breathing Auras ──
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              painter: _SimpleAlivePainter(t: _ctrl.value),
            ),
          ),
        ),

        // ── Content ──
        widget.child,
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
    final moveX = math.sin(t * 2 * math.pi) * 50;
    final moveY = math.cos(t * 2 * math.pi) * 30;

    // Aura 1: Top Left (Accent Blue)
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accent.withValues(alpha: 0.12 + (pulse * 0.05)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2 + moveX, size.height * 0.2 + moveY),
        radius: size.width * 0.8,
      ))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width * 0.2 + moveX, size.height * 0.2 + moveY), size.width * 0.8, paint1);

    // Aura 2: Center Right (Cyan/Mint)
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.cyan.withValues(alpha: 0.08 + ((1-pulse) * 0.04)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8 - moveX, size.height * 0.5 - moveY),
        radius: size.width * 0.7,
      ))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width * 0.8 - moveX, size.height * 0.5 - moveY), size.width * 0.7, paint2);

    // Aura 3: Bottom Left (Purple)
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.purple.withValues(alpha: 0.10 + (pulse * 0.03)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1 + moveX, size.height * 0.8 + moveY),
        radius: size.width * 0.6,
      ))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width * 0.1 + moveX, size.height * 0.8 + moveY), size.width * 0.6, paint3);
  }

  void _drawSubtleGrid(Canvas canvas, Size size) {
    final horizonY = size.height * 0.75;
    final gridSpeed = 2.0;
    final offset = (t * gridSpeed) % 1.0;

    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.03) // EXTREMELY subtle
      ..strokeWidth = 1.0;

    // Horizontal moving lines
    for (int i = 0; i < 8; i++) {
      final frac = (i + offset) / 8;
      if (frac > 1.0) continue;
      
      final yFrac = math.pow(frac, 3.0).toDouble();
      final y = horizonY + (size.height - horizonY) * yFrac;
      
      canvas.drawLine(
        Offset(0, y), 
        Offset(size.width, y), 
        paint..color = AppTheme.accent.withValues(alpha: 0.03 * frac)
      );
    }

    // Vertical vanishing lines
    final vanishX = size.width / 2;
    for (int i = 0; i <= 10; i++) {
      final xFrac = i / 10;
      final bottomX = xFrac * size.width;
      canvas.drawLine(
        Offset(vanishX, horizonY),
        Offset(bottomX, size.height),
        paint..color = AppTheme.accent.withValues(alpha: 0.02)
      );
    }
  }

  @override
  bool shouldRepaint(_SimpleAlivePainter old) => true;
}
