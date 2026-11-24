import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import 'test_home_view.dart';

class VerifyEmailView extends StatefulWidget {
  final AuthController controller;
  const VerifyEmailView({super.key, required this.controller});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  Timer? _timer;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final verified = await widget.controller.checkEmailVerifiedAndSaveProfile();
    if (verified && mounted) {
      _timer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TestHomeView(controller: widget.controller),
        ),
      );
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() => _canResend = false);
    await widget.controller.resendVerificationEmail();
    await Future.delayed(const Duration(seconds: 30));
    if (mounted) setState(() => _canResend = true);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email (Test)')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Verification link sent to:\n$email\n\nClick the link in your inbox, then wait 3s or tap below.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkVerification,
              child: const Text("I've Verified My Email"),
            ),
            TextButton(
              onPressed: _canResend ? _resend : null,
              child: Text(_canResend ? 'Resend Email' : 'Wait 30s...'),
            ),
          ],
        ),
      ),
    );
  }
}