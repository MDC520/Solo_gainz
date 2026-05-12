import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../widgets/chest_sprite.dart';
import '../widgets/wood_background.dart';

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

  // 0 = above screen, 1 = landed
  late Animation<double> _dropProgress;
  late Animation<double> _dropScale;
  late Animation<double> _dustOpacity;
  late Animation<double> _flashOpacity;
  late Animation<double> _rewardScale;
  late Animation<double> _rewardSlide;

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
      if (roll < 0.60)       _rewardCoins = 6   + rng.nextInt(45);
      else if (roll < 0.85)  _rewardCoins = 51  + rng.nextInt(50);
      else if (roll < 0.96)  _rewardCoins = 101 + rng.nextInt(150);
      else if (roll < 0.995) _rewardCoins = 251 + rng.nextInt(148);
      else                   _rewardCoins = 399;
    } else if (type == 'iron_chest') {
      final roll = rng.nextDouble();
      if (roll < 0.45)       _rewardCoins = 6   + rng.nextInt(45);
      else if (roll < 0.75)  _rewardCoins = 51  + rng.nextInt(50);
      else if (roll < 0.92)  _rewardCoins = 101 + rng.nextInt(150);
      else if (roll < 0.99)  _rewardCoins = 251 + rng.nextInt(148);
      else                   _rewardCoins = 399;
    } else {
      final roll = rng.nextDouble();
      if (roll < 0.40)       _rewardCoins = 500  + rng.nextInt(500);
      else if (roll < 0.70)  _rewardCoins = 1001 + rng.nextInt(1000);
      else if (roll < 0.90)  _rewardCoins = 2001 + rng.nextInt(1500);
      else if (roll < 0.98)  _rewardCoins = 3501 + rng.nextInt(1498);
      else                   _rewardCoins = 5000;
    }
    _isMaxReward = (widget.chestType == 'gold_chest') ? _rewardCoins == 5000 : _rewardCoins == 399;
  }

  void _setupAnimations() {
    // Drop: progress 0→1 (0=off screen top, 1=landed)
    _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _dropProgress = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.bounceOut));
    _dropScale = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.easeOut));

    // Dust puff
    _dustCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _dustOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _dustCtrl, curve: Curves.easeOut));

    // Burst open
    _burstCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _flashOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 70),
    ]).animate(_burstCtrl);
    _rewardScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _burstCtrl, curve: const Interval(0.25, 0.6, curve: Curves.elasticOut)));
    _rewardSlide = Tween<double>(begin: 60.0, end: -60.0).animate(
        CurvedAnimation(parent: _burstCtrl, curve: const Interval(0.25, 0.6, curve: Curves.easeOutBack)));

    // Particles after burst
    _particlesCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
  }

  void _onChestTap() {
    if (_chestOpened || !_dropCtrl.isCompleted) return;
    _openChest();
  }

  Future<void> _openChest() async {
    if (_chestOpened) return;
    setState(() => _chestOpened = true);
    HapticFeedback.mediumImpact();
    _burstCtrl.forward();
    _particlesCtrl.repeat();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _spriteAnimation = 'Open');
    });
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
    _burstCtrl.dispose();
    _dustCtrl.dispose();
    _particlesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkNotifier,
      builder: (context, isDark, _) {
        final spriteType = widget.chestType == 'wooden_chest' ? 'wooden'
            : widget.chestType == 'iron_chest' ? 'iron' : 'gold';
        final glowColor = widget.chestType == 'wooden_chest' ? AppTheme.amber
            : widget.chestType == 'iron_chest' ? AppTheme.cyan : AppTheme.purple;

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: WoodBackground(
              child: LayoutBuilder(builder: (context, constraints) {
                final double h = constraints.maxHeight;
                final double w = constraints.maxWidth;

                // Ground sits at groundFraction of screen height
                final double groundY = h * _groundFraction;

                // When fully landed, chest bottom = ground, so chest center = groundY - chestSize/2
                final double landedCenterY = groundY - _chestSize / 2;

                // Start position: chest center far above screen
                final double startCenterY = -_chestSize;

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
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.97),
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
                          ], stops: const [0.0, 0.3, 0.7, 1.0]),
                        ),
                      ),
                    ),

                    // ── ANIMATED: CHEST + REFLECTION ─────────────────────────
                    AnimatedBuilder(
                      animation: _dropCtrl,
                      builder: (context, _) {
                        final double t = _dropProgress.value; // 0→1
                        final double scale = _dropScale.value;

                        // Current chest center Y (lerp from off-screen to landed)
                        final double chestCenterY = startCenterY + t * (landedCenterY - startCenterY);
                        final double chestTop = chestCenterY - _chestSize / 2;

                        // Mirror reflection: same distance below ground as chest is above
                        // chest center distance above ground = groundY - chestCenterY
                        // reflection center = groundY + (groundY - chestCenterY)
                        final double reflCenterY = 2 * groundY - chestCenterY;
                        final double reflTop = reflCenterY - _chestSize / 2;

                        // Reflection opacity fades with distance from ground
                        final double distFromGround = (groundY - chestCenterY).abs();
                        final double maxDist = (groundY - startCenterY).abs();
                        final double reflOpacity = (1 - distFromGround / maxDist) * 0.25;

                        return Stack(
                          children: [

                            // Reflection (below ground, flipped vertically)
                            Positioned(
                              top: reflTop,
                              left: w / 2 - _chestSize / 2,
                              child: Opacity(
                                opacity: reflOpacity.clamp(0.0, 0.25),
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.diagonal3Values(scale, -scale * 0.5, 1.0),
                                  child: ChestSprite(
                                    chestType: spriteType,
                                    animation: _spriteAnimation,
                                    fps: 8,
                                    size: _chestSize,
                                  ),
                                ),
                              ),
                            ),

                            // Oval ground shadow (always on ground line)
                            Positioned(
                              top: groundY - 8,
                              left: w / 2 - 55 * scale,
                              child: Container(
                                width: 110 * scale,
                                height: 16 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.55 * scale),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 18,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // The Chest
                            Positioned(
                              top: chestTop,
                              left: w / 2 - _chestSize / 2,
                              child: Transform.scale(
                                scale: scale,
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
                            ),
                          ],
                        );
                      },
                    ),

                    // ── DUST PUFF ON LANDING ──────────────────────────────────
                    AnimatedBuilder(
                      animation: _dustCtrl,
                      builder: (context, _) {
                        if (!_dustCtrl.isAnimating && !_dustCtrl.isCompleted) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          top: groundY - 20,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: _dustOpacity.value,
                            child: CustomPaint(
                              size: Size(w, 80),
                              painter: _DustPainter(
                                progress: _dustCtrl.value,
                                cx: w / 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // ── PARTICLES (after burst) ───────────────────────────────
                    if (_chestOpened)
                      AnimatedBuilder(
                        animation: _particlesCtrl,
                        builder: (context, _) => CustomPaint(
                          size: Size(w, h),
                          painter: _BurstPainter(
                            progress: _particlesCtrl.value,
                            color: glowColor,
                            originY: groundY,
                          ),
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

                    // ── TAP HINT ─────────────────────────────────────────────
                    if (!_chestOpened)
                      AnimatedBuilder(
                        animation: _dropCtrl,
                        builder: (context, _) {
                          if (!_dropCtrl.isCompleted) return const SizedBox.shrink();
                          return Positioned(
                            bottom: h * 0.18,
                            left: 0, right: 0,
                            child: Column(
                              children: [
                                Text(
                                  'TAP TO REVEAL',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.h2(color: AppTheme.white).copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: Container(
                                    width: 48, height: 4,
                                    decoration: BoxDecoration(
                                      color: glowColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // ── REWARD TEXT ───────────────────────────────────────────
                    if (_chestOpened)
                      AnimatedBuilder(
                        animation: _burstCtrl,
                        builder: (context, _) => Positioned(
                          top: h * 0.08,
                          left: 0, right: 0,
                          child: Transform.translate(
                            offset: Offset(0, _rewardSlide.value),
                            child: Transform.scale(
                              scale: _rewardScale.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _isMaxReward ? '★ JACKPOT ★' : 'YOU FOUND',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.h2(
                                      color: _isMaxReward ? AppTheme.amber : AppTheme.text2,
                                    ).copyWith(
                                      fontSize: _isMaxReward ? 26 : 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.generating_tokens_rounded, size: 52, color: AppTheme.amber),
                                      const SizedBox(width: 12),
                                      Text(
                                        '+$_rewardCoins',
                                        style: AppTheme.h1(color: AppTheme.white).copyWith(
                                          fontSize: 72,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── COLLECT BUTTON ────────────────────────────────────────
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      bottom: _showClaimButton ? 40 : -120,
                      left: 24, right: 24,
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
      final angle = (rng.nextDouble() * 40 - 20) * pi / 180; // mostly horizontal
      final dist = progress * (40 + rng.nextDouble() * 80) * speed;
      final rise = progress * (10 + rng.nextDouble() * 30) * progress; // arc upward then fall
      
      final dx = cx + side * dist * cos(angle);
      final dy = size.height * 0.6 - rise + progress * progress * 20;
      final radius = (3 + rng.nextDouble() * 6) * (1 - progress);
      final opacity = (1 - progress) * (0.4 + rng.nextDouble() * 0.4);

      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, dy), radius.clamp(0.5, 12), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter old) => old.progress != progress;
}

// ── Burst Painter ─────────────────────────────────────────────────────────────
class _BurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double originY;

  _BurstPainter({required this.progress, required this.color, required this.originY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, originY);
    final rng = Random(42);

    for (int i = 0; i < 50; i++) {
      final angle = rng.nextDouble() * pi * 2;
      final speed = 0.6 + rng.nextDouble() * 1.4;
      final delay = rng.nextDouble();
      final localT = (progress + delay) % 1.0;
      final opacity = (1.0 - localT) * (rng.nextDouble() * 0.7 + 0.3);
      final dist = localT * size.width * 0.6 * speed;
      final dx = center.dx + cos(angle) * dist;
      final dy = center.dy + sin(angle) * dist;
      paint.color = (i % 3 == 0 ? Colors.white : color).withValues(alpha: opacity.clamp(0.0, 1.0));
      final radius = (4.0 + rng.nextDouble() * 4.0) * (1.0 - localT);
      canvas.drawCircle(Offset(dx, dy), radius.clamp(0.1, 10.0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => true;
}
