import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/care_index_controller.dart';
import '../../controllers/quest_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../models/user_model.dart';
import '../quests/quests_view.dart';
import 'landing_view.dart';
import 'verify_email_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authController = AuthController();
  final _careIndexController = CareIndexController();
  final _questController = QuestController();
  final _shiftController = ShiftController();

  String? _profileUid;
  Stream<AppUser?>? _profileStream;

  Stream<AppUser?> _streamProfile(String uid) {
    if (_profileUid != uid) {
      _profileUid = uid;
      _profileStream = _careIndexController.streamUser(uid);
    }
    return _profileStream!;
  }

  @override
  void dispose() {
    _questController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingView();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const LandingPage();
        }

        if (!firebaseUser.emailVerified) {
          return VerifyEmailView(controller: _authController);
        }

        return StreamBuilder<AppUser?>(
          stream: _streamProfile(firebaseUser.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingView();
            }

            if (profileSnapshot.hasError) {
              return _ProfileMessageView(
                message:
                    'Unable to load your account profile: '
                    '${profileSnapshot.error}',
              );
            }

            final appUser = profileSnapshot.data;
            if (appUser == null) {
              return const _ProfileMessageView(
                message: 'Your account profile could not be found.',
              );
            }

            return QuestsScreen(
              currentUser: appUser,
              questController: _questController,
              shiftController: _shiftController,
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ProfileMessageView extends StatelessWidget {
  final String message;

  const _ProfileMessageView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
