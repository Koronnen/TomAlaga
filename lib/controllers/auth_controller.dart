import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController {
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? validateUstEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    final ustRegex = RegExp(r'^[a-z0-9._%+-]+@ust\.edu\.ph$');
    if (email.isEmpty) return 'Enter your UST email';
    if (!ustRegex.hasMatch(email)) {
      return 'Must be an official @ust.edu.ph email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value != password) return 'Passwords do not match';
    return null;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    await credential.user?.getIdToken(true);
  }

  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    await _auth.sendPasswordResetEmail(email: cleanEmail);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    await credential.user?.sendEmailVerification();
  }

  Future<bool> checkEmailVerifiedAndSaveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final refreshedUser = _auth.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      await refreshedUser.getIdToken(true);

      final newUser = AppUser(
        uid: refreshedUser.uid,
        email: refreshedUser.email ?? '',
        status: 'pending',
        role: 'volunteer',
        completedQuestsCount: 0,
        careIndex: 0,
      );

      await _firestore
          .collection('users')
          .doc(refreshedUser.uid)
          .set(newUser.toMap());

      return true;
    }
    return false;
  }

  Future<void> incrementCareIndex(String uid, int points) async {
    await _firestore.collection('users').doc(uid).update({
      'careIndex': FieldValue.increment(points),
    });
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  String mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this UST email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'invalid-email':
        return 'Please enter a valid @ust.edu.ph email address.';
      default:
        return e.message ?? 'Sign-up failed. Please try again.';
    }
  }
}