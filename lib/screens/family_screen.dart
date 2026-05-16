import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  static const _quickMessages = [
    'Dad, drink some water!',
    "Don't forget your medication!",
    'Have you eaten?',
    'Take care of yourself!',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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

  ({Color color, Color bgColor, Color badgeColor, IconData icon, String label})
      _styleForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'appointment':
        return (
          color: const Color(0xFF0F6E56),
          bgColor: const Color(0xFFE1F5EE),
          badgeColor: const Color(0xFF9FE1CB),
          icon: Icons.calendar_today,
          label: 'Appointment',
        );
      case 'medication':
        return (
          color: const Color(0xFF854F0B),
          bgColor: const Color(0xFFFAEEDA),
          badgeColor: const Color(0xFFFAC775),
          icon: Icons.medication,
          label: 'Medication',
        );
      default:
        return (
          color: Colors.grey as Color,
          bgColor: Colors.white,
          badgeColor: const Color(0xFFE0E0E0),
          icon: Icons.notifications_outlined,
          label: 'Reminder',
        );
    }
  }

  Future<void> _sendReminder(String message) async {
    final text = message.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('reminders').add({
        'category': 'custom',
        'location': 'Family Message',
        'summary': text,
        'time': Timestamp.now(),
        'acknowledged': false,
      });
      _messageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent to Pak Ahmad!'),
            backgroundColor: Color(0xFF0F6E56),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildStreakCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'UPCOMING REMINDERS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRemindersList(),
                    const SizedBox(height: 24),
                    _buildSendReminderSection(),
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
                'Family Dashboard',
                style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 13),
              ),
              const Icon(Icons.family_restroom,
                  color: Color(0xFF9FE1CB), size: 24),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitoring',
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

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF0F6E56),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Active today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F6E56),
              ),
            ),
          ),
          const Text(
            'Last seen: 8:30 am',
            style: TextStyle(fontSize: 13, color: Colors.grey),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEDICATION STREAK',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9FE1CB),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '5 Days',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Pak Ahmad is doing great!',
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

  Widget _buildRemindersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reminders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0F6E56)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading reminders',
              style: TextStyle(fontSize: 14, color: Colors.red.shade400),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
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
              'No upcoming reminders',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < docs.length; i++) ...[
              _buildReminderCard(docs[i]),
              if (i < docs.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final category = (data['category'] as String?) ?? '';
    final location = (data['location'] as String?) ?? '';
    final summary = (data['summary'] as String?) ?? '';
    final timeStr = _formatTime(data['time']);
    final acknowledged = (data['acknowledged'] as bool?) ?? false;
    final style = _styleForCategory(category);
    final subtitle =
        [timeStr, summary].where((s) => s.isNotEmpty).join(' — ');

    return Container(
      decoration: BoxDecoration(
        color: style.bgColor,
        border: Border(left: BorderSide(color: style.color, width: 4)),
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
                    Icon(style.icon, size: 16, color: style.color),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: style.badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        style.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: style.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: style.color,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: style.color),
                  ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: acknowledged ? Colors.grey : style.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              acknowledged ? Icons.check : Icons.access_time,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEND REMINDER',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Message to Pak Ahmad',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickMessages.map((msg) {
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _messageController.text = msg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5EE),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: const Color(0xFF9FE1CB)),
                      ),
                      child: Text(
                        msg,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F6E56),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 16),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending
                      ? null
                      : () => _sendReminder(_messageController.text),
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white,
                          size: 22),
                  label: Text(
                    _isSending ? 'Sending...' : 'Send Reminder',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6E56),
                    disabledBackgroundColor:
                        const Color(0xFF0F6E56).withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
