export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════
/// Solo Gainz — "Aura & Glass" Design System
/// An elegant, living UI that feels like modern art.
/// Deep voids, frosted glass, and breathing neon auras.
/// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Core Colors (Solid & Clean) ───────────────────────────────
  static const Color black     = Color(0xFF0A0C10); // Deeper Solid Black
  static const Color dark      = Color(0xFF14171C); // Deeper Solid Surface
  
  // ── Accents (Solid, Professional) ─────────────────────────────
  static const Color accent    = Color(0xFF1D9BF0); // Solid Vibrant Blue
  static const Color cyan      = Color(0xFF00BA7C); // Solid Mint/Cyan
  static const Color amber     = Color(0xFFFFD400); // Solid Gold
  static const Color red       = Color(0xFFF91880); // Solid Red/Pink
  static const Color purple    = Color(0xFF8224E3); // Solid Purple
  static const Color silver    = Color(0xFFE1E8ED); // Crisp Bright Silver

  // ── Borders ───────────────────────────────────────────────────
  static final Color glassLight = Colors.white.withValues(alpha: 0.02);
  static final Color glassMedium = Colors.white.withValues(alpha: 0.05);
  static final Color glassBorder = const Color(0xFF38444D); // Solid Clean Border

  // ── Text ──────────────────────────────────────────────────────
  static const Color text1     = Color(0xFFF7F9F9); // Crisp Clean White
  static const Color text2     = Color(0xFF8B98A5); // Solid Secondary Blue-Grey
  static const Color text3     = Color(0xFF6A7D8C); // Solid Tertiary Blue-Grey

  // ── Legacy Getters (Mapped to new system to prevent breaking) ─
  static bool get isDark    => true;
  static Color get bg       => black;
  static Color get surface  => dark;
  static Color get elevated => dark;
  static Color get line     => glassBorder;
  static Color get muted    => text3;
  static Color get accentDim => const Color(0xFF1D9BF0); // Matching solid blue
  static const Color green  = Color(0xFF00BA7C); // Solid Green
  static const Color white  = text1;
  static final List<BoxShadow> cardShadow = [];

  // ── Helpers ───────────────────────────────────────────────────
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: body(color: isError ? text1 : black)),
        backgroundColor: isError ? red : accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Haptics ───────────────────────────────────────────────────
  static void tap()     { try { HapticFeedback.lightImpact();  } catch (_) {} }
  static void success() { try { HapticFeedback.mediumImpact(); } catch (_) {} }
  static void heavy()   { try { HapticFeedback.heavyImpact();  } catch (_) {} }

  // ── Typography (Artistic & Minimal) ───────────────────────────
  // We use Outfit for everything to ensure complete visual harmony.
  
  /// Huge, artistic page headers
  static TextStyle h1({Color? color}) => GoogleFonts.outfit(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: color ?? text1, letterSpacing: -1.0, height: 1.1,
  );

  /// Section headers
  static TextStyle h2({Color? color}) => GoogleFonts.outfit(
    fontSize: 20, fontWeight: FontWeight.w600,
    color: color ?? text1, letterSpacing: -0.5, height: 1.2,
  );

  /// Card titles, distinct labels
  static TextStyle h3({Color? color}) => GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w500,
    color: color ?? text1, letterSpacing: -0.2, height: 1.3,
  );

  /// Buttons, small active states
  static TextStyle label({Color? color}) => GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w700,
    color: color ?? text1, letterSpacing: 1.0, // Wide tracking for tech feel
  );

  /// Body text, descriptions
  static TextStyle body({Color? color}) => GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w300,
    color: color ?? text2, height: 1.6,
  );

  /// Muted captions
  static TextStyle caption({Color? color}) => GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: color ?? text3, letterSpacing: 0.5,
  );

  /// Data / Numbers (Space Mono for strict tabular lining)
  static TextStyle mono({Color? color, double size = 14}) => GoogleFonts.spaceMono(
    fontSize: size, fontWeight: FontWeight.w700,
    color: color ?? text1, letterSpacing: -0.5,
  );

  // ── Theme Data ────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent, // Let the Aura shine through
    primaryColor: accent,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: cyan,
      surface: black,
      error: red,
      onPrimary: black,
    ),
  );
}

// ── Shared Animation Curves ─────────────────────────────────────
class SGCurves {
  static const Curve smooth = Cubic(0.2, 0.8, 0.2, 1.0);
  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
}

// ── Fluid Touchable Wrapper ─────────────────────────────────────
class SGTouchable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool disabled;

  const SGTouchable({
    super.key, required this.child, this.onTap, this.disabled = false,
  });

  @override
  State<SGTouchable> createState() => _SGTouchableState();
}

class _SGTouchableState extends State<SGTouchable> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: SGCurves.smooth),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _down() { if (!widget.disabled) { _ctrl.forward(); AppTheme.tap(); } }
  void _up() { if (!widget.disabled) _ctrl.reverse(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: widget.disabled ? null : widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── Frosted Glass Card ──────────────────────────────────────────
class SGCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? glowColor;

  const SGCard({
    super.key, required this.child, this.padding, this.radius = 24, this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.8), // Rich solid surface
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: glowColor?.withValues(alpha: 0.5) ?? AppTheme.glassBorder, 
          width: 1.5
        ),
      ),
      child: child,
    );
  }
}

// ── Luminous Button ─────────────────────────────────────────────
class SGButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final bool outlined;
  final bool danger;
  final double height;
  final Color? customColor;

  const SGButton({
    super.key, required this.label, this.onTap,
    this.icon, this.loading = false, this.outlined = false,
    this.danger = false, this.height = 54, this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = customColor ?? (danger ? AppTheme.red : AppTheme.accent);
    
    return SGTouchable(
      onTap: onTap,
      disabled: loading || onTap == null,
      child: outlined 
      ? _buildOutlined(baseColor)
      : _buildSolid(baseColor),
    );
  }

  Widget _buildSolid(Color color) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        // Removed glowing effects completely
      ),
      child: Center(
        child: loading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.text1))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 20, color: AppTheme.text1), const SizedBox(width: 10)],
              Text(label, style: AppTheme.label(color: AppTheme.text1)),
            ]),
      ),
    );
  }

  Widget _buildOutlined(Color color) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: loading 
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 20, color: color), const SizedBox(width: 10)],
              Text(label, style: AppTheme.label(color: color)),
            ]),
      ),
    );
  }
}

// ── Sleek Section Header ────────────────────────────────────────
class SGSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SGSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(title.toUpperCase(), style: AppTheme.label(color: AppTheme.text2)),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

// ── Screen Entrance Animation ───────────────────────────────────
class SGScreenEntrance extends StatefulWidget {
  final Widget child;
  const SGScreenEntrance({super.key, required this.child});

  @override
  State<SGScreenEntrance> createState() => _SGScreenEntranceState();
}

class _SGScreenEntranceState extends State<SGScreenEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: SGCurves.smooth),
    );
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
