import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/quest_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../models/map_pin_model.dart';
import '../../models/pet_model.dart';

class CoordinatorCreateSheet extends StatefulWidget {
  final QuestController questController;
  final ShiftController shiftController;

  const CoordinatorCreateSheet({
    super.key,
    required this.questController,
    required this.shiftController,
  });

  @override
  State<CoordinatorCreateSheet> createState() => _CoordinatorCreateSheetState();
}

class _CoordinatorCreateSheetState extends State<CoordinatorCreateSheet> {
  int _mode = 0; // 0 = On-Demand Quest, 1 = Batch Shift Calendar
  String _category = 'feeding'; // 'feeding' | 'healthcare'
  bool _zoneRestricted = true;
  String _selectedZoneId = 'area_3';
  int _capacityPerDay = 2;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _openWindowHoursController = TextEditingController(text: '3');
  final _openWindowMinutesController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedBowlIds = {};
  List<String> _selectedBowlLocations = [];
  String? _selectedPetId;
  String? _selectedPetName;
  bool _isSaving = false;

  late final Stream<List<PetModel>> _petsStream;
  late final Stream<List<MapPinModel>> _bowlsStream;

  @override
  void initState() {
    super.initState();
    _petsStream = widget.questController.streamAvailablePets();
    _bowlsStream = widget.questController.streamBowlStations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _openWindowHoursController.dispose();
    _openWindowMinutesController.dispose();
    super.dispose();
  }

