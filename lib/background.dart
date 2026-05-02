import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme/theme.dart';

/// LivelyBackground — High-Density Dual RGB Fan
/// A premium, high-fidelity animated background featuring dual-layer rotating
/// neon blades with sword trails and an energy core.
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
      duration: const Duration(seconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        children: [
          // RGB Fan Layers
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: _RGBFanPainter(progress: _ctrl.value),
              ),
            ),
          ),

          // Depth & Vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.4,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          widget.child,
        ],
      ),
    );
  }
}

class _RGBFanPainter extends CustomPainter {
  final double progress;

  _RGBFanPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDim = math.max(size.width, size.height);
    
    // ── Layer 1: Outer Layer (70 wings total) ──
    _drawFanLayer(
      canvas, 
      center, 
      radius: maxDim * 1.3, 
      bladeCount: 35, 
      rotation: progress * 2 * math.pi, 
      reverse: false,
    );

    // ── Layer 2: Inner Layer (Synchronized) ──
    _drawFanLayer(
      canvas, 
      center, 
      radius: maxDim * 0.9, 
      bladeCount: 35, 
      rotation: progress * 2 * math.pi, 
      reverse: false,
    );

    // ── Central Energy Core ──
    _drawCore(canvas, center);
  }

  void _drawFanLayer(Canvas canvas, Offset center, {
    required double radius, 
    required int bladeCount, 
    required double rotation, 
    required bool reverse,
  }) {
    // Solo Gainz Blue Palette
    final List<Color> palette = [
      AppTheme.accent,
      AppTheme.accent.withValues(alpha: 0.8),
      const Color(0xFF00E5FF), // Bright Cyan Blue
      AppTheme.accent.withValues(alpha: 0.6),
    ];

    for (int i = 0; i < bladeCount; i++) {
      final double offsetAngle = (i * 2 * math.pi / bladeCount);
      final double currentAngle = rotation + offsetAngle;

      // Smooth interpolation between app colors
      final double colorValue = (progress + (i / bladeCount)) % 1.0;
      final int colorIdx = (colorValue * palette.length).floor();
      final double colorT = (colorValue * palette.length) % 1.0;
      
      final Color color = Color.lerp(
        palette[colorIdx], 
        palette[(colorIdx + 1) % palette.length], 
        colorT
      ) ?? AppTheme.accent;
      
      _drawTrail(canvas, center, radius, currentAngle, color, reverse);
      _drawBlade(canvas, center, radius, currentAngle, color, reverse);
    }
  }

  void _drawBlade(Canvas canvas, Offset center, double radius, double angle, Color color, bool reverse) {
    final Path path = Path();
    final double startDist = 20.0;
    final double dir = reverse ? -1 : 1;
    
    // Root points - narrowed for extreme density
    final Offset p1 = center + Offset(math.cos(angle - 0.002 * dir) * startDist, math.sin(angle - 0.002 * dir) * startDist);
    final Offset p2 = center + Offset(math.cos(angle + 0.002 * dir) * startDist, math.sin(angle + 0.002 * dir) * startDist);
    final Offset tip = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    
    // Control points for sleeker taper - tighter for more blades
    final Offset cp1 = center + Offset(math.cos(angle + 0.08 * dir) * (radius * 0.4), math.sin(angle + 0.08 * dir) * (radius * 0.4));
    final Offset cp2 = center + Offset(math.cos(angle - 0.01 * dir) * (radius * 0.3), math.sin(angle - 0.01 * dir) * (radius * 0.3));

    path.moveTo(p1.dx, p1.dy);
    path.quadraticBezierTo(cp1.dx, cp1.dy, tip.dx, tip.dy);
    path.quadraticBezierTo(cp2.dx, cp2.dy, p2.dx, p2.dy);
    path.close();

    final bladePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.center,
        end: Alignment(math.cos(angle), math.sin(angle)),
        colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.1), Colors.transparent],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, bladePaint);

    // Sharp Edge Highlight
    final edgePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final Path edgePath = Path();
    edgePath.moveTo(p1.dx, p1.dy);
    edgePath.quadraticBezierTo(cp1.dx, cp1.dy, tip.dx, tip.dy);
    canvas.drawPath(edgePath, edgePaint);
  }

  void _drawTrail(Canvas canvas, Offset center, double radius, double angle, Color color, bool reverse) {
    // Dramatically lengthened trails for a "light cycle" effect
    final double trailLength = 1.2; 
    final double dir = reverse ? 1 : -1; 
    final Path trailPath = Path();
    
    final int segments = 15; // Smoother segments for longer trail
    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double currentTrailAngle = angle + (trailLength * t * dir);
      final double x = center.dx + math.cos(currentTrailAngle) * radius;
      final double y = center.dy + math.sin(currentTrailAngle) * radius;
      if (i == 0) trailPath.moveTo(x, y); else trailPath.lineTo(x, y);
    }
    
    for (int i = segments; i >= 0; i--) {
      final double t = i / segments;
      final double currentTrailAngle = angle + (trailLength * t * dir);
      // Tapering the trail to a sharp point at the end
      final double innerRadius = radius - (40.0 * (1.0 - t));
      final double x = center.dx + math.cos(currentTrailAngle) * innerRadius;
      final double y = center.dy + math.sin(currentTrailAngle) * innerRadius;
      trailPath.lineTo(x, y);
    }
    trailPath.close();

    final trailPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: reverse ? angle : angle - trailLength,
        endAngle: reverse ? angle + trailLength : angle,
        colors: reverse 
          ? [color.withValues(alpha: 0.6), color.withValues(alpha: 0.2), Colors.transparent]
          : [Colors.transparent, color.withValues(alpha: 0.2), color.withValues(alpha: 0.6)],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(trailPath, trailPaint);
    
    // ── Secondary "Inner" Glow Trail for more depth ──
    final glowPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: reverse ? angle : angle - trailLength * 0.5,
        endAngle: reverse ? angle + trailLength * 0.5 : angle,
        colors: reverse 
          ? [color.withValues(alpha: 0.3), Colors.transparent]
          : [Colors.transparent, color.withValues(alpha: 0.3)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center + Offset(math.cos(angle)*radius, math.sin(angle)*radius), 4, Paint()..color = Colors.white.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  void _drawCore(Canvas canvas, Offset center) {
    // App Themed Energy Hub
    final corePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, corePaint);

    final pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi * 2);
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accent.withValues(alpha: 0.4 * pulse), 
          AppTheme.purple.withValues(alpha: 0.1),
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 60))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 60, auraPaint);
    
    canvas.drawCircle(center, 15, Paint()
      ..color = AppTheme.text1.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(_RGBFanPainter old) => old.progress != progress;
}


