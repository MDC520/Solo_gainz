import 'dart:math';
import 'storage.dart';
import 'theme.dart';
import 'chest.dart';
import 'background.dart';

class OpenScreen extends StatefulWidget {
  final int slotIndex;
  final String chestType;

  const OpenScreen({
    super.key,
    required this.slotIndex,
    required this.chestType,
  });

  @override
  State<OpenScreen> createState() => _OpenScreenState();
}

class _OpenScreenState extends State<OpenScreen> with TickerProviderStateMixin {
  int _rewardCoins = 0;
  bool _isMaxReward = false;
  String _spriteAnimation = 'Idle';
  bool _chestOpened = false;
  bool _showClaimButton = false;
  bool _didStart = false;

  // Ground sits at 62% screen height
  static const double _groundFraction = 0.62;
  final double _chestSize = 160.0;

  late AnimationController _dropCtrl;
  late AnimationController _burstCtrl;
  late AnimationController _dustCtrl;
  late AnimationController _particlesCtrl;
  late AnimationController _floatCtrl; // Subtle idle bob for reward text

  // 0 = above screen, 1 = landed
  late Animation<double> _dropProgress;
  late Animation<double> _dustOpacity;
  late Animation<double> _flashOpacity;
  late Animation<double> _rewardScale;
  late Animation<double> _rewardSlide;
  late Animation<double> _floatOffset; // Gentle up-down bob
  late Animation<int> _rewardCounter; // Rapid counting arcade animation
  late AnimationController _pulseCtrl; // Breathing pulse loop for reveal button
  late Animation<double> _pulseScale; // Gentle scaling of tap hint

