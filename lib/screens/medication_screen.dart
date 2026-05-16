import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

class MedicationItem {
  final int id;
  final String name;
  final String dosage;
  final String schedule;
  final int hour;
  final int minute;
  bool isTaken;

  MedicationItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.schedule,
    required this.hour,
    required this.minute,
    this.isTaken = false,
  });
}

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  late List<MedicationItem> _medications;
  final int _streakDays = 5;

  @override
  void initState() {
    super.initState();
    _medications = [
      MedicationItem(
          id: 1,
          name: 'Metformin',
          dosage: '500mg',
          schedule: '8:00 am — after breakfast',
          hour: 8,
          minute: 0),
      MedicationItem(
          id: 2,
          name: 'Amlodipine',
          dosage: '5mg',
          schedule: '1:00 pm — after lunch',
          hour: 13,
          minute: 0),
      MedicationItem(
          id: 3,
          name: 'Atorvastatin',
          dosage: '20mg',
          schedule: '9:00 pm — before bed',
          hour: 21,
          minute: 0),
    ];
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleAlarm(MedicationItem med) async {
    const androidDetails = AndroidNotificationDetails(
      'ubat_reminder',
      'Medication Reminder',
      channelDescription: 'Reminder to take your medication',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);

    await flnPlugin.zonedSchedule(
      med.id,
      'Time to Take Your Medication!',
      '${med.name} ${med.dosage} — ${med.schedule}',
      _nextInstanceOfTime(med.hour, med.minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm set for ${med.name}'),
          backgroundColor: const Color(0xFF0F6E56),
        ),
      );
    }
  }

  Future<void> _scheduleAllAlarms() async {
    for (final med in _medications) {
      await _scheduleAlarm(med);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All medication alarms have been set!'),
          backgroundColor: Color(0xFF0F6E56),
        ),
      );
    }
  }

  void _toggleTaken(MedicationItem med) {
    setState(() => med.isTaken = !med.isTaken);
    if (med.isTaken) {
      flnPlugin.cancel(med.id);
    } else {
      _scheduleAlarm(med);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreakCard(),
                    const SizedBox(height: 20),
                    const Text(
                      "TODAY'S MEDICATIONS",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._medications.map(_buildMedicationCard),
                    const SizedBox(height: 20),
                    _buildSetAllAlarmsButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F6E56),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Friday, 16 May 2026',
                style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 13),
              ),
              const Icon(Icons.notifications_outlined,
                  color: Color(0xFF9FE1CB), size: 24),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Medication Tracker',
            style: TextStyle(
              color: Color(0xFFE1F5EE),
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6E56), Color(0xFF1A9478)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STREAK RECORD',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9FE1CB),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_streakDays Days',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Keep up the good work!',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9FE1CB)),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Color(0xFF9FE1CB),
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(MedicationItem med) {
    final color = med.isTaken ? const Color(0xFF0F6E56) : const Color(0xFF854F0B);
    final bgColor =
        med.isTaken ? const Color(0xFFF0FAF6) : const Color(0xFFFAEEDA);
    final badgeColor =
        med.isTaken ? const Color(0xFF9FE1CB) : const Color(0xFFFAC775);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medication, size: 16, color: color),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'MED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  med.name,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500, color: color),
                ),
                Text(med.dosage,
                    style: TextStyle(fontSize: 14, color: color)),
                Text(med.schedule,
                    style: TextStyle(fontSize: 14, color: color)),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _toggleTaken(med),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    med.isTaken ? Icons.check : Icons.access_time,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _scheduleAlarm(med),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF854F0B), width: 1.5),
                  ),
                  child: const Icon(Icons.alarm,
                      color: Color(0xFF854F0B), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetAllAlarmsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _scheduleAllAlarms,
        icon: const Icon(Icons.alarm_on, color: Colors.white, size: 28),
        label: const Text(
          'Set All Alarms',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F6E56),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
