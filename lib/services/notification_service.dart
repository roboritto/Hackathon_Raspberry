import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

class NotificationService {
  /// Fetches all unacknowledged reminders from Firestore and schedules
  /// a local notification for each one whose time is in the future.
  static Future<void> scheduleAllReminders() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reminders')
        .get();

    debugPrint('[NotificationService] Fetched ${snapshot.docs.length} document(s) from reminders');

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final acknowledged = (data['acknowledged'] as bool?) ?? false;
      if (acknowledged) continue;

      final category = (data['category'] as String?) ?? 'Reminder';
      final location = (data['location'] as String?) ?? '';
      final summary = (data['summary'] as String?) ?? '';
      final time = data['time'];

      debugPrint('[NotificationService] Doc ${doc.id} — raw time field: $time (${time.runtimeType})');

      final scheduledTime = _parseTime(time);

      if (scheduledTime == null) {
        debugPrint('[NotificationService] Doc ${doc.id} — scheduledTime: null (could not parse)');
        continue;
      }

      debugPrint('[NotificationService] Doc ${doc.id} — scheduledTime parsed: $scheduledTime');

      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('[NotificationService] Doc ${doc.id} — skipped (time is in the past)');
        continue;
      }

      final body = [location, summary]
          .where((s) => s.isNotEmpty)
          .join(' — ');

      // Keep ID in positive 31-bit range to satisfy Android's int32 requirement,
      // and avoid colliding with medication IDs (1, 2, 3).
      final id = (doc.id.hashCode & 0x7FFFFFFF) + 1000;

      await _schedule(id: id, title: category, body: body, when: scheduledTime);
      debugPrint('[NotificationService] Scheduled notification — id: $id, time: $scheduledTime');

      final now = tz.TZDateTime.now(tz.local);

      // Night before at 9:00 PM
      final dayBefore = scheduledTime.subtract(const Duration(days: 1));
      final nightBefore = tz.TZDateTime(
        tz.local,
        dayBefore.year,
        dayBefore.month,
        dayBefore.day,
        21,
        0,
      );
      if (nightBefore.isAfter(now)) {
        await _schedule(
          id: id + 2000,
          title: "Tomorrow's Reminder",
          body: body,
          when: nightBefore,
        );
        debugPrint('[NotificationService] Scheduled night-before notification — id: ${id + 2000}, time: $nightBefore');
      }

      // One hour before
      final oneHourBefore = scheduledTime.subtract(const Duration(hours: 1));
      if (oneHourBefore.isAfter(now)) {
        await _schedule(
          id: id + 3000,
          title: 'In 1 Hour',
          body: body,
          when: oneHourBefore,
        );
        debugPrint('[NotificationService] Scheduled 1-hour-before notification — id: ${id + 3000}, time: $oneHourBefore');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Time parsing
  // ---------------------------------------------------------------------------

  static tz.TZDateTime? _parseTime(dynamic value) {
    if (value == null) return null;

    // Firestore Timestamp (written by family/help screens)
    if (value is Timestamp) {
      return tz.TZDateTime.from(value.toDate(), tz.local);
    }

    // Human-readable string written by Firestore console or seeded data
    if (value is String) {
      return _parseString(value);
    }

    return null;
  }

  /// Parses strings like:
  ///   'today 10am'  'today 3:30pm'
  ///   'tomorrow 10am'  'tomorrow 2:45pm'
  static tz.TZDateTime? _parseString(String raw) {
    final now = tz.TZDateTime.now(tz.local);
    final s = raw.toLowerCase().trim();

    DateTime base;
    String rest;

    if (s.startsWith('tomorrow')) {
      final t = now.add(const Duration(days: 1));
      base = DateTime(t.year, t.month, t.day);
      rest = s.replaceFirst('tomorrow', '').trim();
    } else if (s.startsWith('today')) {
      base = DateTime(now.year, now.month, now.day);
      rest = s.replaceFirst('today', '').trim();
    } else {
      return null;
    }

    // Matches: 10am  3pm  10:30am  3:30pm
    final match =
        RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$').firstMatch(rest);
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)!;

    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    return tz.TZDateTime.from(
      DateTime(base.year, base.month, base.day, hour, minute),
      tz.local,
    );
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Scheduled reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    await flnPlugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
