import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../Manob/app_validators.dart';
import '../Manob/auth_service.dart';
import 'donor_service.dart';
import 'user_data.dart';
import 'user_nav.dart';
import 'user_service.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _addressController;
  String _bloodGroup = 'AB+';
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserProfileData.name);
    _mobileController = TextEditingController(text: UserProfileData.mobile);
    _addressController = TextEditingController(text: UserProfileData.address);
    _bloodGroup = UserProfileData.bloodGroup;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = AuthService.currentFirebaseUser;
    if (user == null) return;

    final userProfile = await UserService.getUser(user.uid);
    final donorProfile = await DonorService.getDonorProfile(user.uid);
    String? savedPhoto;
    try {
      savedPhoto = await UserService.streamUserProfilePhoto(user.uid).first;
    } catch (_) {
      // Fall back to legacy profileImageUrl / Firebase Auth photoURL.
    }

    if (mounted) {
      setState(() {
        if (userProfile != null && userProfile.fullName.isNotEmpty) {
          _nameController.text = userProfile.fullName;
        }
        if (userProfile != null && userProfile.phoneNumber.isNotEmpty) {
          _mobileController.text = userProfile.phoneNumber;
        }
        final photoCandidates = <String?>[
          savedPhoto,
          userProfile?.profileImageUrl,
          donorProfile?.profileImageUrl,
          user.photoURL,
        ];
        _profileImageUrl = photoCandidates.firstWhere(
          (value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );

        if (donorProfile != null) {
          if (donorProfile.address.isNotEmpty) {
            _addressController.text = donorProfile.address;
          }
          if (donorProfile.bloodGroup.isNotEmpty) {
            _bloodGroup = donorProfile.bloodGroup;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality:
            70, // Compresses to ~30-60 KB, well within the 300 KiB limit
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      // Enforce 300 KiB document size limit to preserve ₹0 free tier
      if (bytes.lengthInBytes > 307200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected image is too large (max 300 KiB). Please choose a smaller photo.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      _showImagePreviewDialog(dataUri, bytes.lengthInBytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access image: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImagePreviewDialog(String dataUri, int sizeBytes) {
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Preview Profile Photo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kUserBlue, width: 3),
                    ),
                    child: ClipOval(child: buildAvatarImage(dataUri, 120)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Size: ${(sizeBytes / 1024).toStringAsFixed(1)} KB (Max 300 KB)',
                    style: const TextStyle(fontSize: 12, color: kUserMuted),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogCtx);
                          _showPhotoOptions();
                        },
                  child: const Text('Change Photo'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          final uid = AuthService.currentFirebaseUser?.uid;
                          if (uid != null) {
                            final success = await UserService.saveProfilePhoto(
                              uid,
                              photoData: dataUri,
                              sizeBytes: sizeBytes,
                            );

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }

                            if (!mounted) return;
                            if (success) {
                              setState(() {
                                _profileImageUrl = dataUri;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profile photo updated and synchronized across all screens!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to save profile photo.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kUserBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Photo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final hasPhoto =
            _profileImageUrl != null && _profileImageUrl!.trim().isNotEmpty;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kUserDark,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: kUserBlue,
                  ),
                  title: const Text(
                    'Choose from Device / Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: kUserBlue,
                  ),
                  title: const Text(
                    'Take a Photo with Camera',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Profile Photo'),
                          content: const Text(
                            'Are you sure you want to remove your profile photo?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Remove',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        final uid = AuthService.currentFirebaseUser?.uid;
                        if (uid != null) {
                          await UserService.removeProfilePhoto(uid);
                          try {
                            await AuthService.currentFirebaseUser
                                ?.updatePhotoURL(null);
                          } catch (_) {}

                          if (!mounted) return;
                          setState(() {
                            _profileImageUrl = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile photo removed.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final nameErr = AppValidators.validateName(_nameController.text);
    if (nameErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(nameErr)));
      return;
    }
    final phoneErr = AppValidators.validatePhone(_mobileController.text);
    if (phoneErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(phoneErr)));
      return;
    }
    final addressErr = AppValidators.validateAddress(_addressController.text);
    if (addressErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(addressErr)));
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    final user = AuthService.currentFirebaseUser;
    final uid = user?.uid;

    if (uid != null) {
      final name = _nameController.text.trim();
      final phone = _mobileController.text.trim();
      final address = _addressController.text.trim();

      // Persist to Firestore: users & donor_profiles collections.
      // Notice: bloodGroup is strictly excluded from user updates to enforce policy.
      final legacyPhotoUrl =
          (_profileImageUrl != null &&
              !_profileImageUrl!.trim().startsWith('data:image'))
          ? _profileImageUrl
          : null;

      await UserService.updateUserProfile(
        uid,
        fullName: name,
        phoneNumber: phone,
        profileImageUrl: legacyPhotoUrl,
      );

      await DonorService.updateDonorProfile(
        uid,
        fullName: name,
        phoneNumber: phone,
        address: address,
        profileImageUrl: legacyPhotoUrl,
      );

      // Update legacy bridge
      UserProfileData.name = name;
      UserProfileData.mobile = phone;
      UserProfileData.address = address;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: const UserBottomBar(currentIndex: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const UserBackHeader(title: 'EDIT PROFILE'),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                          border: Border.all(color: kUserBorder, width: 2),
                        ),
                        child: ClipOval(
                          child: buildAvatarImage(_profileImageUrl, 110),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kUserBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showPhotoOptions,
                  child: const Text(
                    'Choose Photo from Device',
                    style: TextStyle(
                      color: kUserBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  maxLength: 30,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                    LengthLimitingTextInputFormatter(30),
                  ],
                ),
                const SizedBox(height: 14),
                _buildField(
                  label: 'Mobile Number',
                  controller: _mobileController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 14),
                _buildBloodDropdown(),
                const SizedBox(height: 14),
                _buildField(
                  label: 'Address',
                  controller: _addressController,
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kUserBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kUserDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: formatters,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kUserHint, size: 20),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kUserBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kUserBlue, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Blood Group',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kUserDark,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.lock, size: 14, color: kUserHint),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kUserBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.water_drop_outlined,
                color: Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _bloodGroup,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kUserDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Locked',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kUserBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Blood group is verified and locked. Contact an administrator to update.',
          style: TextStyle(fontSize: 11, color: kUserHint),
        ),
      ],
    );
  }
}
