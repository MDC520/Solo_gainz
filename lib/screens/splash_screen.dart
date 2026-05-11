import '../theme/theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 50), _ctrl.forward);
    // Reduced from 2100ms to 1200ms to make it fast
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: Text('SOLO GAINZ',
                    style: GoogleFonts.poppins(
                      fontSize: 36, // Smaller title
                      fontWeight: FontWeight.w900,
                      color: AppTheme.text1,
                      letterSpacing: 4,
                    )),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('powered by',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.text2,
                          letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 4),
                    Text('Xoventic',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text1,
                          letterSpacing: 2,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
