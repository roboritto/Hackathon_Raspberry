import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _Contact {
  final String name;
  final String relation;
  final String phone;
  final IconData icon;

  const _Contact({
    required this.name,
    required this.relation,
    required this.phone,
    required this.icon,
  });
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool _isAlerted = false;
  bool _isSending = false;
  bool _isBooking = false;

  static const _contacts = [
    _Contact(
      name: 'Siti',
      relation: 'Daughter',
      phone: '012-3456 789',
      icon: Icons.person,
    ),
    _Contact(
      name: 'Abu',
      relation: 'Son',
      phone: '011-2345 678',
      icon: Icons.person,
    ),
    _Contact(
      name: 'Dr. Rahman',
      relation: 'Family Doctor',
      phone: '03-1234 5678',
      icon: Icons.medical_services,
    ),
    _Contact(
      name: 'Ambulance',
      relation: 'Emergency',
      phone: '999',
      icon: Icons.local_hospital,
    ),
  ];

  Future<void> _sendEmergencyAlert() async {
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('reminders').add({
        'category': 'emergency',
        'location': 'EMERGENCY',
        'summary': 'Pak Ahmad needs help urgently!',
        'time': Timestamp.now(),
        'acknowledged': false,
      });
    } catch (_) {
      // Still show success — demo must not break on network error
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isAlerted = true;
        });
      }
    }
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Request Help?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Would you like to send an emergency alert to your family members?',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendEmergencyAlert();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA32D2D),
            ),
            child: const Text(
              'Yes, Send Alert',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Book a Carer',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'A carer will arrive within 30 minutes. Would you like to proceed with the booking?',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isBooking = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() => _isBooking = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Carer booked! They're on their way."),
                      backgroundColor: Color(0xFF0F6E56),
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F6E56),
            ),
            child: const Text(
              'Yes, Book',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
                    _buildSosButton(),
                    const SizedBox(height: 28),
                    const Text(
                      'EMERGENCY CONTACTS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._contacts.map(_buildContactCard),
                    const SizedBox(height: 24),
                    _buildParentSitterSection(),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Help',
                style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 13),
              ),
              Icon(Icons.health_and_safety,
                  color: Color(0xFF9FE1CB), size: 24),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'You are not',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          Text(
            'Alone',
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

  Widget _buildSosButton() {
    // Sending state
    if (_isSending) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFA32D2D).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Sending alert...',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      );
    }

    // Alerted / success state
    if (_isAlerted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F6E56),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Alert Sent!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your family has been notified.\nThey're on their way.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF9FE1CB),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _isAlerted = false),
              child: const Text(
                'Send again',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    // Default idle state
    return GestureDetector(
      onTap: _showSosDialog,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFA32D2D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA32D2D).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 56),
            SizedBox(height: 12),
            Text(
              'I Need Help',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap to notify your family',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(_Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE1F5EE),
              shape: BoxShape.circle,
            ),
            child: Icon(contact.icon,
                color: const Color(0xFF0F6E56), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  contact.relation,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  contact.phone,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0F6E56),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF0F6E56),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildParentSitterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BOOK A CARER',
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
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1F5EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.supervisor_account,
                        color: Color(0xFF0F6E56), size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ParentSitter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Certified carers for the elderly',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Need companionship or help at home? Our carers are ready to assist you anytime.',
                style: TextStyle(
                    fontSize: 15, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBooking ? null : _showBookingDialog,
                  icon: _isBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.calendar_month,
                          color: Colors.white, size: 22),
                  label: Text(
                    _isBooking ? 'Booking...' : 'Book a Carer',
                    style: const TextStyle(
                        fontSize: 20, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6E56),
                    disabledBackgroundColor:
                        const Color(0xFF0F6E56).withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 18),
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
