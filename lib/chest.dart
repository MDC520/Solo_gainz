import 'dart:async';
import 'package:flutter/material.dart';
import 'responsive.dart';

/// Animated chest sprite widget.
/// Loops through PNG frames for idle animation, or plays once for open animation.
class ChestSprite extends StatefulWidget {
  /// The type of chest: 'wooden', 'iron', 'gold', or 'mysterious'
  final String chestType;

  /// The active animation state: 'Idle' or 'Open'
  final String animation;

  /// Frames per second for the sprite animation
  final double fps;

  /// Alignment of the chest inside its container layout
  final Alignment alignment;

  /// Optional fixed square size of the chest sprite widget
  final double? size;

  /// If true, plays once and stops on last frame (useful for chest opening sequence)
  final bool playOnce;

  /// Callback triggered when a play-once animation reaches its final frame
  final VoidCallback? onComplete;

  const ChestSprite({
    super.key,
    required this.chestType,
    this.animation = 'Idle',
    this.fps = 6,
    this.size,
    this.playOnce = false,
    this.onComplete,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  State<ChestSprite> createState() => _ChestSpriteState();
}

class _ChestSpriteState extends State<ChestSprite> {
  int _frame = 0;
  Timer? _timer;
  late List<String> _frames;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _buildFrameList();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant ChestSprite old) {
    super.didUpdateWidget(old);
    if (old.chestType != widget.chestType ||
        old.animation != widget.animation ||
        old.fps != widget.fps) {
      _timer?.cancel();
      _frame = 0;
      _finished = false;
      _buildFrameList();
      _startTimer();
    }
  }

  void _buildFrameList() {
    final String folder;
    final String animFolder;
    final type = widget.chestType.toLowerCase();

    // Map chestType string and animation state to local asset paths
    if (type.contains('wooden')) {
      folder = 'Wooden Chest';
      animFolder = widget.animation == 'Open' ? 'open' : 'Idle';
    } else if (type.contains('iron')) {
      folder = 'Iron Chest';
      animFolder = widget.animation == 'Open' ? 'Open' : 'Idle';
    } else if (type.contains('mysterious')) {
      folder = 'Mysterious Chest';
      animFolder = widget.animation == 'Open' ? 'open' : 'Idle';
    } else {
      folder = 'Gold Chest';
      animFolder = widget.animation == 'Open' ? 'oepn' : 'idle';
    }

    // Each animation loop in Assets consists of 5 frames (1.png through 5.png)
    _frames = List.generate(5, (i) {
      return 'Assets/Chests/$folder/$animFolder/${i + 1}.png';
    });
  }

  void _startTimer() {
    final adjustedFps = Responsive.fps(widget.fps);
    final interval = Duration(milliseconds: (1000 / adjustedFps).round());
    _timer = Timer.periodic(interval, (_) {
      if (!mounted || _frames.isEmpty) return;
      if (widget.playOnce && _finished) return;

      final nextFrame = _frame + 1;
      if (widget.playOnce && nextFrame >= _frames.length) {
        // Halt and lock on the last open frame
        setState(() {
          _frame = _frames.length - 1;
          _finished = true;
        });
        _timer?.cancel();
        widget.onComplete?.call();
        return;
      }

      setState(() => _frame = nextFrame % _frames.length);
    });
  }

  /// Skip directly to the last frame (immediately triggers opened state)
  void skipToEnd() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _frame = _frames.length - 1;
        _finished = true;
      });
    }
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderSize = widget.size != null ? Responsive.w(widget.size!) : widget.size;
    return Image.asset(
      _frames[_frame],
      fit: BoxFit.contain,
      width: renderSize,
      height: renderSize,
      alignment: widget.alignment,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading chest sprite asset: $error at ${_frames[_frame]}');
        return SizedBox(
          width: renderSize,
          height: renderSize,
          child: const Center(
            child: Icon(Icons.inventory_2_outlined, color: Colors.redAccent, size: 36),
          ),
        );
      },
    );
  }
}
