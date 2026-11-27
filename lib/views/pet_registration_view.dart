import 'package:flutter/material.dart';

import '../controllers/pet_registration_controller.dart';
import '../models/map_pin_model.dart';
import '../models/pet_model.dart';
import '../utils/campus_map_landmark_constants.dart';
import 'map/campus_map_picker.dart';

class PetRegistrationView extends StatefulWidget {
  const PetRegistrationView({super.key});

  @override
  State<PetRegistrationView> createState() => _PetRegistrationViewState();
}

class _PetRegistrationViewState extends State<PetRegistrationView> {
  final PetRegistrationController _controller = PetRegistrationController();
  late final Stream<List<PetModel>> _petsStream = _controller.streamPets();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _vaccinationController = TextEditingController();
  final _conditionController = TextEditingController();

  static const _neuteredOptions = ['Yes', 'No', 'Unknown'];
  final List<CampusLandmark> _landmarks =
      CampusMapLandmarkConstants.ustLandmarks;

  String _neutered = 'Unknown';
  bool _locationWasAutoFilled = true;

  PickedMapLocation? _pickedLocation;
  String? _pinError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _vaccinationController.dispose();
    _conditionController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleLocationPicked(PickedMapLocation picked) {
    setState(() {
      _pickedLocation = picked;
      _pinError = null;

      if (_locationController.text.trim().isEmpty || _locationWasAutoFilled) {
        _locationController.text =
            picked.nearestLandmark?.name ?? picked.zoneName;
        _locationWasAutoFilled = true;
      }
    });
  }

  Future<bool> _confirmDuplicates(List<PetModel> matches) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Possible duplicates found'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text('These similar cats are already registered:'),
              const SizedBox(height: 8),
              ...matches.map(
                (pet) => ListTile(
                  title: Text(pet.name),
                  subtitle: Text(
                    'Location: ${pet.location}\n'
                    'Description: ${pet.description}\n'
                    'Status: ${pet.verificationStatus}',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Register Anyway'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _vaccinationController.clear();
    _conditionController.clear();
    setState(() {
      _neutered = 'Unknown';
      _locationWasAutoFilled = true;
      _pickedLocation = null;
      _pinError = null;
    });
    _controller.clearSelectedImage();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (_pickedLocation == null) {
      setState(() {
        _pinError = 'Please tap the map to pin where the cat was spotted.';
      });
    }
    if (!formValid || _pickedLocation == null) return;

    final matches = await _controller.checkDuplicates(
      name: _nameController.text,
      location: _locationController.text,
      description: _descriptionController.text,
    );
    if (!mounted) return;

    if (_controller.errorMessage != null) {
      _showMessage(_controller.errorMessage!);
      return;
    }

    if (matches.isNotEmpty) {
      final proceed = await _confirmDuplicates(matches);
      if (!proceed || !mounted) return;
    }

    final success = await _controller.registerPet(
      name: _nameController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      neutered: _neutered,
      vaccination: _vaccinationController.text,
      condition: _conditionController.text,
      mapX: _pickedLocation!.mapX,
      mapY: _pickedLocation!.mapY,
      zoneId: _pickedLocation!.zoneId,
      landmarkId: _pickedLocation!.nearestLandmark?.id,
    );
    if (!mounted) return;

    if (success) {
      _resetForm();
      _showMessage('Cat registered. Verification is pending.');
    } else {
      _showMessage(_controller.errorMessage ?? 'Registration failed.');
    }
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Cat Introduction / Description',
                hintText: 'Appearance, color/markings, personality, etc.',
              ),
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CampusMapPickerField(
                value: _pickedLocation,
                onChanged: _handleLocationPicked,
                landmarks: _landmarks,
                existingPins: const [],
                pinType: PinType.cat,
                pinTitle: _nameController.text.trim().isEmpty
                    ? 'New Cat'
                    : _nameController.text.trim(),
                overlayTitle: 'Pin Cat Location',
                errorText: _pinError,
              ),
            ),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location / Specific Spot',
                hintText: 'Auto-filled from map pin; add spot details if needed',
              ),
              onChanged: (_) => _locationWasAutoFilled = false,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Location is required'
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _neutered,
              decoration: const InputDecoration(labelText: 'Neutered'),
              items: _neuteredOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _neutered = v ?? _neutered),
            ),
            TextFormField(
              controller: _vaccinationController,
              decoration: const InputDecoration(
                labelText: 'Vaccination / Vaccines',
                hintText: 'e.g. Anti-rabies, 2025 (leave blank if unknown)',
              ),
            ),
            TextFormField(
              controller: _conditionController,
              decoration: const InputDecoration(
                labelText: 'Condition',
                hintText: 'Warnings: aggressive, pregnant, injured, etc.',
              ),
              minLines: 2,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.isLoading ? null : _controller.pickImage,
              child: const Text('Upload Photo'),
            ),
            if (_controller.selectedImageBytes != null) ...[
              const SizedBox(height: 8),
              Text('Selected: ${_controller.selectedImageName ?? ''}'),
              const SizedBox(height: 8),
              Image.memory(_controller.selectedImageBytes!, height: 150),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.isLoading ? null : _submit,
              child: const Text('Submit Registration'),
            ),
            if (_controller.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_controller.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_controller.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(PetModel pet, String status) async {
    if (pet.id == null) return;
    final ok = await _controller.updateVerificationStatus(pet.id!, status);
    if (!ok) _showMessage(_controller.errorMessage ?? 'Update failed.');
  }

  Widget _buildPetCard(PetModel pet) {
    final zoneLabel = pet.zoneId != null
        ? (MapPinModel.zones[pet.zoneId] ?? pet.zoneId!)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pet.imageUrl.isNotEmpty)
              Image.network(
                pet.imageUrl,
                height: 150,
                errorBuilder: (context, error, stack) =>
                    const Text('Photo could not be loaded'),
              )
            else
              const Text('No photo'),
            const SizedBox(height: 8),
            Text('Name: ${pet.name}'),
            Text('Description: ${pet.description}'),
            Text('Location: ${pet.location}'),
            if (pet.hasPin)
              Text(
                'Map Pin: ${zoneLabel ?? 'Pinned'} '
                '(${pet.mapX!.toStringAsFixed(2)}, ${pet.mapY!.toStringAsFixed(2)})',
              )
            else
              const Text('Map Pin: Not pinned yet'),
            Text('Neutered: ${pet.neutered}'),
            Text('Vaccination: ${pet.vaccination}'),
            Text('Condition: ${pet.condition}'),
            Text('Verification Status: ${pet.verificationStatus}'),
            if (pet.verificationStatus == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _controller.isLoading
                        ? null
                        : () => _updateStatus(pet, 'verified'),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _controller.isLoading
                        ? null
                        : () => _updateStatus(pet, 'rejected'),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryTab() {
    return StreamBuilder<List<PetModel>>(
      stream: _petsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load cats: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final pets = snapshot.data!;
        return Column(
          children: [
            if (_controller.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: pets.isEmpty
                  ? const Center(child: Text('No cats registered yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: pets.length,
                      itemBuilder: (context, index) =>
                          _buildPetCard(pets[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Campus Cat Registration'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Register Pet'),
              Tab(text: 'Verify & Directory'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => TabBarView(
            children: [
              _buildRegisterTab(),
              _buildDirectoryTab(),
            ],
          ),
        ),
      ),
    );
  }
}