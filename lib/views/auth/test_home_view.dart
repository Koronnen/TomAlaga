import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/care_index_controller.dart';
import '../../models/care_index_log_model.dart';
import '../../models/user_model.dart';
import 'sign_up_view.dart';

class TestHomeView extends StatefulWidget {
  final AuthController controller;
  final CareIndexController? careController;

  const TestHomeView({
    super.key,
    required this.controller,
    this.careController,
  });

  @override
  State<TestHomeView> createState() => _TestHomeViewState();
}

class _TestHomeViewState extends State<TestHomeView> {
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

  Widget _buildProfile(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Email: ${user.email}'),
        Text('Role: ${user.role}'),
        Text('Trust Tier: ${user.trustTier.label}'),
        Text(
          'Care Index: ${user.careIndex}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text('Completed Quests: ${user.completedQuestsCount}'),
        const SizedBox(height: 8),
        const Text('Unlocked privileges:'),
        Text('- Participate: ${user.canParticipate ? 'Yes' : 'No'}'),
        Text('- Edit pet details: ${user.canEditPetDetails ? 'Yes' : 'No'}'),
        Text('- Register pets: ${user.canRegisterPets ? 'Yes' : 'No'}'),
        Text('- Apply for adoption: ${user.canApplyForAdoption ? 'Yes' : 'No'}'),
        Text('- Max concurrent tasks: ${user.maxConcurrentTasks}'),
        if (user.pointsToNextTier > 0)
          Text('${user.pointsToNextTier} points to the next tier'),
      ],
    );
  }

  Widget _buildButtons(String uid) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CareActivityType.values.map((activity) {
        return ElevatedButton(
          onPressed: _busy ? null : () => _award(uid, activity),
          child: Text('${activity.label} +${activity.defaultPoints}'),
        );
      }).toList(),
    );
  }

  Widget _buildLogs(String uid) {
    return StreamBuilder<List<CareIndexLog>>(
      stream: _careController.streamLogs(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Failed to load logs: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data!;
        if (logs.isEmpty) return const Text('No activity yet.');
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final desc = log.description;
            return ListTile(
              title: Text('${log.activityType.label}: +${log.points}'),
              subtitle: Text(
                '${_formatTime(log.createdAt)}'
                '${desc != null && desc.isNotEmpty ? '\n$desc' : ''}',
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Sandbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignUpView()),
              );
            },
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
                      child: Text('Failed to load profile: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = snapshot.data;
                if (user == null) {
                  return const Center(child: Text('User profile not found.'));
                }
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfile(user),
                      const SizedBox(height: 16),
                      const Text('Test activities:'),
                      const SizedBox(height: 8),
                      _buildButtons(uid),
                      const SizedBox(height: 16),
                      const Text('Recent activity:'),
                      Expanded(child: _buildLogs(uid)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}