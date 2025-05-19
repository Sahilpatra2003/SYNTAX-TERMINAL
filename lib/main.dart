import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/firebase_options.dart';
import 'package:safety_app/screens/auth_screen.dart';
import 'package:safety_app/screens/map_screen.dart';
import 'package:safety_app/screens/notifications_screen.dart';
import 'package:safety_app/screens/report_screen.dart';
import 'package:safety_app/screens/settings_screen.dart';
import 'package:safety_app/services/auth_service.dart';

// Global AuthService instance for dependency injection
AuthService authService = AuthService(); // Uses default constructor

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SafetyApp());
}

class SafetyApp extends StatelessWidget {
  const SafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const MapScreen();
          }
          return const AuthScreen();
        },
      ),
      routes: {
        '/map': (context) => const MapScreen(),
        '/report': (context) => const ReportScreen(),
        '/auth': (context) => const AuthScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}