import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/worker_profile_controller.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_chip.dart';
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
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bioController;
  late final TextEditingController _headlineController;
  late final TextEditingController _experienceYearsController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountNameController;

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
        TextEditingController(text: profile['account_number'] ?? '');
    _accountNameController =
        TextEditingController(text: profile['account_name'] ?? '');
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

    // Save bank details if any are filled
    if (_bankNameController.text.trim().isNotEmpty ||
        _accountNumberController.text.trim().isNotEmpty) {
      await _workerProfileController.updateBankDetails({
        'bank_name': _bankNameController.text.trim(),
        'account_number': _accountNumberController.text.trim(),
        'account_name': _accountNameController.text.trim(),
      });
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
              _buildBasicInfoSection(),
              const SizedBox(height: AppDimensions.lg),
              _buildSkillsManagementSection(),
              const SizedBox(height: AppDimensions.lg),
              _buildAvailabilitySection(),
              const SizedBox(height: AppDimensions.lg),
              _buildBankDetailsSection(),
              const SizedBox(height: AppDimensions.xl),
              _buildSaveButton(),
              const SizedBox(height: AppDimensions.xxl),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.md),
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
    );
  }

  Widget _buildSkillsManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Skills', style: AppTextStyles.h4),
            TextButton.icon(
              onPressed: _showAddSkillDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          final skills = _workerProfileController.workerSkills;

          if (skills.isEmpty) {
            return AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: Text(
                  'No skills added yet. Tap "Add" to add your skills.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            );
          }

          return Wrap(
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
          );
        }),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Availability', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.sm),
        Obx(() => AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available for Work',
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 4),
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
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Work Schedule',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'Configure your working hours and days of availability. Clients will see when you are typically available.',
                style: AppTextStyles.bodySmall,
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
                    style: (isAvailableDay as bool)
                        ? AppTextStyles.labelMedium
                        : AppTextStyles.bodySmall,
                  ),
                ),
                if (isAvailableDay) ...[
                  GestureDetector(
                    onTap: () => _pickTime(dayIndex, true, startTime as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm),
                      ),
                      child: Text(
                        _formatTimeString(startTime as String),
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
                    onTap: () => _pickTime(dayIndex, false, endTime as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm),
                      ),
                      child: Text(
                        _formatTimeString(endTime as String),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bank Details', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For receiving payouts',
                style: AppTextStyles.bodySmall,
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
                label: 'Account Name',
                hint: 'Name on account',
                controller: _accountNameController,
              ),
            ],
          ),
        ),
      ],
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
