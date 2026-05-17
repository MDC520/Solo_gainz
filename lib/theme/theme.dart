import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage.dart';

export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Theme State ──────────────────────────────────────────────────────────
  static final ValueNotifier<bool> isDarkNotifier = ValueNotifier(true);
  static bool get isDark => isDarkNotifier.value;

  static Future<void> init() async {
    isDarkNotifier.value = Storage.getData('is_dark_mode', defaultValue: true);
    _updateSystemUI();
  }

  static void toggleTheme() {
    isDarkNotifier.value = !isDarkNotifier.value;
    Storage.saveData('is_dark_mode', isDarkNotifier.value);
    _updateSystemUI();
    heavy();
  }

  static void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // ── Colors ───────────────────────────────────────────────────────────────
  static Color get black      => isDark ? const Color(0xFF0A0A12) : const Color(0xFFE2E8F0); // Silver Light
  static Color get dark       => isDark ? const Color(0xFF14141F) : const Color(0xFFCBD5E1); // Silver Dark
  static Color get accent     => isDark ? const Color(0xFF00B8D4) : const Color(0xFF0F172A);
  static Color get cyan       => isDark ? const Color(0xFF00B8D4) : const Color(0xFF059669);
  static Color get amber      => isDark ? const Color(0xFFFACC15) : const Color(0xFFD97706);
  static Color get red        => isDark ? const Color(0xFFFF4B4B) : const Color(0xFFDC2626);
  static Color get purple     => isDark ? const Color(0xFF7000FF) : const Color(0xFF7C3AED);
  static Color get silver     => isDark ? const Color(0xFF94A3B8) : const Color(0xFF1F2937);

  // ── Glass & Borders ──────────────────────────────────────────────────────
  static Color get glassLight  => isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02);
  static Color get glassMedium => isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.05);
  static Color get glassBorder => isDark ? Colors.white.withOpacity(0.15) : const Color(0xFF111827);

  // ── Text ─────────────────────────────────────────────────────────────────
  static Color get text1 => isDark ? const Color(0xFFFDFCF7) : const Color(0xFF111827);
  static Color get text2 => isDark ? const Color(0xFFFDFCF7).withOpacity(0.7) : const Color(0xFF4B5563);
  static Color get text3 => isDark ? const Color(0xFFFDFCF7).withOpacity(0.4) : const Color(0xFF9CA3AF);

  // ── Aliases ──────────────────────────────────────────────────────────────
  static Color get bg        => black;
  static Color get surface   => dark;
  static Color get elevated  => dark;
  static Color get line      => glassBorder;
  static Color get muted     => text3;
  static Color get white     => text1;
  static Color get green     => isDark ? const Color(0xFF00E676) : const Color(0xFF16A34A);
  static Color get accentDim => isDark ? accent.withOpacity(0.2) : const Color(0xFF334155);

  static final List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
  ];

  // ── Haptics ──────────────────────────────────────────────────────────────
  static void tap()     { try { HapticFeedback.lightImpact();  } catch (_) {} }
  static void success() { try { HapticFeedback.mediumImpact(); } catch (_) {} }
  static void heavy()   { try { HapticFeedback.heavyImpact();  } catch (_) {} }

  // ── Snackbar ─────────────────────────────────────────────────────────────
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: body(color: text1)),
        backgroundColor: isError ? red.withOpacity(0.1) : accent.withOpacity(0.1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isError ? red : accent, width: 1),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Typography ───────────────────────────────────────────────────────────
  static TextStyle h1({Color? color}) => GoogleFonts.outfit(
    fontSize: 32, fontWeight: FontWeight.w800, color: color ?? text1, letterSpacing: -1.0, height: 1.1,
  );
  static TextStyle h2({Color? color}) => GoogleFonts.outfit(
    fontSize: 20, fontWeight: FontWeight.w600, color: color ?? text1, letterSpacing: -0.5, height: 1.2,
  );
  static TextStyle h3({Color? color}) => GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w500, color: color ?? text1, letterSpacing: -0.2, height: 1.3,
  );
  static TextStyle label({Color? color}) => GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w700, color: color ?? text1, letterSpacing: 1.0,
  );
  static TextStyle body({Color? color}) => GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w300, color: color ?? text2, height: 1.6,
  );
  static TextStyle caption({Color? color}) => GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w400, color: color ?? text3, letterSpacing: 0.5,
  );
  static TextStyle mono({Color? color, double size = 14}) => GoogleFonts.spaceMono(
    fontSize: size, fontWeight: FontWeight.w700, color: color ?? text1, letterSpacing: -0.5,
  );

  // ── Theme Data ───────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: accent,
    colorScheme: isDark
      ? ColorScheme(
          brightness: Brightness.dark,
          primary: accent,
          onPrimary: Colors.black,
          secondary: cyan,
          onSecondary: Colors.black,
          error: red,
          onError: Colors.white,
          surface: black,
          onSurface: text1,
        )
      : ColorScheme(
          brightness: Brightness.light,
          primary: accent,
          onPrimary: Colors.white,
          secondary: cyan,
          onSecondary: Colors.white,
          error: red,
          onError: Colors.white,
          surface: black,
          onSurface: text1,
        ),
  );
}

// ── Animation Curves ─────────────────────────────────────────────────────────
class SGCurves {
  static const Curve smooth       = Cubic(0.2, 0.8, 0.2, 1.0);
  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
}

// ── Touchable Wrapper ────────────────────────────────────────────────────────
class SGTouchable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool disabled;

  const SGTouchable({super.key, required this.child, this.onTap, this.disabled = false});

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
  void _up()   { if (!widget.disabled) _ctrl.reverse(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _down(),
    onTapUp: (_) => _up(),
    onTapCancel: _up,
    onTap: widget.disabled ? null : widget.onTap,
    behavior: HitTestBehavior.opaque,
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

// ── Glass Card ───────────────────────────────────────────────────────────────
class SGCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? glowColor;

  const SGCard({super.key, required this.child, this.padding, this.radius = 24, this.glowColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.surface.withOpacity(0.8),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glowColor?.withOpacity(0.5) ?? AppTheme.glassBorder,
        width: 1.5,
      ),
    ),
    child: child,
  );
}

// ── Button ───────────────────────────────────────────────────────────────────
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
    final color = customColor ?? (danger ? AppTheme.red : AppTheme.accent);
    return SGTouchable(
      onTap: onTap,
      disabled: loading || onTap == null,
      child: outlined ? _buildOutlined(color) : _buildSolid(color),
    );
  }

  Widget _buildSolid(Color color) => Container(
    height: height,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Center(
      child: loading
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 10)],
            Text(label, style: AppTheme.label(color: Colors.white)),
          ]),
    ),
  );

  Widget _buildOutlined(Color color) => Container(
    height: height,
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.5), width: 1.5),
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

// ── Section Header ───────────────────────────────────────────────────────────
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
        Row(children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: AppTheme.label(color: AppTheme.text2)),
        ]),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

// ── Screen Entrance Animation ─────────────────────────────────────────────────
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
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
