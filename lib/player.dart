import 'dart:async';
import 'package:flutter/material.dart';

/// Animated pixel-art player sprite.
/// Loops through a sequence of PNG frames at a configurable frame rate.
class Player extends StatefulWidget {
  /// Which animation to play (maps to a subfolder under Assets/Player Model/).
  final String animation;

  /// Frames per second for the sprite animation.
  final double fps;

  /// Optional fixed size – defaults to expanding to fill parent.
  final double? size;

  /// Tint color for the sprite.
  final Color? color;

  /// Whether the animation should loop.
  final bool loop;

  /// Whether the animation is paused.
  final bool paused;

  /// Callback when a non-looping animation finishes.
  final VoidCallback? onComplete;

  /// Alignment of the sprite within its box.
  final Alignment alignment;

  const Player({
    super.key,
    this.animation = 'Idle',
    this.fps = 8,
    this.size,
    this.color,
    this.loop = true,
    this.paused = false,
    this.onComplete,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  int _frame = 0;
  late Timer _timer;
  late List<String> _frames;

  // Frame counts per animation folder
  static const Map<String, int> _frameCounts = {
    'Hit': 3,
    'GetUp': 3,
    'Idle': 7,
    'Jump': 3,
    'JumpDust': 7,
    'Kick01': 9,
    'Kick02': 8,
    'Kick03': 9,
    'Knockback': 6,
    'LadderClimb': 8,
    'LadderClimbFinish': 6,
    'LadderClimbHorizontal': 8,
    'Land': 2,
    'LandingDust': 6,
    'Pull': 6,
    'Punch01': 6,
    'Punch02': 4,
    'Punch03': 7,
    'Push': 6,
    'PushIdle': 6,
    'Roll': 10,
    'Run': 8,
    'RunToIdle': 3,
    'ShockHeavy': 4,
    'ShockLight': 4,
    'Slide': 4,
    'Spin': 8,
    'Sprint': 6,
    'Stunned': 7,
    'ThrowOverarm': 5,
    'ThrowUnderarm': 6,
    'Walk': 8,
  };

  @override
  void initState() {
    super.initState();
    _buildFrameList();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant Player old) {
    super.didUpdateWidget(old);
    bool animChanged = old.animation != widget.animation;
    bool fpsChanged = old.fps != widget.fps;
    bool pauseChanged = old.paused != widget.paused;
    bool loopChanged = old.loop != widget.loop;

    if (animChanged) {
      _timer.cancel();
      _frame = 0;
      _buildFrameList();
      _startTimer();
    } else if (fpsChanged || loopChanged || pauseChanged) {
      _timer.cancel();
      _startTimer();
    }
  }

  void _buildFrameList() {
    if (widget.animation == 'Jump Fall') {
      _frames = ['Assets/Player Model/Jump/Jump03.png'];
      return;
    }
    final count = _frameCounts[widget.animation] ?? 7;
    _frames = List.generate(count, (i) {
      final idx = (i + 1).toString().padLeft(2, '0');
      return 'Assets/Player Model/${widget.animation}/${widget.animation}$idx.png';
    });
  }

  void _startTimer() {
    if (widget.fps <= 0) return;
    final interval = Duration(milliseconds: (1000 / widget.fps).round());
    _timer = Timer.periodic(interval, (_) {
      if (!mounted || _frames.isEmpty || widget.paused) return;

      if (_frame >= _frames.length) {
        setState(() => _frame = 0);
        return;
      }

      final nextFrame = _frame + 1;
      if (nextFrame >= _frames.length) {
        if (widget.loop) {
          setState(() => _frame = 0);
        } else {
          _timer.cancel();
          widget.onComplete?.call();
        }
      } else {
        setState(() => _frame = nextFrame);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    return Image.asset(
      _frames[_frame],
      fit: BoxFit.contain,
      width: widget.size,
      height: widget.size,
      color: widget.color,
      alignment: widget.alignment,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true, // smoother transitions
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading sprite $_frame: $error');
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.red, size: 40),
          ),
        );
      },
    );
  }
}
