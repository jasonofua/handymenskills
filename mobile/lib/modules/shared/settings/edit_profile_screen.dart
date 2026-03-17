import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/auth_controller.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authController = Get.find<AuthController>();
  final _profileRepo = Get.find<ProfileRepository>();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;

  File? _avatarFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = _authController.profile;
    _nameController = TextEditingController(text: profile['full_name'] ?? '');
    _phoneController = TextEditingController(text: profile['phone'] ?? '');
    _addressController = TextEditingController(text: profile['address'] ?? '');
    _cityController = TextEditingController(text: profile['city'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final userId = _authController.userId;
      final data = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
      };

      if (_avatarFile != null) {
        await _profileRepo.uploadAvatar(userId, _avatarFile!);
      }

      await _profileRepo.updateProfile(userId, data);
      await _authController.refreshProfile();

      AppSnackbar.success('Profile updated');
      if (mounted) context.pop();
    } catch (e) {
      AppSnackbar.error('Failed to update profile');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: AppTextStyles.h4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.md),
              // Avatar
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    if (_avatarFile != null)
                      ClipOval(
                        child: Image.file(
                          _avatarFile!,
                          width: AppDimensions.avatarXl,
                          height: AppDimensions.avatarXl,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      AppAvatar(
                        imageUrl: _authController.userAvatar,
                        name: _authController.userName,
                        size: AppDimensions.avatarXl,
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'Tap to change photo',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppDimensions.xl),

              AppTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                label: 'Address',
                hint: 'Enter your address',
                controller: _addressController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                label: 'City',
                hint: 'Enter your city',
                controller: _cityController,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  )
                : const Text('Save Changes', style: AppTextStyles.button),
          ),
        ),
      ),
    );
  }
}
