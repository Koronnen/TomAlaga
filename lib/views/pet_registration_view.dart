import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/pet_registration_controller.dart';
import '../models/pet_model.dart';
import '../views/auth/login_view.dart';
import '../models/map_pin_model.dart';
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

  InputDecoration _inputDecoration({required String label, String? hint}){
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500,),
      hintStyle: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
      filled: true,
      fillColor: const Color.fromARGB(87, 254, 190, 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black87),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 113, 3, 3)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 113, 3, 3)),
      ),
    );
  }

  Widget _fieldLabel(String text){
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 18, color: Colors.black)),
    );
  }

  ButtonStyle _buttonStyle({Color backgroundColor = Colors.white}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: Colors.black),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _fieldLabel("Enter the pet's name: "),
            SizedBox(height: 2),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(label: 'Name', hint: 'e.g. Mingming, Tiger'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            SizedBox(height: 20),
            _fieldLabel("Describe the animal: "),
            SizedBox(height: 2),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration(
                label: 'Introduction / Description',
                hint: 'Appearance, color/markings, personality, etc.',
              ),
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 20),
            _fieldLabel("Enter the location/area where it was found: "),
            SizedBox(height: 2),
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
              decoration: _inputDecoration(
                label: 'Location / Specific Spot',
                hint: 'Auto-filled from map pin; add spot details if needed',
              ),
              onChanged: (_) => _locationWasAutoFilled = false,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Location is required'
                  : null,
            ),
            SizedBox(height: 20),
            _fieldLabel("Neuter Status: "),
            SizedBox(height: 2),
            DropdownButtonFormField<String>(
              value: _neutered,
              decoration: _inputDecoration(label: 'Neutered'),
              items: _neuteredOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(color: Colors.black, fontSize: 14))))
                  .toList(),
              onChanged: (v) => setState(() => _neutered = v ?? _neutered),
            ),
            SizedBox(height: 20),
            _fieldLabel("Vaccination Status: "),
            SizedBox(height: 2),
            TextFormField(
              controller: _vaccinationController,
              decoration: _inputDecoration(
                label: 'Vaccination / Vaccines',
                hint: 'e.g. Anti-rabies, 2025 (leave blank if Unknown)',
              ),
            ),
            SizedBox(height: 20),
            _fieldLabel("Enter their condition: "),
            SizedBox(height: 2),
            TextFormField(
              controller: _conditionController,
              decoration: _inputDecoration(
                label: 'Condition',
                hint: 'Warnings: aggressive, pregnant, injured, etc.',
              ),
              minLines: 2,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _controller.isLoading ? null : _controller.pickImage,
                    style: _buttonStyle(),
                    child: Text('Upload Photo', style: GoogleFonts.inter(color: Colors.black, fontSize: 14)),
                  ),
                  if (_controller.selectedImageBytes != null) ...[
                    const SizedBox(height: 8),
                    Text('Selected: ${_controller.selectedImageName ?? ''}'),
                    const SizedBox(height: 8),
                    Image.memory(_controller.selectedImageBytes!, height: 150),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _controller.isLoading ? null : _submit,
                    style: _buttonStyle(),
                    child: Text('Submit Registration', style: GoogleFonts.inter(color: Colors.black, fontSize: 14)),
                  ),
                  if (_controller.isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator(color: Color(0xFFFEC00F))),
                  ],
                  if (_controller.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_controller.errorMessage!),
                  ],
                ],
              ),
            ),
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
      color: const Color.fromARGB(255, 223, 223, 223),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pet.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  pet.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Text(
                    'Photo could not be loaded',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
                  ),
                ),
              )
            else
              Text(
                'No photo',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
              ),
            const SizedBox(height: 8),
            Text(
              'Name: ${pet.name}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Description: ${pet.description}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
            ),
            Text(
              'Location: ${pet.location}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
            ),
             if (pet.hasPin)
              Text(
                'Map Pin: ${zoneLabel ?? 'Pinned'} '
                '(${pet.mapX!.toStringAsFixed(2)}, ${pet.mapY!.toStringAsFixed(2)})',
              )
            else
              const Text('Map Pin: Not pinned yet'),
            Text(
              'Neutered: ${pet.neutered}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
            ),
            Text(
              'Vaccination: ${pet.vaccination}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
            ),
            Text(
              'Condition: ${pet.condition}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
            ),
            Text(
              'Verification Status: ${pet.verificationStatus}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (pet.verificationStatus == 'pending') ...[
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _controller.isLoading
                        ? null
                        : () => _updateStatus(pet, 'verified'),
                    style: _buttonStyle(backgroundColor: Color.fromARGB(245, 96, 226, 124)),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.inter(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _controller.isLoading
                        ? null
                        : () => _updateStatus(pet, 'rejected'),
                    style: _buttonStyle(backgroundColor: Color.fromARGB(245, 226, 96, 96)),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.inter(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
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
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          title: Text("Campus Pet Registration", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.logout),
                color: const Color(0xFFFEC00F),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Color(0xFFFEC00F),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
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