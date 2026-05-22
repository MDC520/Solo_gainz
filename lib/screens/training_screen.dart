import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import '../ui/theme.dart';
import '../widgets/player.dart';
import 'engine_screen.dart';
import '../engine/combat_engine.dart';
import '../engine/training_engine.dart';

class TrainingScreen extends StatefulWidget {
  final bool isLoading;
  const TrainingScreen({super.key, this.isLoading = false});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> with TickerProviderStateMixin {
  final TrainingEngine engine = TrainingEngine();
  bool _loading = true;
  bool _showColliders = false;
  ColliderTarget? _selectedCollider = ColliderTarget.player;
  int _selectedBoxIndex = 0;
  double _editorPanelX = 300.0;
  double _editorPanelY = 20.0;
  bool _isPaused = false;
  int _dotCount = 0;
  Timer? _dotTimer;
  late AnimationController _bgCtrl;
  late AnimationController _doorCtrl;

  // Input State (Better multi-touch tracking)
  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _jumpPressed = false;
  bool _runPressed = false;
  bool _attackPressed = false;
  bool _kickPressed = false;

  // Double Tap Run tracking
  DateTime? _lastLeftDown;
  DateTime? _lastRightDown;
  static const _doubleTapThreshold = Duration(milliseconds: 300);

  // Safety fallback timers
  Timer? _punchTimer;
  Timer? _kickTimer;

  // Debugger / Stop State
  bool _isFrozen = false;
  
  late Ticker _ticker;
  int _currentEditFrame = 0;
  // Use CombatData instead of local frame data

  int _getAnimFrameCount(String anim) => engine.getAnimFrameCount(anim);
  int _getCurrentFrameIndex(String anim, DateTime startTime, double fps) => engine.getCurrentFrameIndex(anim, startTime, fps);
  String _getFrameAssetPath(String anim, int frameIdx) => engine.getFrameAssetPath(anim, frameIdx);


  // Camera/World logic
  double _cameraX = 0;
  double _screenW = 800.0;

  @override
  void initState() {
    super.initState();
    
    // Pre-populate specific frame data requested by user
    CombatData.frameData[CombatData.getFrameKey(ColliderTarget.attack, 'Punch01', 2)] = 
        ColliderFrameData(x: 33, y: 55, w: 107, h: 14, r: 0);
    
    // Kick01 Frame 3 (0-indexed frame 2)
    CombatData.frameData[CombatData.getFrameKey(ColliderTarget.kickAttack, 'Kick01', 2)] = 
        ColliderFrameData(x: 38.0, y: 79.0, w: 65.0, h: 11.0, r: -13 * math.pi / 180);

    // Aggressive landscape and immersive mode for "Game" feel
    engine.clone.x = 1500;
    _setupGameMode();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _ticker = createTicker(_tick)..start();

    // Animated loading dots
    if (_loading) {
      _dotTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        if (mounted) setState(() => _dotCount = (timer.tick % 4));
      });
      
      Timer(const Duration(milliseconds: 1200), () {
        if (mounted) {
          _doorCtrl.forward().then((_) {
            if (mounted) setState(() => _loading = false);
          });
        }
      });
    }
  }

  void _tick(Duration elapsed) {
    if (_loading || _isPaused || _isFrozen) return;

    setState(() {
      engine.leftPressed = _leftPressed;
      engine.rightPressed = _rightPressed;
      engine.runPressed = _runPressed;
      engine.tick();

      double targetCameraX = engine.playerWorldX - (_screenW * 0.4);
      if (targetCameraX < 0) targetCameraX = 0;
      if (targetCameraX > TrainingEngine.mapWidth - _screenW) {
        targetCameraX = TrainingEngine.mapWidth - _screenW;
      }
      _cameraX = lerpDouble(_cameraX, targetCameraX, 0.12)!;
    });
  }


  String _getCurrentAnimation() {
    if (_showColliders) {
      if (_selectedCollider == ColliderTarget.attack) return 'Punch01';
      if (_selectedCollider == ColliderTarget.kickAttack) return 'Kick01';
      if (_selectedCollider == ColliderTarget.player) return 'Idle';
    }
    return engine.getCurrentAnimation();
  }

  void _jump() => setState(() => engine.jump());

  void _punch() {
    if (_isFrozen) return;
    engine.punch();
    _punchTimer?.cancel();
    _punchTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && engine.isPunching) setState(() => engine.isPunching = false);
    });
  }

  void _kick() {
    if (_isFrozen) return;
    engine.kick();
    _kickTimer?.cancel();
    _kickTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && engine.isKicking) setState(() => engine.isKicking = false);
    });
  }

  void _startGrab() => setState(() => engine.startGrab());
  void _endGrab() => setState(() => engine.endGrab());

  Future<void> _setupGameMode() async {
    // Hide status bar and navigation bar
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Set orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _bgCtrl.dispose();
    _doorCtrl.dispose();
    _ticker.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Reset orientation to portrait when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _dotTimer?.cancel();
    super.dispose();
  }

  String _getColliderName(ColliderTarget target) {
    switch (target) {
      case ColliderTarget.player: return 'BODY';
      case ColliderTarget.attack: return 'PUNCH';
      case ColliderTarget.kickAttack: return 'KICK';
      case ColliderTarget.box: return 'BOX';
      case ColliderTarget.clone: return 'CLONE';
      case ColliderTarget.cloneAttack: return 'CL_ATK';
    }
  }

  void _cycleCollider(int direction) {
    if (_selectedCollider == null) {
      setState(() => _selectedCollider = ColliderTarget.player);
      return;
    }
    int idx = ColliderTarget.values.indexOf(_selectedCollider!);
    idx = (idx + direction) % ColliderTarget.values.length;
    if (idx < 0) idx += ColliderTarget.values.length;
    setState(() {
      _selectedCollider = ColliderTarget.values[idx];
      _currentEditFrame = 0; // Reset frame to 0 to prevent asset loading crashes
    });
  }

  double _getColliderValue(String type) {
    if (_selectedCollider == null) return 0;

    // For player and attacks, check if we have per-frame data
    if (_selectedCollider == ColliderTarget.player || 
        _selectedCollider == ColliderTarget.attack || 
        _selectedCollider == ColliderTarget.kickAttack) {
      
      final anim = _getCurrentAnimation();
      final data = CombatData.getOrCreateFrameData(_selectedCollider!, anim, _currentEditFrame);
      
      if (type == 'W') return data.w;
      if (type == 'H') return data.h;
      if (type == 'X') return data.x;
      if (type == 'Y') return data.y;
      if (type == 'R') return data.r;
    }

    if (_selectedCollider == ColliderTarget.box && engine.boxes.isNotEmpty) {
      if (type == 'W') return engine.boxes[_selectedBoxIndex].colliderWidth;
      if (type == 'H') return engine.boxes[_selectedBoxIndex].colliderHeight;
      if (type == 'X') return engine.boxes[_selectedBoxIndex].colliderOffsetX;
      if (type == 'Y') return engine.boxes[_selectedBoxIndex].colliderOffsetY;
      if (type == 'R') return engine.boxes[_selectedBoxIndex].rotation;
    } else if (_selectedCollider == ColliderTarget.clone) {
      if (type == 'W') return engine.clone.colliderW;
      if (type == 'H') return engine.clone.colliderH;
      if (type == 'X') return engine.clone.colliderOffsetX;
      if (type == 'Y') return engine.clone.colliderOffsetY;
      if (type == 'R') return engine.clone.rotation;
    } else if (_selectedCollider == ColliderTarget.cloneAttack) {
      if (type == 'W') return engine.cloneAttackWidth;
      if (type == 'H') return engine.cloneAttackHeight;
      if (type == 'X') return engine.cloneAttackOffsetX;
      if (type == 'Y') return engine.cloneAttackOffsetY;
      if (type == 'R') return engine.cloneAttackRotation;
    }
    return 0;
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
              child: const Icon(Icons.remove, size: 12, color: Colors.white)
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
              child: const Icon(Icons.add, size: 12, color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  void _adjustSelected({double dx = 0, double dy = 0, double dw = 0, double dh = 0, double dr = 0}) {
    setState(() {
      if (_selectedCollider == null) return;

      if (_selectedCollider == ColliderTarget.player || 
          _selectedCollider == ColliderTarget.attack || 
          _selectedCollider == ColliderTarget.kickAttack) {
        
        final anim = _getCurrentAnimation();
        final data = CombatData.getOrCreateFrameData(_selectedCollider!, anim, _currentEditFrame);
        
        data.x += dx;
        data.y += dy;
        data.w = (data.w + dw).clamp(5, 500);
        data.h = (data.h + dh).clamp(5, 500);
        data.r += dr;
        return;
      }

      if (_selectedCollider == ColliderTarget.box && engine.boxes.isNotEmpty) {
        engine.boxes[_selectedBoxIndex].colliderOffsetX += dx;
        engine.boxes[_selectedBoxIndex].colliderOffsetY += dy;
        engine.boxes[_selectedBoxIndex].colliderWidth = (engine.boxes[_selectedBoxIndex].colliderWidth + dw).clamp(10, 500);
        engine.boxes[_selectedBoxIndex].colliderHeight = (engine.boxes[_selectedBoxIndex].colliderHeight + dh).clamp(10, 500);
        engine.boxes[_selectedBoxIndex].rotation += dr;
      } else if (_selectedCollider == ColliderTarget.clone) {
        engine.clone.colliderOffsetX += dx;
        engine.clone.colliderOffsetY += dy;
        engine.clone.colliderW = (engine.clone.colliderW + dw).clamp(10, 500);
        engine.clone.colliderH = (engine.clone.colliderH + dh).clamp(10, 500);
        engine.clone.rotation += dr;
      } else if (_selectedCollider == ColliderTarget.cloneAttack) {
        engine.cloneAttackOffsetX += dx;
        engine.cloneAttackOffsetY += dy;
        engine.cloneAttackWidth = (engine.cloneAttackWidth + dw).clamp(10, 500);
        engine.cloneAttackHeight = (engine.cloneAttackHeight + dh).clamp(10, 500);
        engine.cloneAttackRotation += dr;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    _screenW = orientation == Orientation.portrait ? size.height : size.width;

    return OrientationBuilder(
      builder: (context, orientation) {
        bool isPortrait = orientation == Orientation.portrait;
        
        Widget gameView = PopScope(
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
              double playerScreenX = engine.playerWorldX - _cameraX;
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

                // Ground Floor (Grey area below the line)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: TrainingEngine.groundY,
                    decoration: BoxDecoration(
                      color: const Color(0xFF08121C).withValues(alpha: 0.95), // Darker ground
                      border: Border(
                        top: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5), width: 3),
                      ),
                    ),
                  ),
                ),

                // Ground Reflections (Player and Boxes)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: TrainingEngine.groundY,
                  child: ClipRect(
                    child: Stack(
                      children: [
                        // Box Reflections
                        ...engine.boxes.map((box) {
                          return Positioned(
                            top: box.y - 90,
                            left: box.x - _cameraX,
                            child: Transform.scale(
                              scaleY: -1,
                              alignment: Alignment.bottomCenter,
                              child: Opacity(
                                opacity: 0.15,
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF2D1B18), width: 3),
                                    ),
                                    child: CustomPaint(painter: CratePainter()),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Player Reflection
                        Positioned(
                          top: engine.playerY - 110, // Positioned above floor line for mirroring
                          left: playerScreenX - 20,
                          child: Transform.scale(
                            scaleY: -1,
                            alignment: Alignment.bottomCenter, // Flip around feet
                            child: Opacity(
                              opacity: 0.15,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                                child: SizedBox(
                                  width: 40,
                                  height: 110,
                                  child: OverflowBox(
                                    maxWidth: 240,
                                    maxHeight: 240,
                                    alignment: Alignment.bottomCenter, // Maintain foot position
                                    child: Transform.scale(
                                      scaleX: engine.flip ? -1 : 1,
                                      child: _showColliders
                                      // In collider mode: mirror the exact frame shown in the main view
                                      ? Image.asset(
                                          _getFrameAssetPath(_getCurrentAnimation(), _currentEditFrame),
                                          width: 240,
                                          height: 240,
                                          alignment: Alignment.bottomCenter,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.none,
                                        )
                                      : Player(
                                          animation: _getCurrentAnimation(),
                                          size: 240,
                                          fps: engine.isPlayerHit ? 12 : (engine.isPunching || engine.isKicking ? 12 : (engine.isRunning ? 14 : (engine.isPushingBox || engine.isPullingBox ? 8 : 10))),
                                          loop: !engine.isJumping && !engine.isPunching && !engine.isKicking && !engine.isPlayerHit,
                                          onComplete: () {
                                            if (engine.isPunching) setState(() => engine.isPunching = false);
                                            if (engine.isKicking) setState(() => engine.isKicking = false);
                                          },
                                          paused: _isFrozen,
                                        ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Surface Fade (Fades reflection into the ground color)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppTheme.surface.withValues(alpha: 0.9),
                                ],
                                stops: const [0.0, 0.9],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Boxes
                ...engine.boxes.map((box) {
                  return Positioned(
                    bottom: TrainingEngine.groundY + box.y,
                    left: box.x - _cameraX,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // MAIN BODY (Visual - Fixed size)
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF795548), Color(0xFF4E342E)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF2D1B18), width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(4, 4)),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 2), color: Colors.black.withValues(alpha: 0.05)))),
                              Positioned.fill(child: CustomPaint(painter: CratePainter())),
                              if (_showColliders)
                                Center(child: Text('X:${box.x.floor()}\nY:${box.y.floor()}', style: const TextStyle(color: Colors.white70, fontSize: 10))),
                            ],
                          ),
                        ),
                        // THE COLLIDER (Separate item as child)
                        if (_showColliders)
                          Positioned(
                            left: box.colliderOffsetX,
                            bottom: box.colliderOffsetY,
                            width: box.colliderWidth,
                            height: box.colliderHeight,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedCollider = ColliderTarget.box;
                                _selectedBoxIndex = engine.boxes.indexOf(box);
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: _selectedCollider == ColliderTarget.box && _selectedBoxIndex == engine.boxes.indexOf(box) ? AppTheme.accent : Colors.yellow, width: 2),
                                  color: (_selectedCollider == ColliderTarget.box && _selectedBoxIndex == engine.boxes.indexOf(box) ? AppTheme.accent : Colors.yellow).withValues(alpha: 0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    'OX:${box.colliderOffsetX.floor()} OY:${box.colliderOffsetY.floor()}\nW:${box.colliderWidth.floor()} H:${box.colliderHeight.floor()}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _selectedCollider == ColliderTarget.box && _selectedBoxIndex == engine.boxes.indexOf(box) ? AppTheme.accent : Colors.yellow, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),


                // Damage Numbers
                ...engine.damageNumbers.map((dn) => Positioned(
                  bottom: TrainingEngine.groundY + dn.y,
                  left: dn.x - _cameraX,
                  child: Opacity(
                    opacity: dn.opacity,
                    child: Text(
                      dn.damage.toString(),
                      style: AppTheme.mono(color: Colors.yellow, size: 24).copyWith(
                        fontWeight: FontWeight.bold,
                        shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ),
                )),

                // Player Attack Box (Debug Only)
                if (_showColliders && (_selectedCollider == ColliderTarget.attack || _isFrozen || engine.isPunching))
                  () {
                    final frameIdx = engine.isPunching && engine.punchStartTime != null 
                        ? _getCurrentFrameIndex('Punch01', engine.punchStartTime!, 12)
                        : _currentEditFrame;
                    
                    final data = CombatData.getOrCreateFrameData(ColliderTarget.attack, 'Punch01', frameIdx, defaults: ColliderFrameData(x: engine.debugPunchOffsetX, y: engine.debugPunchOffsetY, w: engine.debugPunchWidth, h: engine.debugPunchHeight, r: engine.debugPunchRotation));
                    return Positioned(
                      bottom: TrainingEngine.groundY + engine.playerY + data.y,
                      left: ((engine.flip 
                          ? (engine.playerWorldX + engine.playerHitboxOffsetX + (engine.playerHitboxW / 2)) - data.x 
                          : (engine.playerWorldX + engine.playerHitboxOffsetX + (engine.playerHitboxW / 2)) + data.x) - (data.w / 2)) - _cameraX,
                      child: Visibility(
                        visible: frameIdx == 2, // Visible only on frame 3 (0-indexed 2)
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
                                boxShadow: [
                                  BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 8),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'F:${frameIdx + 1}\nW:${data.w.floor()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),

                // Player Kick Box (Debug Only)
                if (_showColliders && (_selectedCollider == ColliderTarget.kickAttack || _isFrozen || engine.isKicking))
                  () {
                    final frameIdx = engine.isKicking && engine.kickStartTime != null 
                        ? _getCurrentFrameIndex('Kick01', engine.kickStartTime!, 12)
                        : _currentEditFrame;
                    final data = CombatData.getOrCreateFrameData(ColliderTarget.kickAttack, 'Kick01', frameIdx, defaults: ColliderFrameData(x: engine.debugKickOffsetX, y: engine.debugKickOffsetY, w: engine.debugKickWidth, h: engine.debugKickHeight, r: engine.debugKickRotation));
                    return Positioned(
                      bottom: TrainingEngine.groundY + engine.playerY + data.y,
                      left: ((engine.flip 
                          ? (engine.playerWorldX + engine.playerHitboxOffsetX + (engine.playerHitboxW / 2)) - data.x 
                          : (engine.playerWorldX + engine.playerHitboxOffsetX + (engine.playerHitboxW / 2)) + data.x) - (data.w / 2)) - _cameraX,
                      child: Visibility(
                        visible: frameIdx == 2, // Visible only on frame 3 (0-indexed 2)
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
                                boxShadow: [
                                  BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 8),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'F:${frameIdx + 1}\nW:${data.w.floor()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),

                // Player Visual
                Positioned(
                  bottom: TrainingEngine.groundY + engine.playerY, 
                  left: playerScreenX - 120, // Center of 240x240 box
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // MAIN BODY (Visual Player - Sprite size 240)
                        Positioned.fill(
                          child: Transform.scale(
                            scaleX: engine.flip ? -1 : 1,
                            child: _showColliders
                              // Collider mode always freezes — show exact frame image
                              ? Image.asset(
                                  _getFrameAssetPath(_getCurrentAnimation(), _currentEditFrame),
                                  width: 240,
                                  height: 240,
                                  alignment: Alignment.bottomCenter,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                )
                              : Player(
                                  animation: _getCurrentAnimation(),
                                  size: 240,
                                  fps: engine.isPlayerHit ? 12 : (engine.isPunching || engine.isKicking ? 12 : (engine.isRunning ? 14 : (engine.isPushingBox || engine.isPullingBox ? 8 : 10))),
                                  loop: !engine.isJumping && !engine.isPunching && !engine.isKicking && !engine.isPlayerHit,
                                  onComplete: () {
                                    if (engine.isPunching) setState(() => engine.isPunching = false);
                                    if (engine.isKicking) setState(() => engine.isKicking = false);
                                  },
                                  paused: _isFrozen,
                                ),
                          ),
                        ),
                        // PLAYER COLLIDER (Only in debug)
                        if (_showColliders)
                          () {
                            final anim = _getCurrentAnimation();
                            // Simple frame calculation for body collider too
                            final frameIdx = _isFrozen ? _currentEditFrame : 0; // Use frame 0 for non-attack animations unless frozen
                            final data = CombatData.getOrCreateFrameData(ColliderTarget.player, anim, frameIdx, defaults: ColliderFrameData(x: engine.playerHitboxOffsetX, y: engine.playerHitboxOffsetY, w: engine.playerHitboxW, h: engine.playerHitboxH, r: engine.playerHitboxRotation));
                            
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
                                      border: Border.all(color: _selectedCollider == ColliderTarget.player ? AppTheme.accent : Colors.white, width: 2),
                                      color: (_selectedCollider == ColliderTarget.player ? AppTheme.accent : Colors.white).withValues(alpha: 0.1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'BODY F:${frameIdx + 1}\nW:${data.w.floor()}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: _selectedCollider == ColliderTarget.player ? AppTheme.accent : Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }(),
                        if (_showColliders)
                           Transform.translate(
                             offset: const Offset(120, 240), // Show coordinates near feet
                             child: FractionalTranslation(
                               translation: const Offset(-0.5, 0),
                               child: Text('X:${engine.playerWorldX.floor()}\nY:${engine.playerY.floor()}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 9)),
                             ),
                            ),
                      ],
                    ),
                  ),
                ),

                // CLONE
                Positioned(
                  bottom: TrainingEngine.groundY + engine.clone.y,
                  left: engine.clone.x - _cameraX - 120, // Offset for 240 size
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.green.withValues(alpha: 0.4), 
                      BlendMode.srcATop
                    ),
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: OverflowBox(
                        maxWidth: 240,
                        maxHeight: 240,
                        alignment: Alignment.bottomCenter,
                        child: Transform.scale(
                          scaleX: engine.clone.flip ? -1 : 1,
                          child: Player(
                            animation: engine.clone.getCurrentAnimation(),
                            size: 240,
                            fps: engine.clone.isPunching ? 12 : (engine.clone.isGettingUp ? 8 : 10),
                            loop: !engine.clone.isPunching && !engine.clone.isHit && !engine.clone.isKnockback && !engine.clone.isGettingUp,
                            paused: _isFrozen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // CLONE COLLIDER (Only in debug)
                if (_showColliders)
                  Positioned(
                    bottom: TrainingEngine.groundY + engine.clone.y + engine.clone.colliderOffsetY,
                    left: (engine.clone.x + engine.clone.colliderOffsetX) - _cameraX,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCollider = ColliderTarget.clone),
                      child: Container(
                        width: engine.clone.colliderW,
                        height: engine.clone.colliderH,
                        decoration: BoxDecoration(
                          border: Border.all(color: _selectedCollider == ColliderTarget.clone ? AppTheme.accent : Colors.white24, width: 2),
                          color: Colors.white12,
                        ),
                      ),
                    ),
                  ),

                // CLONE ATTACK COLLIDER (CL_ATK)
                if (_showColliders && (_selectedCollider == ColliderTarget.cloneAttack || engine.clone.isPunching))
                  Positioned(
                    bottom: TrainingEngine.groundY + engine.clone.y + engine.cloneAttackOffsetY,
                    left: ((engine.clone.flip 
                        ? (engine.clone.x + engine.clone.colliderOffsetX + (engine.clone.colliderW / 2)) - engine.cloneAttackOffsetX 
                        : (engine.clone.x + engine.clone.colliderOffsetX + (engine.clone.colliderW / 2)) + engine.cloneAttackOffsetX) - (engine.cloneAttackWidth / 2)) - _cameraX,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCollider = ColliderTarget.cloneAttack),
                      child: Transform.rotate(
                        angle: engine.cloneAttackRotation,
                        child: Container(
                          width: engine.cloneAttackWidth,
                          height: engine.cloneAttackHeight,
                          decoration: BoxDecoration(
                            color: (_selectedCollider == ColliderTarget.cloneAttack ? AppTheme.accent : AppTheme.red).withValues(alpha: 0.6),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              'CL_ATK\nW:${engine.cloneAttackWidth.floor()} R:${(engine.cloneAttackRotation * 180 / 3.14159).floor()}°',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),



              // Height Rope & Meter Label (Only in Collider Mode)
              if (_showColliders)
                Positioned(
                    bottom: TrainingEngine.groundY,
                    left: playerScreenX,
                    child: SizedBox(
                      width: 100,
                      height: engine.playerY + 55,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Vertical Rope
                          Positioned(
                            left: 0,
                            bottom: 0,
                            top: 0,
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                boxShadow: [
                                  BoxShadow(color: AppTheme.accent.withValues(alpha: 0.5), blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                          // Ground Point
                          Positioned(
                            left: -4,
                            bottom: -4,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                          ),
                          // Center of Gravity Point
                          Positioned(
                            left: -4,
                            top: -4,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
                            ),
                          ),
                          // Meter Label
                          Positioned(
                            left: 12,
                            top: (engine.playerY + 55) / 2 - 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.accent, width: 1),
                              ),
                              child: Text(
                                '${(engine.playerY / 10).toStringAsFixed(1)}m',
                                style: AppTheme.mono(color: AppTheme.accent, size: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                // Collider Editor Panel
                if (_showColliders)
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
                                  onTap: () => setState(() => _showColliders = false),
                                  child: Icon(Icons.close_rounded, color: AppTheme.red, size: 16),
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
                                    child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20)
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  alignment: Alignment.center,
                                  child: Text(_getColliderName(_selectedCollider ?? ColliderTarget.player), style: AppTheme.mono(color: AppTheme.accent, size: 13)),
                                ),
                                GestureDetector(
                                  onTap: () => _cycleCollider(1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4), 
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                    child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20)
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Frame Selector
                            Builder(builder: (context) {
                              final anim = _getCurrentAnimation();
                              final maxFrames = _getAnimFrameCount(anim);
                              if (_currentEditFrame >= maxFrames) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => _currentEditFrame = maxFrames - 1);
                                });
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('FRAME', style: AppTheme.mono(color: Colors.white60, size: 9)),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _currentEditFrame = (_currentEditFrame - 1).clamp(0, maxFrames - 1)),
                                      child: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white70, size: 18),
                                    ),
                                    Container(
                                      width: 44,
                                      alignment: Alignment.center,
                                      child: Text('${_currentEditFrame + 1}/$maxFrames', style: AppTheme.mono(color: Colors.yellow, size: 12)),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _currentEditFrame = (_currentEditFrame + 1).clamp(0, maxFrames - 1)),
                                      child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70, size: 18),
                                    ),
                                  ],
                                ),
                              );
                            }),
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
                                _buildAdjustGroup('R', (d) => _adjustSelected(dr: d * (math.pi / 180))), // Adjust by 1 degree
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // UI - Minimap & Collider Toggle (Top Right)
                Positioned(
                  top: 30,
                  right: 30,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clone Punch Button (Left of Stop Button)
                      SGTouchable(
                        onTap: () => setState(() => engine.clone.punch()),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.red.withValues(alpha: 0.8), width: 2),
                          ),
                          child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Stop/Freeze Toggle (Left of Collider Button)
                      SGTouchable(
                        onTap: () {
                          setState(() {
                            _isFrozen = !_isFrozen;
                            if (_isFrozen) {
                              _bgCtrl.stop();
                            } else {
                              _bgCtrl.repeat();
                            }
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isFrozen ? AppTheme.red : AppTheme.line, width: 2),
                          ),
                          child: Icon(
                            _isFrozen ? Icons.play_arrow_rounded : Icons.stop_rounded,
                            color: _isFrozen ? AppTheme.red : AppTheme.text2,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Collider Toggle (Now navigates to Engine Screen)
                      SGTouchable(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EngineScreen()));
                          if (mounted) setState(() {});
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.line, width: 2),
                          ),
                          child: Icon(
                            Icons.visibility_off_rounded,
                            color: AppTheme.text2,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Minimap Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 220,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.line, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  // 1. Playable World Area (The actual map background)
                                  Positioned(
                                    left: (0 - engine.playerWorldX) * 0.12 + 110,
                                    width: TrainingEngine.mapWidth * 0.12,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      color: AppTheme.surface.withValues(alpha: 0.4),
                                      child: Stack(
                                        children: [
                                          // Grid line (Only inside the world)
                                          Positioned(
                                            left: 0, right: 0, bottom: 8,
                                            child: Container(height: 1, color: AppTheme.accent.withValues(alpha: 0.1)),
                                          ),
                                          
                                          // Map objects (Boxes - positioned relative to world start)
                                          ...engine.boxes.map((box) {
                                            return Positioned(
                                              left: box.x * 0.12 - (90 * 0.06),
                                              bottom: 8,
                                              child: Container(
                                                width: 90 * 0.12,
                                                height: 90 * 0.12,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accent.withValues(alpha: 0.4),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // 2. Boundary Walls
                                  Positioned(
                                    left: (0 - engine.playerWorldX) * 0.12 + 110 - 2,
                                    top: 0, bottom: 0,
                                    child: Container(width: 4, color: AppTheme.red.withValues(alpha: 0.8)),
                                  ),
                                  Positioned(
                                    left: (TrainingEngine.mapWidth - engine.playerWorldX) * 0.12 + 110 - 2,
                                    top: 0, bottom: 0,
                                    child: Container(width: 4, color: AppTheme.cyan.withValues(alpha: 0.8)),
                                  ),

                                  // 3. Player indicator (Static at center)
                                  Positioned(
                                    left: 110 - 16,
                                    bottom: 8,
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Center(
                                        child: Transform.scale(
                                          scaleX: engine.flip ? -1 : 1,
                                          child: Player(
                                            animation: _getCurrentAnimation(),
                                            size: 30,
                                            fps: 8,
                                            loop: true,
                                            paused: _isFrozen,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(engine.playerWorldX / 10).floor()}m',
                            style: AppTheme.mono(color: AppTheme.accent, size: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // UI - Top Left (Exit & Stamina)
                Positioned(
                  top: 30,
                  left: 30,
                  child: Row(
                    children: [
                      SGTouchable(
                        onTap: () => setState(() => _isPaused = true),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Icon(Icons.pause_rounded, color: AppTheme.white, size: 24),
                        ),
                      ),
                      // Stamina Bar - REMOVED
                    ],
                  ),
                ),


                // UI - Grab Button (Action)
                Positioned(
                  bottom: 30, 
                  right: 292, // Shifted further left to clear the new linear action buttons
                  child: AnimatedOpacity(
                    opacity: (engine.canGrab || engine.isGrabbing) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !(engine.canGrab || engine.isGrabbing),
                      child: Listener(
                        onPointerDown: (_) {
                          if (engine.isGrounded) _startGrab();
                        },
                        onPointerUp: (_) {
                          _endGrab();
                        },
                        onPointerCancel: (_) {
                          _endGrab();
                        },
                        child: AnimatedScale(
                          scale: engine.isGrabbing ? 0.9 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: engine.isGrabbing ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.8), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: engine.isGrabbing ? 0.4 : 0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.back_hand_rounded,
                                color: engine.isGrabbing ? Colors.black : AppTheme.accent,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // UI - Run Button (Secondary) - REMOVED as requested, now using double-tap-and-hold on arrows

                // UI - Action Buttons (Punch, Kick, Jump) - Now Linear
                Positioned(
                  bottom: 30,
                  right: 40,
                  child: Row(
                    children: [
                      // Kick Button
                      Listener(
                        onPointerDown: (_) {
                          _kickPressed = true;
                          _kick();
                        },
                        onPointerUp: (_) => setState(() => _kickPressed = false),
                        onPointerCancel: (_) => setState(() => _kickPressed = false),
                        child: AnimatedScale(
                          scale: _kickPressed ? 0.85 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 64,
                            height: 64,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: engine.isKicking ? Colors.orange : AppTheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.8), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  blurRadius: engine.isKicking ? 20 : 10,
                                ),
                              ],
                            ),
                            child: OverflowBox(
                              maxWidth: 240,
                              maxHeight: 240,
                              child: Transform.translate(
                                offset: const Offset(0, -36), 
                                child: Transform.scale(
                                  scale: 1.5,
                                  child: engine.isKicking
                                    ? Player(
                                        animation: 'Kick01',
                                        fps: 12,
                                        size: 140,
                                        alignment: Alignment.center,
                                        loop: false,
                                        paused: _isFrozen,
                                      )
                                    : Image.asset(
                                        'assets/Player Model/Kick01/Kick0101.png',
                                        width: 140,
                                        height: 140,
                                        alignment: Alignment.center,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.none,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Punch Button
                      Listener(
                        onPointerDown: (_) {
                          _attackPressed = true;
                          _punch();
                        },
                        onPointerUp: (_) => _attackPressed = false,
                        onPointerCancel: (_) => _attackPressed = false,
                        child: AnimatedScale(
                          scale: _attackPressed ? 0.85 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 64,
                            height: 64,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: _attackPressed ? AppTheme.red : AppTheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.red.withValues(alpha: 0.8), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.red.withValues(alpha: 0.3),
                                  blurRadius: _attackPressed ? 20 : 10,
                                ),
                              ],
                            ),
                            child: OverflowBox(
                              maxWidth: 240,
                              maxHeight: 240,
                              child: Transform.translate(
                                offset: const Offset(0, -36), 
                                child: Transform.scale(
                                  scale: 1.5,
                                  child: engine.isPunching
                                    ? Player(
                                        animation: 'Punch01',
                                        fps: 12,
                                        size: 140,
                                        alignment: Alignment.center,
                                        loop: false,
                                        paused: _isFrozen,
                                      )
                                    : Image.asset(
                                        'assets/Player Model/Punch01/Punch0101.png',
                                        width: 140,
                                        height: 140,
                                        alignment: Alignment.center,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.none,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Jump Button
                      Listener(
                        onPointerDown: (_) {
                          _jumpPressed = true;
                          _jump();
                        },
                        onPointerUp: (_) => _jumpPressed = false,
                        onPointerCancel: (_) => _jumpPressed = false,
                        child: AnimatedScale(
                          scale: _jumpPressed ? 0.85 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 64,
                            height: 64,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: engine.isJumping ? AppTheme.cyan : AppTheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.8), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.cyan.withValues(alpha: 0.3),
                                  blurRadius: engine.isJumping ? 20 : 10,
                                ),
                              ],
                            ),
                            child: OverflowBox(
                              maxWidth: 240,
                              maxHeight: 240,
                              child: Transform.translate(
                                offset: const Offset(0, -36), 
                                child: Transform.scale(
                                  scale: 1.5,
                                  child: engine.isJumping
                                    ? Player(
                                        animation: 'Jump',
                                        fps: 10,
                                        size: 140,
                                        alignment: Alignment.center,
                                        loop: false,
                                        paused: _isFrozen,
                                      )
                                    : Image.asset(
                                        'assets/Player Model/Jump/Jump02.png',
                                        width: 140,
                                        height: 140,
                                        alignment: Alignment.center,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.none,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 30,
                  left: 40,
                  child: Row(
                    children: [
                      // Left Button
                      Listener(
                        onPointerDown: (_) {
                          final now = DateTime.now();
                          bool isDoubleTap = _lastLeftDown != null && 
                                            now.difference(_lastLeftDown!) < _doubleTapThreshold;
                          setState(() {
                            _leftPressed = true;
                            _lastLeftDown = now;
                            if (isDoubleTap && engine.isGrounded && engine.grabbedBox == null) {
                              _runPressed = true;
                              engine.isRunning = true;
                            }
                          });
                        },
                        onPointerUp: (_) => setState(() {
                          _leftPressed = false;
                          _runPressed = false;
                          engine.isRunning = false;
                        }),
                        onPointerCancel: (_) => setState(() {
                          _leftPressed = false;
                          _runPressed = false;
                          engine.isRunning = false;
                        }),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _leftPressed ? (_runPressed ? AppTheme.cyan : AppTheme.accent) : AppTheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _runPressed ? AppTheme.cyan : AppTheme.accent.withValues(alpha: 0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: (_runPressed ? AppTheme.cyan : AppTheme.accent).withValues(alpha: _leftPressed ? 0.3 : 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: _leftPressed ? Colors.black : AppTheme.accent,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Button
                      Listener(
                        onPointerDown: (_) {
                          final now = DateTime.now();
                          bool isDoubleTap = _lastRightDown != null && 
                                            now.difference(_lastRightDown!) < _doubleTapThreshold;
                          setState(() {
                            _rightPressed = true;
                            _lastRightDown = now;
                            if (isDoubleTap && engine.isGrounded && engine.grabbedBox == null) {
                              _runPressed = true;
                              engine.isRunning = true;
                            }
                          });
                        },
                        onPointerUp: (_) => setState(() {
                          _rightPressed = false;
                          _runPressed = false;
                          engine.isRunning = false;
                        }),
                        onPointerCancel: (_) => setState(() {
                          _rightPressed = false;
                          _runPressed = false;
                          engine.isRunning = false;
                        }),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _rightPressed ? (_runPressed ? AppTheme.cyan : AppTheme.accent) : AppTheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _runPressed ? AppTheme.cyan : AppTheme.accent.withValues(alpha: 0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: (_runPressed ? AppTheme.cyan : AppTheme.accent).withValues(alpha: _rightPressed ? 0.3 : 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: _rightPressed ? Colors.black : AppTheme.accent,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // UI - Pause Overlay
                if (_isPaused)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Center(
                          child: Container(
                            width: 320,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppTheme.line, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PAUSED',
                                  style: AppTheme.mono(color: AppTheme.accent, size: 28),
                                ),
                                const SizedBox(height: 32),
                                // Resume Button
                                SGTouchable(
                                  onTap: () => setState(() => _isPaused = false),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'RESUME',
                                        style: AppTheme.label(color: Colors.black).copyWith(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Exit Button
                                SGTouchable(
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    await _doorCtrl.reverse();
                                    if (mounted) {
                                      SystemChrome.setPreferredOrientations([
                                        DeviceOrientation.portraitUp,
                                      ]);
                                      navigator.pop();
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.red.withValues(alpha: 0.5)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'EXIT TRAINING',
                                        style: AppTheme.label(color: AppTheme.red).copyWith(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
        );

        // Wrap GameView with the sliding doors
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              isPortrait ? RotatedBox(quarterTurns: 1, child: gameView) : gameView,
              
              if (_loading || _doorCtrl.value < 1.0)
                AnimatedBuilder(
                  animation: _doorCtrl,
                  builder: (context, child) {
                    // Use a more stable width reference for perfect symmetry
                    final double doorWidth = size.width * 0.5;
                    
                    return Stack(
                      children: [
                        // Left Door
                        Transform.translate(
                          offset: Offset(-_doorCtrl.value * doorWidth, 0),
                          child: Container(
                            width: doorWidth,
                            height: size.height,
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
                        // Right Door
                        Transform.translate(
                          offset: Offset(_doorCtrl.value * doorWidth, 0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: doorWidth,
                              height: size.height,
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
          ),
        );
      },
    );
  }
}


