import 'dart:async';
import 'dart:math' as math;
import '../ui/theme.dart';
import '../engine/combat_engine.dart';

class EngineScreen extends StatefulWidget {
  final bool isLoading;
  const EngineScreen({super.key, this.isLoading = false});

  @override
  State<EngineScreen> createState() => _EngineScreenState();
}

class _EngineScreenState extends State<EngineScreen> with TickerProviderStateMixin {
  // All available animations for selection
  static const List<String> _allAnimations = [
    'Idle', 'Walk', 'Run', 'Jump', 'Jump Fall',
    'Punch01', 'Kick01',
    'Hit', 'GetUp', 'Knockback',
    'Push', 'PushIdle', 'Pull',
  ];

  // Editor state
  String _selectedAnim = 'Idle';
  int _currentFrame = 0;
  bool _isPlaying = false;
  Timer? _playTimer;

  // Collider editing state
  bool _showColliders = true;
  ColliderTarget _selectedCollider = ColliderTarget.player;
  double _editorPanelX = 30.0;
  double _editorPanelY = 80.0;

  bool _flip = false;

  // Default collider values
  static const double _playerHitboxW = 40.0;
  static const double _playerHitboxH = 103.0;
  static const double _playerHitboxOffsetX = -20.0;
  static const double _playerHitboxOffsetY = 0.0;
  static const double _playerHitboxRotation = 0.0;
  static const double _debugPunchOffsetX = 38.0;
  static const double _debugPunchOffsetY = 41.0;
  static const double _debugPunchWidth = 107.0;
  static const double _debugPunchHeight = 14.0;
  static const double _debugPunchRotation = 0.0;
  static const double _debugKickOffsetX = 45.0;
  static const double _debugKickOffsetY = 30.0;
  static const double _debugKickWidth = 90.0;
  static const double _debugKickHeight = 25.0;
  static const double _debugKickRotation = 0.0;

