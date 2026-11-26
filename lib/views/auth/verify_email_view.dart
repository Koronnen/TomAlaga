import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';

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
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFEC00F),
      appBar: AppBar(
        title: Text('TomAlaga Verify Email', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Verification link sent to:',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Click the link in your inbox, then wait 3s or tap below.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 15, color: Colors.black),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _checkVerification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEC00F),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    side: const BorderSide(color: Colors.black, width: 1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                  ),
                                  child: Text(
                                    "I've Verified My Email",
                                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                TextButton(
                                  onPressed: _canResend ? _resend : null,
                                  child: Text(
                                    _canResend ? 'Resend Email' : 'Wait 30s...',
                                    style: GoogleFonts.inter(
                                      fontSize: 15, fontWeight: FontWeight.bold,
                                      color: _canResend ? Colors.black : Colors.grey,
                                      decoration: _canResend ? TextDecoration.underline : TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}