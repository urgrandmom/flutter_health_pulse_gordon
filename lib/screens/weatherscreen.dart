import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// WEATHER & LIVE PSI SCREEN
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = true;
  List<Map<String, String>> _forecasts = [];
  int _psiValue = 42;
  String _displayName = ''; // Stores user name for greeting

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchUserName(), _fetchWeather(), _fetchPsi()]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Fetch display name from Firestore (Requirement 4.2)
  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted && doc.exists && doc.data()?['name'] != null) {
        setState(() => _displayName = doc.data()!['name']);
      } else if (mounted) {
        setState(() => _displayName = user.email?.split('@').first ?? 'User');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _displayName = user.email?.split('@').first ?? 'User');
      }
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api-open.data.gov.sg/v2/real-time/api/two-hr-forecast'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['data']['items'] as List;
        if (items.isNotEmpty) {
          final list = items[0]['forecasts'] as List;
          _forecasts = list
              .map<Map<String, String>>((item) => {
                    'area': item['area'].toString(),
                    'forecast': item['forecast'].toString(),
                  })
              .toList();
          return;
        }
      }
    } catch (_) {}

    _forecasts = [
      {'area': 'Ang Mo Kio', 'forecast': 'Partly Cloudy'},
      {'area': 'Bedok', 'forecast': 'Light Rain'},
      {'area': 'Clementi', 'forecast': 'Fair'},
      {'area': 'Jurong East', 'forecast': 'Thundery Showers'},
      {'area': 'Tampines', 'forecast': 'Cloudy'},
    ];
  }

  Future<void> _fetchPsi() async {
    try {
      final response = await http
          .get(Uri.parse('https://api-open.data.gov.sg/v2/real-time/api/psi'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['data']['items'] as List;
        if (items.isNotEmpty) {
          final readings = items[0]['readings']['psi_twenty_four_hourly'];
          _psiValue = (readings['national'] as num).toInt();
        }
      }
    } catch (_) {}
  }

  IconData _getIcon(String forecast) {
    final t = forecast.toLowerCase();
    if (t.contains('rain') || t.contains('shower')) return Icons.grain;
    if (t.contains('thunder')) return Icons.thunderstorm;
    if (t.contains('cloud')) return Icons.cloud;
    return Icons.wb_sunny;
  }

  Map<String, dynamic> _getPsiStatus(int psi) {
    if (psi <= 50) {
      return {
        'status': 'Good',
        'color': Colors.green.shade700,
        'advice': 'Air quality is healthy. Safe for outdoor activities!'
      };
    } else if (psi <= 100) {
      return {
        'status': 'Moderate',
        'color': Colors.amber.shade800,
        'advice': 'Normal outdoor activities permitted.'
      };
    } else {
      return {
        'status': 'Unhealthy',
        'color': Colors.red.shade700,
        'advice': 'High PSI! Seniors are advised to stay indoors.'
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final psiInfo = _getPsiStatus(_psiValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SG Weather & Air Quality'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                //  Greeting Banner
                Card(
                  color: Colors.teal.shade50,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName.isEmpty
                                    ? 'Welcome back!'
                                    : 'Welcome back, $_displayName!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const Text(
                                'Here is your daily environmental update.',
                                style:
                                    TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // PSI Status Card
                Card(
                  color: (psiInfo['color'] as Color).withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: psiInfo['color'], width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: psiInfo['color'],
                          child: Text(
                            '$_psiValue',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PSI Reading: ${psiInfo['status']}',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: psiInfo['color']),
                              ),
                              const SizedBox(height: 4),
                              Text(psiInfo['advice'],
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                //  Weather Forecast List
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text('2-Hour Weather Forecasts By Area',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                ..._forecasts.map((item) => Card(
                      child: ListTile(
                        leading: Icon(_getIcon(item['forecast']!),
                            color: Colors.teal, size: 36),
                        title: Text(item['area']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(item['forecast']!,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    )),
              ],
            ),
    );
  }
}
