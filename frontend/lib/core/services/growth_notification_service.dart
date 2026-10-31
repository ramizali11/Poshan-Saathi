import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class GrowthReminderSettings {
  final bool isEnabled;
  final int dayOfMonth; // 1 to 28
  final int hour; // 0 to 23
  final int minute; // 0 to 59
  final String? nextReminderText;

  const GrowthReminderSettings({
    this.isEnabled = true,
    this.dayOfMonth = 1,
    this.hour = 9,
    this.minute = 0,
    this.nextReminderText,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}

class GrowthNotificationService {
  GrowthNotificationService._();
  static final GrowthNotificationService instance = GrowthNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _channelId = 'poshan_growth_reminders';
  static const String _channelName = 'Monthly Height & Growth Reminders';
  static const String _channelDesc =
      'Monthly height measurement reminders for tracking child growth and WHO development standards';

  /// Initializes the local notification plugin and timezone data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('[GrowthNotification] User tapped reminder notification: ${response.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('[GrowthNotification] Local notifications initialized successfully.');
    } catch (e) {
      debugPrint('[GrowthNotification] Initialization notice: $e');
    }
  }

  /// Requests notification permission on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    try {
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }
      final iosPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        final granted = await iosPlatform.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[GrowthNotification] Permission request notice: $e');
    }
    return true;
  }

  /// Unique notification ID for each child
  int _notificationIdForChild(int childId) => 10000 + childId;

  /// Retrieves saved reminder settings for a specific child
  Future<GrowthReminderSettings> getSettings(int childId) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('growth_reminder_enabled_$childId') ?? true;
    final day = prefs.getInt('growth_reminder_day_$childId') ?? 1;
    final hour = prefs.getInt('growth_reminder_hour_$childId') ?? 9;
    final minute = prefs.getInt('growth_reminder_minute_$childId') ?? 0;
    final nextText = prefs.getString('growth_reminder_next_$childId');

    return GrowthReminderSettings(
      isEnabled: isEnabled,
      dayOfMonth: day.clamp(1, 28),
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
      nextReminderText: nextText,
    );
  }

  /// Saves settings and reschedules the monthly notification for the child
  Future<void> saveSettings({
    required int childId,
    required String childName,
    required bool isEnabled,
    required int dayOfMonth,
    required int hour,
    required int minute,
    bool justMeasured = false,
  }) async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('growth_reminder_enabled_$childId', isEnabled);
    await prefs.setInt('growth_reminder_day_$childId', dayOfMonth);
    await prefs.setInt('growth_reminder_hour_$childId', hour);
    await prefs.setInt('growth_reminder_minute_$childId', minute);

    final notifId = _notificationIdForChild(childId);

    if (!isEnabled) {
      try {
        await _notificationsPlugin.cancel(id: notifId);
      } catch (_) {}
      await prefs.remove('growth_reminder_next_$childId');
      debugPrint('[GrowthNotification] Reminder disabled and cancelled for child $childId ($childName)');
      return;
    }

    // Calculate next occurrence
    final scheduledDate = _calculateNextScheduleDate(
      dayOfMonth: dayOfMonth,
      hour: hour,
      minute: minute,
      skipCurrentMonth: justMeasured,
    );

    final formattedNext = _formatDateTime(scheduledDate);
    await prefs.setString('growth_reminder_next_$childId', formattedNext);

    try {
      await _notificationsPlugin.cancel(id: notifId);

      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails();
      const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.zonedSchedule(
        id: notifId,
        title: "Time to measure $childName's height!",
        body: "Time to measure your child's height! Record this month's measurement to keep track of their growth.",
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        payload: 'child_height_$childId',
      );

      debugPrint('[GrowthNotification] Scheduled reminder for $childName at $formattedNext');
    } catch (e) {
      debugPrint('[GrowthNotification] Notice during scheduling: $e');
    }
  }

  /// Updates next reminder when parent enters a measurement today
  Future<void> onMeasurementRecorded({required int childId, required String childName}) async {
    final settings = await getSettings(childId);
    if (!settings.isEnabled) return;

    await saveSettings(
      childId: childId,
      childName: childName,
      isEnabled: settings.isEnabled,
      dayOfMonth: settings.dayOfMonth,
      hour: settings.hour,
      minute: settings.minute,
      justMeasured: true, // Pushes to next month since measured today
    );
  }

  /// Cancels reminders when a child is removed
  Future<void> cancelReminder(int childId) async {
    try {
      final notifId = _notificationIdForChild(childId);
      await _notificationsPlugin.cancel(id: notifId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('growth_reminder_enabled_$childId');
      await prefs.remove('growth_reminder_day_$childId');
      await prefs.remove('growth_reminder_hour_$childId');
      await prefs.remove('growth_reminder_minute_$childId');
      await prefs.remove('growth_reminder_next_$childId');
    } catch (e) {
      debugPrint('[GrowthNotification] Error cancelling reminder: $e');
    }
  }

  /// Computes next reminder date
  DateTime _calculateNextScheduleDate({
    required int dayOfMonth,
    required int hour,
    required int minute,
    bool skipCurrentMonth = false,
  }) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    if (skipCurrentMonth) {
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      return DateTime(year, month, dayOfMonth.clamp(1, 28), hour, minute);
    }

    // Try current month
    final candidateThisMonth = DateTime(year, month, dayOfMonth.clamp(1, 28), hour, minute);
    if (candidateThisMonth.isAfter(now)) {
      return candidateThisMonth;
    }

    // Target next month
    month += 1;
    if (month > 12) {
      month = 1;
      year += 1;
    }
    return DateTime(year, month, dayOfMonth.clamp(1, 28), hour, minute);
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthName = months[dt.month - 1];
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minutePadded = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $monthName ${dt.year} at $hour12:$minutePadded $period';
  }
}
