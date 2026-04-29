import 'dart:math';
import 'dart:async';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../widgets/player.dart';
import 'inventory_screen.dart';

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

  bool _flipPlayer = false;
  int _hitCount = 0;
  double _cardHurtPulse = 0.0;
  String _voiceLine = "Let's get those gains today!";
  bool _showBubble = false;
  Timer? _bubbleTimer;
  Timer? _hitResetTimer;
  Alignment _voiceAlign = Alignment.centerLeft;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 17) return 'Good Afternoon,';
    if (hour >= 17 && hour < 22) return 'Good Evening,';
    return 'Go To Sleep,';
  }

  static const List<String> _lines = [
    "Are we lifting or just scrolling?",
    "Your muscles are buffering...",
    "Sweat is just fat crying.",
    "Gravity is your only enemy.",
    "Biceps: Loading... 404 error.",
    "I'm 100% pixels, 0% body fat.",
    "Do you even lift, bro?",
    "Don't stop, I'm watching.",
    "My code is stronger than your squat.",
    "Legacy is better than likes.",
    "Earn that cheat meal.",
    "I don't need rest, but you do.",
    "Upgrade your body, not your phone.",
    "Is that a pump or just lighting?",
    "Winners don't make excuses.",
    "I'm judging your form right now.",
    "Put the phone down and push!",
    "Your potential is infinite.",
    "Character growth requires pain.",
    "I'm digital, you're biological. Move!",
  ];

  static const List<String> _hurtLines = [
    "Stop poking my polygons!",
    "That's a technical foul!",
    "My ego! It's bruised!",
    "I'll remember this at level 100.",
    "Reported for bullying a sprite.",
    "Is this your cardio? Tapping?",
    "My health bar is screaming.",
    "Go fight a boss, not me!",
    "Ouch! My pixels are leaking!",
    "I'll remember this!",
    "Hey! I'm on your team!",
    "That wasn't in the tutorial!",
    "Stop, or I'll delete your save!",
    "You tap like a level 1.",
    "My collision box isn't a toy!",
    "I'm fragile! Handle with care!",
    "Save the aggression for the iron!",
    "Pixelated pain! It's real!",
  ];

  static const List<String> _stunnedLines = [
    "Dizzy... so dizzy...",
    "Brain.exe has stopped.",
    "Seeing stars... many stars.",
    "Overload! Rebooting!",
  ];

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
    _bubbleTimer?.cancel();
    _hitResetTimer?.cancel();
    super.dispose();
  }

  void _showVoiceLine({bool isHurt = false, bool isStunned = false}) {
    _bubbleTimer?.cancel();
    setState(() {
      final list = isStunned ? _stunnedLines : (isHurt ? _hurtLines : _lines);
      String newLine;
      do {
        newLine = list[Random().nextInt(list.length)];
      } while (newLine == _voiceLine && list.length > 1);

      _voiceLine = newLine;
      final isLeft = Random().nextBool();
      _voiceAlign = Alignment(
        isLeft ? -0.85 : 0.85,
        (Random().nextDouble() * 1.4) - 0.7,
      );
      _showBubble = true;
    });
    _bubbleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  void _onPlayerTap() async {
    if (_playerAnim == 'Stunned') return;
    _hitResetTimer?.cancel();
    _showVoiceLine(isHurt: true);
    _hitCount++;

    setState(() => _cardHurtPulse = 1.0);

    if (_hitCount >= 10) {
      _hitCount = 0;
      setState(() => _playerAnim = 'Stunned');
      _showVoiceLine(isStunned: true);
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _playerAnim = _isNight ? 'Stunned' : 'Run';
          _cardHurtPulse = 0.0;
        });
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _playerAnim != 'Stunned') {
        setState(() => _cardHurtPulse = 0.0);
      }
    });

    _hitResetTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _hitCount = 0);
    });

    final anims = ['Hit', 'HitUp'];
    setState(() => _playerAnim = anims[Random().nextInt(anims.length)]);
  }

  @override
  Widget build(BuildContext context) {
    if (_s == null) return const Center(child: CircularProgressIndicator());
    final s = _s!;
    final xpNeeded = RankSystem.getXpNeededForNextLevel(s.rank);
    final progress = (s.xp / xpNeeded).clamp(0.0, 1.0);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
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
                  horizontal: BorderSide(
                    color: Color.lerp(AppTheme.line, AppTheme.red.withValues(alpha: 0.5), _cardHurtPulse)!,
                    width: 1.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Voice Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _showBubble ? 1.0 : 0.0,
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          alignment: _voiceAlign,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                _voiceLine,
                                style: AppTheme.caption(color: AppTheme.text1).copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                textAlign: _voiceAlign.x < 0 ? TextAlign.left : TextAlign.right,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

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
                      child: Transform.scale(
                        scaleX: _flipPlayer ? -1 : 1,
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
                  ),

                  // Sleep Zs
                  if (_isNight && _playerAnim == 'Stunned')
                    const Positioned.fill(child: _SleepZs()),

                  // Hitbox
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _onPlayerTap,
                      behavior: HitTestBehavior.opaque,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
