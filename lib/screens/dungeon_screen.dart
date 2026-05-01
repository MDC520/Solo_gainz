import 'package:flutter/services.dart';
import '../theme/theme.dart';
import 'training_screen.dart';

class DungeonPage extends StatelessWidget {
  const DungeonPage({super.key});

  void _startTraining(BuildContext context) async {
    // 1. Request orientation change first
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // 2. Wait for the OS to rotate (fixes the "still not landscaped" issue on many devices)
    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;

    // 3. Navigate and ensure it resets when returning
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrainingScreen(isLoading: true),
      ),
    ).then((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fort_rounded,
              size: 60,
              color: AppTheme.accent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'DUNGEONS',
              style: AppTheme.h1().copyWith(letterSpacing: 4, fontSize: 24),
            ),
            const SizedBox(height: 32),
            
            // Training Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SGTouchable(
                onTap: () => _startTraining(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.surface,
                        AppTheme.surface.withValues(alpha: 0.8),
                        AppTheme.accent.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fitness_center_rounded, color: AppTheme.accent, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CARD OF TRAINING',
                        style: AppTheme.h2().copyWith(color: AppTheme.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Master your movement and speed',
                        style: AppTheme.body(color: AppTheme.text2),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ENTER',
                          style: AppTheme.label(color: Colors.black).copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            Text(
              'MORE CHALLENGES COMING SOON',
              style: AppTheme.label(color: AppTheme.text2).copyWith(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}
