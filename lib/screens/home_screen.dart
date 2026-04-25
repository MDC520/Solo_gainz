import 'dart:math';
import 'dart:async';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../widgets/player.dart';
import 'inventory_screen.dart';
import 'dungeon_workout_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserStats? _s;
  String _playerAnim = 'Idle';
  bool _flipPlayer = false;
  int _hitCount = 0;
  double _cardHurtPulse = 0.0;
  String _voiceLine = "Let's get those gains today!";
  bool _showBubble = false;
  Timer? _bubbleTimer;
  Timer? _hitResetTimer;
  Alignment _voiceAlign = Alignment.centerLeft;

  // Dungeon Focus Mode State
  bool _isDungeonFocus = false;
  double _playerX = 0.0;
  Timer? _moveTimer;

  void _startMovement(bool left) {
    if (_playerAnim == 'Stunned') return;
    _moveTimer?.cancel();
    setState(() {
      _playerAnim = 'Run';
      _flipPlayer = left;
    });
    _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _playerX = (_playerX + (left ? -0.02 : 0.02)).clamp(-1.0, 1.0);
      });
    });
  }

  void _stopMovement() {
    _moveTimer?.cancel();
    if (_playerAnim != 'Stunned') {
      setState(() => _playerAnim = 'Idle');
    }
  }

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
    "I'm callin' my developer!",
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

      // Randomize position: Left or Right side, avoiding center model
      final isLeft = Random().nextBool();
      _voiceAlign = Alignment(
        isLeft ? -0.85 : 0.85,
        (Random().nextDouble() * 1.4) -
            0.7, // Random vertical position within card bounds
      );

      _showBubble = true;
    });
    _bubbleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  void _onPlayerTap() async {
    // Prevent any new interaction if the player is stunned
    if (_playerAnim == 'Stunned') return;

    _hitResetTimer?.cancel();
    _showVoiceLine(isHurt: true);
    _hitCount++;

    setState(() {
      _cardHurtPulse = 1.0;
    });

    if (_hitCount >= 10) {
      _hitCount = 0;
      setState(() {
        _playerAnim = 'Stunned';
      });
      _showVoiceLine(isStunned: true);
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _playerAnim = 'Idle';
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
      if (mounted) {
        setState(() {
          _hitCount = 0;
        });
      }
    });

    final anims = ['Hit', 'HitUp'];
    setState(() {
      _playerAnim = anims[Random().nextInt(anims.length)];
    });
  }

  void _enterDungeon() async {
    setState(() => _isDungeonFocus = true);
    await Storage.setNavbarHidden(true);
  }

  void _exitDungeon() async {
    setState(() {
      _isDungeonFocus = false;
      _playerX = 0.0;
    });
    await Storage.setNavbarHidden(false);
  }

  void _showExitDungeonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SGCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.red, size: 32),
              ),
              const SizedBox(height: 16),
              Text('End Session?', style: AppTheme.h2()),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to exit the dungeon focus mode?',
                style: AppTheme.body(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SGButton(
                      label: 'Stay',
                      outlined: true,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SGButton(
                      label: 'Exit',
                      danger: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _exitDungeon();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_s == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = _s!;
    final xpNeeded = RankSystem.getXpNeededForNextLevel(s.rank);
    final progress = (s.xp / xpNeeded).clamp(0.0, 1.0);

    return CustomScrollView(
      physics: ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Top bar & Profile Info
        SliverToBoxAdapter(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _isDungeonFocus ? 0.0 : 1.0,
            child: Visibility(
              visible: !_isDungeonFocus,
              maintainState: true,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_greeting, style: AppTheme.caption()),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Storage.getCurrentUser() ?? 'Athlete',
                                    style: AppTheme.h1(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lv.${s.level}',
                                    style: AppTheme.mono(
                                            color: AppTheme.accent, size: 14)
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // XP Progress Bar
                              Container(
                                width: 140,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.line,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 600),
                                      width: 140 * progress,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.accent,
                                            AppTheme.cyan
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accent
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rank ${s.rank} - ${s.xp}/$xpNeeded XP',
                                style: AppTheme.caption(color: AppTheme.text2)
                                    .copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              SGTouchable(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const InventoryScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.line,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.backpack,
                                    size: 18,
                                    color: AppTheme.text1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Player Card
        SliverToBoxAdapter(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 800),
            curve: SGCurves.easeOutQuart,
            padding: _isDungeonFocus
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: SGCurves.easeOutQuart,
              width: double.infinity,
              height:
                  _isDungeonFocus ? MediaQuery.of(context).size.height : 160,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(_isDungeonFocus ? 0 : 22),
                border: Border.all(
                    color: Color.lerp(AppTheme.line,
                        AppTheme.red.withValues(alpha: 0.5), _cardHurtPulse)!,
                    width: _isDungeonFocus ? 0 : 1),
                boxShadow: _isDungeonFocus
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Internalized Voice Overlay (Visible only in standard mode)
                  if (!_isDungeonFocus)
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 110),
                                child: Text(
                                  _voiceLine,
                                  style: AppTheme.caption(color: AppTheme.text1)
                                      .copyWith(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  textAlign: _voiceAlign.x < 0
                                      ? TextAlign.left
                                      : TextAlign.right,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Ground line
                  Positioned(
                    bottom: _isDungeonFocus ? 180 : 30,
                    left: _isDungeonFocus ? 0 : 20,
                    right: _isDungeonFocus ? 0 : 20,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.line.withValues(alpha: 0),
                            AppTheme.accent.withValues(alpha: 0.6),
                            AppTheme.line.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Player Model (Oversized)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    curve: SGCurves.easeOutQuart,
                    bottom: _isDungeonFocus ? 180 : 30,
                    left: 0,
                    right: 0,
                    height: _isDungeonFocus ? 400 : 260,
                    child: Align(
                      alignment: _isDungeonFocus
                          ? Alignment(_playerX, 1.0)
                          : Alignment.bottomCenter,
                      child: Transform.scale(
                        scaleX: _flipPlayer ? -1 : 1,
                        child: Player(
                          animation: _playerAnim,
                          fps: _playerAnim == 'Run' ? 12 : 8,
                          size: _isDungeonFocus ? 400 : 260,
                          loop: _playerAnim == 'Idle' ||
                              _playerAnim == 'Run' ||
                              _playerAnim == 'Stunned',
                          onComplete: () {
                            if (mounted) setState(() => _playerAnim = 'Idle');
                          },
                        ),
                      ),
                    ),
                  ),

                  // Interaction areas for movement (Background Layer)
                  _DungeonInteractionArea(
                    onHoldLeft: () => _startMovement(true),
                    onHoldRight: () => _startMovement(false),
                    onRelease: _stopMovement,
                  ),

                  // Specialized Hitbox (Only triggers hit when touching the model)
                  // MUST BE ON TOP of movement areas to catch taps on character
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    curve: SGCurves.easeOutQuart,
                    bottom: _isDungeonFocus ? 180 : 0,
                    left: 0,
                    right: 0,
                    top: _isDungeonFocus
                        ? 0
                        : -100, // Reaching up for head/torso hits
                    child: Align(
                      alignment: _isDungeonFocus
                          ? Alignment(_playerX, 1.0)
                          : Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: _onPlayerTap,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: _isDungeonFocus ? 200 : 160,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),

                  // Dungeon Control Arrows (At standard bottom)
                  if (_isDungeonFocus)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _DungeonControlButton(
                              icon: Icons.chevron_left,
                              onHoldToggle: (hold) =>
                                  hold ? _startMovement(true) : _stopMovement(),
                            ),
                            _DungeonControlButton(
                              icon: Icons.chevron_right,
                              onHoldToggle: (hold) => hold
                                  ? _startMovement(false)
                                  : _stopMovement(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Immersive Action HUD
                  if (_isDungeonFocus)
                    Positioned.fill(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 120),
                            SGTouchable(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const DungeonWorkoutScreen()),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppTheme.amber, AppTheme.accent],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.amber.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt,
                                        color: Colors.black, size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'CLEAR FLOOR 1',
                                      style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'DANGER LEVEL: LOW',
                              style:
                                  AppTheme.mono(color: AppTheme.amber, size: 10)
                                      .copyWith(letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Return Button (Moved to top of stack)
                  if (_isDungeonFocus)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: SGTouchable(
                        onTap: _showExitDungeonDialog,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.5),
                                width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.stop_rounded,
                              color: AppTheme.accent, size: 24),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Dungeon Portal Card (Hide in Focus Mode)
        SliverToBoxAdapter(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _isDungeonFocus ? 0.0 : 1.0,
            child: Visibility(
              visible: !_isDungeonFocus,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: SGCard(
                  padding: EdgeInsets.zero,
                  child: SGTouchable(
                    onTap: _enterDungeon,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              border:
                                  Border.all(color: AppTheme.accent, width: 1),
                            ),
                            child: Icon(Icons.door_sliding_outlined,
                                color: AppTheme.accent, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text('ENTER THE GAINZ DUNGEON',
                              style: AppTheme.mono(
                                      color: AppTheme.accent, size: 10)
                                  .copyWith(letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text('Challenge the 20 levels of power',
                              style: AppTheme.caption()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DungeonInteractionArea extends StatelessWidget {
  final VoidCallback onHoldLeft;
  final VoidCallback onHoldRight;
  final VoidCallback onRelease;

  const _DungeonInteractionArea({
    required this.onHoldLeft,
    required this.onHoldRight,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => onHoldLeft(),
              onTapUp: (_) => onRelease(),
              onTapCancel: () => onRelease(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => onHoldRight(),
              onTapUp: (_) => onRelease(),
              onTapCancel: () => onRelease(),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DungeonControlButton extends StatelessWidget {
  final IconData icon;
  final Function(bool) onHoldToggle;

  const _DungeonControlButton({
    required this.icon,
    required this.onHoldToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        AppTheme.tap();
        onHoldToggle(true);
      },
      onTapUp: (_) => onHoldToggle(false),
      onTapCancel: () => onHoldToggle(false),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.accent, size: 36),
      ),
    );
  }
}