  @override
  void initState() {
    super.initState();
    _generateReward();
    _setupAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didStart) {
      _didStart = true;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _dropCtrl.forward().then((_) {
            if (!mounted) return;
            // Trigger dust on land
            _dustCtrl.forward();
            _pulseCtrl.repeat(reverse: true); // Start premium breathing pulse
            HapticFeedback.heavyImpact();
          });
        }
      });
    }
  }

  void _generateReward() {
    final rng = Random();
    final type = widget.chestType;
    if (type == 'wooden_chest') {
      final roll = rng.nextDouble();
      if (roll < 0.05) {
        // Troll drop (5% chance)
        _rewardCoins = 2 + rng.nextInt(9);
      } else if (roll < 0.70) {
        // Common (65% chance)
        _rewardCoins = 25 + rng.nextInt(36);
      } else if (roll < 0.90) {
        // Rare (20% chance)
        _rewardCoins = 65 + rng.nextInt(46);
      } else if (roll < 0.99) {
        // Epic (9% chance)
        _rewardCoins = 120 + rng.nextInt(81);
      } else {
        // Mythical Jackpot (1% chance)
        _rewardCoins = 350;
      }
    } else if (type == 'iron_chest') {
      final roll = rng.nextDouble();
      if (roll < 0.05) {
        // Troll drop (5% chance)
        _rewardCoins = 15 + rng.nextInt(26);
      } else if (roll < 0.65) {
        // Common (60% chance)
        _rewardCoins = 70 + rng.nextInt(61);
      } else if (roll < 0.88) {
        // Rare (23% chance)
        _rewardCoins = 140 + rng.nextInt(81);
      } else if (roll < 0.98) {
        // Epic (10% chance)
        _rewardCoins = 230 + rng.nextInt(151);
      } else {
        // Mythical Jackpot (2% chance)
        _rewardCoins = 600;
      }
    } else if (type == 'gold_chest') {
      final roll = rng.nextDouble();
      if (roll < 0.05) {
        // Troll drop (5% chance)
        _rewardCoins = 50 + rng.nextInt(71);
      } else if (roll < 0.60) {
        // Common (55% chance)
        _rewardCoins = 220 + rng.nextInt(161);
      } else if (roll < 0.85) {
        // Rare (25% chance)
        _rewardCoins = 400 + rng.nextInt(251);
      } else if (roll < 0.97) {
        // Epic (12% chance)
        _rewardCoins = 700 + rng.nextInt(401);
      } else {
        // Mythical Jackpot (3% chance)
        _rewardCoins = 2000;
      }
    } else {
      // Mysterious Chest: Massive premium rewards and mythical jackpot!
      final roll = rng.nextDouble();
      if (roll < 0.05) {
        // Troll drop (5% chance)
        _rewardCoins = 150 + rng.nextInt(201);
      } else if (roll < 0.55) {
        // Common (50% chance)
        _rewardCoins = 500 + rng.nextInt(351);
      } else if (roll < 0.82) {
        // Rare (27% chance)
        _rewardCoins = 900 + rng.nextInt(501);
      } else if (roll < 0.96) {
        // Epic (14% chance)
        _rewardCoins = 1500 + rng.nextInt(1001);
      } else {
        // Mythical Jackpot (4% chance)
        _rewardCoins = 5000;
      }
    }
    _isMaxReward = (widget.chestType == 'mysterious_chest')
        ? _rewardCoins == 5000
        : (widget.chestType == 'gold_chest')
            ? _rewardCoins == 2000
            : (widget.chestType == 'iron_chest')
                ? _rewardCoins == 600
                : _rewardCoins == 350;
  }

  void _setupAnimations() {
    // Drop: progress 0→1 (0=off screen top, 1=landed)
    _dropCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _dropProgress = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.bounceOut));

    // Dust puff
    _dustCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _dustOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _dustCtrl, curve: Curves.easeOut));

    // Burst open (made much faster and snappier for instant gratification!)
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _flashOpacity = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 15),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 60),
    ]).animate(_burstCtrl);
    
    // Animate instantly from tap (0.0 to 0.55 interval)
    _rewardScale = Tween<double>(begin: 0.1, end: 1.0).animate(CurvedAnimation(
        parent: _burstCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack)));
    _rewardSlide = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: _burstCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.fastOutSlowIn)));

    // Dynamic ticking arcade count (ticks rapidly 0 -> final amount during flight)
    _rewardCounter = IntTween(begin: 0, end: _rewardCoins).animate(CurvedAnimation(
        parent: _burstCtrl,
        curve: const Interval(0.12, 0.65, curve: Curves.easeOutCubic)));

    // Particles after burst
    _particlesCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000));

    // Subtle floating bob for reward text
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
    _floatOffset = Tween<double>(begin: -4.0, end: 4.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // Breathing pulse for reveal button
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  void _onChestTap() {
    if (_chestOpened || !_dropCtrl.isCompleted) return;
    _openChest();
  }

  Future<void> _openChest() async {
    if (_chestOpened) return;
    setState(() {
      _chestOpened = true;
      _spriteAnimation = 'Open';
    });
    _pulseCtrl.stop(); // Stop pulsing reveal loop
    HapticFeedback.mediumImpact();
    _burstCtrl.forward();
    _particlesCtrl.repeat();
    _floatCtrl.repeat(reverse: true); // Start the gentle floating bob
    Future.delayed(const Duration(milliseconds: 800), () {
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
    _burstCtrl.dispose();
    _dustCtrl.dispose();
    _particlesCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkNotifier,
      builder: (context, isDark, _) {
        final spriteType = widget.chestType == 'wooden_chest'
            ? 'wooden'
            : widget.chestType == 'iron_chest'
                ? 'iron'
                : widget.chestType == 'gold_chest'
                    ? 'gold'
                    : 'mysterious';
        final glowColor = widget.chestType == 'wooden_chest'
            ? AppTheme.amber
            : widget.chestType == 'iron_chest'
                ? AppTheme.cyan
                : widget.chestType == 'gold_chest'
                    ? AppTheme.purple
                    : AppTheme.accent;

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: LivelyBackground(
              mode: LivelyBackgroundMode.wood,
              child: LayoutBuilder(builder: (context, constraints) {
                final double h = constraints.maxHeight;
                final double w = constraints.maxWidth;

                // Ground sits at groundFraction of screen height
                final double groundY = h * _groundFraction;

                // When fully landed, chest bottom = ground, so chest center = groundY - chestSize/2
                final double landedCenterY = groundY - _chestSize / 2;

                // Start position: chest center far above screen
                final double startCenterY = -_chestSize;

                // Reward text emerge & float paths
                final double restingY = h * 0.16;
                final double startingY = landedCenterY - 10;
                final double slideDist = startingY - restingY;

                return Stack(
                  children: [
                    // ── DARK GROUND (below ground line) ──────────────────────
                    Positioned(
                      top: groundY,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF2C1A10).withValues(alpha: 0.85), // Warm premium dark wood top
                              const Color(0xFF140D08).withValues(alpha: 0.98), // Rich deep brown bottom
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── GROUND SHIMMER LINE ───────────────────────────────────
                    Positioned(
                      top: groundY,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.4),
                            isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.4),
                            Colors.transparent,
                          ], stops: const [
                            0.0,
                            0.3,
                            0.7,
                            1.0
                          ]),
                        ),
                      ),
                    ),

                    // ── THEATRICAL SPOTLIGHT (Backlit Volumetric Cinematic Cone) ──────────────────
                    AnimatedBuilder(
                      animation: Listenable.merge([_dropCtrl, _burstCtrl]),
                      builder: (context, _) {
                        double spotlightProgress = 0.0;
                        if (_dropCtrl.isCompleted) {
                          if (_chestOpened) {
                            // Surge spotlight on chest burst
                            spotlightProgress = 0.45 + 0.55 * _burstCtrl.value;
                          } else {
                            // Atmospheric ambient stage glow
                            spotlightProgress = 0.45;
                          }
                        }
                        return IgnorePointer(
                          child: CustomPaint(
                            size: Size(w, h),
                            painter: _SpotlightPainter(
                              progress: spotlightProgress,
                              color: const Color(0xFFFFF2C2), // Warm, theatrical cinematic stage glow color
                              groundY: groundY,
                              chestWidth: _chestSize,
                            ),
                          ),
                        );
                      },
                    ),

                    // ── ANIMATED: CHEST + REFLECTION ─────────────────────────
                    AnimatedBuilder(
                      animation: _dropCtrl,
                      builder: (context, _) {
                        final double t = _dropProgress.value; // 0→1

                        // Current chest center Y (lerp from off-screen to landed)
                        final double chestCenterY =
                            startCenterY + t * (landedCenterY - startCenterY);
                        final double chestTop = chestCenterY - _chestSize / 2;

                        // Reflection opacity fades with distance from ground
                        final double distFromGround =
                            (groundY - chestCenterY).abs();
                        final double maxDist = (groundY - startCenterY).abs();
                        final double reflOpacity =
                            (1 - distFromGround / maxDist) * 0.22;

                        return Stack(
                          children: [
                            // Reflection: anchored at the ground line, flipped vertically
                            Positioned(
                              top: groundY,
                              left: w / 2 - _chestSize / 2,
                              child: ClipRect(
                                child: Opacity(
                                  opacity: reflOpacity.clamp(0.0, 0.22),
                                  child: Transform.scale(
                                    scaleY: -0.5,
                                    alignment: Alignment.topCenter,
                                    child: ChestSprite(
                                      chestType: spriteType,
                                      animation: _spriteAnimation,
                                      fps: _spriteAnimation == 'Open' ? 14 : 8,
                                      size: _chestSize,
                                      playOnce: _spriteAnimation == 'Open',
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // The Chest (always full size, no scale changes, ground shadow removed!)
                            Positioned(
                              top: chestTop,
                              left: w / 2 - _chestSize / 2,
                              child: GestureDetector(
                                onTap: _onChestTap,
                                behavior: HitTestBehavior.opaque,
                                child: ChestSprite(
                                  chestType: spriteType,
                                  animation: _spriteAnimation,
                                  fps: _spriteAnimation == 'Open' ? 14 : 10,
                                  size: _chestSize,
                                  playOnce: _spriteAnimation == 'Open',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // ── DUST PUFF ON LANDING ──────────────────────────────────
                    Positioned(
                      top: groundY - 60, // Give 60px height above ground to rise!
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _dustCtrl,
                        builder: (context, _) {
                          if (!_dustCtrl.isAnimating && !_dustCtrl.isCompleted) {
                            return const SizedBox.shrink();
                          }
                          return Opacity(
                            opacity: _dustOpacity.value,
                            child: CustomPaint(
                              size: Size(w, 60), // Ground is bottom edge of container
                              painter: _DustPainter(
                                progress: _dustCtrl.value,
                                cx: w / 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── WHITE FLASH ───────────────────────────────────────────
                    AnimatedBuilder(
                      animation: _burstCtrl,
                      builder: (context, _) => IgnorePointer(
                        child: Opacity(
                          opacity: _flashOpacity.value,
                          child: Container(color: Colors.white),
                        ),
                      ),
                    ),

                    // ── TAP HINT (upgraded to breathing-pulsing glassmorphic premium capsule) ──
                    if (!_chestOpened)
                      Positioned(
                        bottom: h * 0.17,
                        left: 0,
                        right: 0,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_dropCtrl, _pulseCtrl]),
                          builder: (context, _) {
                            if (!_dropCtrl.isCompleted) {
                              return const SizedBox.shrink();
                            }
                            return ScaleTransition(
                              scale: _pulseScale,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        glowColor.withValues(alpha: 0.10),
                                        glowColor.withValues(alpha: 0.22),
                                        glowColor.withValues(alpha: 0.10),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: glowColor.withValues(alpha: 0.45),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: glowColor.withValues(alpha: 0.15),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'TAP CHEST TO UNLEASH',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.h2(color: AppTheme.white).copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.0,
                                      shadows: [
                                        Shadow(
                                          color: glowColor.withValues(alpha: 0.9),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // ── REWARD TEXT (rises from chest and floats with gentle bob) ────────────────
                    if (_chestOpened)
                      Positioned(
                        top: restingY,
                        left: 0,
                        right: 0,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_burstCtrl, _floatCtrl]),
                          builder: (context, _) {
                            final double currentSlide = _rewardSlide.value;
                            final double yOffset = (currentSlide * slideDist) + 
                                (_burstCtrl.isCompleted || _burstCtrl.value > 0.65 ? _floatOffset.value : 0.0);
                            return Transform.translate(
                              offset: Offset(0, yOffset),
                              child: Transform.scale(
                                scale: _rewardScale.value,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isMaxReward ? '★ JACKPOT ★' : 'YOU FOUND',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.h2(
                                        color: _isMaxReward
                                            ? AppTheme.amber
                                            : AppTheme.text2,
                                      ).copyWith(
                                        fontSize: _isMaxReward ? 26 : 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.7),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '\$',
                                          style: AppTheme.h1(color: AppTheme.amber).copyWith(
                                            fontSize: 52,
                                            fontWeight: FontWeight.w900,
                                            shadows: [
                                              Shadow(
                                                color: AppTheme.amber.withValues(alpha: 0.5),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_rewardCounter.value}',
                                          style: AppTheme.h1(color: AppTheme.white).copyWith(
                                            fontSize: 72,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withValues(alpha: 0.6),
                                                blurRadius: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // ── CINEMATIC VIGNETTE (darkened edges for dramatic depth) ──────────
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0.0, -0.2),
                            radius: 1.1,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            stops: const [0.0, 0.45, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // ── COLLECT BUTTON ────────────────────────────────────────
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      bottom: _showClaimButton ? 40 : -120,
                      left: 24,
                      right: 24,
                      child: SGTouchable(
                        onTap: _claim,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.45),
                                blurRadius: 24,
                                spreadRadius: 4,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'COLLECT REWARD',
                              style: AppTheme.h2(color: Colors.white).copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// ── Dust Puff Painter ─────────────────────────────────────────────────────────
class _DustPainter extends CustomPainter {
  final double progress; // 0 → 1
  final double cx;

  _DustPainter({required this.progress, required this.cx});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 24; i++) {
      final side = i % 2 == 0 ? 1 : -1; // spread left & right
      final speed = 0.4 + rng.nextDouble() * 0.6;
      final angle =
          (rng.nextDouble() * 40 - 20) * pi / 180; // mostly horizontal
      final dist = progress * (40 + rng.nextDouble() * 80) * speed;
      final rise = progress *
          (15 + rng.nextDouble() * 35) *
          progress; // arc upward then fall

      final dx = cx + side * dist * cos(angle);
      final dy = size.height - rise; // Rise upward from the ground line (bottom of container)
      final radius = (4 + rng.nextDouble() * 6) * (1 - progress);
      final opacity = (1 - progress) * (0.5 + rng.nextDouble() * 0.5);

      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, dy), radius.clamp(0.5, 12), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter old) => old.progress != progress;
}



// ── Theatrical Spotlight Painter ──────────────────────────────────────────────
class _SpotlightPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (for fade-in and pulsing/shimmering)
  final Color color;
  final double groundY;
  final double chestWidth;

  _SpotlightPainter({
    required this.progress,
    required this.color,
    required this.groundY,
    required this.chestWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final double cx = size.width / 2;
    
    // Create the cone path (like a classic theatre spotlight radiating downwards)
    final path = Path();
    path.moveTo(cx - 20, 0); // Narrow beam start at the very top of the screen
    path.lineTo(cx + 20, 0);
    path.lineTo(cx + chestWidth * 1.5, groundY); // Wider cone surrounding the chest
    path.lineTo(cx - chestWidth * 1.5, groundY);
    path.close();

    // Volumetric glow shader
    final rect = Rect.fromLTRB(cx - chestWidth * 1.5, 0, cx + chestWidth * 1.5, groundY);
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: progress * 0.45), // Bright source glow at the top
        color.withValues(alpha: progress * 0.08), // Soft dispersed beam around chest
        Colors.transparent,
      ],
      stops: const [0.0, 0.75, 1.0],
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20); // Volumetric cinematic blur

    canvas.drawPath(path, paint);

    // Draw the bright spotlight beam source spotlight bulb at the very top
    final sourcePaint = Paint()
      ..color = Colors.white.withValues(alpha: progress * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(cx, 0), 30, sourcePaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.progress != progress || old.color != color;
}
