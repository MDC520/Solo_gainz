import '../services/storage.dart';
import '../theme/theme.dart';
import '../background.dart';

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

class BuyCoinsScreen extends StatelessWidget {
  const BuyCoinsScreen({super.key});

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
    // await Storage.syncData();

    if (!context.mounted) return;

    AppTheme.showSnackBar(
      context,
      'Purchased ${bundle.title} for ${bundle.price}.',
    );

    Navigator.pop(context, bundle.coins);
  }

  @override
  Widget build(BuildContext context) {
    return LivelyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Coin Shop', style: AppTheme.h1()),
                                const SizedBox(height: 4),
                                Text(
                                  'Fuel your grind and gain the edge.',
                                  style: AppTheme.caption(),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.line, width: 1.5),
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
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.line,
                            width: 1.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Title
                                Text(
                                  bundle.title.toUpperCase(),
                                  style: AppTheme.label().copyWith(
                                    color: bundle.color,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                // Icon / Coins graphic
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.generating_tokens_rounded,
                                      size: 48,
                                      color: AppTheme.white,
                                    ),
                                  ],
                                ),

                                // Amount
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
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
                                      'T COINS',
                                      style: AppTheme.label().copyWith(
                                        fontSize: 9,
                                        color: AppTheme.text2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                ),

                                // Subtitle
                                Text(
                                  bundle.subtitle,
                                  style: AppTheme.caption(color: AppTheme.text2).copyWith(
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                // Price tag
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cyan,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      bundle.price,
                                      style: AppTheme.label().copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
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
      ),
    );
  }
}
