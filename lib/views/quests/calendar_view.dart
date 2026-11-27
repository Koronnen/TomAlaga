import 'package:flutter/material.dart';
import '../../controllers/shift_controller.dart';
import '../../models/shift_model.dart';
import '../../models/user_model.dart';

class CinemaSeatCalendarView extends StatefulWidget {
  final List<ShiftModel> shifts;
  final AppUser currentUser;
  final ShiftController shiftController;
  final void Function(String spawnedQuestId) onCheckedInAndSpawned;

  const CinemaSeatCalendarView({
    super.key,
    required this.shifts,
    required this.currentUser,
    required this.shiftController,
    required this.onCheckedInAndSpawned,
  });

  @override
  State<CinemaSeatCalendarView> createState() => _CinemaSeatCalendarViewState();
}

class _CinemaSeatCalendarViewState extends State<CinemaSeatCalendarView> {
  String? _selectedSeriesId;
  final Set<String> _stagedShiftIds = {};

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdays = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
  ];

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  Future<void> _confirmStagedReservations() async {
    if (_stagedShiftIds.isEmpty) return;

    final user = widget.currentUser;
    final count = _stagedShiftIds.length;
    final success = await widget.shiftController.batchReserveShifts(
      shiftIds: _stagedShiftIds.toList(),
      uid: user.uid,
      email: user.email,
      status: user.isSuspended ? 'suspended' : 'approved',
      isSuspended: user.isSuspended,
    );

    if (!mounted) return;
    if (success) {
      setState(() => _stagedShiftIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Confirmed $count shift slot${count == 1 ? '' : 's'}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.shiftController.errorMessage ?? 'Could not reserve shifts.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openShiftDetailSheet(ShiftModel shift) {
    final user = widget.currentUser;
    final myEntry = shift.volunteerFor(user.uid);
    final isLateCancel =
        shift.startTime.difference(DateTime.now()).inMinutes < 120;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: shift.isHealthcare
                          ? const Color(0xFF0D9488).withValues(alpha: 0.12)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      shift.zoneRestricted ? 'HOME ZONE' : 'CROSS-ZONE OPEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: shift.isHealthcare
                            ? const Color(0xFF0D9488)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${shift.spotsFilled}/${shift.capacity} seats filled',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${_months[shift.startTime.month - 1]} ${shift.startTime.day} • ${shift.title}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${shift.zoneName} • ${_formatTime(shift.startTime)} – ${_formatTime(shift.endTime)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              if (shift.petName != null && shift.petName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Target Pet: ${shift.petName}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
              if (shift.bowlLocations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Stations: ${shift.bowlLocations.join(' • ')}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Assigned Volunteers',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              if (shift.volunteers.isEmpty)
                const Text(
                  'No volunteers booked yet.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                )
              else
                Wrap(
                  spacing: 8,
                  children: shift.volunteers.map((v) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFF18181B),
                        child: Text(
                          v.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      label: Text(
                        '${v.displayName} (${v.status})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 18),

              // Action Controls based on user's slot status
              if (myEntry != null && myEntry.status == 'reserved') ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final questId =
                          await widget.shiftController.checkInAndSpawnQuest(
                        shiftId: shift.shiftId,
                        uid: user.uid,
                        email: user.email,
                      );
                      if (questId != null) {
                        widget.onCheckedInAndSpawned(questId);
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.shiftController.errorMessage ??
                                  'Check-in unavailable yet.',
                            ),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text(
                      'Check In & Start Run (+25 pts)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await widget.shiftController.cancelShiftReservation(
                        shiftId: shift.shiftId,
                        uid: user.uid,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLateCancel
                          ? 'Cancel Reservation (-5 pt late penalty)'
                          : 'Cancel Reservation (Free ≥ 2h notice)',
                    ),
                  ),
                ),
              ] else if (myEntry != null && myEntry.status == 'checked_in') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'You are already checked in! Open On-Demand Quests -> My Active Runs to submit proof.',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shifts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No scheduled shift calendars available right now.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    // Group shifts by seriesId so each schedule gets its own Cinema Seat Grid
    final Map<String, List<ShiftModel>> grouped = {};
    for (final s in widget.shifts) {
      grouped.putIfAbsent(s.seriesId, () => []).add(s);
    }

    final seriesKeys = grouped.keys.toList();
    final activeSeriesId =
        seriesKeys.contains(_selectedSeriesId) ? _selectedSeriesId! : seriesKeys.first;
    final seriesShifts = grouped[activeSeriesId]!
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final sample = seriesShifts.first;

    // Pad leading empty cells so columns align cleanly with Sun..Sat
    final leadingBlanks = sample.startTime.weekday % 7;
    final totalCells = leadingBlanks + seriesShifts.length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            if (seriesKeys.length > 1) ...[
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: seriesKeys.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final key = seriesKeys[idx];
                    final firstItem = grouped[key]!.first;
                    final isSelected = key == activeSeriesId;
                    return ChoiceChip(
                      label: Text(firstItem.seriesTitle),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedSeriesId = key;
                          _stagedShiftIds.clear();
                        });
                      },
                      selectedColor: const Color(0xFF18181B),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF334155),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Series Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sample.seriesTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: sample.zoneRestricted
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sample.zoneRestricted ? sample.zoneName : 'ALL ZONES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: sample.zoneRestricted
                                ? const Color(0xFFB45309)
                                : const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(sample.startTime)} – ${_formatTime(sample.endTime)} • Tap green seats to multi-select',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Legend
                  const Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _SeatLegend(color: Color(0xFFDCFCE7), border: Color(0xFF22C55E), label: 'Open'),
                      _SeatLegend(color: Color(0xFFFEF3C7), border: Color(0xFFF59E0B), label: 'Selected'),
                      _SeatLegend(color: Color(0xFFDBEAFE), border: Color(0xFF2563EB), label: 'Booked (You)'),
                      _SeatLegend(color: Color(0xFFF1F5F9), border: Color(0xFFCBD5E1), label: 'Full'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Weekday Header Row
            Row(
              children: _weekdays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),

            // Cinema Seat Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                if (index < leadingBlanks) {
                  return const SizedBox.shrink();
                }

                final shift = seriesShifts[index - leadingBlanks];
                final isMine = shift.hasUser(widget.currentUser.uid);
                final isStaged = _stagedShiftIds.contains(shift.shiftId);
                final isFull = shift.isFull;

                Color bg = const Color(0xFFDCFCE7);
                Color border = const Color(0xFF22C55E);
                Color textColor = const Color(0xFF14532D);

                if (isMine) {
                  bg = const Color(0xFFDBEAFE);
                  border = const Color(0xFF2563EB);
                  textColor = const Color(0xFF1E3A8A);
                } else if (isStaged) {
                  bg = const Color(0xFFFEF3C7);
                  border = const Color(0xFFF59E0B);
                  textColor = const Color(0xFF78350F);
                } else if (isFull) {
                  bg = const Color(0xFFF1F5F9);
                  border = const Color(0xFFCBD5E1);
                  textColor = const Color(0xFF94A3B8);
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (isMine || isFull || !widget.currentUser.canParticipate) {
                      _openShiftDetailSheet(shift);
                      return;
                    }
                    setState(() {
                      if (isStaged) {
                        _stagedShiftIds.remove(shift.shiftId);
                      } else {
                        _stagedShiftIds.add(shift.shiftId);
                      }
                    });
                  },
                  onLongPress: () => _openShiftDetailSheet(shift),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: border,
                        width: isStaged || isMine ? 1.8 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _months[shift.startTime.month - 1],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '${shift.startTime.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMine
                              ? 'YOU'
                              : '${shift.spotsFilled}/${shift.capacity}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        // Floating Multi-Select Commit Bar
        if (_stagedShiftIds.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF18181B),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_stagedShiftIds.length} shift date${_stagedShiftIds.length == 1 ? '' : 's'} selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            '+25 Care Index pts per completed run',
                            style: TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _stagedShiftIds.clear()),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Color(0xFFA1A1AA)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: _confirmStagedReservations,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF18181B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Confirm (${_stagedShiftIds.length})',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SeatLegend extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;

  const _SeatLegend({
    required this.color,
    required this.border,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
        ),
      ],
    );
  }
}