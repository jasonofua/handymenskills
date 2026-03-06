import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';

class ReportScreen extends StatefulWidget {
  final String userId;

  const ReportScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _reportRepo = Get.find<ReportRepository>();
  final _authController = Get.find<AuthController>();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      AppSnackbar.warning('Please select a reason for your report');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _reportRepo.createReport({
        'reporter_id': _authController.userId,
        'reported_id': widget.userId,
        'reason': _selectedReason!.toJsonValue(),
        'description': _descriptionController.text.trim(),
      });

      AppSnackbar.success('Report submitted successfully');

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      AppSnackbar.error('Failed to submit report. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReasonSection(),
              const SizedBox(height: AppDimensions.lg),
              _buildDescriptionSection(),
              const SizedBox(height: AppDimensions.xl),
              _buildSubmitButton(),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is the issue?',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Select the reason that best describes the problem',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppDimensions.md),
          ...ReportReason.values.map((reason) {
            final isSelected = _selectedReason == reason;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RadioListTile<ReportReason>(
                title: Text(
                  _reasonLabel(reason),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  _reasonDescription(reason),
                  style: AppTextStyles.caption,
                ),
                value: reason,
                groupValue: _selectedReason,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Provide more context to help us investigate',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppDimensions.md),
        AppTextField(
          controller: _descriptionController,
          hint: 'Describe what happened...',
          maxLines: 5,
          maxLength: 500,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
            }
            if (value.trim().length < 10) {
              return 'Please provide at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AppButton(
      label: 'Submit Report',
      onPressed: _submitReport,
      isLoading: _isSubmitting,
      icon: Icons.flag_outlined,
    );
  }

  String _reasonLabel(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.fraud:
        return 'Fraud';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.fakeProfile:
        return 'Fake Profile';
      case ReportReason.poorService:
        return 'Poor Service';
      case ReportReason.noShow:
        return 'No Show';
      case ReportReason.other:
        return 'Other';
    }
  }

  String _reasonDescription(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Unwanted or repetitive messages/content';
      case ReportReason.harassment:
        return 'Abusive, threatening, or intimidating behavior';
      case ReportReason.fraud:
        return 'Scam, dishonest dealings, or financial deception';
      case ReportReason.inappropriateContent:
        return 'Offensive, vulgar, or inappropriate material';
      case ReportReason.fakeProfile:
        return 'False identity or misleading information';
      case ReportReason.poorService:
        return 'Substandard work quality or unprofessional conduct';
      case ReportReason.noShow:
        return 'Failed to show up for a scheduled job';
      case ReportReason.other:
        return 'Something else not listed above';
    }
  }
}
