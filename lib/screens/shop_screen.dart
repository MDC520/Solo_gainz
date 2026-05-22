import 'package:flutter/cupertino.dart';

import 'buy_screen.dart';
import '../models/storage.dart';
import '../ui/theme.dart';
import '../widgets/chest.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late UserStats _s;
  int _tab = 0;

  static const _tabs = ['Boosts', 'Premium', 'Cosmetics', 'Chests'];

  @override
  void initState() {
    super.initState();
    _s = Storage.getUserStats();
    _load();
  }

  void _load() => setState(() => _s = Storage.getUserStats());

  void _openBuyCoins() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuyScreen()),
    ).then((value) {
      if (value != null) {
        _load();
      }
    });
  }

  // ── Chest Purchase Flow ──────────────────────────────────────
  void _buyChest(String chestType, String chestName, int price) {
    final availableSlots =
        Storage.getInventorySlots().where((s) => s == null).length;
    final isFull = availableSlots < 1;
    final canBuy = _s.coins >= price;
    final spriteType = chestType.split('_').first;

    // Map description
    String description = '';
    if (chestType.contains('wooden')) {
      description =
          'A sturdy wooden chest. Rewards \$2–350. Chance of rare/jackpot loot!';
    } else if (chestType.contains('iron')) {
      description =
          'A reinforced iron chest. Rewards \$15–600. Higher quality drops.';
    } else if (chestType.contains('gold')) {
      description =
          'A magnificent gold chest. Rewards \$50–2000. Guaranteed epic drops.';
    } else {
      description =
          'A powerful and mysterious vault. Rewards \$150–5000. Pure high-tier gacha luck!';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.black.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border(
              top: BorderSide(
                  color: AppTheme.silver.withValues(alpha: 0.3), width: Responsive.dp(1.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: Responsive.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: Responsive.w(48),
                    height: Responsive.h(5),
                    decoration: BoxDecoration(
                      color: AppTheme.silver.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(Responsive.r(2.5)),
                    ),
                  ),
                  SizedBox(height: Responsive.h(24)),

                  // Large Item Square
                  Container(
                    width: Responsive.h(96),
                    height: Responsive.h(96),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(Responsive.r(20)),
                      border: Border.all(
                          color: AppTheme.silver.withValues(alpha: 0.25), width: Responsive.dp(1.5)),
                    ),
                    child: Center(
                      child: ChestSprite(
                        chestType: spriteType,
                        animation: 'Idle',
                        fps: 8,
                        size: 76,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.h(20)),

                  // Title & Price Info
                  Text(
                    chestName,
                    style: AppTheme.h2()
                        .copyWith(fontSize: Responsive.sp(22), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Price: ',
                        style: AppTheme.caption(color: AppTheme.text2)
                            .copyWith(fontSize: Responsive.sp(14)),
                      ),
                      Text(
                        '\$$price',
                        style: AppTheme.mono(size: 16, color: AppTheme.accent)
                            .copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(16)),

                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: AppTheme.body().copyWith(
                        color: AppTheme.text2,
                        fontSize: Responsive.sp(13),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.h(32)),

                  // Action Button
                  if (isFull)
                    Container(
                      width: double.infinity,
                      padding: Responsive.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(Responsive.r(16)),
                        border: Border.all(
                            color: AppTheme.red.withValues(alpha: 0.2), width: Responsive.dp(1.5)),
                      ),
                      child: Center(
                        child: Text(
                          'INVENTORY FULL',
                          style: AppTheme.label(color: AppTheme.red).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    )
                  else if (!canBuy)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.red.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          'NOT ENOUGH COINS (NEED \$${price - _s.coins} MORE)',
                          style: AppTheme.label(color: AppTheme.red).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: Responsive.sp(12),
                          ),
                        ),
                      ),
                    )
                  else
                    SGTouchable(
                      onTap: () async {
                        Navigator.pop(ctx); // Close sheet first
                        // Deduct coins
                        _s.coins -= price;
                        await Storage.saveUserStats(_s);
                        // Add chest to inventory
                        await Storage.addChestToInventory(chestType);
                        _load();
                        // Show chest arrival animation
                        _showChestArrival(chestType, chestName);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: Responsive.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(Responsive.r(16)),
                        ),
                        child: Center(
                          child: Text(
                            'CONFIRM PURCHASE',
                            style: AppTheme.label(color: Colors.black).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: Responsive.h(12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChestArrival(String chestType, String chestName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, anim2) {
        return _ChestArrivalPopup(
          chestType: chestType,
          chestName: chestName,
          qty: 1,
          onDone: () => Navigator.pop(ctx),
        );
      },
      transitionBuilder: (ctx, anim, anim2, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChestTab = _tab == 3;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.fromLTRB(20, 40, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gear Shop', style: AppTheme.h1()),
                        SizedBox(height: Responsive.h(4)),
                        Text(
                          'Exchange coins for elite upgrades.',
                          style: AppTheme.caption(color: AppTheme.text2),
                        ),
                      ],
                    ),
                    // Balance chip
                    Row(
                      children: [
                        Container(
                          padding: Responsive.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(Responsive.r(10)),
                            border: Border.all(
                                color: AppTheme.text1.withValues(alpha: 0.1),
                                width: Responsive.dp(1)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: Responsive.icon(16),
                                color: AppTheme.accent,
                              ),
                              SizedBox(width: Responsive.w(6)),
                              Text(
                                '${_s.coins}',
                                style: AppTheme.label().copyWith(
                                  color: AppTheme.text1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: Responsive.w(10)),
                        GestureDetector(
                          onTap: _openBuyCoins,
                          child: Container(
                            width: Responsive.h(34),
                            height: Responsive.h(34),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(Responsive.r(10)),
                              border: Border.all(
                                color: AppTheme.accent,
                                width: Responsive.dp(1.5),
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: Responsive.icon(18),
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(16)),
                // Segment tabs
                Container(
                  width: double.infinity,
                  padding: Responsive.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                    border: Border.all(color: AppTheme.silver, width: Responsive.dp(1.5)),
                  ),
                  child: CupertinoSlidingSegmentedControl<int>(
                    backgroundColor: AppTheme.surface,
                    thumbColor: AppTheme.accent,
                    groupValue: _tab,
                    onValueChanged: (v) {
                      if (v != null) setState(() => _tab = v);
                    },
                    children: {
                      for (int i = 0; i < _tabs.length; i++)
                        i: Padding(
                          padding: Responsive.symmetric(vertical: 8),
                          child: Text(
                            _tabs[i],
                            style: AppTheme.label(
                              color: _tab == i ? Colors.white : AppTheme.text2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isChestTab)
          SliverPadding(
            padding: Responsive.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _chestCard(
                  chestType: 'wooden',
                  name: 'Wooden Chest',
                  price: 80,
                ),
                const SizedBox(height: 16),
                _chestCard(
                  chestType: 'iron',
                  name: 'Iron Chest',
                  price: 150,
                ),
                const SizedBox(height: 16),
                _chestCard(
                  chestType: 'gold',
                  name: 'Gold Chest',
                  price: 400,
                ),
                const SizedBox(height: 16),
                _chestCard(
                  chestType: 'mysterious',
                  name: 'What a Chest',
                  price: 900,
                ),
              ]),
            ),
          )
        else
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: Responsive.icon(64),
                    color: AppTheme.text2.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: Responsive.h(16)),
                  Text(
                    'COMING SOON',
                    style: AppTheme.h2()
                        .copyWith(letterSpacing: 4, color: AppTheme.text2),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  Text(
                    'The blacksmith is still forging these items.',
                    style: AppTheme.caption(color: AppTheme.text2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _chestCard({
    required String chestType,
    required String name,
    required int price,
  }) {
    final canBuy = _s.coins >= price;
    final chestTypeKey = '${chestType}_chest';
    final availableSlots =
        Storage.getInventorySlots().where((s) => s == null).length;
    final isFull = availableSlots == 0;

    return Container(
      padding: Responsive.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        border: Border.all(color: AppTheme.silver, width: Responsive.dp(1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item square container enclosing the chest visual centered perfectly
          Container(
            width: Responsive.h(56),
            height: Responsive.h(56),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              border: Border.all(
                  color: AppTheme.silver.withValues(alpha: 0.15), width: Responsive.dp(1.2)),
            ),
            child: Center(
              child: ChestSprite(
                chestType: chestType,
                animation: 'Idle',
                fps: 8,
                size: 44,
                alignment: Alignment.center,
              ),
            ),
          ),
          SizedBox(width: Responsive.w(16)),
          // Chest Title: guaranteed to be in the same line
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.h3().copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: Responsive.w(12)),
          // Compact Buy Button: guaranteed to be in the same line
          SGTouchable(
            onTap: () => _buyChest(chestTypeKey, name, price),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: Responsive.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (canBuy && !isFull) ? AppTheme.accent : AppTheme.surface,
                borderRadius: BorderRadius.circular(Responsive.r(14)),
                border: Border.all(
                  color: (canBuy && !isFull)
                      ? AppTheme.accent
                      : AppTheme.text1.withValues(alpha: 0.15),
                  width: Responsive.dp(1.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFull ? 'FULL' : 'BUY \$',
                    style: AppTheme.label(
                      color: (canBuy && !isFull)
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.9),
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: Responsive.sp(13.5)),
                  ),
                  if (!isFull)
                    Text(
                      '$price',
                      style: AppTheme.mono(
                        size: 14.5,
                        color:
                            (canBuy && !isFull) ? Colors.black : Colors.white,
                      ).copyWith(fontWeight: FontWeight.w900),
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

// ── Chest Arrival Animation Popup ──────────────────────────────
class _ChestArrivalPopup extends StatefulWidget {
  final String chestType;
  final String chestName;
  final int qty;
  final VoidCallback onDone;

  const _ChestArrivalPopup({
    required this.chestType,
    required this.chestName,
    required this.qty,
    required this.onDone,
  });

  @override
  State<_ChestArrivalPopup> createState() => _ChestArrivalPopupState();
}

class _ChestArrivalPopupState extends State<_ChestArrivalPopup>
    with TickerProviderStateMixin {
  late AnimationController _arriveCtrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  late AnimationController _glowCtrl;

  bool _showButton = false;

  @override
  void initState() {
    super.initState();

    // High-impact fast entry (300ms)
    _arriveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _arriveCtrl, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _arriveCtrl, curve: Curves.easeIn),
    );

    // Dynamic glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _arriveCtrl.forward().then((_) {
      if (mounted) setState(() => _showButton = true);
    });
  }

  @override
  void dispose() {
    _arriveCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chestSpriteType = widget.chestType.split('_').first.toLowerCase();

    Color glowColor;
    if (chestSpriteType == 'wooden') {
      glowColor = AppTheme.amber;
    } else if (chestSpriteType == 'iron') {
      glowColor = AppTheme.cyan;
    } else if (chestSpriteType == 'gold') {
      glowColor = AppTheme.purple;
    } else {
      glowColor = AppTheme.accent; // Mysterious!
    }

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: AppTheme.body(),
        child: Center(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 28),
            child: ScaleTransition(
              scale: _scale,
              child: FadeTransition(
                opacity: _opacity,
                child: Container(
                  padding: Responsive.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(Responsive.r(28)),
                    border: Border.all(
                      color: AppTheme.silver,
                      width: Responsive.dp(2.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subtitle Header
                      Text(
                        'LOOT UNLOCKED',
                        style: AppTheme.label().copyWith(
                          color: glowColor,
                          letterSpacing: 3.0,
                          fontSize: Responsive.sp(12),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: Responsive.h(8)),
                      // Title Text
                      Text(
                        widget.qty > 1
                            ? '${widget.qty} CHESTS ACQUIRED!'
                            : 'CHEST ACQUIRED!',
                        style: AppTheme.h2().copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Responsive.h(32)),

                      // Perfectly Centered Glowing Sprite Visual
                      SizedBox(
                        width: Responsive.h(180),
                        height: Responsive.h(180),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Chest Sprite centered inside square
                            ChestSprite(
                              chestType: chestSpriteType,
                              animation: 'Idle',
                              fps: 12,
                              size: Responsive.h(110),
                              alignment: Alignment.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.h(24)),

                      // Chest Name Label
                      Text(
                        widget.chestName,
                        style: AppTheme.h1().copyWith(
                          fontSize: Responsive.sp(24),
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Responsive.h(6)),
                      Text(
                        'Stored securely in your inventory',
                        style: AppTheme.caption(color: AppTheme.text2),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Responsive.h(36)),

                      // Action Button (Continue)
                      AnimatedOpacity(
                        opacity: _showButton ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: SGTouchable(
                          onTap: widget.onDone,
                          child: Container(
                            width: double.infinity,
                            padding: Responsive.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(Responsive.r(16)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'CONTINUE',
                                style: AppTheme.label(color: Colors.black)
                                    .copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
