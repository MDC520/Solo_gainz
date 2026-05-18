
import 'storage.dart';
import 'notifications.dart';
import 'theme.dart';
import 'background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _transitionCompleted = false;
  bool _notificationsEnabled = true;
  String _notificationTime = '08:00';

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = Storage.getData('notifications_enabled', defaultValue: true);
    _notificationTime = Storage.getData('notification_time', defaultValue: '08:00');
    // BUTTERY SMOOTH TRANSITIONS: Defer heavy widgets
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _transitionCompleted = true);
      }
    });
  }

  Future<void> _selectTime() async {
    final parts = _notificationTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.cyan,
              onPrimary: AppTheme.black,
              surface: AppTheme.surface,
              onSurface: AppTheme.text1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await Storage.saveData('notification_time', timeStr);
      await NotificationService.scheduleDailyReminder();
      setState(() {
        _notificationTime = timeStr;
      });
      if (mounted) {
        AppTheme.success();
        AppTheme.showSnackBar(context, 'Daily reminder time set to $timeStr.');
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 24, 6, 12),
      child: Row(
        children: [
          // Cyberpunk glowing start dash
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(1.5),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: AppTheme.label(color: AppTheme.text2).copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppTheme.isDarkNotifier,
      builder: (context, _) {
        final bodyWidget = Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ── Redesigned Header to match quest_screen.dart exactly ──
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
                            Text(
                              'Settings',
                              style: AppTheme.h1(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'App preferences & system core.',
                              style: AppTheme.caption(color: AppTheme.text2),
                            ),
                          ],
                        ),
                        // Right-aligned close button styled exactly like quest_screen.dart
                        SGTouchable(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close,
                                color: AppTheme.text2, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Settings Rows ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('Interface Theme'),
                    const SizedBox(height: 8),
                    // Theme capsule choice
                    Row(
                      children: [
                        Expanded(
                          child: SGTouchable(
                            onTap: () {
                              if (!AppTheme.isDark) AppTheme.toggleTheme();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: AppTheme.isDark
                                    ? AppTheme.surface
                                    : AppTheme.surface.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.isDark
                                      ? AppTheme.accent
                                      : AppTheme.silver.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                                boxShadow: AppTheme.isDark
                                    ? [
                                        BoxShadow(
                                          color:
                                              AppTheme.accent.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.nights_stay_rounded,
                                    color: AppTheme.isDark
                                        ? AppTheme.accent
                                        : AppTheme.text3,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'OBSIDIAN DARK',
                                    style: AppTheme.mono(
                                      color: AppTheme.isDark
                                          ? AppTheme.accent
                                          : AppTheme.text3,
                                      size: 11,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SGTouchable(
                            onTap: () {
                              if (AppTheme.isDark) AppTheme.toggleTheme();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: !AppTheme.isDark
                                    ? AppTheme.surface
                                    : AppTheme.surface.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: !AppTheme.isDark
                                      ? AppTheme.accent
                                      : AppTheme.silver.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                                boxShadow: !AppTheme.isDark
                                    ? [
                                        BoxShadow(
                                          color:
                                              AppTheme.accent.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.wb_sunny_rounded,
                                    color: !AppTheme.isDark
                                        ? AppTheme.accent
                                        : AppTheme.text3,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'SILVER LIGHT',
                                    style: AppTheme.mono(
                                      color: !AppTheme.isDark
                                          ? AppTheme.accent
                                          : AppTheme.text3,
                                      size: 11,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Float Navigator / Normal Navigator'),
                    const SizedBox(height: 8),
                    // Navigator Mode capsule choice
                    Row(
                      children: [
                        Expanded(
                          child: SGTouchable(
                            onTap: () async {
                              if (!Storage.isNavbarFloating()) {
                                await Storage.setNavbarFloating(true);
                                if (mounted) setState(() {});
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: Storage.isNavbarFloating()
                                    ? AppTheme.surface
                                    : AppTheme.surface.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Storage.isNavbarFloating()
                                      ? AppTheme.accent
                                      : AppTheme.silver.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                                boxShadow: Storage.isNavbarFloating()
                                    ? [
                                        BoxShadow(
                                          color:
                                              AppTheme.accent.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_motion_rounded,
                                    color: Storage.isNavbarFloating()
                                        ? AppTheme.accent
                                        : AppTheme.text3,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'FLOAT NAVIGATOR',
                                    style: AppTheme.mono(
                                      color: Storage.isNavbarFloating()
                                          ? AppTheme.accent
                                          : AppTheme.text3,
                                      size: 11,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SGTouchable(
                            onTap: () async {
                              if (Storage.isNavbarFloating()) {
                                await Storage.setNavbarFloating(false);
                                if (mounted) setState(() {});
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: !Storage.isNavbarFloating()
                                    ? AppTheme.surface
                                    : AppTheme.surface.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: !Storage.isNavbarFloating()
                                      ? AppTheme.accent
                                      : AppTheme.silver.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                                boxShadow: !Storage.isNavbarFloating()
                                    ? [
                                        BoxShadow(
                                          color:
                                              AppTheme.accent.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.view_headline_rounded,
                                    color: !Storage.isNavbarFloating()
                                        ? AppTheme.accent
                                        : AppTheme.text3,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'NORMAL NAVIGATOR',
                                    style: AppTheme.mono(
                                      color: !Storage.isNavbarFloating()
                                          ? AppTheme.accent
                                          : AppTheme.text3,
                                      size: 11,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Daily Reminders'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.cyan.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.notifications_active_rounded,
                                    color: AppTheme.cyan, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Enable Reminders', style: AppTheme.h3()),
                                    Text('Get notified daily to train',
                                        style: AppTheme.caption(color: AppTheme.text3)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _notificationsEnabled,
                                onChanged: (v) async {
                                  if (v) {
                                    final granted = await NotificationService.requestPermissions();
                                    if (!context.mounted) return;
                                    if (granted) {
                                      await Storage.saveData('notifications_enabled', true);
                                      await NotificationService.scheduleDailyReminder();
                                      setState(() => _notificationsEnabled = true);
                                      if (mounted) AppTheme.success();
                                    } else {
                                      AppTheme.showSnackBar(context, 'Notification permission denied.');
                                    }
                                  } else {
                                    await Storage.saveData('notifications_enabled', false);
                                    await NotificationService.scheduleDailyReminder();
                                    setState(() => _notificationsEnabled = false);
                                  }
                                },
                                activeThumbColor: AppTheme.cyan,
                                activeTrackColor: AppTheme.cyan.withValues(alpha: 0.3),
                                inactiveTrackColor: AppTheme.surface,
                                inactiveThumbColor: AppTheme.text2,
                              ),
                            ],
                          ),
                          if (_notificationsEnabled) ...[
                            const SizedBox(height: 16),
                            Divider(color: AppTheme.line, height: 1),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    color: AppTheme.text2, size: 18),
                                const SizedBox(width: 10),
                                Text('Reminder Time',
                                    style: AppTheme.body(color: AppTheme.text1)),
                                const Spacer(),
                                SGTouchable(
                                  onTap: _selectTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cyan.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppTheme.cyan.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      _notificationTime,
                                      style: AppTheme.label(color: AppTheme.cyan),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                    Center(
                      child: Text(
                        'Solo Gainz © 2026. Keep grinding.',
                        style: AppTheme.mono(color: AppTheme.text3, size: 9.5)
                            .copyWith(
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );

        // Defer drawing heavy animators until the route transition ends
        if (!_transitionCompleted) {
          return Container(
            color: AppTheme.black,
            child: bodyWidget,
          );
        }

        return LivelyBackground(
          isMoving: false,
          child: bodyWidget,
        );
      },
    );
  }
}
