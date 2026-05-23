import '../ui/theme.dart';

/// Flat day cell for weekly quest progress (no glow / sweep borders).
class WeeklyDaySquare extends StatelessWidget {
  final String letter;
  final double progress;
  final bool completed;
  final bool isToday;
  final bool isFuture;
  final String tooltip;
  final VoidCallback? onTap;

  const WeeklyDaySquare({
    super.key,
    required this.letter,
    required this.progress,
    required this.completed,
    required this.isToday,
    required this.isFuture,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = Responsive.r(8);
    final borderWidth = isToday ? Responsive.dp(2) : Responsive.dp(1);

    late final Color borderColor;
    late final Color fillColor;
    late final Color letterColor;

    if (isFuture) {
      borderColor = AppTheme.line.withValues(alpha: 0.4);
      fillColor = Colors.transparent;
      letterColor = AppTheme.text3;
    } else if (isToday) {
      if (completed) {
        borderColor = AppTheme.green;
        fillColor = AppTheme.green.withValues(alpha: 0.1);
        letterColor = AppTheme.green;
      } else {
        borderColor = AppTheme.accent;
        fillColor = AppTheme.accent.withValues(alpha: 0.06);
        letterColor = AppTheme.accent;
      }
    } else if (completed) {
      borderColor = AppTheme.green.withValues(alpha: 0.45);
      fillColor = AppTheme.green.withValues(alpha: 0.06);
      letterColor = AppTheme.text2;
    } else {
      borderColor = AppTheme.red.withValues(alpha: 0.35);
      fillColor = AppTheme.red.withValues(alpha: 0.05);
      letterColor = AppTheme.text3;
    }

    Widget cell = Tooltip(
      message: tooltip,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (progress > 0 && progress < 1)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: progress.clamp(0.0, 1.0),
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.green.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    letter,
                    style: AppTheme.mono(
                      color: letterColor,
                      size: isToday ? 13 : 11,
                    ).copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      cell = GestureDetector(onTap: onTap, child: cell);
    }
    return cell;
  }
}
