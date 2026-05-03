import 'dart:async';
import 'dart:ui';
import 'package:flutter/scheduler.dart';
import '../theme/theme.dart';
import '../widgets/player.dart';
// import '../background.dart'; // Removed as requested

class TrainingScreen extends StatefulWidget {
  final bool isLoading;
  const TrainingScreen({super.key, this.isLoading = false});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> with TickerProviderStateMixin {
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
  bool _isPaused = false;
  bool _isGrounded = true;
  int _dotCount = 0;
  Timer? _dotTimer;
  late AnimationController _bgCtrl;
  late AnimationController _doorCtrl;
  final bool _doorsOpen = false;

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
  bool _grabPressed = false;
  bool _attackPressed = false;

  // Punching System
  bool _isPunching = false;
  DateTime? _punchStartTime;
  Timer? _punchTimer;
  late _PunchBag _punchBag;
  final List<_DamageNumber> _damageNumbers = [];

  // Box Physics
  final List<_Box> _boxes = [
    _Box(x: 800, width: 90, height: 90),
  ];
  
  late Ticker _ticker;
  final Duration _lastElapsed = Duration.zero;

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
    
    // Aggressive landscape and immersive mode for "Game" feel
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

    // Init Punch Bag
    _punchBag = _PunchBag(x: 1000); // Put it at 100m

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
    if (_loading || _isPaused) return;
    
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
          _grabbedBox!.x = _playerWorldX + 20; // playerW/2
          _flip = false; // face the box
        } else {
          _grabbedBox!.x = _playerWorldX - 20 - _grabbedBox!.width;
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
        double playerW = 40; 
        double playerH = 110; 
        
        bool overlapX = (_playerWorldX + playerW/2 > box.x) && (_playerWorldX - playerW/2 < box.x + box.width);
        bool overlapY = (_playerY + playerH > box.y) && (_playerY < box.y + box.height);

        if (overlapX && overlapY) {
          // Check if landing on top (with a bit more tolerance for grounded state)
          if (_velocityY <= 0 && _playerY > box.y + box.height * 0.5) {
            _playerY = box.y + box.height;
            _velocityY = 0;
            _isJumping = false;
            groundedOnBox = true;
          } 
          // Solid Block (No auto-push)
          else {
            if (_playerWorldX < box.x) {
              _playerWorldX = box.x - playerW/2;
            } else {
              _playerWorldX = box.x + box.width + playerW/2;
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

          bool overlapX = (b1.x + b1.width > b2.x) && (b1.x < b2.x + b2.width);
          bool overlapY = (b1.y + b1.height > b2.y) && (b1.y < b2.y + b2.height);

          if (overlapX && overlapY) {
            // Horizontal Resolution (Push apart)
            if (b1.x < b2.x) {
              double overlap = (b1.x + b1.width) - b2.x;
              b1.x -= overlap / 2;
              b2.x += overlap / 2;
              // Transfer momentum
              double avgVel = (b1.velX + b2.velX) / 2;
              b1.velX = avgVel;
              b2.velX = avgVel;
            } else {
              double overlap = (b2.x + b2.width) - b1.x;
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
          _playerWorldX = _grabbedBox!.x - 20;
        } else {
          _playerWorldX = _grabbedBox!.x + _grabbedBox!.width + 20;
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
        double playerW = 40;
        double playerH = 110;
        for (var box in _boxes) {
          bool overlapY = (_playerY + playerH > box.y) && (_playerY < box.y + box.height);
          if (!overlapY) continue;
          
          if ((_playerWorldX + playerW/2) >= box.x - 15 && (_playerWorldX + playerW/2) <= box.x + box.width/2) {
              _canGrab = true;
              break;
          } else if ((_playerWorldX - playerW/2) <= box.x + box.width + 15 && (_playerWorldX - playerW/2) >= box.x + box.width/2) {
              _canGrab = true;
              break;
          }
        }
      }

      // 8. Constraints
      if (_playerWorldX < 20) {
        _playerWorldX = 20;
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

      // 7. Hit Detection (Only on the last frame of the punch)
      if (_isPunching && _punchStartTime != null) {
        final elapsed = DateTime.now().difference(_punchStartTime!).inMilliseconds;
        // Last frame (frame 6) starts at roughly 420ms (500ms / 6 frames)
        if (elapsed > 420) {
          // Attack Box check
          double playerW = 40;
          double attackReach = 60;
          double attackX = _flip 
              ? _playerWorldX - playerW/2 - attackReach 
              : _playerWorldX + playerW/2;
          
          Rect attackRect = Rect.fromLTWH(attackX, _playerY + 40, attackReach, 40);
          Rect bagRect = Rect.fromLTWH(_punchBag.x, _punchBag.y, 60, 140);
          
          if (attackRect.overlaps(bagRect) && !_punchBag.isHit) {
             _punchBag.hit(_flip ? -1 : 1);
             _damageNumbers.add(_DamageNumber(
               x: _punchBag.x + 30, 
               y: _punchBag.y + 100, 
               damage: 10 + (canRun ? 15 : 0) // Extra damage if running
             ));
          }
        }
      }
    });
  }

  String _getCurrentAnimation() {
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
    if (_isPunching) return 'Punch01';
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
    if (_isPunching || _grabbedBox != null) return;
    
    setState(() {
      _isPunching = true;
      _punchStartTime = DateTime.now();
      _punchBag.isHit = false; // Reset hit flag for this punch
    });

    _punchTimer?.cancel();
    _punchTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isPunching = false);
    });
  }

