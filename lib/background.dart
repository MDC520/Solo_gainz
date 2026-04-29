import 'dart:ui';
import 'dart:math';
import 'theme/theme.dart';

/// Living Notebook — A creepy, infinite-scrolling notebook background.
/// Evokes the feeling of being trapped inside a haunted journal in a dead world.
class LivelyBackground extends StatefulWidget {
  final Widget child;
  final bool isMoving;

  const LivelyBackground({super.key, required this.child, this.isMoving = true});

  @override
  State<LivelyBackground> createState() => _LivelyBackgroundState();
}

class _LivelyBackgroundState extends State<LivelyBackground>
    with TickerProviderStateMixin {
  late AnimationController _scrollCtrl;

  @override
  void didUpdateWidget(covariant LivelyBackground old) {
    super.didUpdateWidget(old);
    if (old.isMoving != widget.isMoving) {
      if (widget.isMoving) {
        _scrollCtrl.repeat();
      } else {
        _scrollCtrl.stop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // For the infinite scrolling lines
    _scrollCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 15));
    if (widget.isMoving) _scrollCtrl.repeat();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08080A), // Obsidian Void (Deep atmospheric black)
      child: Stack(
        children: [
          // ── The Scrolling Notebook Paper ────────────────────────
          AnimatedBuilder(
            animation: _scrollCtrl,
            builder: (context, child) {
              return CustomPaint(
                painter: _NotebookPainter(
                  // 35.0 (spacing) * 20 = 700.0. 
                  // Total distance MUST be a multiple of spacing for a perfect loop.
                  offset: _scrollCtrl.value * 700.0, 
                  lineColor: const Color(0xFF2A2A2A),
                ),
                size: Size.infinite,
              );
            },
          ),

          widget.child,
        ],
      ),
    );
  }
}

class _NotebookPainter extends CustomPainter {
  final double offset;
  final Color lineColor;

  _NotebookPainter({
    required this.offset,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    // Horizontal notebook lines
    const double spacing = 35.0;
    double startY = -(offset % spacing);
    
    for (double y = startY; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }


  }

  @override
  bool shouldRepaint(_NotebookPainter old) => old.offset != offset;
}
