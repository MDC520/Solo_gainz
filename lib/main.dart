import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui';
import 'background.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/quest_screen.dart';
import 'screens/dungeon_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/no_connection_screen.dart';
import 'screens/login_screen.dart';
import 'services/storage.dart';
import 'services/security_service.dart';
import 'services/notification_manager.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notification Manager
  final notificationManager = NotificationManager();
  await notificationManager.init();

  // Edge-to-edge display (better than immersiveSticky — less jank)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

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
  } catch (e) {
    debugPrint('Init error: $e');
  }

  // Init Supabase (auth service)
  try {
    // await AuthService().initialize();
    debugPrint('Supabase initialization bypassed');
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  runApp(const SoloGainzApp());
}

// ── Root App ───────────────────────────────────────────────────────
class SoloGainzApp extends StatelessWidget {
  const SoloGainzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solo Gainz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _AppRoot(),
    );
  }
}

// ── App Root State Machine ─────────────────────────────────────────
enum _AppState { splash, noConnection, login, onboarding, shell }

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

      case _AppState.noConnection:
        return NoConnectionScreen(onConnected: _onConnected);

      case _AppState.login:
        return LoginScreen(
          onSignUpSuccess: _goToOnboarding,
          onSignInSuccess: _goToShell,
        );

      case _AppState.onboarding:
        return OnboardingScreen(onDone: _goToShell);

      case _AppState.shell:
        return RepaintBoundary(
          child: AppShell(key: AppShell.navKey, onLogout: _onLogout),
        );
    }
  }

  // ── Splash done ────────────────────────────────────────────────
  Future<void> _afterSplash() async {
    // Skip connectivity and auth checks
    try {
      await Storage.checkDailyLoginReward();
    } catch (_) {}
    _setState(_AppState.shell);
  }

  // ── No connection → retry ──────────────────────────────────────
  void _onConnected() {
    // After connectivity restored, re-evaluate auth state
    _afterSplashNoAnim();
  }

  Future<void> _afterSplashNoAnim() async {
    if (Storage.isLoggedIn()) {
      if (Storage.isOnboarded()) {
        _setState(_AppState.shell);
      } else {
        _setState(_AppState.onboarding);
      }
    } else {
      _setState(_AppState.login);
    }
  }

  // ── After sign-up ──────────────────────────────────────────────
  void _goToOnboarding() => _setState(_AppState.onboarding);

  // ── After sign-in or onboarding done ──────────────────────────
  void _goToShell() => _setState(_AppState.shell);

  // ── Logout ────────────────────────────────────────────────────
  Future<void> _onLogout() async {
    // await AuthService().logout();
    // _setState(_AppState.login);
    debugPrint('Logout disabled');
  }

  void _setState(_AppState s) {
    if (mounted) setState(() => _state = s);
  }
}

// ── App Shell ──────────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  final VoidCallback onLogout;
  static final GlobalKey<_AppShellState> navKey = GlobalKey<_AppShellState>();
  static final ValueNotifier<List<({double b, double r})>> midnightOdds = ValueNotifier([]);
  const AppShell({super.key, required this.onLogout});

  static void navigateTo(int index) {
    navKey.currentState?.setIndex(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _navAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: Storage.isNavbarFloating() ? 1.0 : 0.0,
    );
    _pages = [
      const RepaintBoundary(child: SGScreenEntrance(child: HomePage())),
      const RepaintBoundary(child: SGScreenEntrance(child: QuestPage())),
      const RepaintBoundary(child: SGScreenEntrance(child: DungeonPage())),
      const RepaintBoundary(child: SGScreenEntrance(child: ShopPage())),
      RepaintBoundary(
          child:
              SGScreenEntrance(child: ProfilePage(onLogout: widget.onLogout))),
    ];
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

    return ValueListenableBuilder(
      valueListenable:
          Storage.watch(['is_navbar_floating', 'is_navbar_hidden']),
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
              body: SafeArea(
                bottom: false,
                child: IndexedStack(index: _idx, children: _pages),
              ),
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

                    return Container(
                      margin: EdgeInsets.fromLTRB(
                          marginSide, 0, marginSide, _gap * t),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            height: currentNavH,
                            padding: EdgeInsets.only(
                                bottom: bottomPadding * (1 - t)),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.01),
                              borderRadius: BorderRadius.circular(radius),
                              border: Border(
                                top: BorderSide(
                                    color: AppTheme.accent.withValues(alpha: 0.4), width: 1.5),
                                bottom: BorderSide(
                                    color: t > 0.01
                                        ? AppTheme.accent.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: t > 0.01 ? 1.2 : 0),
                                left: BorderSide(
                                    color: t > 0.01
                                        ? AppTheme.accent.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: t > 0.01 ? 1.2 : 0),
                                right: BorderSide(
                                    color: t > 0.01
                                        ? AppTheme.accent.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: t > 0.01 ? 1.2 : 0),
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
                                color: sel ? AppTheme.accent : AppTheme.white,
                              ),
                              const SizedBox(height: 4),
                              Text(item.$3,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight:
                                        sel ? FontWeight.w600 : FontWeight.w500,
                                    color:
                                        sel ? AppTheme.accent : AppTheme.white,
                                    letterSpacing: 0.2,
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
            ValueListenableBuilder(
              valueListenable: AppShell.midnightOdds,
              builder: (context, odds, _) {
                return IgnorePointer(
                  ignoring: true,
                  child: Stack(
                    children: odds.map((pos) => Positioned(
                      bottom: pos.b,
                      right: pos.r,
                      child: Image.asset(
                        'Assets/Odds7.png',
                        width: 250,
                        fit: BoxFit.contain,
                      ),
                    )).toList(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
