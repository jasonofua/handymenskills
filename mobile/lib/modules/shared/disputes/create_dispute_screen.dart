import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/dispute_controller.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';

class CreateDisputeScreen extends StatefulWidget {
  final String bookingId;

  const CreateDisputeScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<CreateDisputeScreen> createState() => _CreateDisputeScreenState();
}

class _CreateDisputeScreenState extends State<CreateDisputeScreen> {
  final _disputeController = Get.find<DisputeController>();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _disputeController.createDispute(
      bookingId: widget.bookingId,
      reason: _reasonController.text.trim(),
    );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Dispute'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: AppDimensions.lg),
              _buildReasonSection(),
              const SizedBox(height: AppDimensions.xl),
              _buildSubmitButton(),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 24),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you proceed',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Disputes are reviewed by our team. Please provide a clear and detailed description of the issue.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Describe the Issue',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Explain what went wrong with this booking',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppDimensions.md),
        AppTextField(
          controller: _reasonController,
          hint:
              'Describe the problem in detail. Include what was agreed upon and what actually happened...',
          maxLines: 6,
          maxLength: 1000,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please describe the issue';
            }
            if (value.trim().length < 20) {
              return 'Please provide at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => AppButton(
          label: 'Submit Dispute',
          onPressed: _submitDispute,
          isLoading: _disputeController.isSubmitting.value,
          icon: Icons.gavel_outlined,
        ));
  }
}
