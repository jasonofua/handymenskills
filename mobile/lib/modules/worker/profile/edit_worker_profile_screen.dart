import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/worker_profile_controller.dart';
import '../../../data/constants/nigerian_locations.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_chip.dart';
import '../../../widgets/common/app_dropdown.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_text_field.dart';

class EditWorkerProfileScreen extends StatefulWidget {
  const EditWorkerProfileScreen({super.key});

  @override
  State<EditWorkerProfileScreen> createState() =>
      _EditWorkerProfileScreenState();
}

class _EditWorkerProfileScreenState extends State<EditWorkerProfileScreen> {
  final _workerProfileController = Get.find<WorkerProfileController>();
  final _profileController = Get.find<ProfileController>();
  final _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bioController;
  late final TextEditingController _headlineController;
  late final TextEditingController _experienceYearsController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountNameController;

  String? _selectedState;
  String? _selectedLga;

  @override
  void initState() {
    super.initState();
    final profile = _workerProfileController.workerProfile;
    _bioController = TextEditingController(text: profile['bio'] ?? '');
    _headlineController =
        TextEditingController(text: profile['headline'] ?? '');
    _experienceYearsController = TextEditingController(
      text: (profile['experience_years'] ?? '').toString(),
    );
    _bankNameController =
        TextEditingController(text: profile['bank_name'] ?? '');
    _accountNumberController =
        TextEditingController(text: profile['bank_account_number'] ?? '');
    _accountNameController =
        TextEditingController(text: profile['bank_account_name'] ?? '');

    // Load current location from user profile
    final userProfile = _authController.profile;
    _selectedState = userProfile['state'] as String?;
    _selectedLga = userProfile['lga'] as String?;

    _workerProfileController.loadSchedule();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _headlineController.dispose();
    _experienceYearsController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'bio': _bioController.text.trim(),
      'headline': _headlineController.text.trim(),
    };

    final years = int.tryParse(_experienceYearsController.text.trim());
    if (years != null) {
      data['experience_years'] = years;
    }

    await _workerProfileController.updateWorkerProfile(data);

    // Save location to profiles table
    if (_selectedState != null && _selectedLga != null) {
      await _profileController.updateProfile({
        'state': _selectedState,
        'lga': _selectedLga,
      });
    }

    // Save bank details if any are filled
    if (_bankNameController.text.trim().isNotEmpty ||
        _accountNumberController.text.trim().isNotEmpty) {
      await _workerProfileController.updateBankDetails({
        'bank_name': _bankNameController.text.trim(),
        'bank_account_number': _accountNumberController.text.trim(),
        'bank_account_name': _accountNameController.text.trim(),
      });
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (_workerProfileController.isLoading.value &&
            _workerProfileController.workerProfile.isEmpty) {
          return AppShimmer.list(count: 5);
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              // -- Profile photo section --
              _buildProfilePhotoSection(),
              const SizedBox(height: AppDimensions.lg),

              // -- Basic Info section --
              _buildSectionHeader('BASIC INFO'),
              const SizedBox(height: AppDimensions.md),
              _buildBasicInfoSection(),
              const SizedBox(height: AppDimensions.lg),

              // -- Service Location section --
              _buildSectionHeader('SERVICE LOCATION'),
              const SizedBox(height: AppDimensions.md),
              _buildLocationSection(),
              const SizedBox(height: AppDimensions.lg),

              // -- Skills section --
              _buildSectionHeader('SKILLS'),
              const SizedBox(height: AppDimensions.md),
              _buildSkillsManagementSection(),
              const SizedBox(height: AppDimensions.lg),

              // -- Availability section --
              _buildSectionHeader('AVAILABILITY'),
              const SizedBox(height: AppDimensions.md),
              _buildAvailabilitySection(),
              const SizedBox(height: AppDimensions.lg),

              // -- Bank Details section --
              _buildSectionHeader('BANK DETAILS'),
              const SizedBox(height: AppDimensions.md),
              _buildBankDetailsSection(),
              const SizedBox(height: AppDimensions.xl),

              // -- Save button --
              _buildSaveButton(),
              const SizedBox(height: AppDimensions.xxl),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTextStyles.sectionHeader);
  }

