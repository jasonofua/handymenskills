import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/job_controller.dart';
import '../../../controllers/worker_profile_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../data/constants/nigerian_locations.dart';
import '../../../data/repositories/skill_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/app_dropdown.dart';
import '../../../widgets/common/app_chip.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_snackbar.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _jobController = Get.find<JobController>();
  final _workerProfileController = Get.find<WorkerProfileController>();
  final _authController = Get.find<AuthController>();

  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 4;

  // Step 1: Basic Info
  final _step1Key = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  final List<String> _selectedSkillIds = [];
  final List<String> _selectedSkillNames = [];

  // Step 2: Budget
  final _step2Key = GlobalKey<FormState>();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  String _budgetType = 'fixed';
  String _urgency = 'medium';

  // Step 3: Location & Date
  final _step3Key = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedJobState;
  String? _selectedJobLga;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRemote = false;

  // Step 4: Images
  final List<File> _localImageFiles = [];
  bool _isSubmitting = false;

  // Categories — loaded locally from SkillRepository to avoid Obx issues
  List<Map<String, dynamic>> _categories = [];
  bool _isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final skillRepo = Get.find<SkillRepository>();
      final cats = await skillRepo.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCategoriesLoading = false);
        AppSnackbar.error('Failed to load categories');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;

    // Validate current step before going forward
    if (step > _currentStep) {
      if (!_validateCurrentStep()) return;
    }

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (!(_step1Key.currentState?.validate() ?? false)) return false;
        if (_selectedCategoryId == null) {
          AppSnackbar.warning('Please select a category');
          return false;
        }
        return true;
      case 1:
        return _step2Key.currentState?.validate() ?? false;
      case 2:
        if (!_isRemote) {
          if (!(_step3Key.currentState?.validate() ?? false)) return false;
          if (_selectedJobState == null) {
            AppSnackbar.warning('Please select a state');
            return false;
          }
        }
        return true;
      case 3:
        return true;
      default:
        return true;
    }
  }

  Future<void> _submitJob() async {
    if (_isSubmitting) return;
    if (!_validateCurrentStep()) return;
    setState(() => _isSubmitting = true);

    try {
    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category_id': _selectedCategoryId,
      'skill_ids': _selectedSkillIds,
      'budget_min': double.tryParse(_budgetMinController.text) ?? AppConstants.minBudget,
      'budget_max': double.tryParse(_budgetMaxController.text) ?? AppConstants.minBudget,
      'budget_type': _budgetType,
      'urgency': _urgency,
      'is_remote': _isRemote,
      'status': 'open',
    };

    if (!_isRemote) {
      data['address'] = _addressController.text.trim();
      data['city'] = _cityController.text.trim();
      data['state'] = _selectedJobState;
    }

    if (_startDate != null) {
      data['start_date'] = _startDate!.toIso8601String();
    }
    if (_endDate != null) {
      data['end_date'] = _endDate!.toIso8601String();
    }
    if (_localImageFiles.isNotEmpty) {
      final uploadedUrls = await _uploadImages();
      if (uploadedUrls.isNotEmpty) {
        data['image_urls'] = uploadedUrls;
      }
    }

    final result = await _jobController.createJob(data);
    if (result != null && mounted) {
      final jobId = result['id']?.toString();
      final jobTitle = _titleController.text.trim();
      final uri = Uri(
        path: AppRoutes.clientJobPostedSuccess,
        queryParameters: {
          if (jobId != null) 'jobId': jobId,
          if (jobTitle.isNotEmpty) 'jobTitle': jobTitle,
        },
      );
      context.go(uri.toString());
    }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [
                _buildStep1BasicInfo(),
                _buildStep2Budget(),
                _buildStep3Location(),
                _buildStep4Review(),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final labels = ['Details', 'Budget', 'Location', 'Review'];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppDimensions.md,
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 16, color: AppColors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.white : AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.primary : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                if (index < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppColors.primary : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Job Details', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            const Text(
              'Describe the work you need done.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.lg),
            AppTextField(
              label: 'Job Title',
              hint: 'e.g. Fix leaking kitchen pipe',
              controller: _titleController,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 10) return 'Title must be at least 10 characters';
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.md),
            AppTextField(
              label: 'Description',
              hint: 'Describe the job in detail...',
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 2000,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Description is required';
                if (v.trim().length < 50) return 'Description must be at least 50 characters';
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.md),
            AppDropdown<String>(
              label: 'Category',
              hint: _isCategoriesLoading ? 'Loading categories...' : 'Select a category',
              value: _selectedCategoryId,
              items: _categories.map((c) => DropdownMenuItem(
                value: c['id']?.toString(),
                child: Text(c['name']?.toString() ?? ''),
              )).toList(),
              onChanged: _isCategoriesLoading
                  ? null
                  : (value) {
                      setState(() => _selectedCategoryId = value);
                      if (value != null) {
                        _workerProfileController.loadSkillsByCategory(value);
                        _selectedSkillIds.clear();
                        _selectedSkillNames.clear();
                      }
                    },
              validator: (v) => v == null ? 'Category is required' : null,
            ),
            const SizedBox(height: AppDimensions.md),
            const Text(
              'Required Skills (optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final skills = _workerProfileController.skills;
              final isLoadingSkills = _workerProfileController.isSkillsLoading.value;
              // Access .length to register the observable with GetX before any early return
              final _ = skills.length;
              if (_selectedCategoryId == null) {
                return Text(
                  'Select a category first',
                  style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                );
              }
              if (isLoadingSkills) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (skills.isEmpty) {
                return Text(
                  'No skills available for this category',
                  style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) {
                  final id = skill['id']?.toString() ?? '';
                  final name = skill['name']?.toString() ?? '';
                  final isSelected = _selectedSkillIds.contains(id);
                  return AppChip(
                    label: name,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSkillIds.remove(id);
                          _selectedSkillNames.remove(name);
                        } else {
                          _selectedSkillIds.add(id);
                          _selectedSkillNames.add(name);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Budget() {
    final budgetTypes = ['fixed', 'hourly', 'negotiable'];
    final urgencyLevels = ['low', 'medium', 'high', 'emergency'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Budget & Urgency', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            const Text(
              'Set your budget range and urgency level.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.lg),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Min Budget (${AppConstants.currencySymbol})',
                    hint: '${AppConstants.minBudget.toInt()}',
                    controller: _budgetMinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final amount = double.tryParse(v);
                      if (amount == null || amount < AppConstants.minBudget) {
                        return 'Min ${AppConstants.currencySymbol}${AppConstants.minBudget.toInt()}';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: AppTextField(
                    label: 'Max Budget (${AppConstants.currencySymbol})',
                    hint: 'Maximum amount',
                    controller: _budgetMaxController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final max = double.tryParse(v);
                      final min = double.tryParse(_budgetMinController.text) ?? 0;
                      if (max == null || max < min) {
                        return 'Must be >= min';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),
            const Text(
              'Budget Type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: budgetTypes.map((type) {
                final label = type[0].toUpperCase() + type.substring(1);
                return AppChip(
                  label: label,
                  isSelected: _budgetType == type,
                  onTap: () => setState(() => _budgetType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.lg),
            const Text(
              'Urgency Level',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: urgencyLevels.map((level) {
                final label = level[0].toUpperCase() + level.substring(1);
                final colors = {
                  'low': AppColors.urgencyLow,
                  'medium': AppColors.urgencyNormal,
                  'high': AppColors.urgencyUrgent,
                  'emergency': AppColors.urgencyEmergency,
                };
                final isSelected = _urgency == level;
                return GestureDetector(
                  onTap: () => setState(() => _urgency = level),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (colors[level] ?? AppColors.info).withValues(alpha: 0.15)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(
                        color: isSelected
                            ? colors[level] ?? AppColors.info
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? colors[level] ?? AppColors.info
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.md),
            _buildUrgencyDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyDescription() {
    final descriptions = {
      'low': 'Can be done within the next few weeks.',
      'medium': 'Should be done within a week.',
      'high': 'Needed within 24-48 hours.',
      'emergency': 'Needed immediately! Higher costs may apply.',
    };
    return AppCard(
      color: _urgency == 'emergency'
          ? AppColors.error.withValues(alpha: 0.05)
          : AppColors.info.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Row(
        children: [
          Icon(
            _urgency == 'emergency' ? Icons.warning_amber : Icons.info_outline,
            color: _urgency == 'emergency' ? AppColors.error : AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              descriptions[_urgency] ?? '',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location & Schedule', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            const Text(
              'Where and when do you need this done?',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'This is a remote job',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Worker does not need to be physically present',
                style: AppTextStyles.caption,
              ),
              value: _isRemote,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _isRemote = v),
            ),
            const SizedBox(height: AppDimensions.md),
            if (!_isRemote) ...[
              AppTextField(
                label: 'Address',
                hint: 'Street address',
                controller: _addressController,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (!_isRemote && (v == null || v.trim().isEmpty)) {
                    return 'Address is required for on-site jobs';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                label: 'City',
                hint: 'Enter city',
                controller: _cityController,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (!_isRemote && (v == null || v.trim().isEmpty)) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.md),
              AppDropdown<String>(
                label: 'State',
                hint: 'Select state',
                value: _selectedJobState,
                items: NigerianLocations.states
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedJobState = val;
                    _selectedJobLga = null;
                  });
                },
                validator: (v) {
                  if (!_isRemote && v == null) return 'State is required';
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.md),
              AppDropdown<String>(
                label: 'LGA',
                hint: _selectedJobState == null ? 'Select a state first' : 'Select LGA',
                value: _selectedJobLga,
                items: _selectedJobState != null
                    ? NigerianLocations.lgasForState(_selectedJobState!)
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList()
                    : [],
                onChanged: _selectedJobState == null
                    ? null
                    : (val) => setState(() => _selectedJobLga = val),
              ),
              const SizedBox(height: AppDimensions.lg),
            ],
            const Text(
              'Schedule (optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Start Date',
                    date: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onPicked: (d) => setState(() => _startDate = d),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: _DatePickerField(
                    label: 'End Date',
                    date: _endDate,
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onPicked: (d) => setState(() => _endDate = d),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Review() {
    final category = _categories
        .cast<Map<String, dynamic>?>()
        .firstWhere((c) => c?['id']?.toString() == _selectedCategoryId, orElse: () => null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review & Submit', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          const Text(
            'Review your job details before posting.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppDimensions.lg),
          _ReviewSection(
            title: 'Job Details',
            items: [
              _ReviewItem('Title', _titleController.text),
              _ReviewItem('Description', _descriptionController.text),
              _ReviewItem('Category', category?['name']?.toString() ?? 'N/A'),
              if (_selectedSkillNames.isNotEmpty)
                _ReviewItem('Skills', _selectedSkillNames.join(', ')),
            ],
            onEdit: () => _goToStep(0),
          ),
          const SizedBox(height: AppDimensions.md),
          _ReviewSection(
            title: 'Budget & Urgency',
            items: [
              _ReviewItem(
                'Budget Range',
                '${AppConstants.currencySymbol}${_budgetMinController.text} - ${AppConstants.currencySymbol}${_budgetMaxController.text}',
              ),
              _ReviewItem(
                'Budget Type',
                _budgetType[0].toUpperCase() + _budgetType.substring(1),
              ),
              _ReviewItem(
                'Urgency',
                _urgency[0].toUpperCase() + _urgency.substring(1),
              ),
            ],
            onEdit: () => _goToStep(1),
          ),
          const SizedBox(height: AppDimensions.md),
          _ReviewSection(
            title: 'Location & Schedule',
            items: [
              _ReviewItem('Type', _isRemote ? 'Remote' : 'On-site'),
              if (!_isRemote) ...[
                _ReviewItem('Address', _addressController.text),
                _ReviewItem('City', _cityController.text),
                _ReviewItem('State', _selectedJobState ?? 'N/A'),
                if (_selectedJobLga != null)
                  _ReviewItem('LGA', _selectedJobLga!),
              ],
              if (_startDate != null)
                _ReviewItem('Start', _formatDate(_startDate!)),
              if (_endDate != null)
                _ReviewItem('End', _formatDate(_endDate!)),
            ],
            onEdit: () => _goToStep(2),
          ),
          const SizedBox(height: AppDimensions.lg),
          // Images section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JOB IMAGES', style: AppTextStyles.sectionHeader),
              const SizedBox(height: AppDimensions.sm),
              Wrap(
                spacing: AppDimensions.sm,
                runSpacing: AppDimensions.sm,
                children: [
                  ..._localImageFiles.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          child: Image.file(
                            entry.value,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _localImageFiles.removeAt(entry.key)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_localImageFiles.length < 5)
                    GestureDetector(
                      onTap: () => _pickJobImages(),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary.withValues(alpha: 0.6), size: 28),
                            const SizedBox(height: 4),
                            Text('Add', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickJobImages() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (images.isEmpty) return;
    final remaining = 5 - _localImageFiles.length;
    final toAdd = images.take(remaining).toList();
    setState(() {
      for (final image in toAdd) {
        _localImageFiles.add(File(image.path));
      }
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_localImageFiles.isEmpty) return [];
    final urls = <String>[];
    try {
      final storageRepo = Get.find<StorageRepository>();
      for (final file in _localImageFiles) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${_authController.userId}/$timestamp.jpg';
        final publicUrl = await storageRepo.uploadFile('job-images', path, file);
        urls.add(publicUrl);
      }
    } catch (e) {
      AppSnackbar.error('Failed to upload some images');
    }
    return urls;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomButtons() {
    return Container(
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
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goToStep(_currentStep - 1),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_currentStep < _totalSteps - 1) {
                          _goToStep(_currentStep + 1);
                        } else {
                          _submitJob();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : Text(
                        _currentStep < _totalSteps - 1 ? 'Next' : 'Post Job',
                        style: AppTextStyles.button,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.label,
    this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? firstDate,
              firstDate: firstDate,
              lastDate: lastDate,
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    primary: AppColors.primary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? '${date!.day}/${date!.month}/${date!.year}'
                        : 'Select date',
                    style: date != null
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final List<_ReviewItem> items;
  final VoidCallback onEdit;

  const _ReviewSection({
    required this.title,
    required this.items,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              GestureDetector(
                onTap: onEdit,
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    item.label,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ReviewItem {
  final String label;
  final String value;
  const _ReviewItem(this.label, this.value);
}
