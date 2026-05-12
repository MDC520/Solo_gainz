import 'dart:math';
import 'dart:async';
import 'dart:ui';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../widgets/player.dart';
import 'inventory_screen.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserStats? _s;
  String _playerAnim = 'Run'; // Refined in initState based on time
  
  bool get _isNight {
    final hour = DateTime.now().hour;
    return hour >= 22 || hour < 5;
  }

  bool _isAutoSpawning = false;

  bool get _isMidnightHour {
    final hour = DateTime.now().hour;
    // Visible from Midnight (0) up to 4 AM (3:59)
    if (hour >= 4) return false;
    
    final lastTrigger = Storage.getData('last_midnight_event_date');
    final today = DateTime.now().toIso8601String().split('T')[0];
    return lastTrigger != today;
  }

  void _startMidnightSequence() {
    if (_isAutoSpawning) return;
    setState(() => _isAutoSpawning = true);
    
    // Save current date to prevent multiple triggers in one night
    Storage.saveData('last_midnight_event_date', DateTime.now().toIso8601String().split('T')[0]);
    
    // Clear any existing odds first
    AppShell.midnightOdds.value = [];
    
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      final currentOdds = AppShell.midnightOdds.value;
      if (currentOdds.length >= 150) {
        timer.cancel();
        _showMidnightDialog();
      } else {
        final rand = Random();
        final sw = MediaQuery.of(context).size.width;
        final sh = MediaQuery.of(context).size.height;
        
        AppShell.midnightOdds.value = [
          ...currentOdds,
          (
            b: -200.0 + rand.nextDouble() * (sh + 200),
            r: -200.0 + rand.nextDouble() * (sw + 200),
          )
        ];
      }
    });
  }

  void _showMidnightDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _MidnightDialog(),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 17) return 'Good Afternoon,';
    if (hour >= 17 && hour < 22) return 'Good Evening,';
    return 'Go To Sleep,';
  }



  @override
  void initState() {
    super.initState();
    _load();
    _playerAnim = _isNight ? 'Stunned' : 'Run';
  }

  void _load() {
    try {
      if (mounted) setState(() => _s = Storage.getUserStats());
    } catch (e) {
      debugPrint('Home load error: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_s == null) return const Center(child: CircularProgressIndicator());
    final s = _s!;
    final xpNeeded = RankSystem.getXpNeededForNextLevel(s.rank);
    final progress = (s.xp / xpNeeded).clamp(0.0, 1.0);

    return Stack(
      children: [
        CustomScrollView(
          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting, style: AppTheme.caption(color: _greeting.contains('Sleep') ? AppTheme.white : AppTheme.text2)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(Storage.getCurrentUser() ?? 'Athlete', style: AppTheme.h1()),
                              const SizedBox(width: 8),
                              Text('Lv.${s.level}', 
                                   style: AppTheme.mono(color: AppTheme.accent, size: 14).copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 140,
                            height: 6,
                            decoration: BoxDecoration(color: AppTheme.line, borderRadius: BorderRadius.circular(4)),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  width: 140 * progress,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.cyan]),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 4)],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Rank ${s.rank} - ${s.xp}/$xpNeeded XP',
                               style: AppTheme.caption(color: AppTheme.text2).copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SGTouchable(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.line, width: 1.5),
                          ),
                          child: Icon(Icons.backpack, size: 18, color: AppTheme.text1),
                        ),
                      ),
                    ],
                  ),
              ),
            ),

            // Player Card (Full Width)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 100),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.symmetric(
                      horizontal: BorderSide(color: AppTheme.accent, width: 2.0),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Ground Line
                      Positioned(
                        bottom: 30, left: 20, right: 20,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppTheme.line.withValues(alpha: 0),
                              AppTheme.accent.withValues(alpha: 0.6),
                              AppTheme.line.withValues(alpha: 0),
                            ]),
                          ),
                        ),
                      ),

                      // Player Model
                      Positioned(
                        bottom: 30, left: 0, right: 0, height: 260,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Player(
                            animation: _playerAnim,
                            fps: _playerAnim == 'Run' ? 12 : 8,
                            size: 260,
                            loop: _playerAnim == 'Run' || _playerAnim == 'Stunned' || _playerAnim == 'Idle',
                            onComplete: () {
                              if (mounted) setState(() => _playerAnim = _isNight ? 'Stunned' : 'Run');
                            },
                          ),
                        ),
                      ),

                      // Sleep Zs
                      if (_isNight && _playerAnim == 'Stunned')
                        const Positioned.fill(child: _SleepZs()),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isMidnightHour && !_isAutoSpawning)
          Positioned(
            bottom: 130,
            right: 15,
            child: GestureDetector(
              onTap: _startMidnightSequence,
              child: Image.asset(
                'Assets/Odds7.png',
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
          )
      ],
    );
  }
}

class _MidnightDialog extends StatefulWidget {
  const _MidnightDialog();
  @override
  State<_MidnightDialog> createState() => _MidnightDialogState();
}

class _MidnightDialogState extends State<_MidnightDialog> with TickerProviderStateMixin {
  int _seconds = 5;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            t.cancel();
            SystemNavigator.pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppTheme.red.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.red.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.15).animate(
                    CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.red, width: 3),
                    ),
                    child: Icon(Icons.nightlight_round, size: 60, color: AppTheme.red),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "SYSTEM LOCKOUT",
                  style: AppTheme.mono(color: AppTheme.red, size: 12).copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "GO TO SLEEP",
                  style: AppTheme.h1(color: Colors.white).copyWith(
                    fontSize: 34,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Rest is the foundation of growth. Your training session has been terminated to prioritize biological recovery.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.6,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 48),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: _seconds / 5,
                        strokeWidth: 6,
                        color: AppTheme.red,
                        backgroundColor: AppTheme.red.withValues(alpha: 0.1),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      "$_seconds",
                      style: AppTheme.h1(color: Colors.white).copyWith(fontSize: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 8, height: 8,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "SHUTDOWN IN PROGRESS",
                        style: AppTheme.caption(color: Colors.white38).copyWith(
                          fontSize: 9,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepZs extends StatefulWidget {
  const _SleepZs();
  @override
  State<_SleepZs> createState() => _SleepZsState();
}

class _SleepZsState extends State<_SleepZs> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: List.generate(3, (i) {
            final double t = (_ctrl.value + (i / 3)) % 1.0;
            return Positioned(
              bottom: 80 + (t * 50),
              left: MediaQuery.of(context).size.width / 2 + 10 + (sin(t * 4) * 15),
              child: Opacity(
                opacity: (1.0 - t).clamp(0, 1),
                child: Transform.scale(
                  scale: 0.6 + (t * 0.4),
                  child: Text(
                    'Z',
                    style: AppTheme.mono(
                      color: i % 2 == 0 ? Colors.purpleAccent : Colors.blueAccent,
                      size: 12 + (i * 4).toDouble(),
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
