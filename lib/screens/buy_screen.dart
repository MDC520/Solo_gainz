import '../models/storage.dart';
import '../ui/theme.dart';
import '../widgets/background.dart';

class _Bundle {
  final int coins;
  final String title;
  final String subtitle;
  final String price;
  final Color color;
  _Bundle({
    required this.coins,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.color,
  });
}

class BuyScreen extends StatelessWidget {
  const BuyScreen({super.key});

  static final _bundles = [
    _Bundle(
      coins: 500,
      title: 'Rookie Stash',
      subtitle: 'Best for quick boosts',
      price: '\$0.99',
      color: AppTheme.cyan,
    ),
    _Bundle(
      coins: 1200,
      title: 'Hunter Cache',
      subtitle: 'Great value for grinders',
      price: '\$2.99',
      color: AppTheme.accent,
    ),
    _Bundle(
      coins: 3000,
      title: 'Warrior Trove',
      subtitle: 'Maximum value & bonuses',
      price: '\$4.99',
      color: AppTheme.amber,
    ),
    _Bundle(
      coins: 7500,
      title: 'Knight Hoard',
      subtitle: 'Best price per coin',
      price: '\$9.99',
      color: AppTheme.green,
    ),
    _Bundle(
      coins: 15000,
      title: 'Hero Vault',
      subtitle: 'Epic coin reserves',
      price: '\$14.99',
      color: AppTheme.purple,
    ),
    _Bundle(
      coins: 40000,
      title: 'Legendary Trove',
      subtitle: 'The ultimate treasury',
      price: '\$29.99',
      color: AppTheme.red,
    ),
  ];

  Future<void> _purchase(BuildContext context, _Bundle bundle) async {
    final stats = Storage.getUserStats();
    stats.coins += bundle.coins;
    await Storage.saveUserStats(stats);
    await Storage.saveData('coins', stats.coins);

    if (!context.mounted) return;

    Navigator.pop(context, bundle.coins);
  }

  @override
  Widget build(BuildContext context) {
    return LivelyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Premium Consistent Header ──
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coin Shop', style: AppTheme.h1()),
                          const SizedBox(height: 4),
                          Text(
                            'Fuel your grind and gain the edge.',
                            style: AppTheme.caption(color: AppTheme.text2),
                          ),
                        ],
                      ),
                      // Rounded Close Button matching settings & quest screen
                      SGTouchable(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.text2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Grid of Bundles ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bundle = _bundles[index];

                    return SGTouchable(
                      onTap: () => _purchase(context, bundle),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.silver,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Title
                                Text(
                                  bundle.title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.label().copyWith(
                                    color: bundle.color,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                // Premium Dollar Medallion Icon with Glow Shadow
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        bundle.color.withValues(alpha: 0.3),
                                        bundle.color.withValues(alpha: 0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: bundle.color.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.attach_money_rounded,
                                      size: 28,
                                      color: bundle.color,
                                    ),
                                  ),
                                ),

                                // Amount of Coins
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${bundle.coins}',
                                      style: AppTheme.h1().copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'COINS',
                                      style: AppTheme.label().copyWith(
                                        fontSize: 9,
                                        color: AppTheme.text2,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    )
                                  ],
                                ),

                                // Subtitle
                                Text(
                                  bundle.subtitle,
                                  style: AppTheme.caption(color: AppTheme.text2)
                                      .copyWith(
                                    fontSize: 9.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Price tag matching bundle's color
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: bundle.color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      bundle.price,
                                      style: AppTheme.label().copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _bundles.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
