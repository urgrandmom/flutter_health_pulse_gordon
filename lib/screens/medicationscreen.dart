import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Helper to format timestamp into readable text
  String _formatLastTaken(Timestamp? timestamp) {
    if (timestamp == null) return 'Not taken yet';
    final dt = timestamp.toDate();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return 'Last taken: ${dt.day}/${dt.month}/${dt.year} at $hour:$minute';
  }

  // Add Medication Dialog
  void _showAddMedDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name (e.g., Paracetamol)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage / Instructions (e.g., 2 Pills after food)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('medications').add({
                  'userId': user.uid,
                  'name': nameController.text.trim(),
                  'dosage': dosageController.text.trim(),
                  'isTaken': false,
                  'lastTaken': null,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Toggle Taken Status & Update Timestamp
  Future<void> _toggleTaken(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('medications')
        .doc(docId)
        .update({
      'isTaken': !currentStatus,
      'lastTaken': !currentStatus ? FieldValue.serverTimestamp() : null,
    });
  }

  // Delete Medication
  Future<void> _deleteMed(String docId) async {
    await FirebaseFirestore.instance
        .collection('medications')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Tracker'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medications')
            .where('userId', isEqualTo: user?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No medications added yet. Tap + to add one!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final String docId = docs[i].id;
              final Timestamp? lastTaken = data['lastTaken'] as Timestamp?;

              // resets daily at 12:00 midnight, so user can mark as taken again the next day
              bool takenToday = false;
              if (lastTaken != null) {
                final lastDate = lastTaken.toDate();
                final now = DateTime.now();
                takenToday = lastDate.year == now.year &&
                    lastDate.month == now.month &&
                    lastDate.day == now.day;
              }
              // if the medication was taken today, show as taken; otherwise, show as not taken
              final bool isTaken = takenToday;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      isTaken
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isTaken ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => _toggleTaken(docId, isTaken),
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTaken ? Colors.grey.shade600 : Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dosage: ${data['dosage']}'),
                      const SizedBox(height: 2),
                      Text(
                        _formatLastTaken(lastTaken),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteMed(docId),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