  Widget _buildProfilePhotoSection() {
    final name = _authController.userName;
    final avatarUrl = _authController.userAvatar;

    return Center(
      child: Stack(
        children: [
          // Large avatar with green accent ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: AppAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: AppDimensions.avatarXl,
            ),
          ),
          // Camera overlay button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // Avatar upload handled via profile controller
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Headline',
            hint: 'e.g., Experienced Plumber with 5+ years',
            controller: _headlineController,
            maxLength: 100,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a headline';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: 'Bio',
            hint: 'Tell clients about yourself and your experience...',
            controller: _bioController,
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: 'Years of Experience',
            hint: 'e.g., 5',
            controller: _experienceYearsController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final years = int.tryParse(value);
                if (years == null || years < 0 || years > 50) {
                  return 'Enter a valid number (0-50)';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set your location so clients in your area can find you.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppDimensions.md),
          // State + LGA dropdowns side-by-side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: 'State',
                  hint: 'Select state',
                  value: _selectedState,
                  items: NigerianLocations.states
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedState = val;
                      _selectedLga = null;
                    });
                  },
                  validator: (val) =>
                      val == null ? 'Please select a state' : null,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: AppDropdown<String>(
                  label: 'LGA',
                  hint: _selectedState == null ? 'State first' : 'Select LGA',
                  value: _selectedLga,
                  items: _selectedState != null
                      ? NigerianLocations.lgasForState(_selectedState!)
                          .map((l) =>
                              DropdownMenuItem(value: l, child: Text(l)))
                          .toList()
                      : [],
                  onChanged: _selectedState == null
                      ? null
                      : (val) => setState(() => _selectedLga = val),
                  validator: (val) =>
                      val == null ? 'Please select an LGA' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsManagementSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final skills = _workerProfileController.workerSkills;

            if (skills.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: Text(
                  'No skills added yet. Tap "+ Add Skill" to get started.',
                  style: AppTextStyles.bodySmall,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.md),
              child: Wrap(
                spacing: AppDimensions.sm,
                runSpacing: AppDimensions.sm,
                children: skills.map((skill) {
                  final skillName =
                      skill['skill']?['name'] ?? skill['name'] ?? 'Skill';
                  return AppChip(
                    label: skillName,
                    isSelected: true,
                    onDelete: () {
                      _showRemoveSkillDialog(skill);
                    },
                  );
                }).toList(),
              ),
            );
          }),

          // "+ Add Skill" button
          GestureDetector(
            onTap: _showAddSkillDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Add Skill',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Skill'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select a category first:',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: AppDimensions.sm),
                Obx(() {
                  final categories =
                      _workerProfileController.categories;
                  if (categories.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.md),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (_, index) {
                        final category = categories[index];
                        return ListTile(
                          title: Text(category['name'] ?? ''),
                          dense: true,
                          onTap: () {
                            Navigator.pop(ctx);
                            _showSkillsForCategory(category);
                          },
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSkillsForCategory(Map<String, dynamic> category) {
    _workerProfileController
        .loadSkillsByCategory(category['id'] as String);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${category['name']} Skills'),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(() {
              final skills = _workerProfileController.skills;
              if (skills.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.md),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return SizedBox(
                height: 250,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: skills.length,
                  itemBuilder: (_, index) {
                    final skill = skills[index];
                    final alreadyAdded = _workerProfileController
                        .workerSkills
                        .any((ws) =>
                            ws['skill_id'] == skill['id'] ||
                            ws['skill']?['id'] == skill['id']);

                    return ListTile(
                      title: Text(skill['name'] ?? ''),
                      trailing: alreadyAdded
                          ? const Icon(Icons.check,
                              color: AppColors.success)
                          : null,
                      dense: true,
                      enabled: !alreadyAdded,
                      onTap: alreadyAdded
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _workerProfileController.addSkill({
                                'skill_id': skill['id'],
                              });
                            },
                    );
                  },
                ),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveSkillDialog(Map<String, dynamic> skill) {
    final skillName = skill['skill']?['name'] ?? skill['name'] ?? 'Skill';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Skill'),
        content: Text('Remove "$skillName" from your skills?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _workerProfileController
                  .removeSkill(skill['id'] as String);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      children: [
        // Available toggle
        Obx(() => AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _workerProfileController.isAvailable.value
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.textHint.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Icon(
                      _workerProfileController.isAvailable.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: _workerProfileController.isAvailable.value
                          ? AppColors.success
                          : AppColors.textHint,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available for Work',
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _workerProfileController.isAvailable.value
                              ? 'You are visible to clients'
                              : 'You are hidden from searches',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _workerProfileController.isAvailable.value,
                    onChanged: (_) =>
                        _workerProfileController.toggleAvailability(),
                    activeColor: AppColors.success,
                  ),
                ],
              ),
            )),
        const SizedBox(height: AppDimensions.sm),

        // Work schedule
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Work Schedule', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.xs),
              Text(
                'Configure your working hours and days of availability.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppDimensions.md),
              _buildScheduleWidget(),
            ],
          ),
        ),
      ],
    );
  }

  // Day indices: 0=Sunday, 1=Monday, ... 6=Saturday (matching DB constraint)
  static const _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  Widget _buildScheduleWidget() {
    return Obx(() {
      final schedule = _workerProfileController.schedule;
      return Column(
        children: List.generate(7, (dayIndex) {
          final daySchedule = schedule.firstWhereOrNull(
              (s) => s['day_of_week'] == dayIndex);
          final isAvailableDay = daySchedule?['is_available'] ?? false;
          final startTime = daySchedule?['start_time'] ?? '09:00:00';
          final endTime = daySchedule?['end_time'] ?? '17:00:00';

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Switch(
                    value: isAvailableDay as bool,
                    onChanged: (val) => _workerProfileController
                        .toggleDayAvailability(dayIndex, val),
                    activeColor: AppColors.success,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    _dayNames[dayIndex].substring(0, 3),
                    style: isAvailableDay
                        ? AppTextStyles.labelMedium
                        : AppTextStyles.bodySmall,
                  ),
                ),
                if (isAvailableDay) ...[
                  GestureDetector(
                    onTap: () => _pickTime(dayIndex, true, startTime),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm),
                      ),
                      child: Text(
                        _formatTimeString(startTime),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('-', style: AppTextStyles.bodySmall),
                  ),
                  GestureDetector(
                    onTap: () => _pickTime(dayIndex, false, endTime),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm),
                      ),
                      child: Text(
                        _formatTimeString(endTime),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ] else
                  Text('Unavailable', style: AppTextStyles.caption),
              ],
            ),
          );
        }),
      );
    });
  }

  String _formatTimeString(String time) {
    // Convert "09:00:00" or "09:00" to "09:00"
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  Future<void> _pickTime(
      int dayIndex, bool isStart, String currentTime) async {
    final parts = currentTime.split(':');
    final hour = int.tryParse(parts[0]) ?? (isStart ? 9 : 17);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked == null) return;

    final schedule = _workerProfileController.schedule;
    final daySchedule = schedule.firstWhereOrNull(
        (s) => s['day_of_week'] == dayIndex);

    final startStr = isStart
        ? '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00'
        : (daySchedule?['start_time'] ?? '09:00:00') as String;
    final endStr = !isStart
        ? '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00'
        : (daySchedule?['end_time'] ?? '17:00:00') as String;

    await _workerProfileController.updateScheduleDay(
      dayOfWeek: dayIndex,
      startTime: startStr,
      endTime: endStr,
      isAvailableDay: true,
    );
  }

  Widget _buildBankDetailsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'For receiving payouts',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: 'Bank Name',
            hint: 'e.g., Access Bank',
            controller: _bankNameController,
          ),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: 'Account Number',
            hint: '10-digit account number',
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  value.length != 10) {
                return 'Account number must be 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: 'Account Holder Name',
            hint: 'Name on account',
            controller: _accountNameController,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: ElevatedButton(
            onPressed:
                _workerProfileController.isSaving.value ? null : _saveProfile,
            child: _workerProfileController.isSaving.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ));
  }
}
