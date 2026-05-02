import 'dart:ui';
import 'theme/theme.dart';


/// LivelyBackground — A bold, athletic, and purely solid geometric background.
/// Uses sharp diagonal splits to evoke energy and precision. Zero gradients, zero glow.
class LivelyBackground extends StatefulWidget {
  final Widget child;
  final bool isMoving;

  const LivelyBackground({super.key, required this.child, this.isMoving = true});

  @override
  State<LivelyBackground> createState() => _LivelyBackgroundState();
}

class _LivelyBackgroundState extends State<LivelyBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SharpDiagonalPainter(
                    surfaceColor: AppTheme.dark,
                    accentColor: AppTheme.accent,
                    progress: _ctrl.value,
                  ),
                );
              },
            ),
          ),

          // ── Glass Effect Layer ─────────────────
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── The Content ────────────────────────
          widget.child,
        ],
      ),
    );
  }
}

class _SharpDiagonalPainter extends CustomPainter {
  final Color surfaceColor;
  final Color accentColor;
  final double progress;

  _SharpDiagonalPainter({
    required this.surfaceColor, 
    required this.accentColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Massive dynamic bottom-right polygon (Elevated Surface)
    final path1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, Paint()..color = surfaceColor);

    // 2. Primary sharp accent slash (Bold, solid separator)
    final start = Offset(0, size.height * 0.75);
    final end = Offset(size.width, size.height * 0.45);
    
    canvas.drawLine(
      start,
      end,
      Paint()..color = accentColor.withValues(alpha: 0.8)..strokeWidth = 3.0,
    );

    // 3. MOVING ANIMATION: A sliding "energy pulse" along the line
    final double t = progress; 
    final double segmentWidth = 120.0;
    
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double totalLen = (dx * dx + dy * dy); // squared distance is fine for ratio
    final double actualLen = 1.0; // normalization
    
    // We want the pulse to travel from start to end
    // Using a simple linear interpolation for the segment
    final double pulseT = (t * 1.4) - 0.2; // slight delay/offset to cycle cleanly
    
    if (pulseT > -0.1 && pulseT < 1.1) {
      final p1 = Offset(
        start.dx + dx * pulseT.clamp(0.0, 1.0),
        start.dy + dy * pulseT.clamp(0.0, 1.0),
      );
      final p2 = Offset(
        start.dx + dx * (pulseT + 0.1).clamp(0.0, 1.0),
        start.dy + dy * (pulseT + 0.1).clamp(0.0, 1.0),
      );
      
      canvas.drawLine(
        p1, p2, 
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
      );
    }
    
    // 4. Secondary parallel slash
    canvas.drawLine(
      Offset(0, size.height * 0.75 + 20),
      Offset(size.width, size.height * 0.45 + 20),
      Paint()..color = accentColor.withValues(alpha: 0.2)..strokeWidth = 1.0,
    );

    // 5. Subtle top-left geometric shard
    final path2 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(0, size.height * 0.25)
      ..close();
      
    canvas.drawPath(path2, Paint()..color = surfaceColor.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(_SharpDiagonalPainter old) => old.progress != progress;
}
