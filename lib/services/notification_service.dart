import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return; // Notifications not supported on web

    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: settings,
    );

    // Request Android 13+ notification permission
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule recurring reminders for Monday and Thursday at 9:00 AM
  static Future<void> scheduleWeeklyReminders(double dueAmount) async {
    if (kIsWeb) return;

    // Cancel any existing scheduled notifications first
    await _notifications.cancelAll();

    if (dueAmount <= 0) return; // No dues, no reminders needed

    // Schedule Monday reminder (weekday 1)
    await _scheduleWeeklyNotification(
      id: 1,
      weekday: DateTime.monday,
      hour: 9,
      title: '🔔 Payment Reminder',
      body: 'You have ₹${dueAmount.toInt()} in unpaid hostel food dues. Clear them today!',
    );

    // Schedule Thursday reminder (weekday 4)
    await _scheduleWeeklyNotification(
      id: 2,
      weekday: DateTime.thursday,
      hour: 9,
      title: '🔔 Payment Reminder',
      body: 'You have ₹${dueAmount.toInt()} in unpaid hostel food dues. Clear them today!',
    );
  }

  static Future<void> _scheduleWeeklyNotification({
    required int id,
    required int weekday,
    required int hour,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    
    // Find the next occurrence of the target weekday at the specified hour
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    
    // Move forward to the target weekday
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // If this time already passed today, move to next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'food_reminder_channel',
          'Food Payment Reminders',
          channelDescription: 'Reminds you to pay hostel food dues',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancel all scheduled notifications (e.g., when dues are cleared)
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }
}
