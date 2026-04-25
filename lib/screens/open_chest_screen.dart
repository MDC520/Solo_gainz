import 'dart:math';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../widgets/chest_sprite.dart';

class OpenChestScreen extends StatefulWidget {
  final int slotIndex;
  final String chestType;

  const OpenChestScreen({
    super.key,
    required this.slotIndex,
    required this.chestType,
  });

  @override
  State<OpenChestScreen> createState() => _OpenChestScreenState();
}

class _OpenChestScreenState extends State<OpenChestScreen>
    with TickerProviderStateMixin {
  // -- State --
  int _rewardCoins = 0;
  bool _isMaxReward = false;
  String _spriteAnimation = 'Idle';

  int _tapsRemaining = 3; // Must tap 3 times to open
  bool _chestOpened = false;
  bool _showClaimButton = false;

  // -- Controllers --
  late AnimationController _dropCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _burstCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _particlesCtrl;

  // -- Animations --
  late Animation<double> _dropScale;
  late Animation<Alignment> _dropAlign;

  late Animation<double> _flashOpacity;
  late Animation<double> _glowScale;
  late Animation<double> _rewardScale;
  late Animation<double> _rewardSlide;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _generateReward();
    _setupAnimations();
    _startDropSequence();
  }

  void _generateReward() {
    final rng = Random();
    final isWooden = widget.chestType == 'wooden_chest';

    // Same odds as before
    if (isWooden) {
      final roll = rng.nextDouble();
      if (roll < 0.60) {
        _rewardCoins = 6 + rng.nextInt(45);
      } else if (roll < 0.85)
        _rewardCoins = 51 + rng.nextInt(50);
      else if (roll < 0.96)
        _rewardCoins = 101 + rng.nextInt(150);
      else if (roll < 0.995)
        _rewardCoins = 251 + rng.nextInt(148);
      else
        _rewardCoins = 399;
    } else {
      final roll = rng.nextDouble();
      if (roll < 0.45) {
        _rewardCoins = 6 + rng.nextInt(45);
      } else if (roll < 0.75)
        _rewardCoins = 51 + rng.nextInt(50);
      else if (roll < 0.92)
        _rewardCoins = 101 + rng.nextInt(150);
      else if (roll < 0.99)
        _rewardCoins = 251 + rng.nextInt(148);
      else
        _rewardCoins = 399;
    }
    _isMaxReward = _rewardCoins == 399;
  }

  void _setupAnimations() {
    // 1. Drop In
    _dropCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _dropAlign = AlignmentTween(
            begin: const Alignment(0, -2.0), end: const Alignment(0, 0.2))
        .animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.bounceOut));
    _dropScale = Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.easeOutBack));

    // 2. Float while waiting for tap
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutSine));

    // 3. Shake per tap
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));

    // 4. Burst and Reveal (The explosion!)
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));

    _flashOpacity = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 10),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 70),
    ]).animate(_burstCtrl);

    _glowScale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 4.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(4.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut));

    _rewardScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _burstCtrl,
        curve: const Interval(0.25, 0.6, curve: Curves.elasticOut)));

    _rewardSlide = Tween<double>(begin: 80.0, end: -120.0).animate(
        CurvedAnimation(
            parent: _burstCtrl,
            curve: const Interval(0.25, 0.6, curve: Curves.easeOutBack)));

    // 5. Particles continuously firing after burst
    _particlesCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000));
  }

  Future<void> _startDropSequence() async {
    await _dropCtrl.forward();
  }

  void _onChestTap() {
    if (_chestOpened || !_dropCtrl.isCompleted) return;

    setState(() {
      _tapsRemaining--;
    });

    if (_tapsRemaining > 0) {
      // Rapid shake
      _shakeCtrl.forward(from: 0).then((_) {
        if (mounted && !_chestOpened) _shakeCtrl.reverse();
      });
    } else {
      _openChest();
    }
  }

  Future<void> _openChest() async {
    if (_chestOpened) return;
    setState(() {
      _chestOpened = true;
    });

    _floatCtrl.stop();
    _burstCtrl.forward();
    _particlesCtrl.repeat(); // let the particles rain

    // Switch to open sprite at the flash peak
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _spriteAnimation = 'Open');
    });

    // Show claim button near the end of burst
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showClaimButton = true);
    });
  }

  void _claim() {
    final stats = Storage.getUserStats();
    stats.coins += _rewardCoins;
    Storage.saveUserStats(stats);
    Storage.removeFromInventory(widget.slotIndex);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _dropCtrl.dispose();
    _shakeCtrl.dispose();
    _burstCtrl.dispose();
    _floatCtrl.dispose();
    _particlesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spriteType = widget.chestType == 'wooden_chest' ? 'wooden' : 'iron';
    final isWooden = widget.chestType == 'wooden_chest';

    final Color baseGlow =
        isWooden ? const Color(0xFFD4A373) : const Color(0xFF90E0EF);
    final Color intenseGlow = isWooden ? AppTheme.amber : AppTheme.cyan;

    // ignore: deprecated_member_use
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black, // true black for contrast
        body: Stack(
          alignment: Alignment.center,
          children: [
            // No background light rays (removed)

            // Particle burst (after open) - Keeping particles but making them less "glowy"
            if (_chestOpened)
              AnimatedBuilder(
                animation: _particlesCtrl,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _PremiumBurstPainter(
                      progress: _particlesCtrl.value,
                      color: intenseGlow.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),

            // The Chest (and tap interaction)
            AnimatedBuilder(
              animation: Listenable.merge(
                  [_dropCtrl, _floatCtrl, _shakeCtrl, _burstCtrl]),
              builder: (context, _) {
                // Drop alignment and float
                final currentAlign = _dropAlign.value;
                double currentScale = _dropScale.value;

                // Shake calculation
                double shakeX = 0;
                if (!_chestOpened && _shakeCtrl.isAnimating) {
                  shakeX = sin(_shakeCtrl.value * pi * 4) * 8.0;
                  currentScale += sin(_shakeCtrl.value * pi) * 0.05; // bulge
                }

                return Align(
                  alignment: currentAlign,
                  child: Transform.translate(
                    offset: Offset(shakeX, _chestOpened ? 0 : _floatAnim.value),
                    child: Transform.scale(
                      scale: currentScale,
                      child: GestureDetector(
                        onTap: _onChestTap,
                        behavior: HitTestBehavior.opaque,
                        child: ChestSprite(
                          chestType: spriteType,
                          animation: _spriteAnimation,
                          fps: _spriteAnimation == 'Open' ? 14 : 10,
                          size: 180,
                          playOnce: _spriteAnimation == 'Open',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Instructional Text
            if (!_chestOpened && _dropCtrl.isCompleted)
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.25,
                child: AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (context, _) => Opacity(
                    opacity: 0.5 +
                        (sin(_floatCtrl.value) * 0.5 + 0.5) *
                            0.5, // 0.5 to 1.0 pulse
                    child: Column(
                      children: [
                        Text(
                          _tapsRemaining > 1
                              ? 'TAP TO UNLOCK'
                              : 'ONE MORE TAP!',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                              3,
                              (index) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: index >= (3 - _tapsRemaining)
                                            ? Colors.white24
                                            : intenseGlow,
                                      ),
                                    ),
                                  )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // White Flash Overlay (Explosion)
            AnimatedBuilder(
              animation: _burstCtrl,
              builder: (context, _) => IgnorePointer(
                child: Opacity(
                  opacity: _flashOpacity.value,
                  child: Container(color: Colors.white),
                ),
              ),
            ),

            // The Reward (Floats up from the chest)
            if (_chestOpened)
              AnimatedBuilder(
                animation: _burstCtrl,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(0, _rewardSlide.value),
                      child: Transform.scale(
                        scale: _rewardScale.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isMaxReward) ...[
                              Text('★ JACKPOT ★',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.amber,
                                    letterSpacing: 4,
                                  )),
                              const SizedBox(height: 8),
                            ] else ...[
                              Text('YOU FOUND',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                    letterSpacing: 2,
                                  )),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.generating_tokens_rounded,
                                    size: 48, color: AppTheme.amber),
                                const SizedBox(width: 12),
                                Text(
                                  '+$_rewardCoins',
                                  style: GoogleFonts.inter(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Claim Button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              bottom: _showClaimButton ? 50 : -100,
              child: SGTouchable(
                onTap: _claim,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'COLLECT REWARD',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the premium explosion particles
class _PremiumBurstPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 repeating
  final Color color;

  _PremiumBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Firing particles outwards from center
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final random = Random(42); // fixed seed for consistent rays

    for (int i = 0; i < 40; i++) {
      final angle = random.nextDouble() * pi * 2;
      // We use speed and offset so particles appear at different times during the progress loop
      final speed = 0.5 + random.nextDouble() * 1.5; // distance modifier
      final delay = random.nextDouble();

      // particle's local time [0.0 - 1.0]
      double localT = (progress + delay) % 1.0;

      // smooth fade out
      final opacity = (1.0 - localT) * (random.nextDouble() * 0.6 + 0.4);

      // Calculate position (moving outwards)
      final dist = localT * (size.width * 0.8) * speed;
      final dx = center.dx + cos(angle) * dist;
      final dy = center.dy + sin(angle) * dist;

      paint.color = i % 3 == 0
          ? Colors.white.withValues(alpha: opacity)
          : color.withValues(alpha: opacity);

      // size decreases as it moves outward
      final radius = (3.0 + random.nextDouble() * 3.0) * (1.0 - localT);

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumBurstPainter oldDelegate) => true;
}
