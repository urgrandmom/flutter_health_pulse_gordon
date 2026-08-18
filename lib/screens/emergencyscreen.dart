import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  final List<Map<String, String>> _contacts = const [
    {
      'title': 'Emergency Ambulance & Fire',
      'number': '995',
      'subtitle': 'SCDF Emergency Services',
      'category': 'Emergency',
    },
    {
      'title': 'Police Emergency',
      'number': '999',
      'subtitle': 'Singapore Police Force',
      'category': 'Emergency',
    },
    {
      'title': 'MOH HealthLine',
      'number': '1800-225-4422',
      'subtitle': 'Ministry of Health Advisory',
      'category': 'Hotline',
    },
    {
      'title': 'SingHealth Polyclinics',
      'number': '6643-6969',
      'subtitle': 'Central Appointments & Enquiries',
      'category': 'Polyclinic',
    },
    {
      'title': 'NHGP Polyclinics',
      'number': '6355-3000',
      'subtitle': 'National Healthcare Group Polyclinics',
      'category': 'Polyclinic',
    },
    {
      'title': 'Mental Health Helpline (IMH)',
      'number': '6389-2222',
      'subtitle': '24-Hour Crisis Helpline',
      'category': 'Support',
    },
  ];

  //  launch dialer
  Future<void> _makeCall(BuildContext context, String number) async {
    final messenger = ScaffoldMessenger.of(context);
    final Uri phoneUri = Uri(scheme: 'tel', path: number);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not launch dialer for $number')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & Helplines'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;

          // Fetch dynamic caregiver details from Firestore user doc
          final String caregiverName =
              userData?['caregiverName'] ?? 'Caregiver';
          final String caregiverPhone = userData?['caregiverPhone'] ?? '';

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Caregiver Card
              Card(
                color: Colors.teal.shade50,
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.teal, width: 2),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.family_restroom, color: Colors.white),
                  ),
                  title: Text(
                    'Primary Caregiver ($caregiverName)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    caregiverPhone.isNotEmpty
                        ? 'Number: $caregiverPhone'
                        : 'No caregiver phone number saved in profile.',
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: caregiverPhone.isNotEmpty
                        ? () => _makeCall(context, caregiverPhone)
                        : null,
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Singapore Hotlines & Helplines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              // loops thru list of contacts and creates a card for each and checks if its an emergency contact to change the color of the card and icon
              ..._contacts.map((item) {
                final isEmergency = item['category'] == 'Emergency';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isEmergency ? Colors.redAccent : Colors.teal,
                      child: Icon(
                        isEmergency ? Icons.warning_amber : Icons.phone_in_talk,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      item['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${item['subtitle']}\nNumber: ${item['number']}',
                    ),
                    isThreeLine: true,
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isEmergency ? Colors.redAccent : Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _makeCall(context, item['number']!),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call'),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
