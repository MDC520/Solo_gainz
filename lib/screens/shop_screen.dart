import 'package:flutter/cupertino.dart';
import '../models/user_stats.dart';
import '../screens/buy_coins_screen.dart';
import '../services/storage.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/chest_sprite.dart';

class _Item {
  final int id, price, tab;
  final String name, desc;
  final IconData icon;
  final Color color;
  const _Item({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.icon,
    required this.color,
    required this.tab,
  });
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late UserStats _s;
  int _tab = 0;
  int _woodenQty = 1;
  int _ironQty = 1;

  static final _items = [
    _Item(
      id: 1,
      name: 'Energy Boost',
      desc: '1.5× XP multiplier for one session.',
      price: 100,
      icon: Icons.electric_bolt,
      color: AppTheme.accent,
      tab: 0,
    ),
    _Item(
      id: 2,
      name: 'Double XP',
      desc: '2× XP for the next 24 hours.',
      price: 250,
      icon: Icons.refresh,
      color: AppTheme.cyan,
      tab: 0,
    ),
    _Item(
      id: 5,
      name: 'Coin Multiplier',
      desc: '2× coins earned for 7 days.',
      price: 200,
      icon: Icons.generating_tokens_rounded,
      color: AppTheme.amber,
      tab: 0,
    ),
    _Item(
      id: 3,
      name: 'Level Skip',
      desc: 'Advance to the next level instantly.',
      price: 500,
      icon: Icons.arrow_circle_up,
      color: AppTheme.green,
      tab: 1,
    ),
    _Item(
      id: 4,
      name: 'Perfect Day',
      desc: 'Auto-complete all quests today.',
      price: 300,
      icon: Icons.verified,
      color: AppTheme.accent,
      tab: 1,
    ),
    _Item(
      id: 6,
      name: 'Elite Badge',
      desc: 'Unlock a premium profile cosmetic.',
      price: 1000,
      icon: Icons.security,
      color: AppTheme.amber,
      tab: 2,
    ),
  ];

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
      MaterialPageRoute(builder: (_) => const BuyCoinsScreen()),
    ).then((value) {
      if (value != null) {
        _load();
      }
    });
  }

  void _buy(_Item item) {
    if (_s.coins >= item.price) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(item.name, style: AppTheme.h3()),
          content: Text(
            '${item.desc}\n\nCost: ${item.price} coins.',
            style: AppTheme.body(),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Cancel',
                style: AppTheme.body(color: AppTheme.text2),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                'Purchase',
                style: AppTheme.label(color: AppTheme.accent),
              ),
              onPressed: () async {
                _s.coins -= item.price;
                await Storage.saveUserStats(_s);
                await AuthService().syncData();
                Navigator.pop(ctx);
                _load();
                _ok(item.name);
              },
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Not enough coins', style: AppTheme.h3()),
          content: Text(
            'You need ${item.price - _s.coins} more coins.',
            style: AppTheme.body(),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('OK', style: AppTheme.label(color: AppTheme.accent)),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  void _ok(String name) => showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Purchased', style: AppTheme.h3()),
          content: Text('$name activated.', style: AppTheme.body()),
          actions: [
            CupertinoDialogAction(
              child:
                  Text('Done', style: AppTheme.label(color: AppTheme.accent)),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );

  // ── Chest Purchase Flow ──────────────────────────────────────
  void _buyChest(String chestType, String chestName, int unitPrice, int qty) {
    final totalPrice = unitPrice * qty;
    final availableSlots =
        Storage.getInventorySlots().where((s) => s == null).length;

    // 1. Check inventory space
    if (availableSlots < qty) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Not Enough Space', style: AppTheme.h3()),
          content: Text(
            'You only have $availableSlots empty slots, but you want to buy $qty chests.',
            style: AppTheme.body(),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('OK', style: AppTheme.label(color: AppTheme.accent)),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Check coins
    if (_s.coins < totalPrice) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Not enough coins', style: AppTheme.h3()),
          content: Text(
            'You need ${totalPrice - _s.coins} more T coins to buy $qty chests.',
            style: AppTheme.body(),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('OK', style: AppTheme.label(color: AppTheme.accent)),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    // 3. Confirmation popup
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Buy $chestName${qty > 1 ? " x$qty" : ""}',
            style: AppTheme.h3()),
        content: Text(
          'This will cost $totalPrice T coins.\nThe chest${qty > 1 ? "s" : ""} will be placed in your inventory.',
          style: AppTheme.body(),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.body(color: AppTheme.text2)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child:
                Text('Purchase', style: AppTheme.label(color: AppTheme.accent)),
            onPressed: () async {
              // Deduct coins
              _s.coins -= totalPrice;
              await Storage.saveUserStats(_s);
              await AuthService().syncData();
              // Add chests to inventory
              for (int i = 0; i < qty; i++) {
                await Storage.addChestToInventory(chestType);
              }
              Navigator.pop(ctx);
              _load();
              // Show chest arrival animation
              _showChestArrival(chestType, chestName, qty);
            },
          ),
        ],
      ),
    );
  }

  void _showChestArrival(String chestType, String chestName, int qty) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, anim2) {
        return _ChestArrivalPopup(
          chestType: chestType,
          chestName: chestName,
          qty: qty,
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
    final filtered = _items.where((i) => i.tab == _tab).toList();
    final isChestTab = _tab == 3;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shop', style: AppTheme.h2()),
                      // Balance chip
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.amber.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.generating_tokens_rounded,
                                      size: 16,
                                      color: AppTheme.white,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_s.coins}',
                                  style: AppTheme.label().copyWith(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _openBuyCoins,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Segment tabs
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      backgroundColor: AppTheme.surface,
                      thumbColor: AppTheme.elevated,
                      groupValue: _tab,
                      onValueChanged: (v) {
                        if (v != null) setState(() => _tab = v);
                      },
                      children: {
                        for (int i = 0; i < _tabs.length; i++)
                          i: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _tabs[i],
                              style: AppTheme.label(
                                color:
                                    _tab == i ? AppTheme.text1 : AppTheme.text2,
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
        ),
        if (isChestTab)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _chestCard(
                  chestType: 'wooden',
                  name: 'Wooden Chest',
                  desc:
                      'A sturdy wooden chest. Rewards 6–399 T coins. Rare drops above 100.',
                  price: 900,
                  borderColor: const Color(0xFF8B6914),
                  glowColor: const Color(0xFF8B6914),
                  qty: _woodenQty,
                  onQtyChanged: (v) => setState(() => _woodenQty = v),
                ),
                const SizedBox(height: 14),
                _chestCard(
                  chestType: 'iron',
                  name: 'Iron Chest',
                  desc:
                      'A reinforced iron chest. Rewards 6–399 T coins. Better drop rates.',
                  price: 1600,
                  borderColor: const Color(0xFF7B8794),
                  glowColor: const Color(0xFF9CA8B7),
                  qty: _ironQty,
                  onQtyChanged: (v) => setState(() => _ironQty = v),
                ),
              ]),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _card(filtered[i]),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _chestCard({
    required String chestType,
    required String name,
    required String desc,
    required int price,
    required Color borderColor,
    required Color glowColor,
    required int qty,
    required ValueChanged<int> onQtyChanged,
  }) {
    final canSingle = _s.coins >= price;
    final totalCost = price * qty;
    final canTotal = _s.coins >= totalCost;
    final chestTypeKey = chestType == 'wooden' ? 'wooden_chest' : 'iron_chest';
    final availableSlots =
        Storage.getInventorySlots().where((s) => s == null).length;

    return SGTouchable(
      onTap: () => _buyChest(chestTypeKey, name, price, qty),
      child: SGCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Animated chest sprite
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  // Ground shadow
                  Container(
                    width: 44,
                    height: 8,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Chest
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ChestSprite(
                      chestType: chestType,
                      animation: 'Idle',
                      fps: 8,
                      size: 64,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTheme.label()),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: AppTheme.caption(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity selector
                      GestureDetector(
                        onTap: () {}, // Absorb taps
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.elevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _qtyBtn(
                                icon: Icons.remove,
                                onTap: qty > 1
                                    ? () => onQtyChanged(qty - 1)
                                    : null,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '$qty',
                                  style: AppTheme.mono(
                                          size: 14, color: AppTheme.white)
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              _qtyBtn(
                                icon: Icons.add,
                                onTap: qty < availableSlots && qty < 99
                                    ? () => onQtyChanged(qty + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Price & Buy Button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Price
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$totalCost',
                                style: AppTheme.mono(
                                  color: canTotal
                                      ? AppTheme.white
                                      : AppTheme.text2,
                                  size: 15,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 4),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.generating_tokens_rounded,
                                    size: 14,
                                    color: canTotal
                                        ? AppTheme.white
                                        : AppTheme.muted,
                                  ),
                                  if (canTotal)
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          // Removed glow shadow per user request
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Buy button
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: canTotal && availableSlots >= qty
                                  ? AppTheme.accent
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: canTotal && availableSlots >= qty
                                  ? null
                                  : Border.all(color: AppTheme.line),
                            ),
                            child: Text(
                              availableSlots == 0 ? 'Full' : 'Buy',
                              style: AppTheme.label(
                                color: canTotal && availableSlots >= qty
                                    ? Colors.white
                                    : AppTheme.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, VoidCallback? onTap}) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: disabled ? Colors.transparent : AppTheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon,
            size: 14,
            color: disabled
                ? AppTheme.muted.withValues(alpha: 0.3)
                : AppTheme.white),
      ),
    );
  }

  Widget _card(_Item item) {
    final can = _s.coins >= item.price;
    return GestureDetector(
      onTap: () => _buy(item),
      child: SGCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.glassMedium,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 16, color: item.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTheme.label()),
                  const SizedBox(height: 3),
                  Text(item.desc, style: AppTheme.caption()),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.price}',
                      style: AppTheme.mono(
                        color: can ? AppTheme.white : AppTheme.text2,
                        size: 15,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.generating_tokens_rounded,
                          size: 14,
                          color: can ? AppTheme.white : AppTheme.muted,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: can ? AppTheme.accent : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: can ? null : Border.all(color: AppTheme.line),
                  ),
                  child: Text(
                    'Buy',
                    style: AppTheme.label(
                      color: can ? Colors.white : AppTheme.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
  late Animation<Offset> _slide;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  bool _showButton = false;

  @override
  void initState() {
    super.initState();

    // Chest flies in from far away
    _arriveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scale = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _arriveCtrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _arriveCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 3), end: Offset.zero).animate(
      CurvedAnimation(parent: _arriveCtrl, curve: Curves.easeOutBack),
    );

    // Glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _arriveCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showButton = true);
      });
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
    final chestSpriteType =
        widget.chestType == 'wooden_chest' ? 'wooden' : 'iron';
    final glowColor =
        chestSpriteType == 'wooden' ? AppTheme.amber : AppTheme.cyan;

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: AppTheme.body(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              AnimatedBuilder(
                animation: _arriveCtrl,
                builder: (context, child) => Opacity(
                  opacity: _opacity.value,
                  child: Text(
                    widget.qty > 1
                        ? '${widget.qty} Chests Acquired!'
                        : 'Chest Acquired!',
                    style: AppTheme.h1(color: AppTheme.accent)
                        .copyWith(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Animated chest with glow
              AnimatedBuilder(
                animation: Listenable.merge([_arriveCtrl, _glowCtrl]),
                builder: (context, child) => SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Opacity(
                      opacity: _opacity.value.clamp(0.0, 1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow Effect
                          Transform.scale(
                            scale: _glowAnim.value * 2.0,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: glowColor.withValues(
                                        alpha: 0.4 * _glowAnim.value),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Chest
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: Center(
                              child: ChestSprite(
                                chestType: chestSpriteType,
                                animation: 'Idle',
                                fps: 10,
                                size: 120,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _arriveCtrl,
                builder: (context, child) => Opacity(
                  opacity: _opacity.value,
                  child: Text(
                    '${widget.chestName}${widget.qty > 1 ? " x${widget.qty}" : ""}',
                    style: AppTheme.h2(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _arriveCtrl,
                builder: (context, child) => Opacity(
                  opacity: _opacity.value,
                  child: Text(
                    'Added to your inventory',
                    style: AppTheme.caption(color: AppTheme.text2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Done button
              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: SGTouchable(
                  onTap: widget.onDone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Continue',
                        style: AppTheme.label(color: Colors.white)),
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
