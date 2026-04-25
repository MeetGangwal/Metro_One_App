import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';


class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification IDs reserved for transit alarms
  static const int _interchangeNotifId = 9001;
  static const int _destinationNotifId = 9002;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    // Using named parameters for v21.0.0
    await _notificationsPlugin.initialize(
      settings: initSettings,
    );
    
    // Explicitly request permissions for Android (important for Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    _initialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  /// Schedules a destination alarm notification.
  /// Triggers 5 minutes BEFORE the estimated arrival.
  Future<void> scheduleDestinationAlarm(int travelMinutes, String destination) async {
    if (!_initialized) await init();

    final delayMinutes = travelMinutes - 5;

    if (delayMinutes <= 0) {
      await _showImmediateNotification(destination);
      return;
    }

    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: delayMinutes));

    final androidDetails = AndroidNotificationDetails(
      'transit_alarm_channel_v5',
      'Transit Alarms',
      channelDescription: 'Alarm sound when approaching station',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('metro_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT for continuous ringing
    );

    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      sound: 'metro_alarm.mp3',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Using strictly named parameters for zonedSchedule
    await _notificationsPlugin.zonedSchedule(
      id: _destinationNotifId,
      title: '📍 Destination Arriving!',
      body: 'Your destination "$destination" will arrive in 5 minutes. Get ready to deboard!',
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('Alarm scheduled: will fire in $delayMinutes minutes for $destination');
  }

  /// Schedules an interchange alarm notification.
  /// Triggers 5 minutes BEFORE the estimated arrival at interchange.
  Future<void> scheduleInterchangeAlarm(int travelMinutes, String interchangeStation, String nextLine) async {
    if (!_initialized) await init();

    final delayMinutes = travelMinutes - 5;

    if (delayMinutes <= 0) {
      await showInterchangeAlert(interchangeStation, nextLine);
      return;
    }

    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: delayMinutes));

    final androidDetails = AndroidNotificationDetails(
      'transit_alarm_channel_v5',
      'Transit Alarms',
      channelDescription: 'Alarm sound when approaching station',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('metro_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT for continuous ringing
    );

    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      sound: 'metro_alarm.mp3',
    );

    // Using strictly named parameters for zonedSchedule
    await _notificationsPlugin.zonedSchedule(
      id: _interchangeNotifId,
      title: '🔄 Interchange Approaching!',
      body: 'Station "$interchangeStation" arriving in 5 minutes.\nPrepare to switch to the $nextLine.',
      scheduledDate: scheduledTime,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('Interchange Alarm scheduled: will fire in $delayMinutes minutes for $interchangeStation');
  }

  // ==================== TRANSIT ALARM NOTIFICATIONS ====================

  /// Fires an immediate notification when the interchange station is approaching.
  /// Called by TransitAlarmProvider when Leg 1 countdown reaches 0.
  Future<void> showInterchangeAlert(String interchangeStation, String nextLine) async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      'transit_alarm_channel_v5',
      'Transit Alarms',
      channelDescription: 'Alarm sound when approaching station',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('metro_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
    );

    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      sound: 'metro_alarm.mp3',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: _interchangeNotifId,
      title: '🔄 Interchange Approaching!',
      body: 'Station "$interchangeStation" arriving in 5 minutes.\nPrepare to switch to the $nextLine.',
      notificationDetails: notificationDetails,
    );

    debugPrint('Transit Alarm: Interchange notification fired for $interchangeStation');
  }

  /// Fires an immediate notification when the final destination is approaching.
  /// Called by TransitAlarmProvider when the final countdown reaches 0.
  Future<void> showDestinationAlert(String destination) async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      'transit_alarm_channel_v5',
      'Transit Alarms',
      channelDescription: 'Alarm sound when approaching station',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('metro_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
    );

    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      sound: 'metro_alarm.mp3',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: _destinationNotifId,
      title: '📍 Destination Arriving!',
      body: 'Your destination "$destination" will arrive in 5 minutes. Get ready to deboard!',
      notificationDetails: notificationDetails,
    );

    debugPrint('Transit Alarm: Destination notification fired for $destination');
  }

  /// Cancel all transit alarm notifications (interchange + destination).
  Future<void> cancelTransitAlarms() async {
    if (!_initialized) await init();

    await _notificationsPlugin.cancel(id: _interchangeNotifId);
    await _notificationsPlugin.cancel(id: _destinationNotifId);
    debugPrint('Transit Alarm: All transit alarm notifications cancelled');
  }

  Future<void> _showImmediateNotification(String destination) async {
    final androidDetails = AndroidNotificationDetails(
      'transit_alarm_channel_v5',
      'Transit Alarms',
      channelDescription: 'Alarm sound when approaching station',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('metro_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    // Using named parameters for show
    await _notificationsPlugin.show(
      id: _destinationNotifId,
      title: 'Get Ready!',
      body: 'You will arrive at $destination very soon!',
      notificationDetails: notificationDetails,
    );
  }
}
