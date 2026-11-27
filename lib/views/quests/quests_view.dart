import 'package:flutter/material.dart';
import '../../controllers/quest_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../models/quest_model.dart';
import '../../models/shift_model.dart';
import '../../models/user_model.dart';
import 'calendar_view.dart';
import 'coordinator_create_view.dart';
import 'quest_proof_view.dart';

class QuestsScreen extends StatefulWidget {
  final AppUser currentUser;
  final String? homeZoneId;
  final QuestController questController;
  final ShiftController shiftController;

  const QuestsScreen({
    super.key,
    required this.currentUser,
    this.homeZoneId,
    required this.questController,
    required this.shiftController,
  });

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  static const Color _ustGold = Color(0xFFF59E0B);
  static const Color _ustCharcoal = Color(0xFF18181B);
  static const Color _healthTeal = Color(0xFF0D9488);

  int _selectedSegment = 0; // 0 = On-Demand Quests, 1 = Shifts (Calendar)
  String _categoryFilter = 'all'; // 'all' | 'feeding' | 'healthcare'

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _ustCharcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleClaimQuest(QuestModel quest) async {
    final user = widget.currentUser;
    final success = await widget.questController.claimQuest(
      questId: quest.questId,
      uid: user.uid,
      email: user.email,
      status: user.isSuspended ? 'suspended' : 'approved',
      role: user.role,
      careIndex: user.careIndex,
      isSuspended: user.isSuspended,
    );

    if (!mounted) return;
    if (success) {
      _showSnack('Quest locked! Submit proof before the timer expires.');
    } else {
      _showSnack(
        widget.questController.errorMessage ?? 'Unable to claim quest.',
        isError: true,
      );
    }
  }

