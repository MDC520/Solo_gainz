import 'package:flutter/material.dart';

// ── Collider Types ──────────────────────────────────────────────────────────

enum ColliderTarget { player, attack, kickAttack, box, clone, cloneAttack }

class ColliderFrameData {
  double x, y, w, h, r;
  ColliderFrameData({this.x = 0, this.y = 0, this.w = 50, this.h = 50, this.r = 0});
}

class CombatData {
  static final Map<String, ColliderFrameData> frameData = {};

  static String getFrameKey(ColliderTarget target, String anim, int frame) {
    return '${target.name}_${anim}_$frame';
  }

  static ColliderFrameData getOrCreateFrameData(ColliderTarget target, String anim, int frame, {ColliderFrameData? defaults}) {
    final key = getFrameKey(target, anim, frame);
    if (!frameData.containsKey(key)) {
      frameData[key] = defaults ?? ColliderFrameData();
    }
    return frameData[key]!;
  }
}

// ── Notebook Grid Background Painter ────────────────────────────────────────

class NotebookPainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  final double horizontalOffset;

  NotebookPainter(this.progress, {Color? lineColor, this.horizontalOffset = 0})
      : lineColor = lineColor ?? const Color(0xFF4FC3F7).withValues(alpha: 0.05);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    const double lineSpacing = 40.0;
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    double xOffset = -(progress * lineSpacing * 2) + horizontalOffset;
    for (double x = -lineSpacing + (xOffset % lineSpacing); x < size.width + lineSpacing; x += lineSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(NotebookPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.lineColor != lineColor;
}

// ── Crate (Wooden Box) Painter ──────────────────────────────────────────────

class CratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final o8 = 8.0;
    canvas.drawLine(Offset(o8, o8), Offset(size.width - o8, size.height - o8), framePaint);
    canvas.drawLine(Offset(size.width - o8, o8), Offset(o8, size.height - o8), framePaint);

    final studPaint = Paint()..color = const Color(0xFFBDBDBD).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(6, 6), 1.5, studPaint);
    canvas.drawCircle(Offset(size.width - 6, 6), 1.5, studPaint);
    canvas.drawCircle(Offset(6, size.height - 6), 1.5, studPaint);
    canvas.drawCircle(Offset(size.width - 6, size.height - 6), 1.5, studPaint);

    final bracketPaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    double bSize = 10;
    canvas.drawLine(Offset.zero, Offset(bSize, 0), bracketPaint);
    canvas.drawLine(Offset.zero, Offset(0, bSize), bracketPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - bSize, 0), bracketPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, bSize), bracketPaint);
    canvas.drawLine(Offset(0, size.height), Offset(bSize, size.height), bracketPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - bSize), bracketPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - bSize, size.height), bracketPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - bSize), bracketPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ── Animation Frame Helpers ─────────────────────────────────────────────────

int getAnimFrameCount(String anim) {
  switch (anim) {
    case 'Punch01': return 6;
    case 'Kick01':  return 9;
    case 'Idle':    return 7;
    case 'Walk':    return 8;
    case 'Run':     return 8;
    case 'Jump':    return 3;
    case 'Jump Fall': return 1;
    case 'Hit':     return 3;
    case 'Push':    return 8;
    case 'PushIdle': return 6;
    case 'Pull':    return 6;
    case 'GetUp':   return 3;
    case 'Knockback': return 6;
    default:        return 8;
  }
}

String getFrameAssetPath(String anim, int frameIdx) {
  if (anim == 'Jump Fall') {
    return 'assets/Player Model/Jump/Jump03.png';
  }
  final maxFrames = getAnimFrameCount(anim);
  final clampedFrame = frameIdx.clamp(0, maxFrames - 1);
  final frameNum = (clampedFrame + 1).toString().padLeft(2, '0');
  return 'assets/Player Model/$anim/$anim$frameNum.png';
}
