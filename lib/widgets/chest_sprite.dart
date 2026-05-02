import 'dart:async';
import 'package:flutter/material.dart';

/// Animated chest sprite widget.
/// Loops through PNG frames for idle, or plays once for open animation.
class ChestSprite extends StatefulWidget {
  /// 'wooden' or 'iron'
  final String chestType;

  /// 'Idle' or 'Open'
  final String animation;

  /// Frames per second
  final double fps;

  /// Optional fixed size
  final double? size;

  /// If true, plays once and stops on last frame (for open animation)
  final bool playOnce;

  /// Called when a play-once animation finishes
  final VoidCallback? onComplete;

  const ChestSprite({
    super.key,
    required this.chestType,
    this.animation = 'Idle',
    this.fps = 6,
    this.size,
    this.playOnce = false,
    this.onComplete,
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
    // Map chestType to folder name
    String folder;
    String animFolder;
    final type = widget.chestType.toLowerCase();
    
    if (type.contains('wooden')) {
      folder = 'Wooden Chest';
      animFolder = widget.animation == 'Open' ? 'open' : 'Idle';
    } else if (type.contains('iron')) {
      folder = 'Iron Chest';
      animFolder = widget.animation == 'Open' ? 'Open' : 'Idle';
    } else {
      folder = 'Gold Chest';
      animFolder = widget.animation == 'Open' ? 'oepn' : 'idle';
    }

    // Each animation has 5 frames: 1.png through 5.png
    _frames = List.generate(5, (i) {
      return 'Assets/Chests/$folder/$animFolder/${i + 1}.png';
    });
  }

  void _startTimer() {
    final interval = Duration(milliseconds: (1000 / widget.fps).round());
    _timer = Timer.periodic(interval, (_) {
      if (!mounted || _frames.isEmpty) return;
      if (widget.playOnce && _finished) return;

      final nextFrame = _frame + 1;
      if (widget.playOnce && nextFrame >= _frames.length) {
        // Stay on last frame
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

  /// Skip to the last frame immediately
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
    return Image.asset(
      _frames[_frame],
      fit: BoxFit.contain,
      width: widget.size,
      height: widget.size,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading chest sprite: $error');
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: const Center(
            child: Icon(Icons.inventory_2, color: Colors.red, size: 40),
          ),
        );
      },
    );
  }
}
