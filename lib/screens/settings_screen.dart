import 'package:flutter/material.dart';
import 'package:safety_app/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final AuthService authService = AuthService();
    try {
      await authService.deleteAccount();
      debugPrint('Account deleted successfully');
      // Navigation to AuthScreen is handled by StreamBuilder in main.dart
    } catch (e) {
      debugPrint('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  // Helper widget to load an image with a fallback
  Widget _loadImageIcon(String assetPath, double size, Color? color, IconData fallbackIcon, BuildContext context) {
    return FutureBuilder(
      future: precacheImage(AssetImage(assetPath), context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            debugPrint('Failed to load image: $assetPath, error: ${snapshot.error}, stackTrace: ${snapshot.stackTrace}');
            return Icon(
              fallbackIcon,
              size: size,
              color: color ?? Colors.red,
            );
          } else {
            debugPrint('Successfully loaded image: $assetPath');
            return ImageIcon(
              AssetImage(assetPath),
              size: size,
              color: color,
            );
          }
        } else {
          return Icon(
            fallbackIcon,
            size: size,
            color: Colors.grey,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor, // Match ReportScreen styling
        iconTheme: const IconThemeData(
          color: Colors.white, // Ensure visibility
          size: 24,
        ),
        leading: IconButton(
          icon: _loadImageIcon(
            'assets/icons/arrow_back.png',
            24,
            null, // Use PNG's original color
            Icons.error,
            context,
          ),
          onPressed: () {
            debugPrint('Back button pressed, navigating back from SettingsScreen');
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _deleteAccount(context),
            child: const Text('Delete Account'),
          ),
        ),
      ),
    );
  }
}