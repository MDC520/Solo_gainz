import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Responsive — Universal scaling system for Solo Gainz.
///
/// Designed around a reference device (the device where the app looks perfect).
/// All hardcoded sizes throughout the app pass through this scaler to produce
/// identical visual proportions on every screen size and pixel density.
///
/// ### Usage
///
/// 1. Call `Responsive.init(context)` once at the top of the widget tree
///    (e.g., in the `build` method of the root Shell or via a builder).
///
/// 2. Use the scaling helpers anywhere:
///    ```dart
///    Responsive.sp(16)    // Scaled font size
///    Responsive.w(20)     // Scaled horizontal dimension (paddings, widths)
///    Responsive.h(20)     // Scaled vertical dimension (paddings, heights)
///    Responsive.r(12)     // Scaled radius
///    Responsive.icon(24)  // Scaled icon size
///    Responsive.dp(1.5)   // Scaled thin values (borders, strokes)
///    ```
///
/// 3. For animation frame rates that appear faster on small screens, use:
///    ```dart
///    Responsive.fps(12)   // Returns an adjusted FPS value
///    ```
class Responsive {
  Responsive._();

  // ── Reference Device (the device where the app currently looks perfect) ──
  // Standard modern phone ≈ 393 x 852 logical pixels (e.g., Pixel 7, iPhone 14).
  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  // ── Computed Scale Factors ────────────────────────────────────────────────
  static double _scaleWidth = 1.0;
  static double _scaleHeight = 1.0;
  static double _scaleText = 1.0;
  static double _scaleFps = 1.0;
  static double _deviceWidth = _refWidth;
  static double _deviceHeight = _refHeight;
  static double _devicePixelRatio = 1.0;
  static bool _initialized = false;

  /// Call once at the root of the widget tree.
  /// Best placed inside a `Builder` widget or the shell `build()`.
  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    _deviceWidth = mq.size.width;
    _deviceHeight = mq.size.height;
    _devicePixelRatio = mq.devicePixelRatio;

    // Width-based scale (dominant for horizontal paddings, widths, icon sizes)
    _scaleWidth = _deviceWidth / _refWidth;

    // Height-based scale (for vertical spacers, card heights)
    _scaleHeight = _deviceHeight / _refHeight;

    // Text scale uses the smaller of width/height scales to prevent overflow
    // on narrow or short screens, but capped so it never grows too large
    // on tablets/foldables.
    _scaleText = math.min(_scaleWidth, _scaleHeight).clamp(0.75, 1.25);

    // FPS scale: on smaller screens the visual area is smaller so animations
    // appear to "move faster" relative to the viewport.  We slow them down
    // proportionally.  On larger screens we leave them alone.
    _scaleFps = (_scaleWidth < 1.0) ? _scaleWidth : 1.0;

    _initialized = true;
  }

  // ── Guards ────────────────────────────────────────────────────────────────
  static void _assertInit() {
    assert(_initialized, 'Responsive.init(context) must be called before using Responsive helpers.');
  }

  // ── Public Getters ────────────────────────────────────────────────────────
  static double get scaleWidth => _scaleWidth;
  static double get scaleHeight => _scaleHeight;
  static double get scaleText => _scaleText;
  static double get deviceWidth => _deviceWidth;
  static double get deviceHeight => _deviceHeight;
  static double get devicePixelRatio => _devicePixelRatio;

  /// True when the device is considered "small" (width < 360 lp).
  static bool get isSmallDevice => _deviceWidth < 360;

  /// True when the device is considered "compact" (width < 320 lp).
  static bool get isCompactDevice => _deviceWidth < 320;

  /// True when the device has a short screen (height < 700 lp).
  static bool get isShortDevice => _deviceHeight < 700;

  // ── Scaling Helpers ───────────────────────────────────────────────────────

  /// Scale a **horizontal** dimension (paddings, margins, widths).
  static double w(double value) {
    _assertInit();
    return (value * _scaleWidth).roundToDouble();
  }

  /// Scale a **vertical** dimension (paddings, margins, heights, spacers).
  static double h(double value) {
    _assertInit();
    return (value * _scaleHeight).roundToDouble();
  }

  /// Scale a **font size** (text, mono, pixel fonts).
  static double sp(double value) {
    _assertInit();
    return (value * _scaleText).roundToDouble();
  }

  /// Scale a **border radius**.
  static double r(double value) {
    _assertInit();
    return (value * _scaleText).roundToDouble();
  }

  /// Scale an **icon size**.
  static double icon(double value) {
    _assertInit();
    return (value * _scaleText).roundToDouble();
  }

  /// Scale a thin value (borders, strokes, dividers).
  /// These need less aggressive scaling — we use the square root of the
  /// scale factor so they don't disappear on tiny screens.
  static double dp(double value) {
    _assertInit();
    final factor = math.sqrt(_scaleWidth).clamp(0.85, 1.15);
    return (value * factor);
  }

  /// Adjust a sprite/animation FPS value so visual speed feels consistent
  /// across screen sizes.  On smaller screens the same pixel-per-frame
  /// movement covers a larger proportion of the viewport, so we reduce FPS.
  static double fps(double baseFps) {
    _assertInit();
    // Clamp so we never drop below 60% of the base FPS (avoids choppy feel)
    return (baseFps * _scaleFps).clamp(baseFps * 0.6, baseFps);
  }

  /// Scale a Duration proportionally — useful for scroll-based or
  /// distance-based animations that look too fast on small screens.
  static Duration scaledDuration(Duration base) {
    _assertInit();
    if (_scaleWidth >= 1.0) return base;
    final factor = (1.0 / _scaleWidth).clamp(1.0, 1.5);
    return Duration(milliseconds: (base.inMilliseconds * factor).round());
  }

  // ── Convenience: Scaled EdgeInsets ─────────────────────────────────────────

  /// Scale symmetric padding.
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: w(horizontal),
      vertical: h(vertical),
    );
  }

  /// Scale LTRB padding.
  static EdgeInsets fromLTRB(double l, double t, double r, double b) {
    return EdgeInsets.fromLTRB(w(l), h(t), w(r), h(b));
  }

  /// Scale all-sides padding.
  static EdgeInsets all(double value) {
    final scaled = w(value);
    return EdgeInsets.all(scaled);
  }

  /// Scale only specific sides.
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: w(left),
      top: h(top),
      right: w(right),
      bottom: h(bottom),
    );
  }
}

/// A convenience widget that initializes Responsive at the top of the tree.
/// Wrap your MaterialApp's home or shell with this.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return builder(context);
  }
}
