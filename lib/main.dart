import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui';
import 'background.dart';
import 'splash_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'quest_screen.dart';
import 'dungeon_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';
import 'storage.dart';
import 'security_service.dart';
import 'notifications.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI to transparent and edge-to-edge for immersive feel
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  ));

  // Enable full immersive display
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init storage & security in parallel
  try {
    await Hive.initFlutter();
    await Future.wait([
      Storage.init(),
      SecurityService.init(),
    ]);
    await NotificationService.init(); // Initialize notifications
    await AppTheme.init(); // Load saved theme & activate icon alias
  } catch (e) {
    debugPrint('Init error: $e');
  }


  runApp(const SoloGainzApp());
}

// ── Root App ───────────────────────────────────────────────────────
class SoloGainzApp extends StatelessWidget {
  const SoloGainzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Solo Gainz',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: const _AppRoot(),
        );
      },
    );
  }
}

// ── App Root State Machine ─────────────────────────────────────────
enum _AppState { splash, onboarding, shell }

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  _AppState _state = _AppState.splash;

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AppState.splash:
        return SplashScreen(onDone: _afterSplash);
      case _AppState.onboarding:
        return OnboardingScreen(onDone: () => _setState(_AppState.shell));
      case _AppState.shell:
        return RepaintBoundary(
          child: AppShell(key: AppShell.navKey, onLogout: _onLogout),
        );
    }
  }

  Future<void> _afterSplash() async {
    try { await Storage.checkDailyLoginReward(); } catch (_) {}
    _setState(Storage.isOnboarded() ? _AppState.shell : _AppState.onboarding);
  }

  Future<void> _onLogout() async => debugPrint('Logout disabled');

  void _setState(_AppState s) {
    if (mounted) setState(() => _state = s);
  }
}

// ── App Shell ──────────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  final VoidCallback onLogout;
  static final GlobalKey<AppShellState> navKey = GlobalKey<AppShellState>();

  const AppShell({super.key, required this.onLogout});

  static void navigateTo(int index) {
    navKey.currentState?.setIndex(index);
  }

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _idx = 0;

  void setIndex(int index) {
    if (mounted) setState(() => _idx = index);
  }
  late AnimationController _navAnimCtrl;

  // Pages are built lazily via AutomaticKeepAlive pattern
  static const _icons = [
    (Icons.space_dashboard_rounded, Icons.space_dashboard_outlined, 'Home'),
    (Icons.explore_rounded, Icons.explore_outlined, 'Quests'),
    (Icons.fort_rounded, Icons.fort_outlined, 'Dungeon'),
    (Icons.local_mall_rounded, Icons.local_mall_outlined, 'Shop'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  List<Widget> get _pages => [
    const RepaintBoundary(child: SGScreenEntrance(child: HomePage())),
    const RepaintBoundary(child: SGScreenEntrance(child: QuestPage())),
    const RepaintBoundary(child: SGScreenEntrance(child: DungeonPage())),
    const RepaintBoundary(child: SGScreenEntrance(child: ShopPage())),
    RepaintBoundary(
        child: SGScreenEntrance(child: ProfilePage(onLogout: widget.onLogout))),
  ];

  @override
  void initState() {
    super.initState();
    _navAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: Storage.isNavbarFloating() ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _navAnimCtrl.dispose();
    super.dispose();
  }

  static const double _gap = 16.0;
  static const double _navH = 64.0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Double-notifier: rebuilds when theme OR navbar settings change
    return AnimatedBuilder(
      animation: AppTheme.isDarkNotifier,
      builder: (context, _) => ValueListenableBuilder(
        valueListenable: Storage.watch(['is_navbar_floating', 'is_navbar_hidden']),
        builder: (context, _, __) {
          final isFloating = Storage.isNavbarFloating();
          final isHidden = Storage.isNavbarHidden();

          if (isFloating && _navAnimCtrl.value != 1.0) {
            _navAnimCtrl.animateTo(1.0, curve: Curves.easeOutCubic);
          } else if (!isFloating && _navAnimCtrl.value != 0.0) {
            _navAnimCtrl.animateTo(0.0, curve: Curves.easeOutCubic);
          }

          return Stack(
            children: [
              RepaintBoundary(
                child: LivelyBackground(
                  isMoving: true,
                  child: const SizedBox.expand(),
                ),
              ),
              Scaffold(
                backgroundColor: Colors.transparent,
                extendBody: true,
                body: IndexedStack(index: _idx, children: _pages),
                bottomNavigationBar: AnimatedSlide(
                  offset: isHidden ? const Offset(0, 1.5) : Offset.zero,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn,
                  child: AnimatedBuilder(
                    animation: _navAnimCtrl,
                    builder: (context, child) {
                      final t = _navAnimCtrl.value;
                      final marginSide = 16.0 * t;
                      final radius = 20.0 * t;
                      final currentNavH = _navH + (bottomPadding * (1 - t));
                      final borderColor = Colors.white.withValues(alpha: 0.22);

                      return Container(
                        margin: EdgeInsets.fromLTRB(marginSide, 0, marginSide, _gap * t),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                            child: Container(
                              height: currentNavH,
                              padding: EdgeInsets.only(bottom: bottomPadding * (1 - t)),
                              decoration: BoxDecoration(
                                color: AppTheme.black,
                                borderRadius: BorderRadius.circular(radius),
                                border: Border(
                                  top: BorderSide(color: borderColor, width: 1.2),
                                  bottom: t > 0 ? BorderSide(color: borderColor, width: 1.2 * t) : BorderSide.none,
                                  left: t > 0 ? BorderSide(color: borderColor, width: 1.2 * t) : BorderSide.none,
                                  right: t > 0 ? BorderSide(color: borderColor, width: 1.2 * t) : BorderSide.none,
                                ),
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: List.generate(_icons.length, (i) {
                        final sel = _idx == i;
                        final item = _icons[i];
                        return Expanded(
                          child: SGTouchable(
                            onTap: () => setState(() => _idx = i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  sel ? item.$1 : item.$2,
                                  size: 20,
                                  color: sel ? AppTheme.accent : AppTheme.text3,
                                ),
                                const SizedBox(height: 4),
                                Text(item.$3, style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                  color: sel ? AppTheme.accent : AppTheme.text3,
                                  letterSpacing: 0.5,
                                )),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

             ],
          );
        },
      ),
    );
  }
}
