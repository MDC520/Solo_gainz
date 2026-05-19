import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'player.dart';

// Helper to convert IP string to dynamic 8-character Hex Join Code
String ipToJoinCode(String ip) {
  try {
    final parts = ip.split('.');
    if (parts.length != 4) return 'SOLOPVP1';
    return parts.map((p) => int.parse(p).toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  } catch (_) {
    return 'SOLOPVP1';
  }
}

// Convert Hex Join Code back to raw IP Address
String joinCodeToIp(String code) {
  try {
    final clean = code.trim().toUpperCase();
    if (clean.length != 8) return '';
    final parts = <int>[];
    for (int i = 0; i < 8; i += 2) {
      parts.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return parts.join('.');
  } catch (_) {
    return '';
  }
}

// Model representing a local dynamic discovered room
class PvpRoom {
  final String roomName;
  final String ip;
  final int port;
  final int widthMeters;
  final bool requiresPassword;
  final String passwordHash;
  final int maxPlayers;
  final int currentPlayers;
  final String joinCode;

  PvpRoom({
    required this.roomName,
    required this.ip,
    required this.port,
    required this.widthMeters,
    required this.requiresPassword,
    required this.passwordHash,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.joinCode,
  });

  factory PvpRoom.fromJson(Map<String, dynamic> json) {
    return PvpRoom(
      roomName: json['roomName'] ?? 'Unnamed Arena',
      ip: json['ip'] ?? '127.0.0.1',
      port: json['port'] ?? 4545,
      widthMeters: json['width'] ?? 200,
      requiresPassword: json['requiresPassword'] ?? false,
      passwordHash: json['passwordHash'] ?? '',
      maxPlayers: json['maxPlayers'] ?? 2,
      currentPlayers: json['currentPlayers'] ?? 1,
      joinCode: json['joinCode'] ?? '',
    );
  }
}

// Dynamic Floating Damage Numbers Model
class _PvpDamageNumber {
  final double x;
  double y;
  final int amount;
  double opacity = 1.0;
  final double velocityX;
  double velocityY = -4.0;

  _PvpDamageNumber({
    required this.x,
    required this.y,
    required this.amount,
    required this.velocityX,
  });

  void update() {
    y += velocityY;
    velocityY += 0.15; // Gravity on text
    opacity = (opacity - 0.02).clamp(0.0, 1.0);
  }
}

class PvpScreen extends StatefulWidget {
  const PvpScreen({super.key});

  @override
  State<PvpScreen> createState() => _PvpScreenState();
}

class _PvpScreenState extends State<PvpScreen> with SingleTickerProviderStateMixin {
  // Navigation Tabs: 'lobby' or 'game'
  String _currentScreen = 'lobby';
  String _activeTab = 'host'; // 'host' or 'browse'

  // Host Configuration states
  final TextEditingController _hostRoomNameCtrl = TextEditingController();
  final TextEditingController _hostPasswordCtrl = TextEditingController();
  double _hostRoomWidthMeters = 200.0; // Slider min 200, max 1000
  int _hostMaxPlayers = 2; // 1 or 2

  // Join Configuration states
  final TextEditingController _manualJoinCodeCtrl = TextEditingController();
  final TextEditingController _joinPasswordCtrl = TextEditingController();
  final Map<String, Map<String, dynamic>> _discoveredRooms = {}; // Scanned UDP local rooms

  // Networking variables
  ServerSocket? _tcpServer;
  Socket? _gameSocket;
  RawDatagramSocket? _udpBroadcastSocket;
  RawDatagramSocket? _udpListenerSocket;
  Timer? _udpBroadcastTimer;
  String _localIp = '127.0.0.1';
  bool _isConnecting = false;
  bool _isHost = false;

  // Lobby Loading message
  String _lobbyStatus = '';

  // 60FPS Game loop variables
  late Ticker _ticker;
  double _screenWidth = 800.0;
  double _screenHeight = 400.0;
  double _cameraX = 0.0;
  double _mapWidth = 3000.0; // roomWidthMeters * 15 (e.g. 200m = 3000px)
  final double _groundY = 120.0; // Ground elevation from bottom

  // Player 1 (Local) states
  double _playerX = 200.0;
  double _playerY = 0.0;
  double _playerVx = 0.0;
  double _playerVy = 0.0;
  bool _playerFlip = false;
  int _playerHp = 100;
  bool _playerGrounded = true;
  bool _playerHit = false;

  // Player 2 (Remote) states
  double _remoteX = 2800.0;
  double _remoteY = 0.0;
  bool _remoteFlip = true;
  String _remoteAnim = 'Idle';
  int _remoteHp = 100;
  bool _remoteHit = false;

  // Action variables
  bool _isPunching = false;
  DateTime? _punchStartTime;
  bool _isKicking = false;
  DateTime? _kickStartTime;
  final List<_PvpDamageNumber> _damageNumbers = [];

  // Controls UI mappings
  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _jumpPressed = false;
  bool _attackPressed = false;
  bool _kickPressed = false;

  // Double-tap running
  DateTime? _lastLeftDown;
  DateTime? _lastRightDown;
  static const _doubleTapThreshold = Duration(milliseconds: 250);
  bool _isRunning = false;

  // Dynamic animations mapping
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _setupLobby();

    // 60fps local engine simulator
    _ticker = Ticker(_gameTick);
  }

  // Helper to determine the subnet broadcast IP to bypass strict router blocks
  String getSubnetBroadcast(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length == 4) {
        parts[3] = '255';
        return parts.join('.');
      }
    } catch (_) {}
    return '255.255.255.255';
  }

  // Get local WiFi IP address securely, prioritizing WiFi/WLAN interfaces
  Future<void> _setupLobby() async {
    try {
      String? foundIp;
      final interfaces = await NetworkInterface.list();
      
      // First pass: look specifically for wifi/wlan/ethernet interfaces
      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') || name.contains('wifi') || name.contains('eth')) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              foundIp = addr.address;
              break;
            }
          }
        }
        if (foundIp != null) break;
      }
      
      // Second pass: fallback to any non-loopback IPv4 if no active wifi interface was matched
      if (foundIp == null) {
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              foundIp = addr.address;
              break;
            }
          }
          if (foundIp != null) break;
        }
      }

      if (foundIp != null) {
        setState(() {
          _localIp = foundIp!;
        });
      }
    } catch (_) {}
    _startUdpDiscovery();
  }

  // Raw UDP Discovery listener (Joiner)
  Future<void> _startUdpDiscovery() async {
    try {
      _udpListenerSocket?.close();
      _udpListenerSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4546, reuseAddress: true);
      _udpListenerSocket!.broadcastEnabled = true;
      _udpListenerSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpListenerSocket!.receive();
          if (datagram != null) {
            try {
              final rawStr = utf8.decode(datagram.data);
              final Map<String, dynamic> room = jsonDecode(rawStr);
              final ip = room['ip'] ?? '';
              if (ip.isNotEmpty && ip != _localIp) {
                setState(() {
                  _discoveredRooms[ip] = room;
                });
              }
            } catch (_) {}
          }
        }
      });
    } catch (_) {}
  }

  // 1. HOST ROOM INITIATION
  Future<void> _hostRoom() async {
    if (_isConnecting) return;

    _isHost = true;
    _mapWidth = _hostRoomWidthMeters * 15.0; // 1m = 15px

    // Host spawns left, Client spawns right
    _playerX = 200.0;
    _remoteX = _mapWidth - 200.0;
    _playerHp = 100;
    _remoteHp = 100;
    _playerFlip = false;
    _remoteFlip = true;

    if (_hostMaxPlayers == 1) {
      // Solo Practice Mode: Transition directly to game arena without opening networking loops
      setState(() {
        _isConnecting = false;
        _lobbyStatus = '';
        _currentScreen = 'game';
      });

      // Lock landscape left/right viewport orientations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      // Launch core engine tick simulation
      _ticker.start();
      return;
    }

    setState(() {
      _isConnecting = true;
      _lobbyStatus = 'Binding local port 4545...';
    });

    try {
      // Bind TCP server on port 4545
      _tcpServer?.close();
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, 4545, shared: true);
      
      // Broadcast room availability via UDP every 1.5 seconds on port 4546
      _udpBroadcastSocket?.close();
      _udpBroadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, reuseAddress: true);
      _udpBroadcastSocket!.broadcastEnabled = true;
      
      _udpBroadcastTimer?.cancel();
      _udpBroadcastTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        final data = jsonEncode({
          "roomName": _hostRoomNameCtrl.text.isEmpty ? 'Cyber Arena' : _hostRoomNameCtrl.text,
          "ip": _localIp,
          "port": 4545,
          "width": _hostRoomWidthMeters.toInt(),
          "requiresPassword": _hostPasswordCtrl.text.isNotEmpty,
          "passwordHash": _hostPasswordCtrl.text,
          "maxPlayers": _hostMaxPlayers,
          "currentPlayers": 1,
          "joinCode": ipToJoinCode(_localIp),
        });
        final bytes = utf8.encode(data);
        
        // Target 1: Global subnet broadcast (255.255.255.255)
        try {
          _udpBroadcastSocket!.send(
            bytes, 
            InternetAddress('255.255.255.255'), 
            4546
          );
        } catch (_) {}

        // Target 2: Directed subnet broadcast (e.g. 192.168.1.255) for strict routers
        try {
          final subnetBroadcast = getSubnetBroadcast(_localIp);
          if (subnetBroadcast != '255.255.255.255') {
            _udpBroadcastSocket!.send(
              bytes,
              InternetAddress(subnetBroadcast),
              4546
            );
          }
        } catch (_) {}
      });

      setState(() {
        _lobbyStatus = 'Room created! Waiting for players on Code: ${ipToJoinCode(_localIp)}';
      });

      // Await client TCP socket connection
      _tcpServer!.listen((socket) {
        _udpBroadcastTimer?.cancel();
        _udpBroadcastSocket?.close();
        _gameSocket = socket;
        _setupGameConnection();
      });

    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(context, 'Failed to host room: $e', isError: true);
      }
      setState(() {
        _isConnecting = false;
        _lobbyStatus = '';
      });
    }
  }

  // 2. JOIN ROOM CONNECTION
  Future<void> _joinRoom(String ip, String expectedPassword) async {
    if (_isConnecting) return;
    
    // Check password if required
    if (expectedPassword.isNotEmpty && _joinPasswordCtrl.text != expectedPassword) {
      AppTheme.showSnackBar(context, 'Invalid room password!', isError: true);
      return;
    }

    setState(() {
      _isConnecting = true;
      _lobbyStatus = 'Connecting to host $ip...';
    });

    try {
      _gameSocket = await Socket.connect(ip, 4545).timeout(const Duration(seconds: 8));
      _isHost = false;

      // Spawning layouts
      _playerHp = 100;
      _remoteHp = 100;

      _setupGameConnection();

    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(context, 'Connection timeout or failed: $e', isError: true);
      }
      setState(() {
        _isConnecting = false;
        _lobbyStatus = '';
      });
    }
  }

  // 3. SETTING UP ACTIVE TCP GAME SOCKET
  void _setupGameConnection() {
    setState(() {
      _isConnecting = false;
      _currentScreen = 'game';
      _lobbyStatus = '';
    });

    // Enforce full horizontal gameplay overlays
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initial state exchanges
    _sendStatePacket();

    // Stream listener splitting bytes by newline delimiters
    _gameSocket!.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        _handleGamePacket(line);
      },
      onError: (e) {
        _disconnectAndReturn('Socket error: $e');
      },
      onDone: () {
        _disconnectAndReturn('Opponent disconnected.');
      },
    );

    // Launch core engine loop
    _ticker.start();
  }

  // Game state packet processing
  void _handleGamePacket(String raw) {
    try {
      final Map<String, dynamic> data = jsonDecode(raw);

      // Width exchange
      if (data.containsKey('roomWidth')) {
        setState(() {
          _mapWidth = (data['roomWidth'] as num).toDouble();
        });
        if (!_isHost) {
          // Client spawns on the right of the host's map setting
          setState(() {
            _playerX = _mapWidth - 200.0;
            _remoteX = 200.0;
            _playerFlip = true;
            _remoteFlip = false;
          });
        }
      }

      // Positional coordinates sync
      if (data.containsKey('x')) {
        setState(() {
          _remoteX = (data['x'] as num).toDouble();
          _remoteY = (data['y'] as num).toDouble();
          _remoteFlip = data['flip'] ?? false;
          _remoteAnim = data['anim'] ?? 'Idle';
          _remoteHp = data['hp'] ?? 100;
        });
      }

      // Hit vector calculations triggered remotely
      if (data.containsKey('event') && data['event'] == 'hit') {
        final double damage = (data['damage'] as num).toDouble();
        final double direction = (data['dir'] as num).toDouble();

        setState(() {
          _playerHp = (_playerHp - damage.toInt()).clamp(0, 100);
          _playerHit = true;
          _playerVy = 2.0; // slight hop on damage impact
          _playerVx = direction * 8.0; // knockback recoil
        });

        // Add visual floating damage number
        _damageNumbers.add(_PvpDamageNumber(
          x: _playerX,
          y: _screenHeight - _groundY - _playerY - 80,
          amount: damage.toInt(),
          velocityX: direction * 2.0 + (math.Random().nextDouble() - 0.5),
        ));

        AppTheme.heavy();

        Timer(const Duration(milliseconds: 350), () {
          if (mounted) setState(() => _playerHit = false);
        });
      }

    } catch (_) {}
  }

  // Bidirectional high frequency status write
  void _sendStatePacket() {
    if (_gameSocket == null) return;
    try {
      final state = {
        "x": _playerX,
        "y": _playerY,
        "vx": _playerVx,
        "vy": _playerVy,
        "flip": _playerFlip,
        "anim": _getCurrentAnimation(),
        "hp": _playerHp,
      };

      // If Host, also enforce map size constraints on joiner
      if (_isHost) {
        state["roomWidth"] = _mapWidth;
      }

      _gameSocket!.write('${jsonEncode(state)}\n');
    } catch (_) {}
  }

  // Disconnection cleanup and transition portal
  void _disconnectAndReturn(String message) {
    _ticker.stop();
    _gameSocket?.close();
    _tcpServer?.close();
    _udpBroadcastTimer?.cancel();
    _udpBroadcastSocket?.close();

    _gameSocket = null;
    _tcpServer = null;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      AppTheme.showSnackBar(context, message);
      setState(() {
        _currentScreen = 'lobby';
        _isConnecting = false;
        _discoveredRooms.clear();
      });
      _startUdpDiscovery();
    }
  }

  // Core 60fps Game Tick Loop
  void _gameTick(Duration elapsed) {
    if (!mounted || _currentScreen != 'game') return;

    setState(() {
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;

      // ── Horizontal Physics (100% match with training_screen.dart) ──
      bool canRun = _isRunning && _playerGrounded && !_isPunching && !_isKicking && !_playerHit;
      double accel = canRun ? 0.8 : 0.4;
      if (!_playerGrounded) accel *= 0.4; // Air control penalty

      double joystickInput = (_rightPressed ? 1.0 : 0.0) - (_leftPressed ? 1.0 : 0.0);
      
      // Lock movement when attacking or hit
      if (_isPunching || _isKicking || _playerHit) {
        joystickInput = 0;
        _playerVx = 0;
      }

      if (joystickInput.abs() > 0.1) {
        _playerVx += joystickInput * accel;
      } else {
        _playerVx *= (_playerGrounded ? 0.88 : 0.96); // Ground friction vs air drag
      }

      double maxSpeed = canRun ? 7.5 : 3.5;
      if (_playerVx.abs() > maxSpeed) {
        _playerVx = _playerVx.sign * maxSpeed;
      }

      _playerX += _playerVx;

      // ── Vertical Physics (Gravity & Jump 100% match with training_screen.dart) ──
      if (!_playerGrounded || _playerY > 0) {
        double currentGravity = -1.4;
        if (_playerVy < 0) currentGravity *= 1.6; // Stronger gravity on descent

        _playerVy += currentGravity;
        _playerY += _playerVy;

        if (_playerY <= 0) {
          _playerY = 0;
          _playerVy = 0;
          _playerGrounded = true;
          _isKicking = false;
        }
      }

      // ── Solid Player-vs-Player Body Colliders ──
      if (_hostMaxPlayers == 2 && !_playerHit) {
        double pLeft = _playerX - 20.0;
        double pRight = _playerX + 20.0;
        double pBottom = _playerY;
        double pTop = _playerY + 103.0;

        double rLeft = _remoteX - 20.0;
        double rRight = _remoteX + 20.0;
        double rBottom = _remoteY;
        double rTop = _remoteY + 103.0;

        bool overlapX = (pRight > rLeft) && (pLeft < rRight);
        bool overlapY = (pTop > rBottom) && (pBottom < rTop);

        if (overlapX && overlapY) {
          // Resolve overlap: push players apart horizontally
          if (pLeft + 20 < rLeft + 20) {
            _playerX = rLeft - 20.0;
          } else {
            _playerX = rRight + 20.0;
          }
          _playerVx = 0;
        }
      }

      // Map limits constraints
      if (_playerX < 20) _playerX = 20;
      if (_playerX > _mapWidth - 20) _playerX = _mapWidth - 20;

      // ── Punch Attack Detection & Sync ──
      if (_isPunching && _punchStartTime != null) {
        final ms = DateTime.now().difference(_punchStartTime!).inMilliseconds;
        // Impact frame (approx frame 3 at 12fps = 250ms)
        if (ms >= 200 && ms <= 280) {
          _checkAttackOverlap(isKick: false);
        }
        if (ms > 500) {
          _isPunching = false;
        }
      }

      // ── Kick Attack Detection & Sync ──
      if (_isKicking && _kickStartTime != null) {
        final ms = DateTime.now().difference(_kickStartTime!).inMilliseconds;
        // Impact frame (approx 350ms)
        if (ms >= 300 && ms <= 385) {
          _checkAttackOverlap(isKick: true);
        }
        if (ms > 700) {
          _isKicking = false;
        }
      }

      // Camera dynamic lerp follow
      double targetCam = _playerX - (_screenWidth * 0.42);
      if (targetCam < 0) targetCam = 0;
      if (targetCam > _mapWidth - _screenWidth) targetCam = _mapWidth - _screenWidth;
      _cameraX = lerpDouble(_cameraX, targetCam, 0.12)!;

      // Update flying damage text physics
      for (var damage in _damageNumbers) {
        damage.update();
      }
      _damageNumbers.removeWhere((d) => d.opacity <= 0.05);
    });

    // Sync state values to other player
    _sendStatePacket();
  }

  // Attack overlap collision box intersections
  void _checkAttackOverlap({required bool isKick}) {
    if (_hostMaxPlayers == 1) return;
    // Render reach constraints
    final double reach = isKick ? 88.0 : 70.0;
    final double heightOffset = isKick ? 30.0 : 45.0;
    final double attackW = isKick ? 80.0 : 90.0;
    final double attackH = 20.0;

    double pCenter = _playerX;
    double attackX = _playerFlip ? pCenter - reach - (attackW / 2) : pCenter + reach - (attackW / 2);

    Rect attackRect = Rect.fromLTWH(
      attackX, 
      _playerY + heightOffset, 
      attackW, 
      attackH
    );

    Rect targetRect = Rect.fromLTWH(
      _remoteX - 25, 
      _remoteY, 
      50, 
      103
    );

    // Overlap verified - transmit dynamic damage event packets to joiner client
    if (attackRect.overlaps(targetRect) && !_remoteHit) {
      final double damageVal = isKick ? 24.0 : 12.0;
      
      // Calculate recoil knockback force direction
      double hitDir = _playerFlip ? -1.0 : 1.0;

      setState(() {
        _remoteHp = (_remoteHp - damageVal.toInt()).clamp(0, 100);
        _remoteHit = true;
      });

      // Sync the hit metrics
      if (_gameSocket != null) {
        try {
          final eventPacket = {
            "event": "hit",
            "damage": damageVal,
            "dir": hitDir,
            "type": isKick ? "kick" : "punch"
          };
          _gameSocket!.write('${jsonEncode(eventPacket)}\n');
        } catch (_) {}
      }

      Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _remoteHit = false);
      });
    }
  }

  // Local Animation state resolver
  String _getCurrentAnimation() {
    if (_playerHit) return 'Hit';
    if (_isKicking) return 'Kick01';
    if (_isPunching) return 'Punch01';
    if (!_playerGrounded) {
      return _playerVy > 0 ? 'Jump' : 'Jump Fall';
    }
    if (_leftPressed || _rightPressed) {
      return _isRunning ? 'Run' : 'Walk';
    }
    return 'Idle';
  }

  // ── Action triggers ──
  void _jump() {
    if (_playerGrounded && !_isPunching && !_isKicking && !_playerHit) {
      setState(() {
        _playerVy = 22.0; // jump upward velocity force
        _playerGrounded = false;
        _isRunning = false;
      });
    }
  }

  void _punch() {
    if (_isPunching || _isKicking || _playerHit || _isRunning) return;
    setState(() {
      _isPunching = true;
      _punchStartTime = DateTime.now();
    });
  }

  void _kick() {
    if (_isPunching || _isKicking || _playerHit || _isRunning) return;
    setState(() {
      _isKicking = true;
      _kickStartTime = DateTime.now();
    });
  }

  // Double tap direction tracker
  void _handleDirectionTap(bool isLeft, bool down) {
    if (down) {
      final now = DateTime.now();
      if (isLeft) {
        if (_lastLeftDown != null && now.difference(_lastLeftDown!) < _doubleTapThreshold) {
          _isRunning = true;
        }
        _lastLeftDown = now;
        _leftPressed = true;
      } else {
        if (_lastRightDown != null && now.difference(_lastRightDown!) < _doubleTapThreshold) {
          _isRunning = true;
        }
        _lastRightDown = now;
        _rightPressed = true;
      }
    } else {
      if (isLeft) {
        _leftPressed = false;
      } else {
        _rightPressed = false;
      }
      if (!_leftPressed && !_rightPressed) {
        _isRunning = false;
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bgCtrl.dispose();
    _udpBroadcastTimer?.cancel();
    _udpBroadcastSocket?.close();
    _udpListenerSocket?.close();
    _tcpServer?.close();
    _gameSocket?.close();
    
    _hostRoomNameCtrl.dispose();
    _hostPasswordCtrl.dispose();
    _manualJoinCodeCtrl.dispose();
    _joinPasswordCtrl.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentScreen == 'game') {
      return _buildGameArena();
    }
    return _buildLobbySetup();
  }

  // ── LOBBY & SETUP VIEW ──
  Widget _buildLobbySetup() {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          // Background design elements
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LobbyBgPainter(_bgCtrl.value),
                );
              },
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (consistent with legacy history_screen styling)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PVP ARENA', style: AppTheme.h1(color: AppTheme.white).copyWith(letterSpacing: 2)),
                          const SizedBox(height: 4),
                          Text('Local WiFi Multiplayer Suite', style: AppTheme.caption(color: AppTheme.text2)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.glassBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(Icons.close, color: AppTheme.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Segmented Tabs Control
                  Row(
                    children: [
                      Expanded(
                        child: SGTouchable(
                          onTap: () => setState(() => _activeTab = 'host'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _activeTab == 'host' ? AppTheme.cyan.withValues(alpha: 0.15) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _activeTab == 'host' ? AppTheme.cyan : AppTheme.glassBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text('HOST ROOM', style: AppTheme.label(color: _activeTab == 'host' ? AppTheme.cyan : AppTheme.text2)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SGTouchable(
                          onTap: () {
                            setState(() => _activeTab = 'browse');
                            _startUdpDiscovery();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _activeTab == 'browse' ? AppTheme.cyan.withValues(alpha: 0.15) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _activeTab == 'browse' ? AppTheme.cyan : AppTheme.glassBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text('JOIN ROOM', style: AppTheme.label(color: _activeTab == 'browse' ? AppTheme.cyan : AppTheme.text2)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Connecting State Loader
                  if (_isConnecting || _lobbyStatus.isNotEmpty) ...[
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.cyan),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppTheme.cyan),
                              const SizedBox(height: 20),
                              Text(_lobbyStatus, style: AppTheme.body(color: AppTheme.text1), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              SGTouchable(
                                onTap: () {
                                  _disconnectAndReturn('Connection aborted.');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.red),
                                  ),
                                  child: Text('CANCEL', style: AppTheme.label(color: AppTheme.red)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Active Tab Renderers
                    Expanded(
                      child: SingleChildScrollView(
                        child: _activeTab == 'host' ? _buildHostTab() : _buildBrowseTab(),
                      ),
                    ),
                  ],

                  // bottom IP address card
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: Text('YOUR IP: $_localIp  |  PORT: 4545', style: AppTheme.caption(color: AppTheme.text3).copyWith(fontFamily: GoogleFonts.spaceMono().fontFamily)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room Name
        Text('ROOM IDENTIFIER', style: AppTheme.label(color: AppTheme.text3)),
        const SizedBox(height: 6),
        TextField(
          controller: _hostRoomNameCtrl,
          style: AppTheme.body(color: AppTheme.text1),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.glassBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.cyan)),
            hintStyle: AppTheme.body(color: AppTheme.text3),
            hintText: 'Enter room name',
          ),
        ),
        const SizedBox(height: 16),

        // Password protection settings
        Text('OPTIONAL PASSWORD', style: AppTheme.label(color: AppTheme.text3)),
        const SizedBox(height: 6),
        TextField(
          controller: _hostPasswordCtrl,
          obscureText: true,
          style: AppTheme.body(color: AppTheme.text1),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.glassBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.cyan)),
            hintStyle: AppTheme.body(color: AppTheme.text3),
            hintText: 'Leave empty for no password',
          ),
        ),
        const SizedBox(height: 16),

        // Max Players Selector
        Text('MAX PLAYERS LIMIT', style: AppTheme.label(color: AppTheme.text3)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SGTouchable(
                onTap: () => setState(() => _hostMaxPlayers = 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _hostMaxPlayers == 1 ? AppTheme.cyan.withValues(alpha: 0.15) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hostMaxPlayers == 1 ? AppTheme.cyan : AppTheme.glassBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text('1 PLAYER (SOLO)', style: AppTheme.label(color: _hostMaxPlayers == 1 ? AppTheme.cyan : AppTheme.text2)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SGTouchable(
                onTap: () => setState(() => _hostMaxPlayers = 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _hostMaxPlayers == 2 ? AppTheme.cyan.withValues(alpha: 0.15) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hostMaxPlayers == 2 ? AppTheme.cyan : AppTheme.glassBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text('2 PLAYERS (PVP)', style: AppTheme.label(color: _hostMaxPlayers == 2 ? AppTheme.cyan : AppTheme.text2)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Width Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ARENA WIDTH', style: AppTheme.label(color: AppTheme.text3)),
            Text('${_hostRoomWidthMeters.toInt()} METERS', style: AppTheme.caption(color: AppTheme.cyan).copyWith(fontFamily: GoogleFonts.spaceMono().fontFamily)),
          ],
        ),
        Slider(
          value: _hostRoomWidthMeters,
          min: 200,
          max: 1000,
          divisions: 8,
          activeColor: AppTheme.cyan,
          inactiveColor: AppTheme.surface,
          onChanged: (v) => setState(() => _hostRoomWidthMeters = v),
        ),
        const SizedBox(height: 24),

        // Host trigger button
        SGButton(
          label: 'CREATE PVP ARENA',
          onTap: _hostRoom,
        ),
      ],
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Manual Connection Form
        Text('MANUAL ENTER JOIN CODE', style: AppTheme.label(color: AppTheme.text3)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualJoinCodeCtrl,
                style: AppTheme.body(color: AppTheme.text1),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.glassBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.cyan)),
                  hintStyle: AppTheme.body(color: AppTheme.text3),
                  hintText: 'e.g. C0A8012A or Local IP',
                ),
              ),
            ),
            const SizedBox(width: 12),
            SGTouchable(
              onTap: () {
                final txt = _manualJoinCodeCtrl.text.trim();
                if (txt.isEmpty) return;
                
                String targetIp = txt;
                // If 8-character hex code, resolve back to IP
                if (txt.length == 8 && !txt.contains('.')) {
                  targetIp = joinCodeToIp(txt);
                }

                if (targetIp.isEmpty) {
                  AppTheme.showSnackBar(context, 'Invalid Join Code format!', isError: true);
                  return;
                }

                _joinRoom(targetIp, '');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cyan,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('JOIN', style: AppTheme.label(color: Colors.black)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Scanned active rooms
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AVAILABLE LOCAL LOBBIES', style: AppTheme.label(color: AppTheme.text3)),
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppTheme.cyan, size: 20),
              onPressed: () {
                setState(() => _discoveredRooms.clear());
                _startUdpDiscovery();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_discoveredRooms.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.wifi_find_rounded, color: AppTheme.text3, size: 40),
                const SizedBox(height: 12),
                Text('Scanning WiFi for local host servers...', style: AppTheme.body(color: AppTheme.text3), textAlign: TextAlign.center),
              ],
            ),
          ),
        ] else ...[
          ..._discoveredRooms.values.map((room) {
            final name = room['roomName'] ?? 'Cyber Arena';
            final ip = room['ip'] ?? '127.0.0.1';
            final width = room['width'] ?? 200;
            final isLocked = room['requiresPassword'] ?? false;
            final expectedPass = room['passwordHash'] ?? '';
            final code = room['joinCode'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name.toString().toUpperCase(), style: AppTheme.h3(color: AppTheme.cyan)),
                            const SizedBox(width: 8),
                            if (isLocked) Icon(Icons.lock_rounded, size: 14, color: AppTheme.amber),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('IP: $ip  |  CODE: $code', style: AppTheme.caption(color: AppTheme.text3).copyWith(fontFamily: GoogleFonts.spaceMono().fontFamily, fontSize: 10)),
                        Text('Width: ${width}m  |  Limit: 2 Players', style: AppTheme.caption(color: AppTheme.text3).copyWith(fontFamily: GoogleFonts.spaceMono().fontFamily, fontSize: 10)),
                      ],
                    ),
                  ),
                  SGTouchable(
                    onTap: () {
                      if (isLocked) {
                        _showPasswordPrompt(ip, expectedPass);
                      } else {
                        _joinRoom(ip, '');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cyan.withValues(alpha: 0.15),
                        border: Border.all(color: AppTheme.cyan),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('CONNECT', style: AppTheme.label(color: AppTheme.cyan)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // Password connection prompt dialog
  void _showPasswordPrompt(String ip, String expectedPass) {
    _joinPasswordCtrl.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: AppTheme.cyan)),
        title: Text('ROOM PASSWORD', style: AppTheme.label(color: AppTheme.cyan)),
        content: TextField(
          controller: _joinPasswordCtrl,
          obscureText: true,
          style: AppTheme.body(color: AppTheme.text1),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.black,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintStyle: AppTheme.body(color: AppTheme.text3),
            hintText: 'Enter room password',
          ),
        ),
        actions: [
          TextButton(
            child: Text('CANCEL', style: AppTheme.label(color: AppTheme.text3)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cyan),
            child: Text('CONNECT', style: AppTheme.label(color: Colors.black)),
            onPressed: () {
              Navigator.pop(context);
              _joinRoom(ip, expectedPass);
            },
          ),
        ],
      ),
    );
  }

  // ── GAME PLAY ARENA GRAPHICS & HUD ──
  Widget _buildGameArena() {
    final double localHpPercent = (_playerHp / 100).clamp(0.0, 1.0);
    final double remoteHpPercent = (_remoteHp / 100).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: Stack(
        children: [
          // Cyber Space Grid Floor & Background (Horizontal Scrolling)
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PvpArenaGridPainter(
                      cameraX: _cameraX,
                      mapWidth: _mapWidth,
                      groundY: _groundY,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Player 1 (Local) Character
          Positioned(
            left: _playerX - _cameraX - 80,
            bottom: _groundY + _playerY,
            child: SizedBox(
              width: 160,
              height: 160,
              child: Transform.scale(
                scaleX: _playerFlip ? -1 : 1,
                child: Player(
                  key: ValueKey('local_player_${_getCurrentAnimation()}'),
                  animation: _getCurrentAnimation(),
                  size: 160,
                  loop: !_isPunching && !_isKicking && !_playerHit,
                  fps: _isRunning ? 13 : 10,
                ),
              ),
            ),
          ),

          // Player 2 (Remote) Character
          if (_hostMaxPlayers == 2)
            Positioned(
              left: _remoteX - _cameraX - 80,
              bottom: _groundY + _remoteY,
              child: SizedBox(
                width: 160,
                height: 160,
                child: Transform.scale(
                  scaleX: _remoteFlip ? -1 : 1,
                  child: Player(
                    key: ValueKey('remote_player_$_remoteAnim'),
                    animation: _remoteAnim,
                    size: 160,
                    loop: _remoteAnim != 'Punch01' && _remoteAnim != 'Kick01' && _remoteAnim != 'Hit',
                    fps: 10,
                  ),
                ),
              ),
            ),

          // Damage popups rendering
          ..._damageNumbers.map((damage) {
            return Positioned(
              left: damage.x - _cameraX - 20,
              top: damage.y,
              child: Opacity(
                opacity: damage.opacity,
                child: Text(
                  '-${damage.amount}',
                  style: AppTheme.pixel(size: 24, color: AppTheme.red),
                ),
              ),
            );
          }),

          // HUD overlay (Health bars)
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Row(
              children: [
                // Local HP bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHost 
                          ? (_hostMaxPlayers == 1 ? 'PLAYER 1 (SOLO)' : 'PLAYER 1 (HOST)') 
                          : 'PLAYER 2 (YOU)', 
                        style: AppTheme.pixel(size: 11, color: AppTheme.cyan)
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: localHpPercent,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_hostMaxPlayers == 2) ...[
                  // VS center logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('VS', style: AppTheme.pixel(size: 18, color: AppTheme.text3)),
                  ),

                  // Remote HP bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(!_isHost ? 'PLAYER 1 (HOST)' : 'PLAYER 2 (OPPONENT)', style: AppTheme.pixel(size: 11, color: AppTheme.red)),
                        const SizedBox(height: 4),
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: remoteHpPercent,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [Colors.redAccent, Colors.red]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Immersive Exit button
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: SGTouchable(
                onTap: () {
                  _disconnectAndReturn('Exited game session.');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.red.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: Icon(Icons.exit_to_app_rounded, color: AppTheme.red, size: 18),
                ),
              ),
            ),
          ),

          // High-Fidelity Minimap Column (100% sync from training_screen.dart)
          Positioned(
            top: 80,
            right: 24,
            child: Column(
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
                          left: (0 - _playerX) * 0.12 + 110,
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
                                  child: Container(height: 1, color: AppTheme.cyan.withValues(alpha: 0.15)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Boundary Walls
                        Positioned(
                          left: (0 - _playerX) * 0.12 + 110 - 2,
                          top: 0, bottom: 0,
                          child: Container(width: 4, color: AppTheme.red.withValues(alpha: 0.8)),
                        ),
                        Positioned(
                          left: (_mapWidth - _playerX) * 0.12 + 110 - 2,
                          top: 0, bottom: 0,
                          child: Container(width: 4, color: AppTheme.cyan.withValues(alpha: 0.8)),
                        ),

                        // 3. Player 1 indicator (Static at center)
                        Positioned(
                          left: 110 - 16,
                          bottom: 8,
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: Transform.scale(
                                scaleX: _playerFlip ? -1 : 1,
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

                        // 4. Player 2 (Remote) indicator - moves relative to player 1
                        if (_hostMaxPlayers == 2)
                          Positioned(
                            left: (_remoteX - _playerX) * 0.12 + 110 - 16,
                            bottom: 8,
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Transform.scale(
                                  scaleX: _remoteFlip ? -1 : 1,
                                  child: Player(
                                    animation: _remoteAnim,
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
                  '${(_playerX / 15).floor()}m / ${(_mapWidth / 15).floor()}m',
                  style: AppTheme.mono(color: AppTheme.cyan, size: 11),
                ),
              ],
            ),
          ),

          // Victory / Defeat screen overlay
          if (_playerHp <= 0 || _remoteHp <= 0)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _playerHp <= 0 ? 'DEFEAT' : 'VICTORY',
                        style: AppTheme.pixel(size: 40, color: _playerHp <= 0 ? AppTheme.red : AppTheme.green),
                      ),
                      const SizedBox(height: 24),
                      SGTouchable(
                        onTap: () {
                          _disconnectAndReturn('Rematch requested.');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('RETURN TO LOBBY', style: AppTheme.mono(size: 13, color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // GAME CONTROLS (Multi-touch directional arrows 100% styled from training_screen.dart)
          Positioned(
            left: 30,
            bottom: 30,
            child: Row(
              children: [
                // Left Arrow Button
                Listener(
                  onPointerDown: (_) => setState(() {
                    _handleDirectionTap(true, true);
                  }),
                  onPointerUp: (_) => setState(() {
                    _handleDirectionTap(true, false);
                  }),
                  onPointerCancel: (_) => setState(() {
                    _handleDirectionTap(true, false);
                  }),
                  child: AnimatedScale(
                    scale: _leftPressed ? 0.85 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _leftPressed ? (_isRunning ? AppTheme.cyan : AppTheme.accent) : AppTheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isRunning && _leftPressed ? AppTheme.cyan : AppTheme.accent.withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRunning && _leftPressed ? AppTheme.cyan : AppTheme.accent).withValues(alpha: _leftPressed ? 0.3 : 0.05),
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
                ),
                const SizedBox(width: 20),
                // Right Arrow Button
                Listener(
                  onPointerDown: (_) => setState(() {
                    _handleDirectionTap(false, true);
                  }),
                  onPointerUp: (_) => setState(() {
                    _handleDirectionTap(false, false);
                  }),
                  onPointerCancel: (_) => setState(() {
                    _handleDirectionTap(false, false);
                  }),
                  child: AnimatedScale(
                    scale: _rightPressed ? 0.85 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _rightPressed ? (_isRunning ? AppTheme.cyan : AppTheme.accent) : AppTheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isRunning && _rightPressed ? AppTheme.cyan : AppTheme.accent.withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRunning && _rightPressed ? AppTheme.cyan : AppTheme.accent).withValues(alpha: _rightPressed ? 0.3 : 0.05),
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
                ),
              ],
            ),
          ),

          // Action Buttons (Punch, Kick, Jump 100% animated sprite boxes from training_screen.dart)
          Positioned(
            right: 30,
            bottom: 30,
            child: Row(
              children: [
                // Kick Button
                Listener(
                  onPointerDown: (_) {
                    _kickPressed = true;
                    _kick();
                  },
                  onPointerUp: (_) => _kickPressed = false,
                  onPointerCancel: (_) => _kickPressed = false,
                  child: AnimatedScale(
                    scale: _kickPressed ? 0.85 : 1.0,
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
                        color: !_playerGrounded ? AppTheme.cyan : AppTheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.8), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyan.withValues(alpha: 0.3),
                            blurRadius: !_playerGrounded ? 20 : 10,
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
                            child: !_playerGrounded
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM LOBBY BACKGROUND PAINTER ──
class _LobbyBgPainter extends CustomPainter {
  final double progress;
  _LobbyBgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0B1414).withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    final double offset = progress * 40.0;

    // Horizontal Lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Vertical grid lines scrolling sideways
    for (double x = -40 + (offset % 40); x < size.width + 40; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_LobbyBgPainter oldDelegate) => oldDelegate.progress != progress;
}

// ── CUSTOM DYNAMIC GRID ARENA PAINTER ──
class _PvpArenaGridPainter extends CustomPainter {
  final double cameraX;
  final double mapWidth;
  final double groundY;

  _PvpArenaGridPainter({
    required this.cameraX,
    required this.mapWidth,
    required this.groundY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double screenH = size.height;
    final double screenW = size.width;
    final double groundAbsolute = screenH - groundY;

    // 1. Solid Underworld Fill
    final paintSky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050510), Color(0xFF0F0A20)],
      ).createShader(Rect.fromLTWH(0, 0, screenW, groundAbsolute));
    canvas.drawRect(Rect.fromLTWH(0, 0, screenW, groundAbsolute), paintSky);

    // 2. Horizon Cyber neon aura bar
    final neonPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    canvas.drawLine(Offset(0, groundAbsolute), Offset(screenW, groundAbsolute), neonPaint);

    final neonPaintLine = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, groundAbsolute), Offset(screenW, groundAbsolute), neonPaintLine);

    // 3. Grid Lines Scrolling with Camera (Underground)
    final gridPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    // Verticals scrolling sideways
    const double spacing = 60.0;
    double startX = -(cameraX % spacing);
    for (double x = startX; x < screenW + spacing; x += spacing) {
      canvas.drawLine(Offset(x, groundAbsolute), Offset(x, screenH), gridPaint);
    }

    // Horizontals spacing down
    for (double y = groundAbsolute; y < screenH; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(screenW, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_PvpArenaGridPainter oldDelegate) {
    return oldDelegate.cameraX != cameraX || 
           oldDelegate.mapWidth != mapWidth || 
           oldDelegate.groundY != groundY;
  }
}
