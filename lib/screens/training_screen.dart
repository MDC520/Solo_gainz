import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import '../theme/theme.dart';
import '../widgets/player.dart';
import '../background.dart';

class TrainingScreen extends StatefulWidget {
  final bool isLoading;
  const TrainingScreen({super.key, this.isLoading = false});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> with SingleTickerProviderStateMixin {
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
  bool _showColliders = true;

  // Grabbing State
  bool _isGrabbing = false;
  bool _canGrab = false;
  _Box? _grabbedBox;
  int _grabSide = 0; 
  bool _isPushingBox = false;
  bool _isPullingBox = false;

  // Box Physics
  final List<_Box> _boxes = [
    _Box(x: 800, width: 80, height: 80),
    _Box(x: 1500, width: 100, height: 100),
    _Box(x: 2500, width: 60, height: 60),
    _Box(x: 2600, width: 80, height: 80),
  ];
  
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Physics constants
  static const double _acceleration = 0.2;
  static const double _maxWalkSpeed = 6.0; // Normal move
  static const double _maxRunSpeed = 12.0; // Normal run
  static const double _gravity = -0.8;
  static const double _jumpForce = 15.0;
  
  // Camera/World logic
  double _cameraX = 0;
  final double _groundY = 60.0; 
  final double _mapWidth = 10000.0;

  @override
  void initState() {
    super.initState();
    
    // Aggressive landscape and immersive mode for "Game" feel
    _setupGameMode();

    if (widget.isLoading) {
      Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _loading = false);
      });
    } else {
      _loading = false;
    }

    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    if (_loading) return;
    
    setState(() {
      // 1. Horizontal Physics (Player)
      double targetVel = _joystickInputX * (_isRunning ? _maxRunSpeed : _maxWalkSpeed);
      if (_grabbedBox != null) {
        double weight = _grabbedBox!.weight;
        double speedMod = (1.0 / weight).clamp(0.2, 0.9); // Heavy = slow, max 0.9
        targetVel = _joystickInputX * (_maxWalkSpeed * speedMod);
        
        // Extra stamina drain when moving heavy objects
        if (_velocityX.abs() > 0.1) {
            _stamina -= (0.001 * weight);
        }
      }
      _velocityX = lerpDouble(_velocityX, targetVel, 0.3)!;
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
        _velocityY += _gravity;
        _playerY += _velocityY;
        
        if (_playerY <= 0) {
          _playerY = 0;
          _velocityY = 0;
          _isJumping = false;
        }
      }

      // 3. Box Physics & Collision
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
          // Check if landing on top
          if (_velocityY < 0 && _playerY > box.y + box.height * 0.7) {
            _playerY = box.y + box.height;
            _velocityY = 0;
            _isJumping = false;
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
      if (_isRunning && _isMoving) {
        _stamina -= 0.006; // Drains in ~3 seconds of sprinting
        if (_stamina <= 0) {
          _stamina = 0;
          _isRunning = false; // Forced walk
        }
      } else {
        _stamina += 0.004; // Recovers in ~4 seconds
        if (_stamina > 1.0) _stamina = 1.0;
      }

      // 6. Movement states
      _isMoving = _velocityX.abs() > 0.1;
      if (_joystickInputX < 0) _flip = true;
      if (_joystickInputX > 0) _flip = false;

      // 7. Check Grab Proximity
      _canGrab = false;
      if (!_isGrabbing && _playerY == 0) {
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

      // 6. Smooth Camera follow
      final size = MediaQuery.of(context).size;
      final orientation = MediaQuery.of(context).orientation;
      double screenW = orientation == Orientation.portrait ? size.height : size.width;
      
      double targetCameraX = _playerWorldX - (screenW * 0.4);
      if (targetCameraX < 0) targetCameraX = 0;
      _cameraX = lerpDouble(_cameraX, targetCameraX, 0.12)!;
    });
  }

  String _getCurrentAnimation() {
    if (_isJumping || _playerY > 0) {
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
    if (!_isJumping) {
      setState(() {
        _isJumping = true;
        _velocityY = _jumpForce;
      });
    }
  }

  void _startGrab() {
    if (_playerY > 0) return; // Only grab on ground
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
    _ticker.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Reset orientation to portrait when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _onJoystickUpdate(double dx) {
    setState(() {
      _joystickInputX = dx;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppTheme.accent,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'loading ...',
                style: AppTheme.mono(color: AppTheme.accent, size: 20).copyWith(letterSpacing: 2),
              ),
            ],
          ),
        ),
      );
    }

    double playerScreenX = _playerWorldX - _cameraX;

    return OrientationBuilder(
      builder: (context, orientation) {
        bool isPortrait = orientation == Orientation.portrait;
        
        Widget gameView = PopScope(
          onPopInvoked: (didPop) {
            if (didPop) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.bg,
            body: Stack(
              children: [
                // Living Notebook Background
                Positioned.fill(
                  child: LivelyBackground(
                    isMoving: _isMoving,
                    child: Container(),
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
                      color: AppTheme.surface.withValues(alpha: 0.9), // Dark Grey/Surface
                      border: Border(
                        top: BorderSide(color: AppTheme.accent, width: 3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, -5),
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
                        color: const Color(0xFF5D4037), // Dark Wood Brown
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF3E2723), width: 3), // Reinforced Edge
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(2, 2)),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Crate Cross Beams
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _CratePainter(),
                            ),
                          ),
                          // The Yellow Collider (Visible only if toggled)
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

                // Minimap
                Positioned(
                  top: 30,
                  right: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('MINIMAP', style: AppTheme.label(color: AppTheme.text2).copyWith(fontSize: 10)),
                      const SizedBox(height: 8),
                      Container(
                        width: 220,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Stack(
                          children: [
                            // Map markers
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 2, color: AppTheme.red), // Left boundary
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 2, color: AppTheme.cyan), // Right boundary (Blue Wall)
                            ),
                            // Player indicator
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 100),
                              left: (_playerWorldX / _mapWidth * 210).clamp(0, 210),
                              top: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_playerWorldX / 10).floor()}m',
                        style: AppTheme.mono(color: AppTheme.accent, size: 12),
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
                        onTap: () {
                           SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                          ]);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: const Icon(Icons.close_rounded, color: AppTheme.white, size: 24),
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_stamina < 0.25 ? AppTheme.red : AppTheme.accent).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
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

                // UI - Debug Toggle (Top Center)
                Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SGTouchable(
                      onTap: () => setState(() => _showColliders = !_showColliders),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _showColliders ? AppTheme.accent : AppTheme.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showColliders ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: _showColliders ? AppTheme.accent : AppTheme.text2,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'COLLIDERS',
                              style: AppTheme.label(color: _showColliders ? AppTheme.accent : AppTheme.text2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // UI - Grab Button (Action)
                Positioned(
                  bottom: 140, // Moved above Jump button
                  right: 60,   // Aligned right
                  child: AnimatedOpacity(
                    opacity: (_canGrab || _isGrabbing) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !(_canGrab || _isGrabbing),
                      child: GestureDetector(
                        onTapDown: (_) => _startGrab(),
                        onTapUp: (_) => _endGrab(),
                        onTapCancel: () => _endGrab(),
                        child: AnimatedScale(
                          scale: _isGrabbing ? 0.9 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _isGrabbing ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
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
                                Icons.pan_tool_rounded,
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
                  bottom: 110,
                  right: 140,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isRunning = true),
                    onTapUp: (_) => setState(() => _isRunning = false),
                    onTapCancel: () => setState(() => _isRunning = false),
                    child: AnimatedScale(
                      scale: _isRunning ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _isRunning ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.8), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: _isRunning ? 0.4 : 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.directions_run_rounded,
                            color: _isRunning ? Colors.black : AppTheme.accent,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // UI - Jump Button (Primary)
                Positioned(
                  bottom: 50,
                  right: 60,
                  child: GestureDetector(
                    onTapDown: (_) => _jump(),
                    child: AnimatedScale(
                      scale: _isJumping ? 0.85 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: _isJumping ? AppTheme.cyan : AppTheme.surface.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.8), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.cyan.withValues(alpha: 0.3),
                              blurRadius: _isJumping ? 20 : 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.keyboard_double_arrow_up_rounded,
                            color: _isJumping ? Colors.black : AppTheme.cyan,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // UI - Joystick (Held to the end of stack for touch priority)
                Positioned(
                  bottom: 40,
                  left: 40,
                  child: Joystick(
                    mode: JoystickMode.horizontal,
                    listener: (details) => _onJoystickUpdate(details.x),
                    base: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 2),
                      ),
                    ),
                    stick: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (isPortrait) {
          return RotatedBox(
            quarterTurns: 1,
            child: gameView,
          );
        }
        return gameView;
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
  double y;
  double width;
  double height;
  double velX;
  double velY;

  double get weight => (width * height) / 6400.0; // 80x80 is weight 1.0

  _Box({
    required this.x,
    this.y = 0.0,
    required this.width,
    required this.height,
    this.velX = 0.0,
    this.velY = 0.0,
  });
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

class _CratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3E2723).withValues(alpha: 0.5)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Draw X cross-beams
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
