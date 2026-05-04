import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import '../theme/theme.dart';
import '../widgets/player.dart';
import 'combat_data.dart';

// import '../background.dart'; // Removed as requested

class EngineScreen extends StatefulWidget {
  final bool isLoading;
  const EngineScreen({super.key, this.isLoading = false});

  @override
  State<EngineScreen> createState() => _EngineScreenState();
}

class _EngineScreenState extends State<EngineScreen> with TickerProviderStateMixin {
  bool _loading = true;
  double _playerWorldX = 100.0;
  double _velocityX = 0.0;
  double _joystickInputX = 0.0;
  bool _isMoving = false;
  bool _isRunning = false;
  bool _flip = false;
  bool _isJumping = false;
  double _playerY = 0.0;
  double _velocityY = 0.0;
  double _stamina = 1.0; // 0.0 to 1.0
  bool _showColliders = false;
  ColliderTarget? _selectedCollider = ColliderTarget.player;
  int _selectedBoxIndex = 0;
  double _editorPanelX = 300.0;
  double _editorPanelY = 20.0;
  bool _isPaused = false;
  bool _isGrounded = true;
  int _dotCount = 0;
  Timer? _dotTimer;
  late AnimationController _bgCtrl;
  late AnimationController _doorCtrl;

  // Grabbing State
  bool _isGrabbing = false;
  bool _canGrab = false;
  _Box? _grabbedBox;
  int _grabSide = 0; 
  bool _isPushingBox = false;
  bool _isPullingBox = false;
  
  // Input State (Better multi-touch tracking)
  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _jumpPressed = false;
  bool _runPressed = false;
  bool _attackPressed = false;

  // Double Tap Run tracking
  DateTime? _lastLeftDown;
  DateTime? _lastRightDown;
  static const _doubleTapThreshold = Duration(milliseconds: 300);

  // Punching & Kicking System
  bool _isPunching = false;
  DateTime? _punchStartTime;
  Timer? _punchTimer;
  bool _isKicking = false;
  DateTime? _kickStartTime;
  Timer? _kickTimer;
  late _PunchBag _punchBag;
  final List<_DamageNumber> _damageNumbers = [];

  // Debugger / Stop State
  bool _isFrozen = false;
  final double _debugPunchOffsetX = 38.0; // Reach
  final double _debugPunchOffsetY = 41.0; // Height
  final double _debugPunchWidth = 107.0;
  final double _debugPunchHeight = 14.0;
  final double _debugPunchRotation = 0.0;
  final double _debugKickOffsetX = 45.0; // Slightly more reach
  final double _debugKickOffsetY = 30.0; // Slightly lower
  final double _debugKickWidth = 90.0;
  final double _debugKickHeight = 25.0;
  final double _debugKickRotation = 0.0;
  final double _playerHitboxW = 40.0;
  final double _playerHitboxH = 103.0;
  final double _playerHitboxOffsetX = -20.0; // Centered by default
  final double _playerHitboxOffsetY = 0.0;
  final double _playerHitboxRotation = 0.0;
  bool _isPlayerHit = false;
  late _Clone _clone;
  double _cloneAttackOffsetX = 38.0;
  double _cloneAttackOffsetY = 41.0;
  double _cloneAttackWidth = 107.0;
  double _cloneAttackHeight = 14.0;
  double _cloneAttackRotation = 0.0;

  // Box Physics
  final List<_Box> _boxes = [
    _Box(x: 800, width: 90, height: 90),
  ];
  
  late Ticker _ticker;
  int _currentEditFrame = 0;
  // Use CombatData instead of local frame data

  /// Returns the 0-based max frame index for a given animation name.
  int _getAnimFrameCount(String anim) {
    switch (anim) {
      case 'Punch01': return 6;
      case 'Kick01':  return 9;
      case 'Idle':    return 7;
      case 'Walk':    return 8;
      case 'Run':     return 8;
      case 'Jump':    return 3;
      case 'Jump Fall': return 3;
      case 'Hit':     return 3;
      case 'Push':    return 8;
      case 'PushIdle': return 6;
      case 'Pull':    return 6;
      default:        return 8;
    }
  }

  /// Returns the 0-based frame index within an animation (clamped to actual frame count).
  int _getCurrentFrameIndex(String anim, DateTime startTime, double fps) {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    int frame = (elapsed / (1000 / fps)).floor();
    return frame.clamp(0, _getAnimFrameCount(anim) - 1);
  }

  /// Builds the 1-indexed asset path for a given animation and 0-based frame.
  String _getFrameAssetPath(String anim, int frameIdx) {
    final maxFrames = _getAnimFrameCount(anim);
    final clampedFrame = frameIdx.clamp(0, maxFrames - 1);
    final frameNum = (clampedFrame + 1).toString().padLeft(2, '0');
    return 'Assets/Player Model/$anim/$anim$frameNum.png';
  }

  void _spawnDamage(double x, double y, int damage) {
    setState(() {
      _damageNumbers.add(_DamageNumber(x: x, y: y, damage: damage));
    });
  }


  // Physics constants (Retuned for "Heavy & Snappy" feel)
  static const double _walkAccel = 0.6;
  static const double _runAccel = 1.2;
  static const double _friction = 0.82;
  static const double _airFriction = 0.94;
  static const double _maxWalkSpeed = 4.5; // Slower walk
  static const double _maxRunSpeed = 12.0;
  static const double _gravity = -1.1; 
  static const double _jumpForce = 20.0;
  static const double _fallMultiplier = 1.4;
  
  // Camera/World logic
  double _cameraX = 0;
  final double _groundY = 120.0; 
  final double _mapWidth = 2000.0;
  double _screenW = 800.0;

