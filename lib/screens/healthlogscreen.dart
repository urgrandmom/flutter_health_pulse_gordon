import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// HEALTH LOGBOOK
class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});

  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> {
  String _filter = 'All';

  // formats Firestore Timestamp into a readable String
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final dateTime = timestamp.toDate();
    // Example output: "15/8/2026 14:47"
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}\n$hour:$minute';
  }

  // Saves entry to Firestore
  Future<void> _addLog(String type, String value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('health_logs').add({
      'userId': user.uid,
      'type': type,
      'value': value,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showAddDialog() {
    String selectedType = 'Steps';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Health Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ['Steps', 'Weight']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => selectedType = val!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                  labelText: 'Measurement (e.g. 5000 steps)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addLog(selectedType, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Logbook'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Category:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _filter,
                  items: ['All', 'Steps', 'Weight']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _filter = val!),
                ),
              ],
            ),
          ),
          Expanded(
            //connecting to live Firestore data stream for health logs/instant updates
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('health_logs')
                  .where('userId', isEqualTo: currentUser?.uid ?? '')
                  .snapshots(),
              builder: (context, snapshot) {
                // show loading indicator while waiting for data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                // Local filtering
                var filteredDocs = docs;
                if (_filter != 'All') {
                  filteredDocs =
                      docs.where((doc) => doc['type'] == _filter).toList();
                }

                if (filteredDocs.isEmpty) {
                  return const Center(
                      child: Text('No logs found. Tap + to add one!'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, i) {
                    final data = filteredDocs[i].data() as Map<String, dynamic>;

                    // Extract timestamp securely safely handles older/null documents
                    final Timestamp? timestamp =
                        data['timestamp'] as Timestamp?;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          data['type'] == 'Steps'
                              ? Icons.directions_walk
                              : Icons.monitor_weight,
                          color: Colors.teal,
                        ),
                        title: Text(
                          data['value'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Category: ${data['type']}'),
                        // ADDED: Trailing text that shows the date and time!
                        trailing: Text(
                          _formatTimestamp(timestamp),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