  Future<void> _selectBowlLocations(List<MapPinModel> bowls) async {
    final selectedIds = Set<String>.from(_selectedBowlIds);
    final selection = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Bowl Stations'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: ListView(
              shrinkWrap: true,
              children: bowls
                  .map(
                    (bowl) => CheckboxListTile(
                      value: selectedIds.contains(bowl.id),
                      title: Text(bowl.title),
                      subtitle: bowl.zoneName.isEmpty
                          ? null
                          : Text(bowl.zoneName),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (selected) {
                        setDialogState(() {
                          if (selected == true) {
                            selectedIds.add(bowl.id);
                          } else {
                            selectedIds.remove(bowl.id);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, Set<String>.from(selectedIds)),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );

    if (selection == null || !mounted) return;
    setState(() {
      _selectedBowlIds
        ..clear()
        ..addAll(selection);
      _selectedBowlLocations = bowls
          .where((bowl) => selection.contains(bowl.id))
          .map(_bowlLabel)
          .toList();
    });
  }

  String _bowlLabel(MapPinModel bowl) =>
      bowl.zoneName.isEmpty ? bowl.title : '${bowl.title} (${bowl.zoneName})';

  String _petLabel(PetModel pet) => pet.verificationStatus == 'verified'
      ? pet.name
      : '${pet.name} (${pet.verificationStatus})';

  Widget _buildPetDropdown() {
    return StreamBuilder<List<PetModel>>(
      stream: _petsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _loadingField(
            'Target Pet',
            'Could not load registered pets: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return _loadingField('Target Pet', 'Loading registered pets...');
        }

        final pets = snapshot.data!;
        final selectablePets = pets.where((pet) => pet.id != null).toList();
        final selectedId = pets.any((pet) => pet.id == _selectedPetId)
            ? _selectedPetId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: selectedId,
          decoration: InputDecoration(
            labelText: 'Target Pet (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          hint: Text(pets.isEmpty ? 'No registered pets' : 'Select a pet'),
          items: selectablePets
              .map(
                (pet) => DropdownMenuItem<String>(
                  value: pet.id!,
                  child: Text(_petLabel(pet)),
                ),
              )
              .toList(),
          onChanged: (id) {
            final pet = selectablePets.where((candidate) => candidate.id == id);
            setState(() {
              _selectedPetId = id;
              _selectedPetName = pet.isEmpty ? null : pet.first.name;
            });
          },
        );
      },
    );
  }

  Widget _buildBowlDropdown() {
    return StreamBuilder<List<MapPinModel>>(
      stream: _bowlsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _loadingField(
            'Bowl / Station Locations',
            'Could not load bowl stations: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return _loadingField(
            'Bowl / Station Locations',
            'Loading bowl stations...',
          );
        }

        final bowls = snapshot.data!;
        final selectedLabels = bowls
            .where((bowl) => _selectedBowlIds.contains(bowl.id))
            .map(_bowlLabel)
            .toList();

        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Bowl / Station Locations',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: InkWell(
            onTap: bowls.isEmpty ? null : () => _selectBowlLocations(bowls),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabels.isEmpty
                        ? (bowls.isEmpty
                              ? 'No bowl stations registered'
                              : 'Select bowl stations')
                        : selectedLabels.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _loadingField(String label, String message) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(message),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    if (_mode == 0 && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final zoneName = MapPinModel.zones[_selectedZoneId] ?? _selectedZoneId;
    final petName = _selectedPetName;
    final petId = _selectedPetId;
    final bowls = _selectedBowlLocations;
    final openWindow = Duration(
      hours: int.parse(_openWindowHoursController.text),
      minutes: int.tryParse(_openWindowMinutesController.text) ?? 0,
    );

    bool success;
    if (_mode == 0) {
      success = await widget.questController.createQuest(
        category: _category,
        type: _category == 'healthcare' ? 'caregiving' : 'feeding',
        title: title,
        description: _descController.text,
        zoneId: _selectedZoneId,
        zoneName: zoneName,
        bowlLocations: bowls,
        petId: petId,
        petName: petName,
        validFor: openWindow,
      );
    } else {
      success = await widget.shiftController.batchCreateShifts(
        seriesTitle: title,
        category: _category,
        zoneRestricted: _zoneRestricted,
        zoneId: _selectedZoneId,
        zoneName: zoneName,
        petId: petId,
        petName: petName,
        bowlLocations: bowls,
        startDate: _startDate,
        endDate: _endDate,
        startHour: _startTime.hour,
        startMinute: _startTime.minute,
        endHour: _endTime.hour,
        endMinute: _endTime.minute,
        capacity: _capacityPerDay,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == 0
                ? 'On-demand quest published!'
                : 'Shift calendar generated!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validateOpenWindowHours(String? value) {
    final hours = int.tryParse(value ?? '');
    if (hours == null || hours < 0 || hours > 24) {
      return 'Enter a value from 0 to 24 hours';
    }

    final minutes = int.tryParse(_openWindowMinutesController.text) ?? 0;
    if (minutes < 0 || minutes > 59) return null;

    final totalMinutes = hours * 60 + minutes;
    if (totalMinutes == 0) return 'Open window must be at least one minute';
    if (totalMinutes > 24 * 60) return 'Open window cannot exceed 24 hours';
    return null;
  }

  String? _validateOpenWindowMinutes(String? value) {
    if (value == null || value.isEmpty) return null;
    final minutes = int.tryParse(value);
    if (minutes == null || minutes < 0 || minutes > 59) {
      return 'Enter minutes from 0 to 59';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coordinator Dispatch',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Single Quest')),
                  ButtonSegment(value: 1, label: Text('Cinema Seat Schedule')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Feeding'),
                    selected: _category == 'feeding',
                    onSelected: (_) => setState(() {
                      _category = 'feeding';
                      _zoneRestricted = true;
                    }),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Healthcare'),
                    selected: _category == 'healthcare',
                    onSelected: (_) => setState(() {
                      _category = 'healthcare';
                      _zoneRestricted = false;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _mode == 0
                      ? 'Quest Headline'
                      : 'Schedule Title (e.g., Dec Feeding Run)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedZoneId,
                decoration: InputDecoration(
                  labelText: 'Campus Zone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: MapPinModel.zones.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedZoneId = val);
                },
              ),
              const SizedBox(height: 10),
              _buildPetDropdown(),
              const SizedBox(height: 10),
              _buildBowlDropdown(),
              if (_mode == 0) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Instructions / Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _openWindowHoursController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 2,
                        validator: _validateOpenWindowHours,
                        decoration: InputDecoration(
                          labelText: 'Hours',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _openWindowMinutesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 2,
                        validator: _validateOpenWindowMinutes,
                        decoration: InputDecoration(
                          labelText: 'Minutes',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Restrict to Home-Zone Volunteers',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Turn off for cross-zone healthcare courses',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _zoneRestricted,
                  onChanged: (v) => setState(() => _zoneRestricted = v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isStart: true),
                        icon: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          'Start: ${_startDate.month}/${_startDate.day}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isStart: false),
                        icon: const Icon(Icons.event, size: 16),
                        label: Text('End: ${_endDate.month}/${_endDate.day}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Volunteers per day: '),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _capacityPerDay,
                      items: [1, 2, 3, 4]
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text('$n seat${n == 1 ? '' : 's'}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _capacityPerDay = v);
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _mode == 0 ? 'Publish Quest' : 'Generate Calendar Slots',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