  @override
  void initState() {
    super.initState();
    
    // Pre-populate specific frame data requested by user
    CombatData.frameData[CombatData.getFrameKey(ColliderTarget.attack, 'Punch01', 3)] = 
        ColliderFrameData(x: 33, y: 55, w: 107, h: 14, r: 0);

    // Aggressive landscape and immersive mode for "Game" feel
    _clone = _Clone(x: 1500);
    _setupGameMode();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _punchBag = _PunchBag(x: 1000); // Init before ticker
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
      // 0. Update Joystick Input from states
      _joystickInputX = (_rightPressed ? 1.0 : 0.0) - (_leftPressed ? 1.0 : 0.0);

      // 0.1 Update Punch Bag & Damage Numbers
      _punchBag.update();
      for (int i = _damageNumbers.length - 1; i >= 0; i--) {
        _damageNumbers[i].update();
        if (_damageNumbers[i].opacity <= 0) _damageNumbers.removeAt(i);
      }

      // 1. Horizontal Physics (Improved Acceleration/Friction)
      bool canRun = _runPressed && _isGrounded && _grabbedBox == null;
      double accel = canRun ? _runAccel : _walkAccel;
      
      // Reduce control in air for more weight
      if (!_isGrounded) accel *= 0.4;

      if (_joystickInputX.abs() > 0.1) {
        _velocityX += _joystickInputX * accel;
      } else {
        // Natural friction stop
        _velocityX *= (_isGrounded ? _friction : _airFriction);
      }
      
      // Movement speed limits
      double currentMaxSpeed = canRun ? _maxRunSpeed : _maxWalkSpeed;
      if (_grabbedBox != null) {
        // Calculate chain of boxes being pushed/pulled
        int chainCount = _calculateBoxChain(_grabbedBox!, _velocityX.sign);
        
        // Cumulative penalty: Half speed for the first, half again for each additional
        double speedMult = 1.0;
        for (int i = 0; i < chainCount; i++) {
          speedMult *= 0.5;
        }
        
        currentMaxSpeed *= speedMult;
        
        // Stamina drain based on mass (10kg per box)
        if (_velocityX.abs() > 0.1) {
            _stamina -= (0.002 * chainCount);
            if (_stamina < 0) _stamina = 0;
        }
      }

      // Hard cap speed
      if (_velocityX.abs() > currentMaxSpeed) {
        _velocityX = _velocityX.sign * currentMaxSpeed;
      }

      _playerWorldX += _velocityX;

      // Update Grabbed Box
      if (_grabbedBox != null) {
        if (_grabSide == 1) {
          // Grabbed box should stick to the edge of the player's HITBOX
          _grabbedBox!.x = _playerWorldX + _playerHitboxOffsetX + _playerHitboxW;
          _flip = false; 
        } else {
          _grabbedBox!.x = _playerWorldX + _playerHitboxOffsetX - _grabbedBox!.colliderWidth;
          _flip = true;
        }
        _grabbedBox!.velX = _velocityX;

        _isPushingBox = false;
        _isPullingBox = false;
        if (_velocityX.abs() > 0.1) {
          if ((_grabSide == 1 && _velocityX > 0) || (_grabSide == -1 && _velocityX < 0)) {
            _isPushingBox = true;
          } else {
            _isPullingBox = true;
          }
        }
      } else {
        _isPushingBox = false;
        _isPullingBox = false;
      }

      // 2. Vertical Physics (Gravity & Jump)
      if (_isJumping || _playerY > 0) {
        // Apply stronger gravity when falling for that "punchy" landing
        double currentGravity = _gravity;
        if (_velocityY < 0) currentGravity *= _fallMultiplier;
        
        _velocityY += currentGravity;
        _playerY += _velocityY;
        
        if (_playerY <= 0) {
          _playerY = 0;
          _velocityY = 0;
          _isJumping = false;
        }
      }

      // 3. Box Physics & Collision
      bool groundedOnBox = false;
      for (var box in _boxes) {
        // Box Gravity
        if (box.y > 0) {
          box.velY += _gravity;
          box.y += box.velY;
          if (box.y < 0) { box.y = 0; box.velY = 0; }
        }

        // Box Friction
        if (box != _grabbedBox) {
          box.velX *= 0.9;
          box.x += box.velX;
        }

        if (box == _grabbedBox) continue; // Skip physical block check for the grabbed box

        // Player vs Box Collision (Solid Wall)
        double pLeft = _playerWorldX + _playerHitboxOffsetX;
        double pRight = pLeft + _playerHitboxW;
        double pBottom = _playerY + _playerHitboxOffsetY;
        double pTop = pBottom + _playerHitboxH;

        double bLeft = box.x + box.colliderOffsetX;
        double bRight = bLeft + box.colliderWidth;
        double bBottom = box.y + box.colliderOffsetY;
        double bTop = bBottom + box.colliderHeight;

        bool overlapX = (pRight > bLeft) && (pLeft < bRight);
        bool overlapY = (pTop > bBottom) && (pBottom < bTop);

        if (overlapX && overlapY) {
          // Check if landing on top (with a bit more tolerance for grounded state)
          // Check if landing on top
          if (_velocityY <= 0 && pBottom > bBottom + box.colliderHeight * 0.5) {
            _playerY = bTop - _playerHitboxOffsetY;
            _velocityY = 0;
            _isJumping = false;
            groundedOnBox = true;
          } 
          // Solid Block (No auto-push)
          else {
            if (pLeft + _playerHitboxW/2 < bLeft + box.colliderWidth/2) {
              _playerWorldX = bLeft - _playerHitboxW - _playerHitboxOffsetX;
            } else {
              _playerWorldX = bRight - _playerHitboxOffsetX;
            }
            _velocityX = 0;
          }
        }
      }

      _isGrounded = (_playerY <= 0) || groundedOnBox;

      // 4. Box vs Box Collision (Solid Bodies)
      for (int i = 0; i < _boxes.length; i++) {
        for (int j = i + 1; j < _boxes.length; j++) {
          var b1 = _boxes[i];
          var b2 = _boxes[j];

          double b1L = b1.x + b1.colliderOffsetX;
          double b1R = b1L + b1.colliderWidth;
          double b1B = b1.y + b1.colliderOffsetY;
          double b1T = b1B + b1.colliderHeight;

          double b2L = b2.x + b2.colliderOffsetX;
          double b2R = b2L + b2.colliderWidth;
          double b2B = b2.y + b2.colliderOffsetY;
          double b2T = b2B + b2.colliderHeight;

          bool overlapX = (b1R > b2L) && (b1L < b2R);
          bool overlapY = (b1T > b2B) && (b1B < b2T);

          if (overlapX && overlapY) {
            // Horizontal Resolution (Push apart)
            if (b1L < b2L) {
              double overlap = b1R - b2L;
              b1.x -= overlap / 2;
              b2.x += overlap / 2;
              // Transfer momentum
              double avgVel = (b1.velX + b2.velX) / 2;
              b1.velX = avgVel;
              b2.velX = avgVel;
            } else {
              double overlap = b2R - b1L;
              b1.x += overlap / 2;
              b2.x -= overlap / 2;
              double avgVel = (b1.velX + b2.velX) / 2;
              b1.velX = avgVel;
              b2.velX = avgVel;
            }
          }
        }
      }

      // Enforce grabbed box connection
      if (_grabbedBox != null) {
        if (_grabSide == 1) {
          _playerWorldX = (_grabbedBox!.x + _grabbedBox!.colliderOffsetX) - _playerHitboxW - _playerHitboxOffsetX;
        } else {
          _playerWorldX = (_grabbedBox!.x + _grabbedBox!.colliderOffsetX + _grabbedBox!.colliderWidth) - _playerHitboxOffsetX;
        }
      }

      // 5. Stamina Logic
      if (canRun && _isMoving) {
        _stamina -= 0.006; 
        if (_stamina <= 0) {
          _stamina = 0;
          _isRunning = false; 
        }
      } else if (_isGrounded) {
        _stamina += 0.004; 
        if (_stamina > 1.0) _stamina = 1.0;
      }

      // 6. Movement states
      _isMoving = _velocityX.abs() > 0.1;
      if (_grabbedBox == null) {
        if (_joystickInputX < 0) _flip = true;
        if (_joystickInputX > 0) _flip = false;
      }

      // 7. Check Grab Proximity
      _canGrab = false;
      if (!_isGrabbing && _isGrounded) {
        double pLeft = _playerWorldX + _playerHitboxOffsetX;
        double pRight = pLeft + _playerHitboxW;
        double pBottom = _playerY + _playerHitboxOffsetY;
        double pTop = pBottom + _playerHitboxH;

        for (var box in _boxes) {
          double bLeft = box.x + box.colliderOffsetX;
          double bRight = bLeft + box.colliderWidth;
          double bBottom = box.y + box.colliderOffsetY;
          double bTop = bBottom + box.colliderHeight;

          bool overlapY = (pTop > bBottom) && (pBottom < bTop);
          if (!overlapY) continue;
          
          if (pRight >= bLeft - 15 && pRight <= bLeft + box.colliderWidth / 2) {
              _canGrab = true;
              break;
          } else if (pLeft <= bRight + 15 && pLeft >= bLeft + box.colliderWidth / 2) {
              _canGrab = true;
              break;
          }
        }
      }

      // 8. Constraints
      if (_playerWorldX + _playerHitboxOffsetX < 0) {
        _playerWorldX = -_playerHitboxOffsetX;
        _velocityX = 0;
      } else if (_playerWorldX > _mapWidth) {
        _playerWorldX = _mapWidth;
        _velocityX = 0;
      }

      // 6. Smooth Camera follow with boundaries
      double targetCameraX = _playerWorldX - (_screenW * 0.4);
      
      // Left boundary
      if (targetCameraX < 0) targetCameraX = 0;
      
      // Right boundary (Match the left side behavior)
      if (targetCameraX > _mapWidth - _screenW) {
        targetCameraX = _mapWidth - _screenW;
      }
      
      _cameraX = lerpDouble(_cameraX, targetCameraX, 0.12)!;

      // 7. Punch Detection (Per-frame)
      if (_isPunching && _punchStartTime != null) {
        final frameIdx = _getCurrentFrameIndex('Punch01', _punchStartTime!, 12);
        
        // Only active on frame 3 (the impact frame)
        if (frameIdx == 3) {
          final data = CombatData.getOrCreateFrameData(ColliderTarget.attack, 'Punch01', frameIdx, defaults: ColliderFrameData(x: _debugPunchOffsetX, y: _debugPunchOffsetY, w: _debugPunchWidth, h: _debugPunchHeight, r: _debugPunchRotation));
          
          double pCenter = _playerWorldX + _playerHitboxOffsetX + (_playerHitboxW / 2);
          double reachX = _flip ? pCenter - data.x : pCenter + data.x;
          Rect attackRect = Rect.fromCenter(
            center: Offset(reachX, _groundY + _playerY + data.y + (data.h / 2)),
            width: data.w,
            height: data.h,
          );

          if (!_punchBag.isHit) {
            Rect bagRect = Rect.fromLTWH(_punchBag.x, _groundY + _punchBag.y + _punchBag.colliderOffsetY, _punchBag.colliderWidth, _punchBag.colliderHeight);
            if (attackRect.overlaps(bagRect)) {
              _punchBag.hit(_flip ? -1 : 1);
              _spawnDamage(attackRect.center.dx, attackRect.center.dy, 10 + math.Random().nextInt(5));
            }
          }

          if (!_clone.isHit) {
            Rect cloneRect = Rect.fromLTWH(_clone.x + _clone.colliderOffsetX, _groundY + _clone.y + _clone.colliderOffsetY, _clone.colliderW, _clone.colliderH);
            if (attackRect.overlaps(cloneRect)) {
              _clone.onHit();
              _spawnDamage(attackRect.center.dx, attackRect.center.dy, 15);
            }
          }
        }
      }

      // 7.1 Kick Detection (Per-frame)
      if (_isKicking && _kickStartTime != null) {
        final frameIdx = _getCurrentFrameIndex('Kick01', _kickStartTime!, 12);
        final data = CombatData.getOrCreateFrameData(ColliderTarget.kickAttack, 'Kick01', frameIdx, defaults: ColliderFrameData(x: _debugKickOffsetX, y: _debugKickOffsetY, w: _debugKickWidth, h: _debugKickHeight, r: _debugKickRotation));
        
        double pCenter = _playerWorldX + _playerHitboxOffsetX + (_playerHitboxW / 2);
        double reachX = _flip ? pCenter - data.x : pCenter + data.x;
        Rect attackRect = Rect.fromCenter(
          center: Offset(reachX, _groundY + _playerY + data.y + (data.h / 2)),
          width: data.w,
          height: data.h,
        );

        if (!_punchBag.isHit) {
          Rect bagRect = Rect.fromLTWH(_punchBag.x, _groundY + _punchBag.y + _punchBag.colliderOffsetY, _punchBag.colliderWidth, _punchBag.colliderHeight);
          if (attackRect.overlaps(bagRect)) {
            _punchBag.hit(_flip ? -2.5 : 2.5);
            _spawnDamage(attackRect.center.dx, attackRect.center.dy, 25 + math.Random().nextInt(10));
          }
        }

        if (!_clone.isHit) {
          Rect cloneRect = Rect.fromLTWH(_clone.x + _clone.colliderOffsetX, _groundY + _clone.y + _clone.colliderOffsetY, _clone.colliderW, _clone.colliderH);
          if (attackRect.overlaps(cloneRect)) {
            _clone.onHit();
            _spawnDamage(attackRect.center.dx, attackRect.center.dy, 30);
          }
        }
      }

      // 8. Clone Attack Detection
      if (_clone.isPunching && _clone.punchStartTime != null) {
        final elapsed = DateTime.now().difference(_clone.punchStartTime!).inMilliseconds;
        if (elapsed > 330) {
          double cCenter = _clone.x + _clone.colliderOffsetX + (_clone.colliderW / 2);
          double reachX = _clone.flip ? cCenter - _cloneAttackOffsetX : cCenter + _cloneAttackOffsetX;
          
          Rect cAttackRect = Rect.fromLTWH(
            reachX - (_cloneAttackWidth / 2), 
            _clone.y + _cloneAttackOffsetY, 
            _cloneAttackWidth, 
            _cloneAttackHeight
          );
          Rect pRect = Rect.fromLTWH(
            _playerWorldX + _playerHitboxOffsetX,
            _playerY + _playerHitboxOffsetY,
            _playerHitboxW,
            _playerHitboxH
          );

          if (cAttackRect.overlaps(pRect) && !_isPlayerHit) {
            _isPlayerHit = true;
            _isPunching = false;
            _velocityX = _clone.flip ? -5 : 5; // Knockback
            Timer(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _isPlayerHit = false);
            });
          }
        }
      }
    });
  }

  String _getCurrentAnimation() {
    if (_showColliders) {
      if (_selectedCollider == ColliderTarget.attack) return 'Punch01';
      if (_selectedCollider == ColliderTarget.kickAttack) return 'Kick01';
      if (_selectedCollider == ColliderTarget.player) return 'Idle';
    }

    if (_isPlayerHit) return 'Hit';
    if (_isKicking) return 'Kick01';
    if (_isPunching) return 'Punch01';
    if (_isJumping || !_isGrounded) {
      return _velocityY > 0 ? 'Jump' : 'Jump Fall';
    }
    if (_grabbedBox != null) {
      if (_isPushingBox) return 'Push';
      if (_isPullingBox) return 'Pull';
      return 'PushIdle';
    }
    if (_isMoving) {
      return _isRunning ? 'Run' : 'Walk';
    }
    return 'Idle';
  }

  void _jump() {
    if (!_isJumping && _isGrounded && _stamina >= 0.1) {
      _endGrab(); // Release anything being held
      setState(() {
        _stamina -= 0.1;
        _isJumping = true;
        _velocityY = _jumpForce;
        _isRunning = false; // Stop running
      });
    }
  }

  void _punch() {
    // Punch can be triggered unless already punching or grabbing
    if (_isPunching || _isFrozen || _grabbedBox != null) return;
    
    setState(() {
      _isPunching = true;
      _punchStartTime = DateTime.now();
      _punchBag.isHit = false; // Reset hit flag for this punch
    });

    _punchTimer?.cancel();
    // Safety fallback timer (slightly longer than animation)
    _punchTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && _isPunching) setState(() => _isPunching = false);
    });
  }

  void _kick() {
    if (_isPunching || _isKicking || _isFrozen || _grabbedBox != null) return;
    
    setState(() {
      _isKicking = true;
      _kickStartTime = DateTime.now();
      _punchBag.isHit = false;
    });

    _kickTimer?.cancel();
    _kickTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _isKicking) setState(() => _isKicking = false);
    });
  }

  void _startGrab() {
    if (!_isGrounded) return; // Only grab on ground
    setState(() {
      _isGrabbing = true;
      
      for (var box in _boxes) {
        bool overlapY = (_playerY + _playerHitboxH > box.y + box.colliderOffsetY) && (_playerY + _playerHitboxOffsetY < box.y + box.colliderOffsetY + box.colliderHeight);
        if (!overlapY) continue;
        
        // Is player touching left side? (Within 10px tolerance)
        if ((_playerWorldX + _playerHitboxOffsetX + _playerHitboxW) >= (box.x + box.colliderOffsetX) - 10 && 
            (_playerWorldX + _playerHitboxOffsetX + _playerHitboxW) <= (box.x + box.colliderOffsetX) + box.colliderWidth/2) {
            _grabbedBox = box;
            _grabSide = 1;
            break;
        }
        // Is player touching right side?
        else if ((_playerWorldX + _playerHitboxOffsetX) <= (box.x + box.colliderOffsetX) + box.colliderWidth + 10 && 
                 (_playerWorldX + _playerHitboxOffsetX) >= (box.x + box.colliderOffsetX) + box.colliderWidth/2) {
            _grabbedBox = box;
            _grabSide = -1;
            break;
        }
      }
    });
  }

  void _endGrab() {
    setState(() {
      _isGrabbing = false;
      _grabbedBox = null;
      _isPushingBox = false;
      _isPullingBox = false;
    });
  }

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

  int _calculateBoxChain(_Box startBox, double direction) {
    int count = 1;
    _Box current = startBox;
    List<_Box> visited = [startBox];

    bool foundNext = true;
    while (foundNext) {
      foundNext = false;
      for (var other in _boxes) {
        if (visited.contains(other)) continue;
        
        // Check horizontal adjacency in direction
        bool overlapY = (current.y + current.colliderOffsetY + current.colliderHeight > other.y + other.colliderOffsetY) && 
                        (current.y + current.colliderOffsetY < other.y + other.colliderOffsetY + other.colliderHeight);
        if (!overlapY) continue;

        bool touching = false;
        if (direction >= 0) { // Moving right
           touching = (current.x + current.colliderOffsetX + current.colliderWidth >= (other.x + other.colliderOffsetX) - 10) && 
                      (current.x + current.colliderOffsetX < (other.x + other.colliderOffsetX) + 5);
        } else { // Moving left
           touching = (other.x + other.colliderOffsetX + other.colliderWidth >= (current.x + current.colliderOffsetX) - 10) && 
                      (other.x + other.colliderOffsetX < (current.x + current.colliderOffsetX) + 5);
        }

        if (touching) {
          visited.add(other);
          current = other;
          count++;
          foundNext = true;
          break;
        }
      }
    }
    return count;
  }

  String _getColliderName(ColliderTarget target) {
    switch (target) {
      case ColliderTarget.player: return 'BODY';
      case ColliderTarget.attack: return 'PUNCH';
      case ColliderTarget.kickAttack: return 'KICK';
      case ColliderTarget.bag: return 'BAG';
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

    if (_selectedCollider == ColliderTarget.bag) {
      if (type == 'W') return _punchBag.colliderWidth;
      if (type == 'H') return _punchBag.colliderHeight;
      if (type == 'X') return _punchBag.colliderOffsetX;
      if (type == 'Y') return _punchBag.colliderOffsetY;
      if (type == 'R') return _punchBag.rotation;
    } else if (_selectedCollider == ColliderTarget.box && _boxes.isNotEmpty) {
      if (type == 'W') return _boxes[_selectedBoxIndex].colliderWidth;
      if (type == 'H') return _boxes[_selectedBoxIndex].colliderHeight;
      if (type == 'X') return _boxes[_selectedBoxIndex].colliderOffsetX;
      if (type == 'Y') return _boxes[_selectedBoxIndex].colliderOffsetY;
      if (type == 'R') return _boxes[_selectedBoxIndex].rotation;
    } else if (_selectedCollider == ColliderTarget.clone) {
      if (type == 'W') return _clone.colliderW;
      if (type == 'H') return _clone.colliderH;
      if (type == 'X') return _clone.colliderOffsetX;
      if (type == 'Y') return _clone.colliderOffsetY;
      if (type == 'R') return _clone.rotation;
    } else if (_selectedCollider == ColliderTarget.cloneAttack) {
      if (type == 'W') return _cloneAttackWidth;
      if (type == 'H') return _cloneAttackHeight;
      if (type == 'X') return _cloneAttackOffsetX;
      if (type == 'Y') return _cloneAttackOffsetY;
      if (type == 'R') return _cloneAttackRotation;
    }
    return 0;
  }

  Widget _buildAdjustGroup(String label, void Function(double) onAdjust) {
    double val = _getColliderValue(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 12, child: Text(label, style: AppTheme.mono(color: Colors.white, size: 10))),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => onAdjust(-1),
          child: Container(color: AppTheme.red.withValues(alpha: 0.8), padding: const EdgeInsets.all(4), child: const Icon(Icons.remove, size: 14, color: Colors.white)),
        ),
        Container(
           width: 32,
           alignment: Alignment.center,
           child: Text(val.floor().toString(), style: AppTheme.mono(color: Colors.yellow, size: 10)),
        ),
        GestureDetector(
          onTap: () => onAdjust(1),
          child: Container(color: AppTheme.cyan.withValues(alpha: 0.8), padding: const EdgeInsets.all(4), child: const Icon(Icons.add, size: 14, color: Colors.white)),
        ),
      ],
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

      if (_selectedCollider == ColliderTarget.bag) {
        _punchBag.colliderOffsetX += dx;
        _punchBag.colliderOffsetY += dy;
        _punchBag.colliderWidth = (_punchBag.colliderWidth + dw).clamp(10, 500);
        _punchBag.colliderHeight = (_punchBag.colliderHeight + dh).clamp(10, 500);
        _punchBag.rotation += dr;
      } else if (_selectedCollider == ColliderTarget.box && _boxes.isNotEmpty) {
        _boxes[_selectedBoxIndex].colliderOffsetX += dx;
        _boxes[_selectedBoxIndex].colliderOffsetY += dy;
        _boxes[_selectedBoxIndex].colliderWidth = (_boxes[_selectedBoxIndex].colliderWidth + dw).clamp(10, 500);
        _boxes[_selectedBoxIndex].colliderHeight = (_boxes[_selectedBoxIndex].colliderHeight + dh).clamp(10, 500);
        _boxes[_selectedBoxIndex].rotation += dr;
      } else if (_selectedCollider == ColliderTarget.clone) {
        _clone.colliderOffsetX += dx;
        _clone.colliderOffsetY += dy;
        _clone.colliderW = (_clone.colliderW + dw).clamp(10, 500);
        _clone.colliderH = (_clone.colliderH + dh).clamp(10, 500);
        _clone.rotation += dr;
      } else if (_selectedCollider == ColliderTarget.cloneAttack) {
        _cloneAttackOffsetX += dx;
        _cloneAttackOffsetY += dy;
        _cloneAttackWidth = (_cloneAttackWidth + dw).clamp(10, 500);
        _cloneAttackHeight = (_cloneAttackHeight + dh).clamp(10, 500);
        _cloneAttackRotation += dr;
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
              double playerScreenX = _playerWorldX - _cameraX;
              return Stack(
                children: [
                  // Animated Notebook Background
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _bgCtrl,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _NotebookPainter(_bgCtrl.value, isBlueTheme: true),
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
                    height: _groundY,
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
                  height: _groundY,
                  child: ClipRect(
                    child: Stack(
                      children: [
                        // Box Reflections
                        ..._boxes.map((box) {
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
                                    child: CustomPaint(painter: _CratePainter()),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Player Reflection
                        Positioned(
                          top: _playerY - 110, // Positioned above floor line for mirroring
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
                                      scaleX: _flip ? -1 : 1,
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
                                          fps: _isPlayerHit ? 12 : (_isPunching || _isKicking ? 12 : (_isRunning ? 14 : (_isPushingBox || _isPullingBox ? 8 : 10))),
                                          loop: !_isJumping && !_isPunching && !_isKicking && !_isPlayerHit,
                                          onComplete: () {
                                            if (_isPunching) setState(() => _isPunching = false);
                                            if (_isKicking) setState(() => _isKicking = false);
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
                ..._boxes.map((box) {
                  return Positioned(
                    bottom: _groundY + box.y,
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
                              Positioned.fill(child: CustomPaint(painter: _CratePainter())),
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
                                _selectedBoxIndex = _boxes.indexOf(box);
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: _selectedCollider == ColliderTarget.box && _selectedBoxIndex == _boxes.indexOf(box) ? AppTheme.accent : Colors.yellow, width: 2),
                                  color: (_selectedCollider == ColliderTarget.box && _selectedBoxIndex == _boxes.indexOf(box) ? AppTheme.accent : Colors.yellow).withValues(alpha: 0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    'OX:${box.colliderOffsetX.floor()} OY:${box.colliderOffsetY.floor()}\nW:${box.colliderWidth.floor()} H:${box.colliderHeight.floor()}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _selectedCollider == ColliderTarget.box && _selectedBoxIndex == _boxes.indexOf(box) ? AppTheme.accent : Colors.yellow, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),


                // Punch Bag
                Positioned(
                  bottom: _groundY + _punchBag.y,
                  left: _punchBag.x - _cameraX,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // MAIN BODY (Visual Bag - Fixed)
                      Transform.rotate(
                        angle: _punchBag.rotation,
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 46,
                          height: 105,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [const Color(0xFFD32F2F), const Color(0xFFB71C1C), const Color(0xFF8E0000)],
                            ),
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.8), width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(3, 6))],
                          ),
                          child: Stack(
                            children: [
                              Positioned(left: 6, top: 10, child: Container(width: 4, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
                              Align(alignment: Alignment.bottomCenter, child: Container(height: 15, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))))),
                              const Center(child: RotatedBox(quarterTurns: 1, child: Text('GAINZ', style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)))),
                              if (_showColliders) Center(child: Text('X:${_punchBag.x.floor()}\nY:${_punchBag.y.floor()}', style: const TextStyle(color: Colors.white70, fontSize: 9))),
                            ],
                          ),
                        ),
                      ),
                      // THE COLLIDER (Separate item as child)
                      if (_showColliders)
                        Positioned(
                          left: _punchBag.colliderOffsetX,
                          bottom: _punchBag.colliderOffsetY,
                          width: _punchBag.colliderWidth,
                          height: _punchBag.colliderHeight,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCollider = ColliderTarget.bag),
                            child: Transform.rotate(
                              angle: _punchBag.rotation,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: _selectedCollider == ColliderTarget.bag ? AppTheme.accent : Colors.yellow, width: 2),
                                  color: (_selectedCollider == ColliderTarget.bag ? AppTheme.accent : Colors.yellow).withValues(alpha: 0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    'OX:${_punchBag.colliderOffsetX.floor()} OY:${_punchBag.colliderOffsetY.floor()}\nW:${_punchBag.colliderWidth.floor()} R:${(_punchBag.rotation * 180 / 3.14159).floor()}°',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _selectedCollider == ColliderTarget.bag ? AppTheme.accent : Colors.yellow, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Damage Numbers
                ..._damageNumbers.map((dn) => Positioned(
                  bottom: _groundY + dn.y,
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
                if (_showColliders && (_selectedCollider == ColliderTarget.attack || _isFrozen || _isPunching))
                  () {
                    final frameIdx = _isPunching && _punchStartTime != null 
                        ? _getCurrentFrameIndex('Punch01', _punchStartTime!, 12)
                        : _currentEditFrame;
                    
                    final data = CombatData.getOrCreateFrameData(ColliderTarget.attack, 'Punch01', frameIdx, defaults: ColliderFrameData(x: _debugPunchOffsetX, y: _debugPunchOffsetY, w: _debugPunchWidth, h: _debugPunchHeight, r: _debugPunchRotation));
                    return Positioned(
                      bottom: _groundY + _playerY + data.y,
                      left: ((_flip 
                          ? (_playerWorldX + _playerHitboxOffsetX + (_playerHitboxW / 2)) - data.x 
                          : (_playerWorldX + _playerHitboxOffsetX + (_playerHitboxW / 2)) + data.x) - (data.w / 2)) - _cameraX,
                      child: Visibility(
                        visible: frameIdx == 3,
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
                                  'F:$frameIdx\nW:${data.w.floor()}',
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
                if (_showColliders && (_selectedCollider == ColliderTarget.kickAttack || _isFrozen || _isKicking))
                  () {
                    final frameIdx = _isKicking && _kickStartTime != null 
                        ? _getCurrentFrameIndex('Kick01', _kickStartTime!, 12)
                        : _currentEditFrame;
                    final data = CombatData.getOrCreateFrameData(ColliderTarget.kickAttack, 'Kick01', frameIdx, defaults: ColliderFrameData(x: _debugKickOffsetX, y: _debugKickOffsetY, w: _debugKickWidth, h: _debugKickHeight, r: _debugKickRotation));
                    return Positioned(
                      bottom: _groundY + _playerY + data.y,
                      left: ((_flip 
                          ? (_playerWorldX + _playerHitboxOffsetX + (_playerHitboxW / 2)) - data.x 
                          : (_playerWorldX + _playerHitboxOffsetX + (_playerHitboxW / 2)) + data.x) - (data.w / 2)) - _cameraX,
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
                                'F:$frameIdx\nW:${data.w.floor()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),

                // Player Visual
                Positioned(
                  bottom: _groundY + _playerY, 
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
                            scaleX: _flip ? -1 : 1,
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
                                  fps: _isPlayerHit ? 12 : (_isPunching || _isKicking ? 12 : (_isRunning ? 14 : (_isPushingBox || _isPullingBox ? 8 : 10))),
                                  loop: !_isJumping && !_isPunching && !_isKicking && !_isPlayerHit,
                                  onComplete: () {
                                    if (_isPunching) setState(() => _isPunching = false);
                                    if (_isKicking) setState(() => _isKicking = false);
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
                            final data = CombatData.getOrCreateFrameData(ColliderTarget.player, anim, frameIdx, defaults: ColliderFrameData(x: _playerHitboxOffsetX, y: _playerHitboxOffsetY, w: _playerHitboxW, h: _playerHitboxH, r: _playerHitboxRotation));
                            
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
                                        'BODY F:$frameIdx\nW:${data.w.floor()}',
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
                               child: Text('X:${_playerWorldX.floor()}\nY:${_playerY.floor()}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 9)),
                             ),
                            ),
                      ],
                    ),
                  ),
                ),

                // CLONE
                Positioned(
                  bottom: _groundY + _clone.y,
                  left: _clone.x - _cameraX - 120, // Offset for 240 size
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
                          scaleX: _clone.flip ? -1 : 1,
                          child: Player(
                            animation: _clone.getCurrentAnimation(),
                            size: 240,
                            fps: _clone.isPunching ? 12 : 10,
                            loop: !_clone.isPunching && !_clone.isHit,
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
                    bottom: _groundY + _clone.y + _clone.colliderOffsetY,
                    left: (_clone.x + _clone.colliderOffsetX) - _cameraX,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCollider = ColliderTarget.clone),
                      child: Container(
                        width: _clone.colliderW,
                        height: _clone.colliderH,
                        decoration: BoxDecoration(
                          border: Border.all(color: _selectedCollider == ColliderTarget.clone ? AppTheme.accent : Colors.white24, width: 2),
                          color: Colors.white12,
                        ),
                      ),
                    ),
                  ),

                // CLONE ATTACK COLLIDER (CL_ATK)
                if (_showColliders && (_selectedCollider == ColliderTarget.cloneAttack || _clone.isPunching))
                  Positioned(
                    bottom: _groundY + _clone.y + _cloneAttackOffsetY,
                    left: ((_clone.flip 
                        ? (_clone.x + _clone.colliderOffsetX + (_clone.colliderW / 2)) - _cloneAttackOffsetX 
                        : (_clone.x + _clone.colliderOffsetX + (_clone.colliderW / 2)) + _cloneAttackOffsetX) - (_cloneAttackWidth / 2)) - _cameraX,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCollider = ColliderTarget.cloneAttack),
                      child: Transform.rotate(
                        angle: _cloneAttackRotation,
                        child: Container(
                          width: _cloneAttackWidth,
                          height: _cloneAttackHeight,
                          decoration: BoxDecoration(
                            color: (_selectedCollider == ColliderTarget.cloneAttack ? AppTheme.accent : AppTheme.red).withValues(alpha: 0.6),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              'CL_ATK\nW:${_cloneAttackWidth.floor()} R:${(_cloneAttackRotation * 180 / 3.14159).floor()}°',
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
                    bottom: _groundY,
                    left: playerScreenX,
                    child: SizedBox(
                      width: 100,
                      height: _playerY + 55,
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
                            top: (_playerY + 55) / 2 - 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.accent, width: 1),
                              ),
                              child: Text(
                                '${(_playerY / 10).toStringAsFixed(1)}m',
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.9),
                        border: Border.all(color: AppTheme.accent),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _cycleCollider(-1),
                                child: Container(padding: const EdgeInsets.all(2), color: Colors.white12, child: const Icon(Icons.arrow_left, color: Colors.white, size: 24)),
                              ),
                              Container(
                                width: 80,
                                alignment: Alignment.center,
                                child: Text(_getColliderName(_selectedCollider ?? ColliderTarget.player), style: AppTheme.mono(color: AppTheme.accent, size: 14)),
                              ),
                              GestureDetector(
                                onTap: () => _cycleCollider(1),
                                child: Container(padding: const EdgeInsets.all(2), color: Colors.white12, child: const Icon(Icons.arrow_right, color: Colors.white, size: 24)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Frame Selector (clamped to real animation frame count)
                          Builder(builder: (context) {
                            final anim = _getCurrentAnimation();
                            final maxFrames = _getAnimFrameCount(anim);
                            // Clamp in case animation changed
                            if (_currentEditFrame >= maxFrames) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _currentEditFrame = maxFrames - 1);
                              });
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('F:', style: AppTheme.mono(color: Colors.white, size: 10)),
                                GestureDetector(
                                  onTap: () => setState(() => _currentEditFrame = (_currentEditFrame - 1).clamp(0, maxFrames - 1)),
                                  child: Container(padding: const EdgeInsets.all(2), color: Colors.white12, child: const Icon(Icons.remove, color: Colors.white, size: 16)),
                                ),
                                Container(
                                  width: 44,
                                  alignment: Alignment.center,
                                  child: Text('${_currentEditFrame + 1}/$maxFrames', style: AppTheme.mono(color: Colors.yellow, size: 12)),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _currentEditFrame = (_currentEditFrame + 1).clamp(0, maxFrames - 1)),
                                  child: Container(padding: const EdgeInsets.all(2), color: Colors.white12, child: const Icon(Icons.add, color: Colors.white, size: 16)),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAdjustGroup('W', (d) => _adjustSelected(dw: d)),
                              const SizedBox(width: 20),
                              _buildAdjustGroup('X', (d) => _adjustSelected(dx: d)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAdjustGroup('H', (d) => _adjustSelected(dh: d)),
                              const SizedBox(width: 20),
                              _buildAdjustGroup('Y', (d) => _adjustSelected(dy: d)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAdjustGroup('R', (d) => _adjustSelected(dr: d / 20)), 
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
                        onTap: () => setState(() => _clone.punch()),
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
                      // Collider Toggle — auto-freezes all animations for frame-by-frame editing
                      SGTouchable(
                        onTap: () {
                          setState(() {
                            _showColliders = !_showColliders;
                            if (_showColliders) {
                              _isFrozen = true;
                              _bgCtrl.stop();
                              _currentEditFrame = 0;
                            } else {
                              _isFrozen = false;
                              _bgCtrl.repeat();
                            }
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _showColliders ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _showColliders ? AppTheme.accent : AppTheme.line, width: 2),
                          ),
                          child: Icon(
                            _showColliders ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: _showColliders ? AppTheme.accent : AppTheme.text2,
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
                                    left: (0 - _playerWorldX) * 0.12 + 110,
                                    width: _mapWidth * 0.12,
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
                                          ..._boxes.map((box) {
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
                                    left: (0 - _playerWorldX) * 0.12 + 110 - 2,
                                    top: 0, bottom: 0,
                                    child: Container(width: 4, color: AppTheme.red.withValues(alpha: 0.8)),
                                  ),
                                  Positioned(
                                    left: (_mapWidth - _playerWorldX) * 0.12 + 110 - 2,
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
                                          scaleX: _flip ? -1 : 1,
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
                            '${(_playerWorldX / 10).floor()}m',
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
                          child: const Icon(Icons.pause_rounded, color: AppTheme.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Stamina Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STAMINA', style: AppTheme.label(color: AppTheme.text2).copyWith(fontSize: 10)),
                          const SizedBox(height: 4),
                          Container(
                            width: 120,
                            height: 10,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  width: 116 * _stamina,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: [
                                        _stamina < 0.25 ? AppTheme.red : AppTheme.accent,
                                        _stamina < 0.25 ? AppTheme.red.withValues(alpha: 0.7) : AppTheme.accent.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                // UI - Grab Button (Action)
                Positioned(
                  bottom: 30, 
                  right: 208,   
                  child: AnimatedOpacity(
                    opacity: (_canGrab || _isGrabbing) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !(_canGrab || _isGrabbing),
                      child: Listener(
                        onPointerDown: (_) {
                          if (_isGrounded) _startGrab();
                        },
                        onPointerUp: (_) {
                          _endGrab();
                        },
                        onPointerCancel: (_) {
                          _endGrab();
                        },
                        child: AnimatedScale(
                          scale: _isGrabbing ? 0.9 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _isGrabbing ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.8), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: _isGrabbing ? 0.4 : 0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.back_hand_rounded,
                                color: _isGrabbing ? Colors.black : AppTheme.accent,
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

                Positioned(
                  bottom: 30,
                  right: 40,
                  child: Listener(
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
                              child: _isPunching
                                ? Player(
                                    animation: 'Punch01',
                                    fps: 12,
                                    size: 140,
                                    alignment: Alignment.center,
                                    loop: false,
                                    paused: _isFrozen,
                                  )
                                : Image.asset(
                                    'Assets/Player Model/Punch01/Punch0101.png',
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
                ),

                // UI - Kick Button (Left of Punch)
                Positioned(
                  bottom: 30,
                  right: 124, // 40 (Punch) + 64 (Punch Width) + 20 (SizedBox)
                  child: Listener(
                    onPointerDown: (_) {
                      _kick();
                    },
                    child: AnimatedScale(
                      scale: _isKicking ? 0.85 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 64,
                        height: 64,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: _isKicking ? Colors.orange : AppTheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.8), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: _isKicking ? 20 : 10,
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
                              child: _isKicking
                                ? Player(
                                    animation: 'Kick01',
                                    fps: 12,
                                    size: 140,
                                    alignment: Alignment.center,
                                    loop: false,
                                    paused: _isFrozen,
                                  )
                                : Image.asset(
                                    'Assets/Player Model/Kick01/Kick0101.png',
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
                ),

                // UI - Jump Button (Primary)
                Positioned(
                  bottom: 110,
                  right: 40,
                  child: Listener(
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
                          color: _isJumping ? AppTheme.cyan : AppTheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.8), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.cyan.withValues(alpha: 0.3),
                              blurRadius: _isJumping ? 20 : 10,
                            ),
                          ],
                        ),
                        child: OverflowBox(
                          maxWidth: 240,
                          maxHeight: 240,
                          child: Transform.translate(
                            offset: const Offset(0, -36), // Shift up more for jump sprite alignment
                            child: Transform.scale(
                              scale: 1.5, // Make him much bigger
                              child: _isJumping
                                ? Player(
                                    animation: 'Jump',
                                    fps: 10,
                                    size: 140,
                                    alignment: Alignment.center,
                                    loop: false,
                                    paused: _isFrozen,
                                  )
                                : Image.asset(
                                    'Assets/Player Model/Jump/Jump02.png',
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
                            if (isDoubleTap && _isGrounded && _grabbedBox == null) {
                              _runPressed = true;
                              _isRunning = true;
                            }
                          });
                        },
                        onPointerUp: (_) => setState(() {
                          _leftPressed = false;
                          _runPressed = false;
                          _isRunning = false;
                        }),
                        onPointerCancel: (_) => setState(() {
                          _leftPressed = false;
                          _runPressed = false;
                          _isRunning = false;
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
                            if (isDoubleTap && _isGrounded && _grabbedBox == null) {
                              _runPressed = true;
                              _isRunning = true;
                            }
                          });
                        },
                        onPointerUp: (_) => setState(() {
                          _rightPressed = false;
                          _runPressed = false;
                          _isRunning = false;
                        }),
                        onPointerCancel: (_) => setState(() {
                          _rightPressed = false;
                          _runPressed = false;
                          _isRunning = false;
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
                                  painter: _NotebookPainter(_bgCtrl.value, isBlueTheme: true),
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
                                          painter: _NotebookPainter(_bgCtrl.value, isBlueTheme: true, horizontalOffset: -doorWidth),
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

class _Box {
  double x;
  double y = 0.0;
  double rotation = 0.0;
  
  // Collider (Relative to x, y)
  double colliderOffsetX = 0.0;
  double colliderOffsetY = 0.0;
  double colliderWidth;
  double colliderHeight;
  
  double velX = 0.0;
  double velY = 0.0;

  double get weight => 10.0; 

  _Box({
    required this.x,
    required double width,
    required double height,
  }) : colliderWidth = width, colliderHeight = height;
}

class _PunchBag {
  double x;
  double y = 15.0; 
  
  // Collider (Relative to x, y)
  double colliderOffsetX = 0.0;
  double colliderOffsetY = 0.0;
  double colliderWidth = 46.0;
  double colliderHeight = 103.0;

  double rotation = 0.0;
  double rotationVel = 0.0;
  bool isHit = false;

  _PunchBag({required this.x});

  void hit(double dir) {
    rotationVel = dir * 0.1; // Much smaller rotation effect
    isHit = true;
  }

  void update() {
    // Heavy Pendulum physics
    // Higher weight = slower swing (less gravity impact) and more damping
    double weightEffect = 0.008; 
    rotationVel -= rotation * weightEffect;
    rotationVel *= 0.96; // Higher damping for a heavy bag
    rotation += rotationVel;
  }
}

class _DamageNumber {
  double x;
  double y;
  int damage;
  double opacity = 1.0;
  double velY = 2.0;

  _DamageNumber({required this.x, required this.y, required this.damage});

  void update() {
    y += velY;
    velY *= 0.95;
    opacity -= 0.02;
  }
}


class _NotebookPainter extends CustomPainter {
  final double progress;
  final bool isBlueTheme;
  final double horizontalOffset;
  _NotebookPainter(this.progress, {this.isBlueTheme = false, this.horizontalOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isBlueTheme 
          ? const Color(0xFF4FC3F7).withValues(alpha: 0.05)
          : Colors.blue.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    // Static Horizontal Lines
    const double lineSpacing = 40.0;
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Scrolling Vertical Lines (Horizontal motion)
    double xOffset = -(progress * lineSpacing * 2) + horizontalOffset;
    for (double x = -lineSpacing + (xOffset % lineSpacing); x < size.width + lineSpacing; x += lineSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(_NotebookPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.isBlueTheme != isBlueTheme;
}

class _CratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.6)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;


    // Main X-Beam
    canvas.drawLine(const Offset(10, 10), Offset(size.width - 10, size.height - 10), framePaint);
    canvas.drawLine(Offset(size.width - 10, 10), Offset(10, size.height - 10), framePaint);

    // Corner Studs (Metal nails)
    final studPaint = Paint()..color = const Color(0xFFBDBDBD).withValues(alpha: 0.3);
    canvas.drawCircle(const Offset(8, 8), 2, studPaint);
    canvas.drawCircle(Offset(size.width - 8, 8), 2, studPaint);
    canvas.drawCircle(Offset(8, size.height - 8), 2, studPaint);
    canvas.drawCircle(Offset(size.width - 8, size.height - 8), 2, studPaint);

    // Corner L-Brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    double bSize = 15;
    // Top-Left
    canvas.drawLine(Offset.zero, Offset(bSize, 0), bracketPaint);
    canvas.drawLine(Offset.zero, Offset(0, bSize), bracketPaint);
    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - bSize, 0), bracketPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, bSize), bracketPaint);
    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(bSize, size.height), bracketPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - bSize), bracketPaint);
    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - bSize, size.height), bracketPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - bSize), bracketPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _Clone {
  double x;
  double y = 0.0;
  double rotation = 0.0;
  bool isPunching = false;
  DateTime? punchStartTime;
  bool isHit = false;
  DateTime? hitStartTime;
  bool flip = true; 
  
  double colliderW = 40.0;
  double colliderH = 103.0;
  double colliderOffsetX = -20.0;
  double colliderOffsetY = 0.0;

  _Clone({required this.x});

  void punch() {
    if (isPunching) return;
    isPunching = true;
    punchStartTime = DateTime.now();
    Timer(const Duration(milliseconds: 500), () {
      isPunching = false;
      punchStartTime = null;
    });
  }

  void onHit() {
    isHit = true;
    hitStartTime = DateTime.now();
    Timer(const Duration(milliseconds: 400), () {
      isHit = false;
    });
  }

  String getCurrentAnimation() {
    if (isHit) return 'Hit';
    if (isPunching) return 'Punch01';
    return 'Idle';
  }
}
