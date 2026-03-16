import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/job_controller.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../data/constants/nigerian_locations.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/app_dropdown.dart';
import '../../../widgets/common/app_chip.dart';
import '../../../widgets/common/app_snackbar.dart';

class EditJobScreen extends StatefulWidget {
  final String jobId;

  const EditJobScreen({super.key, required this.jobId});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _jobController = Get.find<JobController>();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _budgetType = 'fixed';
  String _urgency = 'medium';
  String? _selectedState;
  String? _selectedLga;
  bool _isRemote = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFields();
    });
  }

  void _populateFields() {
    final job = _jobController.currentJob;
    if (job.isEmpty) return;

    _titleController.text = job['title']?.toString() ?? '';
    _descriptionController.text = job['description']?.toString() ?? '';

    final budgetMin = job['budget_min'];
    if (budgetMin != null) {
      _budgetMinController.text = _formatBudgetValue(budgetMin);
    }

    final budgetMax = job['budget_max'];
    if (budgetMax != null) {
      _budgetMaxController.text = _formatBudgetValue(budgetMax);
    }

    _addressController.text = job['address']?.toString() ?? '';
    _cityController.text = job['city']?.toString() ?? '';

    setState(() {
      _budgetType = job['budget_type']?.toString() ?? 'fixed';
      _urgency = job['urgency']?.toString() ?? 'medium';
      _isRemote = job['is_remote'] == true;
      _selectedState = job['state']?.toString();
      if (_selectedState != null &&
          NigerianLocations.states.contains(_selectedState)) {
        final lga = job['lga']?.toString();
        if (lga != null &&
            NigerianLocations.lgasForState(_selectedState!).contains(lga)) {
          _selectedLga = lga;
        }
      } else {
        _selectedState = null;
      }
    });
  }

  String _formatBudgetValue(dynamic value) {
    if (value is int) return value.toString();
    if (value is double) return value.toInt().toString();
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed.toInt().toString();
    return '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isRemote && _selectedState == null) {
      AppSnackbar.warning('Please select a state');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'budget_min':
            double.tryParse(_budgetMinController.text) ?? AppConstants.minBudget,
        'budget_max':
            double.tryParse(_budgetMaxController.text) ?? AppConstants.minBudget,
        'budget_type': _budgetType,
        'urgency': _urgency,
        'is_remote': _isRemote,
      };

      if (!_isRemote) {
        data['address'] = _addressController.text.trim();
        data['city'] = _cityController.text.trim();
        data['state'] = _selectedState;
        if (_selectedLga != null) {
          data['lga'] = _selectedLga;
        }
      }

      await _jobController.updateJob(widget.jobId, data);

      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Job'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Job Details ---
                    const Text('Job Details', style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    const Text(
                      'Update the basic information about your job.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    AppTextField(
                      label: 'Job Title',
                      hint: 'e.g. Fix leaking kitchen pipe',
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Title is required';
                        }
                        if (v.trim().length < 10) {
                          return 'Title must be at least 10 characters';
                        }
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
                        if (v == null || v.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (v.trim().length < 50) {
                          return 'Description must be at least 50 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.xl),

                    // --- Budget & Urgency ---
                    const Text('Budget & Urgency', style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    const Text(
                      'Adjust your budget range and urgency level.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label:
                                'Min Budget (${AppConstants.currencySymbol})',
                            hint: '${AppConstants.minBudget.toInt()}',
                            controller: _budgetMinController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final amount = double.tryParse(v);
                              if (amount == null ||
                                  amount < AppConstants.minBudget) {
                                return 'Min ${AppConstants.currencySymbol}${AppConstants.minBudget.toInt()}';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: AppTextField(
                            label:
                                'Max Budget (${AppConstants.currencySymbol})',
                            hint: 'Maximum amount',
                            controller: _budgetMaxController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final max = double.tryParse(v);
                              final min =
                                  double.tryParse(_budgetMinController.text) ??
                                      0;
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
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildBudgetTypeChips(),
                    const SizedBox(height: AppDimensions.lg),
                    const Text(
                      'Urgency Level',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildUrgencyChips(),

                    const SizedBox(height: AppDimensions.xl),

                    // --- Location ---
                    const Text('Location', style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    const Text(
                      'Where should the work be done?',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'This is a remote job',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
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
                          if (!_isRemote &&
                              (v == null || v.trim().isEmpty)) {
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
                          if (!_isRemote &&
                              (v == null || v.trim().isEmpty)) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.md),
                      AppDropdown<String>(
                        label: 'State',
                        hint: 'Select state',
                        value: _selectedState,
                        items: NigerianLocations.states
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedState = val;
                            _selectedLga = null;
                          });
                        },
                        validator: (v) {
                          if (!_isRemote && v == null) {
                            return 'State is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.md),
                      AppDropdown<String>(
                        label: 'LGA',
                        hint: _selectedState == null
                            ? 'Select a state first'
                            : 'Select LGA',
                        value: _selectedLga,
                        items: _selectedState != null
                            ? NigerianLocations.lgasForState(_selectedState!)
                                .map((l) => DropdownMenuItem(
                                    value: l, child: Text(l)))
                                .toList()
                            : [],
                        onChanged: _selectedState == null
                            ? null
                            : (val) =>
                                setState(() => _selectedLga = val),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBudgetTypeChips() {
    const budgetTypes = ['fixed', 'hourly', 'negotiable'];
    return Wrap(
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
    );
  }

  Widget _buildUrgencyChips() {
    const urgencyLevels = ['low', 'medium', 'high', 'emergency'];
    final colors = {
      'low': AppColors.urgencyLow,
      'medium': AppColors.urgencyNormal,
      'high': AppColors.urgencyUrgent,
      'emergency': AppColors.urgencyEmergency,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urgencyLevels.map((level) {
        final label = level[0].toUpperCase() + level.substring(1);
        final isSelected = _urgency == level;
        return GestureDetector(
          onTap: () => setState(() => _urgency = level),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (colors[level] ?? AppColors.info)
                      .withValues(alpha: 0.15)
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
    );
  }

  Widget _buildBottomBar() {
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
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
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
    );
  }
}
