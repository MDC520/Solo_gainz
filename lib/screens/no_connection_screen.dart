import '../main.dart';
import '../theme/theme.dart';

class NoConnectionScreen extends StatefulWidget {
  final VoidCallback onConnected;
  const NoConnectionScreen({super.key, required this.onConnected});

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_checking) return;
    setState(() => _checking = true);
    AppTheme.tap();

    await Future.delayed(const Duration(milliseconds: 400));
    final online = await ConnectivityUtils.isOnline();

    if (!mounted) return;
    if (online) {
      AppTheme.success();
      widget.onConnected();
    } else {
      setState(() => _checking = false);
      AppTheme.heavy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Subtle radial glow behind the icon
          Center(
            child: ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.red.withValues(alpha: 0.12),
                      AppTheme.red.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.red.withValues(alpha: 0.08),
                        border: Border.all(
                            color: AppTheme.red.withValues(alpha: 0.25),
                            width: 1.5),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 64,
                        color: AppTheme.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Title
                  Text(
                    'No Connection',
                    style: AppTheme.h1().copyWith(letterSpacing: -1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Solo Gainz requires an active internet connection to keep your progress synced and secure.',
                    style: AppTheme.body(color: AppTheme.text2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    child: SGButton(
                      label: _checking ? 'Checking...' : 'Retry Connection',
                      icon: _checking ? null : Icons.refresh_rounded,
                      loading: _checking,
                      onTap: _retry,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hint
                  Text(
                    'Make sure you have an active Wi-Fi or mobile data connection.',
                    style: AppTheme.caption(color: AppTheme.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
