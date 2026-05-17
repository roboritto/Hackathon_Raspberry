import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  bool _isSaving = false;

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
      final dt = time.toDate();
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'pm' : 'am';
      final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$h:$minute $period';
    }
    return time.toString();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Add Appointment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Appointment Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: Color(0xFF0F6E56)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 18, color: Color(0xFF0F6E56)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedTime.format(ctx),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      child: const Text('Pick Time'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      final location = locationController.text.trim();
                      if (title.isEmpty) return;

                      final dt = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final ts = Timestamp.fromDate(dt);

                      setState(() => _isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('reminders')
                            .add({
                          'category': 'appointment',
                          'location': title,
                          'summary': location,
                          'time': ts,
                          'timestamp': ts,
                          'acknowledged': false,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E56),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Color(0xFF0F6E56)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF0F6E56),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'Appointments',
                      style: TextStyle(
                        color: Color(0xFFE1F5EE),
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UPCOMING APPOINTMENTS',
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
                              'Error loading appointments',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.red.shade400),
                            ),
                          );
                        }
                        final rawDocs = snapshot.data?.docs ?? [];
                        final docs = rawDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          final category =
                              (data['category'] as String?) ?? '';
                          return category.toLowerCase() == 'appointment';
                        }).toList();

                        if (docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Text(
                              'No appointments',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (int i = 0; i < docs.length; i++) ...[
                              Builder(builder: (context) {
                                final data =
                                    docs[i].data() as Map<String, dynamic>;
                                final category =
                                    (data['category'] as String?) ?? '';
                                final location =
                                    (data['location'] as String?) ?? '';
                                final summary =
                                    (data['summary'] as String?) ?? '';
                                final tsDate = (data['timestamp']
                                        as Timestamp?)
                                    ?.toDate();
                                final timeStr = tsDate != null
                                    ? _formatTime(data['timestamp'])
                                    : _formatTime(data['time']);
                                final acknowledged =
                                    (data['acknowledged'] as bool?) ??
                                        false;
                                final isPast = tsDate != null &&
                                    tsDate.isBefore(DateTime.now());
                                final style = _styleForCategory(category);
                                final subtitle = [timeStr, summary]
                                    .where((s) => s.isNotEmpty)
                                    .join(' — ');
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
                              }),
                              if (i < docs.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isPast ? Colors.grey.shade300 : badgeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon,
                              color: isPast ? Colors.grey : color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  type,
                                  style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12),
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
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ]),
                      if (isDone)
                        const Icon(Icons.check_circle, color: Colors.green)
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