  void _openProofSheet(QuestModel quest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => QuestProofSheet(
        quest: quest,
        currentUser: widget.currentUser,
        questController: widget.questController,
      ),
    );
  }

  void _openCoordinatorCreator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CoordinatorCreateSheet(
        questController: widget.questController,
        shiftController: widget.shiftController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final maxTasks = widget.questController.maxConcurrentTasksFor(
      user.careIndex,
      user.role,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _ustCharcoal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Feeding & Healthcare Tasks',
              style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _ustGold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ustGold.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: _ustGold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${user.careIndex} pts',
                  style: const TextStyle(
                    color: _ustGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: user.isStaff
          ? FloatingActionButton.extended(
              onPressed: _openCoordinatorCreator,
              backgroundColor: _ustCharcoal,
              foregroundColor: _ustGold,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Post / Schedule',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Column(
        children: [
          if (user.isSuspended)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.block_rounded, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account suspended — read-only mode active.',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Primary Mode Switcher + Category Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      icon: Icon(Icons.flash_on_rounded, size: 18),
                      label: Text('On-Demand Quests'),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      icon: Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text('Shifts (Calendar)'),
                    ),
                  ],
                  selected: {_selectedSegment},
                  onSelectionChanged: (set) {
                    setState(() => _selectedSegment = set.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return _ustCharcoal;
                      }
                      return const Color(0xFFF1F5F9);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return _ustGold;
                      }
                      return _ustCharcoal;
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildCategoryChip('all', 'All Tasks'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('feeding', 'Feeding'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('healthcare', 'Healthcare'),
                    const Spacer(),
                    Text(
                      'Limit: $maxTasks active',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _selectedSegment == 0
                ? _buildQuestsFeed()
                : StreamBuilder<List<ShiftModel>>(
                    stream: widget.shiftController.watchVisibleShifts(
                      homeZoneId: widget.homeZoneId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allShifts = snapshot.data ?? [];
                      final filteredShifts = _categoryFilter == 'all'
                          ? allShifts
                          : allShifts
                              .where((s) => s.category == _categoryFilter)
                              .toList();

                      return CinemaSeatCalendarView(
                        shifts: filteredShifts,
                        currentUser: widget.currentUser,
                        shiftController: widget.shiftController,
                        onCheckedInAndSpawned: (spawnedQuestId) {
                          setState(() => _selectedSegment = 0);
                          _showSnack(
                            'Checked in! Linked quest spawned in Active Runs (+25 pts).',
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final selected = _categoryFilter == value;
    final activeColor = value == 'healthcare' ? _healthTeal : _ustCharcoal;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _categoryFilter = value),
      selectedColor: activeColor,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF334155),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  Widget _buildQuestsFeed() {
    return StreamBuilder<List<QuestModel>>(
      stream: widget.questController.watchQuests(
        categoryFilter: _categoryFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final quests = snapshot.data ?? [];
        final myActive = quests
            .where(
              (q) =>
                  q.status == 'claimed' &&
                  q.claimedByUid == widget.currentUser.uid,
            )
            .toList();

        final openQuests = quests.where((q) => q.status == 'open').toList();

        final otherActive = quests
            .where(
              (q) =>
                  q.status == 'claimed' &&
                  q.claimedByUid != widget.currentUser.uid,
            )
            .toList();

        if (myActive.isEmpty && openQuests.isEmpty && otherActive.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No active or open quests in this category right now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (myActive.isNotEmpty) ...[
              const _SectionHeader(
                title: 'MY ACTIVE RUNS',
                subtitle: 'Submit photo proof to earn Care Index points',
              ),
              const SizedBox(height: 8),
              ...myActive.map(
                (q) => _QuestCard(
                  quest: q,
                  isMine: true,
                  canParticipate: widget.currentUser.canParticipate,
                  onPrimaryAction: () => _openProofSheet(q),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (openQuests.isNotEmpty) ...[
              _SectionHeader(
                title: 'OPEN CAMPUS QUESTS (${openQuests.length})',
                subtitle: 'Tap to lock atomically for 45 minutes',
              ),
              const SizedBox(height: 8),
              ...openQuests.map(
                (q) => _QuestCard(
                  quest: q,
                  isMine: false,
                  canParticipate: widget.currentUser.canParticipate,
                  onPrimaryAction: () => _handleClaimQuest(q),
                ),
              ),
            ],
            if (otherActive.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionHeader(
                title: 'IN PROGRESS BY VOLUNTEERS',
                subtitle: 'Currently handled on campus',
              ),
              const SizedBox(height: 8),
              ...otherActive.map(
                (q) => _QuestCard(
                  quest: q,
                  isMine: false,
                  isLockedByOther: true,
                  canParticipate: false,
                  onPrimaryAction: () {},
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Color(0xFF475569),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  final QuestModel quest;
  final bool isMine;
  final bool isLockedByOther;
  final bool canParticipate;
  final VoidCallback onPrimaryAction;

  const _QuestCard({
    required this.quest,
    required this.isMine,
    this.isLockedByOther = false,
    required this.canParticipate,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final isHealth = quest.isHealthcare;
    final badgeColor =
        isHealth ? const Color(0xFF0D9488) : const Color(0xFFD97706);

    final remaining = quest.deadlineAt.difference(DateTime.now());
    final timeLabel = remaining.isNegative
        ? 'Expiring soon'
        : remaining.inHours >= 1
            ? '${remaining.inHours}h ${remaining.inMinutes % 60}m left'
            : '${remaining.inMinutes}m left';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isMine ? const Color(0xFFFFFBEB) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMine ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
          width: isMine ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isHealth ? 'HEALTHCARE' : 'FEEDING',
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (quest.isShiftLinked) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SHIFT RUN',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '+${quest.rewardPoints} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quest.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            if (quest.description != null && quest.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                quest.description!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _MetaTag(
                  icon: Icons.location_on_outlined,
                  label: quest.zoneName,
                ),
                if (quest.petName != null && quest.petName!.isNotEmpty)
                  _MetaTag(
                    icon: Icons.pets_rounded,
                    label: quest.petName!,
                  ),
                _MetaTag(
                  icon: Icons.schedule_rounded,
                  label: timeLabel,
                ),
              ],
            ),
            if (quest.bowlLocations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Bowls: ${quest.bowlLocations.join(' • ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isLockedByOther
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline_rounded, size: 16),
                      label: Text('Claimed by ${quest.claimerDisplayName}'),
                    )
                  : FilledButton.icon(
                      onPressed: canParticipate ? onPrimaryAction : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: isMine
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF18181B),
                        foregroundColor:
                            isMine ? Colors.white : const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isMine
                            ? Icons.camera_alt_rounded
                            : Icons.front_hand_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isMine ? 'Complete & Submit Proof' : 'Claim Quest',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}