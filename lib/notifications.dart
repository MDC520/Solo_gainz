
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'storage.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize notifications and set up standard channels
  static Future<void> init() async {
    if (_initialized) return;

    // DEVELOPER BYPASS TOGGLE:
    // If you haven't stopped the app and done a cold-rebuild yet, leave this as false.
    // This bypasses initialization in debug mode so your IDE debugger doesn't pause on MissingPluginException.
    // Set this to true once you stop the app and perform a fresh cold-rebuild!
    const bool enableInDebugMode = false;
    if (kDebugMode && !enableInDebugMode) {
      debugPrint('NotificationService: Debug mode bypass active to prevent IDE debugger breaks.');
      return;
    }

    // 1. Initialize timezone database
    tz.initializeTimeZones();
    _setupLocalTimezone();

    // 2. Android specific initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // 3. Initialize plugin
    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
          // Handled tapping on notification (could navigate to specific screen if needed)
        },
      );

      // Create Android Notification Channels
      await _createNotificationChannels();

      _initialized = true;

      // Automatically schedule daily reminder on start based on user settings
      await scheduleDailyReminder();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Sets the local timezone location dynamically based on system timezone offset
  static void _setupLocalTimezone() {
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      if (timeZoneName.contains('/')) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } else {
        // Fallback matching logic: find a timezone by offset to guarantee correct tz calculations
        final offset = DateTime.now().timeZoneOffset;
        final location = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == offset.inMilliseconds,
          orElse: () => tz.local,
        );
        tz.setLocalLocation(location);
      }
    } catch (e) {
      debugPrint('Local timezone setup warning: $e. Falling back to UTC.');
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Create dedicated, high-priority channels for clean user separation
  static Future<void> _createNotificationChannels() async {
    const dailyChannel = AndroidNotificationChannel(
      'daily_reminders',
      'Daily Reminders',
      description: 'Daily alerts reminding you to complete your physical training quests.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const chestChannel = AndroidNotificationChannel(
      'chest_unlocks',
      'Chest Unlocks',
      description: 'Alerts when a reward chest is fully unlocked and ready to open.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const milestonesChannel = AndroidNotificationChannel(
      'milestones',
      'Milestones & Achievements',
      description: 'Alerts for level-ups, rank-ups, and completing daily trials.',
      importance: Importance.high,
      playSound: true,
    );

    final androidNotifier = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotifier != null) {
      await androidNotifier.createNotificationChannel(dailyChannel);
      await androidNotifier.createNotificationChannel(chestChannel);
      await androidNotifier.createNotificationChannel(milestonesChannel);
    }
  }

  /// Request permissions on Android 13+ (POST_NOTIFICATIONS)
  static Future<bool> requestPermissions() async {
    if (!_initialized) return false;
    final androidNotifier = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidNotifier != null) {
      final bool? granted = await androidNotifier.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  /// Cancel a single notification by its unique ID
  static Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled/running notifications
  static Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // ─── 1. DAILY TRAINING REMINDER ───────────────────────────────────

  /// Computes the next scheduled occurrence at a given hour and minute
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule a daily timezone-aware training reminder
  static Future<void> scheduleDailyReminder() async {
    if (!_initialized) return;
    const int reminderId = 1001;

    // Load settings from Storage
    final bool enabled = Storage.getData('notifications_enabled', defaultValue: true);
    final String timeStr = Storage.getData('notification_time', defaultValue: '08:00');

    if (!enabled) {
      // If disabled, cancel any existing daily reminder notification
      await cancel(reminderId);
      debugPrint('Daily reminder canceled (user disabled notifications).');
      return;
    }

    try {
      final parts = timeStr.split(':');
      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      final scheduledTime = _nextInstanceOfTime(hour, minute);

      await _plugin.zonedSchedule(
        reminderId,
        'A New Day of Training Awaits! ⚔️',
        'Your daily quests are active, Player. Ascend further today and climb the ranks!',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders',
            'Daily Reminders',
            channelDescription: 'Daily reminders to complete your training quests.',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Reoccurs daily at the specified time
      );

      debugPrint('Daily reminder scheduled for $timeStr daily (next occurrence: $scheduledTime).');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  // ─── 2. CHEST UNLOCK ALERTS ───────────────────────────────────────

  /// Schedules a notification to fire when a chest has finished unlocking in inventory
  static Future<void> scheduleChestUnlock(int slotIndex, String chestType, Duration duration) async {
    if (!_initialized) return;
    // Generate unique ID based on inventory slot index (2000 - 2019 for up to 20 slots)
    final int notificationId = 2000 + slotIndex;

    final String displayName = chestType
        .replaceAll('_', ' ')
        .split(' ')
        .map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '')
        .join(' ');

    final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);

    try {
      await _plugin.zonedSchedule(
        notificationId,
        'Chest Unlocked! 📦',
        'Your $displayName is fully unlocked! Tap to claim your coins and premium loot!',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'chest_unlocks',
            'Chest Unlocks',
            channelDescription: 'Alerts when your reward chests are fully unlocked and ready to open.',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(
              'Your $displayName is fully unlocked! Tap to claim your coins and premium loot!',
            ),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Chest unlock scheduled for slot $slotIndex in ${duration.inHours}h (triggers: $scheduledTime).');
    } catch (e) {
      debugPrint('Error scheduling chest unlock notification: $e');
    }
  }

  /// Cancels a scheduled chest unlock notification for a slot index
  static Future<void> cancelChestUnlock(int slotIndex) async {
    if (!_initialized) return;
    final int notificationId = 2000 + slotIndex;
    await cancel(notificationId);
    debugPrint('Canceled chest unlock notification for slot $slotIndex.');
  }

  // ─── 3. INSTANT LEVEL-UP / ACHIEVEMENT ALERTS ────────────────────

  /// Triggers a level up notification immediately
  static Future<void> showLevelUp(int level) async {
    if (!_initialized) return;
    const int levelUpId = 3001;
    try {
      await _plugin.show(
        levelUpId,
        'LEVEL UP! 🌟',
        'Incredible progress, Player! You ascended to Level $level! Keep pushing your limits!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'milestones',
            'Milestones & Achievements',
            channelDescription: 'Alerts for level-ups, rank-ups, and completing daily trials.',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      debugPrint('Level Up notification triggered.');
    } catch (e) {
      debugPrint('Error showing level up notification: $e');
    }
  }

  /// Triggers a rank up notification immediately
  static Future<void> showRankUp(String rank) async {
    if (!_initialized) return;
    const int rankUpId = 3002;
    try {
      await _plugin.show(
        rankUpId,
        'RANK UP! 🛡️',
        'Superb execution, Player! You have officially ascended to Rank $rank! Let\'s go further!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'milestones',
            'Milestones & Achievements',
            channelDescription: 'Alerts for level-ups, rank-ups, and completing daily trials.',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      debugPrint('Rank Up notification triggered.');
    } catch (e) {
      debugPrint('Error showing rank up notification: $e');
    }
  }

  /// Triggers a quest completion celebration notification immediately
  static Future<void> showQuestsCompleted() async {
    if (!_initialized) return;
    const int questsCompletedId = 3003;
    try {
      await _plugin.show(
        questsCompletedId,
        'Daily Trial Cleared! 🏆',
        'You\'ve successfully completed all daily quests! Return to claim your rewards and XP!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'milestones',
            'Milestones & Achievements',
            channelDescription: 'Alerts for level-ups, rank-ups, and completing daily trials.',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      debugPrint('Quests Completed notification triggered.');
    } catch (e) {
      debugPrint('Error showing quest completion notification: $e');
    }
  }
}
