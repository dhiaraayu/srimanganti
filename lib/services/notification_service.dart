import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    // Request notif permission (Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Request exact alarm permission (Android 12+)
    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    } catch (e) {
      print("Request exact alarm permission gagal: $e");
    }
  }

  // ==========================================
  // SAFE SCHEDULE (fallback exact -> inexact)
  // ==========================================
  static Future<void> _safeSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'srimanganti_channel',
        'Pengingat Jadwal Srimanganti',
        channelDescription: 'Notifikasi untuk mengingatkan jadwal pementasan',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print("Exact alarm gagal, fallback ke inexact: $e");
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        print("Inexact alarm juga gagal: $e2");
      }
    }
  }

  // 1. Notifikasi Tes (N Detik)
  static Future<void> scheduleNotificationInSeconds({
    required int id,
    required String title,
    required String body,
    required int seconds,
  }) async {
    await _safeSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local)
          .add(Duration(seconds: seconds)),
    );
  }

  // 2. Notifikasi N Hari
  static Future<void> scheduleNotificationInDays({
    required int id,
    required String title,
    required String body,
    required int days,
  }) async {
    await _safeSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(days: days)),
    );
  }

  // 3. Notifikasi N Jam
  static Future<void> scheduleNotificationInHours({
    required int id,
    required String title,
    required String body,
    required int hours,
  }) async {
    await _safeSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(hours: hours)),
    );
  }

  // 4. Batalkan notifikasi
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
