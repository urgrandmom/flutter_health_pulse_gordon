import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// PROFILE & ABOUT SCREEN

class ProfileScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String _displayName = 'User';
  String _caregiverName = 'Not set';
  String _caregiverPhone = 'Not set';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Fetch saved particulars & caregiver info from Firestore
  Future<void> _loadUserProfile() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          // Name logic
          if (data['name'] != null) {
            _displayName = data['name'];
          } else {
            final emailName = widget.userEmail.split('@').first;
            _displayName = emailName[0].toUpperCase() + emailName.substring(1);
          }

          // Caregiver logic
          _caregiverName = data['caregiverName'] ?? 'Not set';
          _caregiverPhone = data['caregiverPhone'] ?? 'Not set';
        });
      } else {
        final emailName = widget.userEmail.split('@').first;
        setState(() {
          _displayName = emailName[0].toUpperCase() + emailName.substring(1);
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update profile name in Firestore
  Future<void> _editProfileDialog() async {
    final controller = TextEditingController(text: _displayName);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Particulars'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && _user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid)
                    .set({'name': newName, 'email': widget.userEmail},
                        SetOptions(merge: true));

                setState(() => _displayName = newName);
                if (mounted) Navigator.pop(context);

                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Profile updated successfully!')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Edit Caregiver Particulars in Firestore
  Future<void> _editCaregiverDialog() async {
    final nameController = TextEditingController(
        text: _caregiverName == 'Not set' ? '' : _caregiverName);
    final phoneController = TextEditingController(
        text: _caregiverPhone == 'Not set' ? '' : _caregiverPhone);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caregiver Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Caregiver Name (e.g., Alex)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (e.g., +65 9123 4567)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();

              if (_user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid)
                    .set({
                  'caregiverName': newName.isNotEmpty ? newName : 'Not set',
                  'caregiverPhone': newPhone.isNotEmpty ? newPhone : 'Not set',
                }, SetOptions(merge: true));

                setState(() {
                  _caregiverName = newName.isNotEmpty ? newName : 'Not set';
                  _caregiverPhone = newPhone.isNotEmpty ? newPhone : 'Not set';
                });

                if (mounted) Navigator.pop(context);

                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Caregiver contact updated successfully!')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // email and call links
  Future<void> _launchUri(Uri uri, String errorMsg) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  // About Section Dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About HealthPulse SG'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HealthPulse SG is a Smart Nation initiative app providing Singaporeans with real-time environmental monitoring, health logging, medication tracking, and emergency helplines.',
              ),
              const SizedBox(height: 12),
              const Text('Company: HealthPulse Inc.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Developer: Gordon(EGL303)'),
              const Text('Version: 1.0.0'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Direct Email Feedback Link
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email, color: Colors.teal),
                title: const Text('Email Feedback'),
                subtitle: const Text('feedback@healthpulse.sg'),
                onTap: () {
                  final userEmail = FirebaseAuth.instance.currentUser?.email ??
                      'Unknown User';

                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'feedback@healthpulse.sg',
                    queryParameters: {
                      'subject': 'HealthPulse App Feedback',
                      'body':
                          'App User Account: $userEmail\n\n[Write your feedback here]:\n',
                    },
                  );

                  _launchUri(emailUri, 'Could not launch email app');
                },
              ),
              // Direct Call Link
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone, color: Colors.teal),
                title: const Text('Call Support'),
                subtitle: const Text('+65 6451 5115'),
                onTap: () {
                  final Uri phoneUri = Uri(scheme: 'tel', path: '+6564515115');
                  _launchUri(phoneUri, 'Could not launch phone dialer');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  // Personalized Greeting Display
                  Text(
                    'Welcome back, $_displayName!',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.userEmail,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Change Profile Particulars
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.edit, color: Colors.teal),
                      title: const Text('Edit Particulars'),
                      subtitle: const Text('Update your display name'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editProfileDialog,
                    ),
                  ),

                  // Edit Caregiver Particulars
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.family_restroom, color: Colors.teal),
                      title: const Text('Caregiver Contact'),
                      subtitle: Text('$_caregiverName ($_caregiverPhone)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editCaregiverDialog,
                    ),
                  ),

                  // User ID Info Tile
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge, color: Colors.teal),
                      title: const Text('User ID'),
                      subtitle: Text(_user?.uid ?? 'N/A'),
                    ),
                  ),

                  // About App Button
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.info_outline, color: Colors.teal),
                      title: const Text('About App'),
                      subtitle:
                          const Text('App Info, Direct Call & Feedback Link'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showAboutDialog,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('LOG OUT',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
