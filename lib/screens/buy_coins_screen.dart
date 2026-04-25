import '../services/auth_service.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../background.dart';

class _Bundle {
  final int coins;
  final String title;
  final String subtitle;
  final String price;
  final Color color;
  const _Bundle({
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
      title: 'Starter Pack',
      subtitle: 'Best for quick boosts',
      price: '\$4.99',
      color: AppTheme.cyan,
    ),
    _Bundle(
      coins: 1200,
      title: 'Pro Pack',
      subtitle: 'Great value for grinders',
      price: '\$9.99',
      color: AppTheme.accent,
    ),
    _Bundle(
      coins: 3000,
      title: 'Mega Pack',
      subtitle: 'Maximum value & bonuses',
      price: '\$19.99',
      color: AppTheme.amber,
    ),
    _Bundle(
      coins: 7500,
      title: 'Legend Pack',
      subtitle: 'Best price per coin',
      price: '\$29.99',
      color: AppTheme.green,
    ),
  ];

  Future<void> _purchase(BuildContext context, _Bundle bundle) async {
    final stats = Storage.getUserStats();
    stats.coins += bundle.coins;
    await Storage.saveUserStats(stats);
    await Storage.saveData('coins', stats.coins);
    await AuthService().syncData();

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.text1),
          title: Text('Store', style: AppTheme.h2()),
          centerTitle: true,
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.elevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.amber, width: 1),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 28,
                        color: AppTheme.amber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FUEL YOUR GRIND',
                      style: AppTheme.h1().copyWith(
                        letterSpacing: 2,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the perfect supply drop to gain the edge.',
                      textAlign: TextAlign.center,
                      style: AppTheme.body(color: AppTheme.text2),
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
                    final isPopular = index == 2;
                    final isBest = index == 3;

                    return SGTouchable(
                      onTap: () => _purchase(context, bundle),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPopular || isBest
                                ? bundle.color
                                : AppTheme.line,
                            width: isPopular || isBest ? 2.5 : 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Subtle radial glow behind the icon
                              const SizedBox(),

                              // Main content
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                    12, isPopular || isBest ? 28 : 20, 12, 12),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                      style: AppTheme.caption(
                                              color: AppTheme.text2)
                                          .copyWith(
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isPopular || isBest
                                            ? bundle.color
                                            : AppTheme.elevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isPopular || isBest
                                            ? null
                                            : Border.all(
                                                color: AppTheme.line, width: 1),
                                      ),
                                      child: Center(
                                        child: Text(
                                          bundle.price,
                                          style: AppTheme.label().copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: isPopular || isBest
                                                ? AppTheme.white
                                                : AppTheme.text1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Top Banner for popular / best
                              if (isPopular || isBest)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: bundle.color,
                                    ),
                                    child: Text(
                                      isPopular ? 'MOST POPULAR' : 'BEST VALUE',
                                      textAlign: TextAlign.center,
                                      style:
                                          AppTheme.label(color: AppTheme.white)
                                              .copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
