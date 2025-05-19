import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:safety_app/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth;

  // Constructor with optional FirebaseAuth parameter for dependency injection
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      debugPrint('Signed in anonymously with user ID: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      debugPrint('Error during anonymous sign-in: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Signed in with email: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Error during email sign-in: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Signed up with email: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Error during email sign-up: $e');
      rethrow;
    }
  }

  // Delete user account and associated data
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      // Delete user's reports from Firestore
      final firestoreService = FirestoreService();
      await firestoreService.deleteUserReports(user.uid);
      debugPrint('Deleted user reports for user ID: ${user.uid}');

      // Delete the user account
      await user.delete();
      debugPrint('User account deleted: ${user.email}');

      // Sign out to clean up the session
      await signOut();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}