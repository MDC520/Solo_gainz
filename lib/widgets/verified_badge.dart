import '../theme/theme.dart';

class VerifiedBadge extends StatelessWidget {
  final String type;
  final double size;

  const VerifiedBadge({
    super.key,
    required this.type,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (type == 'none' || type.isEmpty) return const SizedBox.shrink();

    final color = type == 'gold' ? AppTheme.amber : AppTheme.cyan;

    return Container(
      margin: const EdgeInsets.only(left: 6),
      child: Icon(
        Icons.verified_rounded,
        size: size,
        color: color,
      ),
    );
  }
}