  void _startGrab() {
    if (!_isGrounded) return; // Only grab on ground
    setState(() {
      _isGrabbing = true;
      double playerW = 40;
      double playerH = 110;
      
      for (var box in _boxes) {
        bool overlapY = (_playerY + playerH > box.y) && (_playerY < box.y + box.height);
        if (!overlapY) continue;
        
        // Is player touching left side? (Within 10px tolerance)
        if ((_playerWorldX + playerW/2) >= box.x - 10 && (_playerWorldX + playerW/2) <= box.x + box.width/2) {
            _grabbedBox = box;
            _grabSide = 1;
            break;
        }
        // Is player touching right side?
        else if ((_playerWorldX - playerW/2) <= box.x + box.width + 10 && (_playerWorldX - playerW/2) >= box.x + box.width/2) {
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
        bool overlapY = (current.y + current.height > other.y) && (current.y < other.y + other.height);
        if (!overlapY) continue;

        bool touching = false;
        if (direction >= 0) { // Moving right
           touching = (current.x + current.width >= other.x - 10) && (current.x < other.x + 5);
        } else { // Moving left
           touching = (other.x + other.width >= current.x - 10) && (other.x < current.x + 5);
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
          onPopInvoked: (didPop) {
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
                            top: box.y - box.height,
                            left: box.x - _cameraX,
                            child: Transform.scale(
                              scaleY: -1,
                              alignment: Alignment.bottomCenter,
                              child: Opacity(
                                opacity: 0.15,
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                                  child: Container(
                                    width: box.width,
                                    height: box.height,
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
                                      child: Player(
                                        animation: _getCurrentAnimation(),
                                        size: 240,
                                        fps: _isRunning ? 14 : (_isPushingBox || _isPullingBox ? 8 : 10),
                                        loop: !_isJumping,
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
                    child: Container(
                      width: box.width,
                      height: box.height,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF795548), Color(0xFF4E342E)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF2D1B18), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(4, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 0,
                            offset: const Offset(-2, -2),
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Inner Panel Look
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 2),
                                color: Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          // Crate Details (X-Beams & Studs)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _CratePainter(),
                            ),
                          ),
                          if (_showColliders)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.yellow, width: 3),
                                boxShadow: [
                                  BoxShadow(color: Colors.yellow.withValues(alpha: 0.3), blurRadius: 10),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),


                // Punch Bag
                Positioned(
                  bottom: _groundY + _punchBag.y,
                  left: _punchBag.x - _cameraX,
                  child: Transform.rotate(
                    angle: _punchBag.rotation,
                    alignment: Alignment.topCenter,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Detailed Chain
                        Positioned(
                          top: -30,
                          left: 20,
                          child: Column(
                            children: [
                              Container(width: 6, height: 12, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
                              Container(width: 4, height: 20, color: Colors.grey[700]),
                            ],
                          ),
                        ),
                        // The Bag
                        Container(
                          width: 46,
                          height: 105,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFD32F2F), 
                                const Color(0xFFB71C1C),
                                const Color(0xFF8E0000),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.8), width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(3, 6)),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Leather Highlights
                              Positioned(
                                left: 6, top: 10,
                                child: Container(
                                  width: 4, height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Bottom Weight Cap
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                                  ),
                                ),
                              ),
                              // Label
                              const Center(
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text('GAINZ', style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                ),
                              ),
                              if (_showColliders)
                                Container(
                                  decoration: BoxDecoration(border: Border.all(color: Colors.yellow, width: 2)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                if (_showColliders && _isPunching)
                  Positioned(
                    bottom: _groundY + _playerY + 40,
                    left: (_flip 
                        ? _playerWorldX - 20 - 60 
                        : _playerWorldX + 20) - _cameraX,
                    child: Container(
                      width: 60,
                      height: 40,
                      color: Colors.red.withValues(alpha: 0.4),
                    ),
                  ),

                // Player
                Positioned(
                  bottom: _groundY + _playerY, 
                  left: playerScreenX - 20, 
                  child: Container(
                    width: 40,
                    height: 110,
                    decoration: BoxDecoration(
                      border: _showColliders 
                          ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2)
                          : null,
                      boxShadow: _showColliders 
                          ? [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 10)]
                          : null,
                    ),
                    child: OverflowBox(
                      maxWidth: 240,
                      maxHeight: 240,
                      alignment: Alignment.bottomCenter,
                      child: Transform.scale(
                        scaleX: _flip ? -1 : 1,
                        child: Player(
                          animation: _getCurrentAnimation(),
                          size: 240,
                          fps: _isRunning ? 14 : (_isPushingBox || _isPullingBox ? 8 : 10),
                          loop: !_isJumping,
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


                // UI - Minimap & Collider Toggle (Top Right)
                Positioned(
                  top: 30,
                  right: 30,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Collider Toggle (Square Icon Only)
                      SGTouchable(
                        onTap: () => setState(() => _showColliders = !_showColliders),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
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
                                              left: box.x * 0.12 - (box.width * 0.06),
                                              bottom: 8,
                                              child: Container(
                                                width: box.width * 0.12,
                                                height: box.height * 0.12,
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
                          _grabPressed = true;
                          if (_isGrounded) _startGrab();
                        },
                        onPointerUp: (_) {
                          _grabPressed = false;
                          _endGrab();
                        },
                        onPointerCancel: (_) {
                          _grabPressed = false;
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

                // UI - Run Button (Secondary)
                Positioned(
                  bottom: 30,
                  right: 124,
                  child: Listener(
                    onPointerDown: (_) {
                      _runPressed = true;
                      if (_isGrounded && _grabbedBox == null) setState(() => _isRunning = true);
                    },
                    onPointerUp: (_) {
                      _runPressed = false;
                      setState(() => _isRunning = false);
                    },
                    onPointerCancel: (_) {
                      _runPressed = false;
                      setState(() => _isRunning = false);
                    },
                    child: AnimatedScale(
                      scale: _runPressed ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 64,
                        height: 64,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: _isRunning ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.8), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: _isRunning ? 0.4 : 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: OverflowBox(
                          maxWidth: 240,
                          maxHeight: 240,
                          child: Transform.translate(
                            offset: const Offset(0, -26), // Shift up to counteract the sprite's bottom alignment
                            child: Transform.scale(
                              scale: 1.5, // Make him much bigger
                              child: _isRunning
                                ? Player(
                                    animation: 'Run',
                                    fps: 14,
                                    size: 140,
                                    alignment: Alignment.center,
                                  )
                                : Image.asset(
                                    'Assets/Player Model/Run/Run04.png',
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

                // UI - Joystick (Held to the end of stack for touch priority)
                Positioned(
                  bottom: 30,
                  left: 40,
                  child: Row(
                    children: [
                      // Left Button
                      Listener(
                        onPointerDown: (_) => setState(() => _leftPressed = true),
                        onPointerUp: (_) => setState(() => _leftPressed = false),
                        onPointerCancel: (_) => setState(() => _leftPressed = false),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _leftPressed ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: _leftPressed ? 0.3 : 0.05),
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
                        onPointerDown: (_) => setState(() => _rightPressed = true),
                        onPointerUp: (_) => setState(() => _rightPressed = false),
                        onPointerCancel: (_) => setState(() => _rightPressed = false),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _rightPressed ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: _rightPressed ? 0.3 : 0.05),
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
                                    await _doorCtrl.reverse();
                                    if (mounted) {
                                      SystemChrome.setPreferredOrientations([
                                        DeviceOrientation.portraitUp,
                                      ]);
                                      Navigator.pop(context);
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

class _InfiniteGrid extends StatelessWidget {
  final double cameraX;
  const _InfiniteGrid({required this.cameraX});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(cameraX),
    );
  }
}
class _Box {
  double x;
  double y = 0.0;
  double width;
  double height;
  double velX = 0.0;
  double velY = 0.0;

  double get weight => 10.0; // Standard 10kg weight as requested

  _Box({
    required this.x,
    required this.width,
    required this.height,
  });
}

class _PunchBag {
  double x;
  double y = 15.0; // Lowered as requested
  double rotation = 0.0;
  double rotationVel = 0.0;
  bool isHit = false;

  _PunchBag({required this.x});

  void hit(double dir) {
    rotationVel = dir * 0.4;
    isHit = true;
  }

  void update() {
    // Pendulum physics (Wobble)
    double gravity = 0.015;
    rotationVel -= rotation * gravity;
    rotationVel *= 0.98; // Friction
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

class _GridPainter extends CustomPainter {
  final double cameraX;
  _GridPainter(this.cameraX);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const double step = 60.0;
    double offset = -(cameraX % step);

    for (double x = offset; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.cameraX != cameraX;
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

    final detailPaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Main X-Beam
    canvas.drawLine(const Offset(10, 10), Offset(size.width - 10, size.height - 10), framePaint);
    canvas.drawLine(Offset(size.width - 10, 10), Offset(10, size.height - 10), framePaint);

    // Corner Studs (Metal nails)
    final studPaint = Paint()..color = const Color(0xFFBDBDBD).withValues(alpha: 0.3);
    const double s = 6.0;
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
