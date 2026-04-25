import '../theme/theme.dart';
import '../background.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LivelyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: [
                    SGTouchable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.line, width: 1),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Icon(Icons.chevron_left,
                            color: AppTheme.text1, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('ACHIEVEMENTS', style: AppTheme.h1()),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.workspace_premium,
                        size: 80, color: AppTheme.amber.withValues(alpha: 0.3)),
                    const SizedBox(height: 24),
                    Text('COMING SOON',
                        style: AppTheme.h1(color: AppTheme.amber)),
                    const SizedBox(height: 12),
                    Text('Your legacy is being forged.',
                        style: AppTheme.body(color: AppTheme.text2)),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
