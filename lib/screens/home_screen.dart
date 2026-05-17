import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class _CardStyle {
  final Color color;
  final Color bgColor;
  final Color badgeColor;
  final IconData icon;
  final String label;

  const _CardStyle({
    required this.color,
    required this.bgColor,
    required this.badgeColor,
    required this.icon,
    required this.label,
  });
}

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToBantuan;
  const HomeScreen({super.key, this.onNavigateToBantuan});

  _CardStyle _styleForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'appointment':
        return const _CardStyle(
          color: Color(0xFF0F6E56),
          bgColor: Color(0xFFE1F5EE),
          badgeColor: Color(0xFF9FE1CB),
          icon: Icons.calendar_today,
          label: 'Appointment',
        );
      case 'medication':
        return const _CardStyle(
          color: Color(0xFF854F0B),
          bgColor: Color(0xFFFAEEDA),
          badgeColor: Color(0xFFFAC775),
          icon: Icons.medication,
          label: 'Medication',
        );
      default:
        return const _CardStyle(
          color: Colors.grey,
          bgColor: Colors.white,
          badgeColor: Color(0xFFE0E0E0),
          icon: Icons.notifications_outlined,
          label: 'Reminder',
        );
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    if (time is Timestamp) {
      return _formatDateTime(time.toDate());
    }
    if (time is String) {
      final dt = DateTime.tryParse(time);
      if (dt != null) return _formatDateTime(dt);
      return time;
    }
    return time.toString();
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$month $day, $h:$minute $period';
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
                    const Text(
                      "TODAY'S REMINDERS",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reminders')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0F6E56),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Error loading reminders',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.red.shade400),
                            ),
                          );
                        }
                        final now = DateTime.now();
                        final docs = List.of(snapshot.data?.docs ?? [])
                          ..sort((a, b) {
                            final aTs =
                                (a.data() as Map<String, dynamic>)['timestamp'];
                            final bTs =
                                (b.data() as Map<String, dynamic>)['timestamp'];
                            final aDt =
                                aTs is Timestamp ? aTs.toDate() : null;
                            final bDt =
                                bTs is Timestamp ? bTs.toDate() : null;
                            final aIsFuture =
                                aDt != null && aDt.isAfter(now);
                            final bIsFuture =
                                bDt != null && bDt.isAfter(now);
                            // Future items before past/null items
                            if (aIsFuture != bIsFuture) {
                              return aIsFuture ? -1 : 1;
                            }
                            // Null timestamps sink to the end
                            if (aDt == null && bDt == null) return 0;
                            if (aDt == null) return 1;
                            if (bDt == null) return -1;
                            // Within the same group, ascending (soonest first)
                            return aDt.compareTo(bDt);
                          });
                        if (docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Text(
                              'No reminders today',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (int i = 0; i < docs.length; i++) ...[
                              _buildFirestoreCard(docs[i]),
                              if (i < docs.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildHelpButton(context),
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

  Widget _buildFirestoreCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final category = (data['category'] as String?) ?? '';
    final location = (data['location'] as String?) ?? '';
    final summary = (data['summary'] as String?) ?? '';
    final tsDate = (data['timestamp'] as Timestamp?)?.toDate();
    final timeStr = tsDate != null
        ? _formatDateTime(tsDate)
        : _formatTime(data['time']);
    final acknowledged = (data['acknowledged'] as bool?) ?? false;
    final isPast = tsDate != null && tsDate.isBefore(DateTime.now());
    final style = _styleForCategory(category);

    final subtitle = [timeStr, summary].where((s) => s.isNotEmpty).join(' — ');

    return _buildReminderCard(
      icon: style.icon,
      type: style.label,
      title: location,
      subtitle: subtitle,
      color: style.color,
      bgColor: style.bgColor,
      badgeColor: style.badgeColor,
      isDone: acknowledged,
      isPast: isPast,
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
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: Color(0xFF9FE1CB), fontSize: 13),
              ),
              const Icon(Icons.notifications_outlined,
                  color: Color(0xFF9FE1CB), size: 24),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Good morning,',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const Text(
            'Pak Ahmad',
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

  Widget _buildReminderCard({
    required IconData icon,
    required String type,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required Color badgeColor,
    required bool isDone,
    bool isPast = false,
  }) {
    return Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: Container(
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
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      if (isPast) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Passed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFA32D2D),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: color),
                    ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPast || isDone ? Colors.grey : color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : Icons.access_time,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.medication,
            label: 'Medication streak',
            value: '5 days',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _buildAppointmentStatCard()),
      ],
    );
  }

  Widget _buildAppointmentStatCard() {
    final now = DateTime.now();
    final tomorrowStart = DateTime(now.year, now.month, now.day + 1);
    final tomorrowEnd = DateTime(now.year, now.month, now.day + 2);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reminders')
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final category = (data['category'] as String?) ?? '';
            if (category.toLowerCase() != 'appointment') return false;
            final ts = data['timestamp'] ?? data['time'];
            if (ts == null || ts is! Timestamp) return false;
            final dt = ts.toDate();
            return !dt.isBefore(tomorrowStart) && dt.isBefore(tomorrowEnd);
          }).length;
        }
        return _buildStatCard(
          icon: Icons.calendar_month,
          label: 'Appointment',
          value: count == 0 ? 'None tomorrow' : '$count tomorrow',
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0F6E56), size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHelpButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onNavigateToBantuan,
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.white, size: 28),
        label: const Text(
          'I Need Help',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA32D2D),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
