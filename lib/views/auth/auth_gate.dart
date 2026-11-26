import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tomalaga/views/auth/landing_view.dart';
import '../../controllers/auth_controller.dart';
import 'verify_email_view.dart';
import 'test_home_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LandingPage();
        }

        if (!user.emailVerified) {
          return VerifyEmailView(controller: authController);
        }

        return TestHomeView(controller: authController);
      },
    );
  }
}