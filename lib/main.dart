import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/loginscreen.dart';
import 'screens/weatherscreen.dart';
import 'screens/medicationscreen.dart';
import 'screens/healthlogscreen.dart';
import 'screens/emergencyscreen.dart';
import 'screens/profilescreen.dart';

void main() async {
  //  Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  //  Initialize Firebase
  await Firebase.initializeApp();

  runApp(const HealthPulseApp());
}

class HealthPulseApp extends StatelessWidget {
  const HealthPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.teal.shade50,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// AUTHENTICATION STATE TOGGLE

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If logged in, show MainNavigationScreen with the user's email
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return MainNavigationScreen(
            userEmail: user.email ?? 'No Email',
            onLogout: () async {
              await FirebaseAuth.instance.signOut();
            },
          );
        }
        // If not logged in, show LoginScreen
        return const LoginScreen();
      },
    );
  }
}

// MAIN NAVIGATION SCREEN
class MainNavigationScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback onLogout;

  const MainNavigationScreen({
    super.key,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const WeatherScreen(),
      const MedicationScreen(),
      const HealthLogScreen(),
      const EmergencyScreen(),
      ProfileScreen(
        userEmail: widget.userEmail,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny),
            label: 'Weather & PSI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Meds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Health Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
