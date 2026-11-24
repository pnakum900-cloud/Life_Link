import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Manob/app_validators.dart';
import '../Manob/auth_service.dart';
import 'blood_request_service.dart';
import 'user_nav.dart';
import 'user_service.dart';

class Request extends StatefulWidget {
  const Request({super.key});

  @override
  State<Request> createState() => _RequestState();
}

class _RequestState extends State<Request> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _unitController = TextEditingController(text: '1');
  final _contactController = TextEditingController();

  String _bloodGroup = 'AB+';
  String _urgency = 'Normal';
  bool _isLoading = false;

  static const _bloodOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  static const _urgencyOptions = ['Normal', 'Urgent', 'Critical'];

  @override
  void dispose() {
    _patientController.dispose();
    _hospitalController.dispose();
    _unitController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_bloodGroup.isEmpty) {
      _showMessage('Please select a blood group');
      return;
    }

    if (_urgency.isEmpty) {
      _showMessage('Please select urgency level');
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    final currentUser = AuthService.currentFirebaseUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      _showMessage('Please log in before submitting a blood request.');
      return;
    }

    final requesterId = currentUser.uid;

    // Resolve requester's name & picture safely from authenticated user profile
    final userProfile = await UserService.getUser(requesterId);
    final requesterName = (userProfile?.fullName.isNotEmpty == true)
        ? userProfile!.fullName
        : (currentUser.displayName?.isNotEmpty == true
              ? currentUser.displayName!
              : 'LifeLink Member');
    final requesterPhoto = userProfile?.profileImageUrl ?? currentUser.photoURL;

    final units = num.tryParse(_unitController.text.trim()) ?? 1;

    final requestId = await BloodRequestService.createRequest(
      requesterId: requesterId,
      requesterName: requesterName,
      requesterPhotoUrl: requesterPhoto,
      patientName: _patientController.text.trim(),
      bloodGroup: _bloodGroup,
      units: units,
      hospitalName: _hospitalController.text.trim(),
      contactNumber: _contactController.text.trim(),
      urgency: _urgency,
      createdByRole: 'user',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (requestId != null) {
      _showMessage(
        'Blood request submitted successfully! It is now pending admin approval.',
        isSuccess: true,
      );

      _patientController.clear();
      _hospitalController.clear();
      _contactController.clear();
      _unitController.text = '1';
    } else {
      _showMessage('Failed to submit request. Please try again.');
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: const UserBottomBar(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LifeLinkHeader(),
                const SizedBox(height: 28),

                const Text(
                  'Request Blood',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: kUserDark,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Fill the details below to broadcast an urgent blood\nrequest to nearby donors in Rajkot.',
                  style: TextStyle(color: kUserMuted, height: 1.4),
                ),

                const SizedBox(height: 24),

                const Text('Patient Name', style: TextStyle(color: kUserMuted)),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _patientController,
                  decoration: userFieldDecoration('ENTER PATIENT NAME'),
                  validator: AppValidators.validatePatientName,
                ),

                const SizedBox(height: 18),

                const Text(
                  'Blood Group Required',
                  style: TextStyle(color: kUserMuted),
                ),

                const SizedBox(height: 10),

                FormField<String>(
                  initialValue: _bloodGroup,
                  validator: (value) =>
                      AppValidators.validateBloodGroup(_bloodGroup),
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _bloodOptions.map((group) {
                            final selected = _bloodGroup == group;

                            return ChoiceChip(
                              label: Text(group),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _bloodGroup = group;
                                });
                                field.didChange(group);
                              },
                              selectedColor: const Color(0xFFDBEAFE),
                              labelStyle: TextStyle(
                                color: selected ? kUserBlue : kUserDark,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: selected ? kUserBlue : kUserBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }).toList(),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              field.errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                const Text('Hospital', style: TextStyle(color: kUserMuted)),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _hospitalController,
                  decoration: userFieldDecoration(
                    'ENTER HOSPITAL NAME (e.g. Civil Hospital)',
                  ),
                  validator: (value) => AppValidators.validateAddressOrText(
                    value,
                    fieldName: 'Hospital name',
                    minLength: 3,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unit (1U-450ML)',
                            style: TextStyle(color: kUserMuted),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _unitController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: userFieldDecoration('1'),
                            validator: (value) => AppValidators.validateUnits(
                              value,
                              min: 1,
                              max: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Number',
                            style: TextStyle(color: kUserMuted),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _contactController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: userFieldDecoration(
                              'ENTER CONTACT NUMBER',
                            ),
                            validator: AppValidators.validateIndianPhone,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  'Urgency Level',
                  style: TextStyle(color: kUserMuted),
                ),

                const SizedBox(height: 10),

                FormField<String>(
                  initialValue: _urgency,
                  validator: (value) {
                    if (_urgency.isEmpty) {
                      return 'Urgency level is required';
                    }
                    return null;
                  },
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: _urgencyOptions.map((level) {
                            final selected = _urgency == level;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: level == _urgencyOptions.last ? 0 : 8,
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _urgency = level;
                                    });
                                    field.didChange(level);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: selected
                                        ? const Color(0xFFDBEAFE)
                                        : Colors.white,
                                    foregroundColor: selected
                                        ? kUserBlue
                                        : kUserDark,
                                    side: BorderSide(
                                      color: selected ? kUserBlue : kUserBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(level),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              field.errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kUserBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SUBMIT REQUEST',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