  bool _loading = true;
  int _dotCount = 0;
  Timer? _dotTimer;
  late AnimationController _bgCtrl;
  late AnimationController _doorCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (_loading) {
      _dotTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        if (mounted) setState(() => _dotCount = (timer.tick % 4));
      });
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          _doorCtrl.forward().then((_) {
            if (mounted) {
              _dotTimer?.cancel();
              setState(() => _loading = false);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _bgCtrl.dispose();
    _doorCtrl.dispose();
    super.dispose();
  }

  void _playAnimation() {
    if (_isPlaying) {
      _isPlaying = false;
      _playTimer?.cancel();
      setState(() {});
      return;
    }
    _isPlaying = true;
    final maxFrames = getAnimFrameCount(_selectedAnim);
    _playTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentFrame = (_currentFrame + 1) % maxFrames;
      });
    });
  }

  void _stepFrame(int dir) {
    final maxFrames = getAnimFrameCount(_selectedAnim);
    setState(() {
      _currentFrame = (_currentFrame + dir + maxFrames) % maxFrames;
    });
  }

  void _selectAnimation(String anim) {
    _playTimer?.cancel();
    setState(() {
      _selectedAnim = anim;
      _currentFrame = 0;
      _isPlaying = false;
    });
  }

  String _getColliderName(ColliderTarget target) {
    switch (target) {
      case ColliderTarget.player: return 'BODY';
      case ColliderTarget.attack: return 'PUNCH';
      case ColliderTarget.kickAttack: return 'KICK';
      case ColliderTarget.box: return 'BOX';
      case ColliderTarget.clone: return 'CLONE';
      case ColliderTarget.cloneAttack: return 'CLONE_ATK';
    }
  }

  void _cycleCollider(int dir) {
    int idx = ColliderTarget.values.indexOf(_selectedCollider);
    idx = (idx + dir) % ColliderTarget.values.length;
    if (idx < 0) idx += ColliderTarget.values.length;
    setState(() => _selectedCollider = ColliderTarget.values[idx]);
  }

  double _getColliderValue(String type) {
    final anim = _selectedAnim;
    final data = CombatData.getOrCreateFrameData(_selectedCollider, anim, _currentFrame);

    if (type == 'W') return data.w;
    if (type == 'H') return data.h;
    if (type == 'X') return data.x;
    if (type == 'Y') return data.y;
    if (type == 'R') return data.r;
    return 0;
  }

  void _adjustSelected({double dx = 0, double dy = 0, double dw = 0, double dh = 0, double dr = 0}) {
    setState(() {
      final data = CombatData.getOrCreateFrameData(_selectedCollider, _selectedAnim, _currentFrame);
      data.x += dx;
      data.y += dy;
      data.w = (data.w + dw).clamp(5, 500);
      data.h = (data.h + dh).clamp(5, 500);
      data.r += dr;
    });
  }

  Widget _buildAdjustGroup(String label, void Function(double) onAdjust) {
    double val = _getColliderValue(label);
    String displayVal = label == 'R'
        ? '${(val * 180 / math.pi).toStringAsFixed(1)}°'
        : val.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 14, child: Text(label, style: AppTheme.mono(color: Colors.white70, size: 10))),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onAdjust(-1),
            child: Container(
              decoration: BoxDecoration(color: AppTheme.red.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.remove, size: 12, color: Colors.white),
            ),
          ),
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Text(displayVal, style: AppTheme.mono(color: Colors.yellow, size: 11)),
          ),
          GestureDetector(
            onTap: () => onAdjust(1),
            child: Container(
              decoration: BoxDecoration(color: AppTheme.cyan.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.add, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final size = MediaQuery.of(context).size;
        final bool isPortrait = orientation == Orientation.portrait;
        final maxFrames = getAnimFrameCount(_selectedAnim);

        if (_currentFrame >= maxFrames) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentFrame = maxFrames - 1);
          });
        }

        final effectiveFrame = _currentFrame.clamp(0, maxFrames - 1);

        Widget editorView = PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0D1B2A),
            body: Builder(builder: (context) {
          return Stack(
            children: [
              // Animated Notebook Background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgCtrl,
                  builder: (context, child) {
                      return CustomPaint(
                        painter: NotebookPainter(_bgCtrl.value),
                      );
                  },
                ),
              ),

              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF08121C).withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5), width: 3),
                    ),
                  ),
                ),
              ),

              // Player Sprite Display (centered)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Sprite
                        Positioned.fill(
                          child: Transform.scale(
                            scaleX: _flip ? -1 : 1,
                            child: Image.asset(
                              getFrameAssetPath(_selectedAnim, effectiveFrame),
                              width: 240,
                              height: 240,
                              alignment: Alignment.bottomCenter,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                        ),
                        // Player Body Collider
                        () {
                          final data = CombatData.getOrCreateFrameData(
                            ColliderTarget.player, _selectedAnim, effectiveFrame,
                            defaults: ColliderFrameData(
                              x: _playerHitboxOffsetX, y: _playerHitboxOffsetY,
                              w: _playerHitboxW, h: _playerHitboxH, r: _playerHitboxRotation,
                            ),
                          );
                          return Positioned(
                            left: 120 + data.x,
                            bottom: data.y,
                            width: data.w,
                            height: data.h,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCollider = ColliderTarget.player),
                              child: Transform.rotate(
                                angle: data.r,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selectedCollider == ColliderTarget.player ? AppTheme.accent : Colors.white,
                                      width: 2,
                                    ),
                                    color: (_selectedCollider == ColliderTarget.player ? AppTheme.accent : Colors.white).withValues(alpha: 0.15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'BODY F:${effectiveFrame + 1}\nW:${data.w.floor()}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _selectedCollider == ColliderTarget.player ? AppTheme.accent : Colors.white,
                                        fontSize: 9, fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }(),
                        // Attack Collider (Punch01 only)
                        if (_selectedAnim == 'Punch01' && _showColliders)
                          () {
                            final data = CombatData.getOrCreateFrameData(
                              ColliderTarget.attack, 'Punch01', effectiveFrame,
                              defaults: ColliderFrameData(
                                x: _debugPunchOffsetX, y: _debugPunchOffsetY,
                                w: _debugPunchWidth, h: _debugPunchHeight, r: _debugPunchRotation,
                              ),
                            );
                            final double relPunchX = _flip ? -data.x : data.x;
                            return Positioned(
                              left: 120 + (_playerHitboxW / 2) + _playerHitboxOffsetX + relPunchX - (data.w / 2),
                              bottom: data.y,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCollider = ColliderTarget.attack),
                                child: Transform.rotate(
                                  angle: data.r,
                                  child: Container(
                                    width: data.w,
                                    height: data.h,
                                    decoration: BoxDecoration(
                                      color: (_selectedCollider == ColliderTarget.attack ? AppTheme.accent : Colors.red).withValues(alpha: 0.6),
                                      border: Border.all(color: Colors.white, width: _selectedCollider == ColliderTarget.attack ? 2 : 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'PUNCH F:${effectiveFrame + 1}\nW:${data.w.floor()}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }(),
                        // Kick Collider (Kick01 only)
                        if (_selectedAnim == 'Kick01' && _showColliders)
                          () {
                            final data = CombatData.getOrCreateFrameData(
                              ColliderTarget.kickAttack, 'Kick01', effectiveFrame,
                              defaults: ColliderFrameData(
                                x: _debugKickOffsetX, y: _debugKickOffsetY,
                                w: _debugKickWidth, h: _debugKickHeight, r: _debugKickRotation,
                              ),
                            );
                            final double relKickX = _flip ? -data.x : data.x;
                            return Positioned(
                              left: 120 + (_playerHitboxW / 2) + _playerHitboxOffsetX + relKickX - (data.w / 2),
                              bottom: data.y,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCollider = ColliderTarget.kickAttack),
                                child: Transform.rotate(
                                  angle: data.r,
                                  child: Container(
                                    width: data.w,
                                    height: data.h,
                                    decoration: BoxDecoration(
                                      color: (_selectedCollider == ColliderTarget.kickAttack ? AppTheme.accent : Colors.orange).withValues(alpha: 0.6),
                                      border: Border.all(color: Colors.white, width: _selectedCollider == ColliderTarget.kickAttack ? 2 : 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'KICK F:${effectiveFrame + 1}\nW:${data.w.floor()}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }(),
                      ],
                    ),
                  ),
                ),
              ),

              // Animation Info Overlay (below player)
              Positioned(
                bottom: 130,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$_selectedAnim  |  Frame ${effectiveFrame + 1}/$maxFrames',
                      style: AppTheme.mono(color: AppTheme.accent, size: 13),
                    ),
                  ),
                ),
              ),

              // ──── TOP UI: Anim Selector & Playback ────
              Positioned(
                top: 30,
                left: 30,
                right: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Icon(Icons.close_rounded, color: AppTheme.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'POSE & COLLIDER EDITOR',
                          style: AppTheme.mono(color: AppTheme.accent, size: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Animation Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _allAnimations.map((anim) {
                            final isSelected = anim == _selectedAnim;
                            return GestureDetector(
                              onTap: () => _selectAnimation(anim),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.accent.withValues(alpha: 0.3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.accent : Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  anim,
                                  style: AppTheme.mono(
                                    color: isSelected ? AppTheme.accent : Colors.white70,
                                    size: 11,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Playback Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Frame backward
                        GestureDetector(
                          onTap: () => _stepFrame(-1),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Play/Pause
                        GestureDetector(
                          onTap: _playAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.accent),
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: AppTheme.accent, size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Frame forward
                        GestureDetector(
                          onTap: () => _stepFrame(1),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Frame counter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _stepFrame(-1),
                                child: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white70, size: 18),
                              ),
                              Container(
                                width: 44,
                                alignment: Alignment.center,
                                child: Text(
                                  '${effectiveFrame + 1}/$maxFrames',
                                  style: AppTheme.mono(color: Colors.yellow, size: 12),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _stepFrame(1),
                                child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70, size: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Flip toggle
                        GestureDetector(
                          onTap: () => setState(() => _flip = !_flip),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _flip ? AppTheme.accent.withValues(alpha: 0.3) : AppTheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _flip ? AppTheme.accent : AppTheme.line),
                            ),
                            child: Icon(
                              Icons.flip_to_front_rounded,
                              color: _flip ? AppTheme.accent : Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ──── COLLIDER EDITOR PANEL ────
              Positioned(
                left: _editorPanelX,
                top: _editorPanelY,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _editorPanelX += details.delta.dx;
                      _editorPanelY += details.delta.dy;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.95),
                      border: Border.all(color: AppTheme.accent, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2),
                        BoxShadow(color: AppTheme.accent.withValues(alpha: 0.1), blurRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_attributes_rounded, color: AppTheme.accent, size: 16),
                            const SizedBox(width: 8),
                            Text('COLLIDER EDITOR', style: AppTheme.mono(color: Colors.white, size: 10)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _showColliders = !_showColliders),
                              child: Icon(Icons.visibility_off_rounded, color: AppTheme.red, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Target Selector
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _cycleCollider(-1),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                            Container(
                              width: 100,
                              alignment: Alignment.center,
                              child: Text(
                                _getColliderName(_selectedCollider),
                                style: AppTheme.mono(color: AppTheme.accent, size: 13),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _cycleCollider(1),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Adjusters
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAdjustGroup('W', (d) => _adjustSelected(dw: d)),
                            const SizedBox(width: 12),
                            _buildAdjustGroup('X', (d) => _adjustSelected(dx: d)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAdjustGroup('H', (d) => _adjustSelected(dh: d)),
                            const SizedBox(width: 12),
                            _buildAdjustGroup('Y', (d) => _adjustSelected(dy: d)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAdjustGroup('R', (d) => _adjustSelected(dr: d * (math.pi / 180))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );

        final double layoutWidth = isPortrait ? size.height : size.width;
        final double layoutHeight = isPortrait ? size.width : size.height;

        final content = Stack(
          children: [
            editorView,
            if (_loading || _doorCtrl.value < 1.0)
              AnimatedBuilder(
                animation: _doorCtrl,
                builder: (context, child) {
                  final double doorWidth = layoutWidth * 0.5;
                  final double doorHeight = layoutHeight;
                  return Stack(
                    children: [
                      Transform.translate(
                        offset: Offset(-_doorCtrl.value * doorWidth, 0),
                        child: Container(
                          width: doorWidth,
                          height: doorHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A),
                            border: Border(right: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3), width: 1.5)),
                          ),
                          child: ClipRect(
                            child: AnimatedBuilder(
                              animation: _bgCtrl,
                              builder: (context, _) => CustomPaint(
                                painter: NotebookPainter(_bgCtrl.value),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(_doorCtrl.value * doorWidth, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: doorWidth,
                            height: doorHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B2A),
                              border: Border(left: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3), width: 1.5)),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRect(
                                    child: AnimatedBuilder(
                                      animation: _bgCtrl,
                                      builder: (context, _) => CustomPaint(
                                        painter: NotebookPainter(_bgCtrl.value, horizontalOffset: -doorWidth),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 40,
                                  right: 40,
                                  child: Opacity(
                                    opacity: (1.0 - _doorCtrl.value).clamp(0.0, 1.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'loading',
                                          style: AppTheme.mono(color: AppTheme.accent, size: 20).copyWith(letterSpacing: 2),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            '.' * _dotCount,
                                            style: AppTheme.mono(color: AppTheme.accent, size: 20).copyWith(letterSpacing: 2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        );

        return Material(
          type: MaterialType.transparency,
          child: isPortrait ? RotatedBox(quarterTurns: 1, child: content) : content,
        );
      },
    );
  }
}


