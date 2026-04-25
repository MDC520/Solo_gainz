import 'dart:ui';
import 'dart:math';
import 'theme/theme.dart';

/// The Living Void — Slowly drifting auras of neon color.
class LivelyBackground extends StatefulWidget {
  final Widget child;

  const LivelyBackground({super.key, required this.child});

  @override
  State<LivelyBackground> createState() => _LivelyBackgroundState();
}

class _LivelyBackgroundState extends State<LivelyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
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
          // Aura 1 (Accent)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final angle = _ctrl.value * 2 * pi;
              final dx = cos(angle) * 100;
              final dy = sin(angle) * 50;
              return Positioned(
                top: -100 + dy,
                left: -100 + dx,
                child: _buildAura(AppTheme.accent, 300),
              );
            },
          ),

          // Aura 2 (Cyan)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final angle = _ctrl.value * 2 * pi + pi; // Opposite phase
              final dx = cos(angle) * 80;
              final dy = sin(angle) * 100;
              return Positioned(
                bottom: -150 + dy,
                right: -100 + dx,
                child: _buildAura(AppTheme.cyan, 400),
              );
            },
          ),

          // Content Layer (The blur is handled by individual SGCards now,
          // or we can add a global subtle noise grain here in the future)
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildAura(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
