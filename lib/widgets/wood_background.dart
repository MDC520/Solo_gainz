import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// WoodBackground — A premium wooden texture background.
/// 
/// Designed specifically for the "Vault" (Inventory) to create a sense of physical storage.
class WoodBackground extends StatelessWidget {
  final Widget child;
  const WoodBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkNotifier,
      builder: (context, isDark, _) {
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
            child,
          ],
        );
      },
    );
  }
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
      // Draw horizontal plank separation
      canvas.drawLine(Offset(0, y), Offset(size.width, y), plankPaint);

      // Vertical seams (staggered)
      final bool isEven = (y / plankHeight).floor() % 2 == 0;
      final double xOffset = isEven ? 0 : 150;
      for (double x = xOffset; x < size.width; x += 300) {
        canvas.drawLine(Offset(x, y), Offset(x, y + plankHeight), plankPaint);
        
        // Draw little "nail" studs
        final studPaint = Paint()..color = Colors.black.withValues(alpha: 0.2);
        canvas.drawCircle(Offset(x - 4, y + 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x + 4, y + 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x - 4, y + plankHeight - 6), 1.2, studPaint);
        canvas.drawCircle(Offset(x + 4, y + plankHeight - 6), 1.2, studPaint);
      }

      // Draw subtle grain waves
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
