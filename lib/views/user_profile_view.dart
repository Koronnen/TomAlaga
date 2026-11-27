import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomalaga/views/auth/login_view.dart';
import '../controllers/auth_controller.dart';
import '../controllers/care_index_controller.dart';
import '../models/care_index_log_model.dart';
import '../models/user_model.dart';

class UserProfile extends StatefulWidget {
  final AuthController controller;
  final CareIndexController? careController;

  const UserProfile({
    super.key,
    required this.controller,
    this.careController,
  });

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late final CareIndexController _careController =
      widget.careController ?? CareIndexController();
  bool _busy = false;

  Future<void> _award(String uid, CareActivityType activity) async {
    setState(() => _busy = true);
    try {
      await _careController.awardPoints(
        uid: uid,
        activity: activity,
        description: 'Test ${activity.label}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to award points: $e')),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'just now';
    final t = time.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _handleSignOut() async {
    await widget.controller.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  Future<void> _handlePasswordReset(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Send a password reset link to $email?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEC00F),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
                side: const BorderSide(color: Colors.black),
              ),
            ),
            child: Text(
              'Send Link',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.controller.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: $e')),
      );
    }
  }

  Widget _sectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 223, 223),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: child,
    );
  }

  Widget _button(String text, {Color color = const Color(0xFFFEC00F)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.black),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black,
        ),
      ),
    );
  }

  // Account & Care Index Overview
  Widget _buildProfileContainer(AppUser user) {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile', 
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              _button(user.role.toUpperCase()),
            ],
          ),
          const SizedBox(height: 10),
          // Email & Account Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.black, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email, 
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Account Status: ${user.status}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.black, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Send a password reset link to your email',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handlePasswordReset(user.email),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEC00F),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Side-by-side Care Index and Quests Done
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Care Index',
                        style: GoogleFonts.inter(fontSize: 14,
                          color: Colors.black, fontWeight: FontWeight.bold
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border, color: Colors.black, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${user.careIndex}',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'You are currently a ${user.careTier}',
                        style: GoogleFonts.inter(fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quests Completed',
                        style: GoogleFonts.inter(fontSize: 14,
                          color: Colors.black, fontWeight: FontWeight.bold
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.task_alt, color: Colors.black, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${user.completedQuestsCount}',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        user.nextTier != null
                            ? '${user.pointsToNextTier} pts to ${user.nextTier}'
                            : 'Highest tier reached',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Privilege Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.unlockedPrivileges.isEmpty)
                  Text(
                    'No privileges unlocked yet.',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                  )
                else...[
                  Text('Unlocked Privileges',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),  
                  SizedBox(height: 6),
                  ...user.unlockedPrivileges.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $p',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
                      ),
                    ),
                  ),
                ],
                const Divider(height: 16, color: Colors.black26),
                Row(
                  children: [
                    _button(
                      'Edit Pets: ${user.canEditPetInfo ? 'Yes' : 'No'}',
                      color: user.canEditPetInfo
                          ? const Color(0xFFC8E6C9)
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    _button(
                      'Add Pets: ${user.canAddPets ? 'Yes' : 'No'}',
                      color: user.canAddPets
                          ? const Color(0xFFC8E6C9)
                          : Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestActivitiesContainer(String uid) {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Test Care Activities',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              _button('DEV / TEST'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CareActivityType.values.map((activity) {
              return ElevatedButton(
                onPressed: _busy ? null : () => _award(uid, activity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(color: Colors.black),
                  ),
                ),
                child: Text(
                  '${activity.label} +${activity.defaultPoints}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgression(String uid) {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Care Index Activity / Progression',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text(
            'Recent Logs',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<CareIndexLog>>(
            stream: _careController.streamLogs(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Failed to load logs: ${snapshot.error}',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Color(0xFFFEC00F)),
                  ),
                );
              }
              final logs = snapshot.data!;
              if (logs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Text(
                    'No activity yet.',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220), 
                child: ListView.builder(
                  shrinkWrap: true, 
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final desc = log.description;
                    return Container(
                      margin: EdgeInsets.only(bottom: index == logs.length - 1 ? 0 : 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.activityType.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatTime(log.createdAt)}'
                                  '${desc != null && desc.isNotEmpty ? ' • $desc' : ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _button('+${log.points} pts'),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text(
          "TomAlaga",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFEC00F),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Not signed in.'))
          : StreamBuilder<AppUser?>(
              stream: _careController.streamUser(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load profile: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFEC00F)),
                  );
                }
                final user = snapshot.data;
                if (user == null) {
                  return const Center(child: Text('User profile not found.'));
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileContainer(user),
                      const SizedBox(height: 16),
                      _buildTestActivitiesContainer(uid),
                      const SizedBox(height: 16),
                      _buildProgression(uid),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }
}