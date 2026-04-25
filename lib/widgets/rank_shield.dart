import '../theme/theme.dart';

class RankShield extends StatelessWidget {
  final String rank;
  final double size;
  final bool showShadow;

  const RankShield({
    super.key,
    required this.rank,
    this.size = 80,
    this.showShadow = false,
  });

  String get _assetPath {
    final r = rank.toUpperCase();
    // Mapping internal rank names to asset filenames
    if (r == 'BB') return 'Assets/Rank Shields/B Rank.png';
    // Fallback for missing SG Rank image to SS or S
    if (r == 'SG') return 'Assets/Rank Shields/SS Rank.png';

    // Default mapping for E, D, C, A, S, SS
    return 'Assets/Rank Shields/$r Rank.png';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.accent, width: 2),
      ),
      child: Center(
        child: Text(
          rank,
          style: AppTheme.h1(color: AppTheme.accent)
              .copyWith(fontSize: size * 0.4),
        ),
      ),
    );
  }
}
