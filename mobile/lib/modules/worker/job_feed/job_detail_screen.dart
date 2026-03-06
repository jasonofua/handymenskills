import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/job_controller.dart';
import '../../../controllers/application_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_bottom_sheet.dart';
import '../../../widgets/common/app_cached_image.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_error_widget.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';
import '../../../widgets/common/app_text_field.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _jobController = Get.find<JobController>();
  final _applicationController = Get.find<ApplicationController>();

  @override
  void initState() {
    super.initState();
    _jobController.loadJobDetail(widget.jobId);
  }

  void _showApplySheet() {
    final coverLetterController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    AppBottomSheet.show(
      context: context,
      title: 'Apply for this Job',
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.screenPadding,
          right: AppDimensions.screenPadding,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              AppDimensions.screenPadding,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppDimensions.md),
                AppTextField(
                  label: 'Cover Letter',
                  hint: 'Tell the client why you\'re the best fit...',
                  controller: coverLetterController,
                  maxLines: 4,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a cover letter';
                    }
                    if (value.trim().length < 20) {
                      return 'Cover letter must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.md),
                AppTextField(
                  label: 'Proposed Price (${AppConstants.currencySymbol})',
                  hint: 'Enter your price',
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your proposed price';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price < AppConstants.minBudget) {
                      return 'Minimum price is ${AppConstants.currencySymbol}${AppConstants.minBudget.toStringAsFixed(0)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.md),
                AppTextField(
                  label: 'Estimated Duration',
                  hint: 'e.g., 2 hours, 1 day',
                  controller: durationController,
                ),
                const SizedBox(height: AppDimensions.lg),
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _applicationController.isSubmitting.value
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                final success =
                                    await _applicationController.applyToJob(
                                  jobId: widget.jobId,
                                  coverLetter:
                                      coverLetterController.text.trim(),
                                  proposedPrice: double.parse(
                                      priceController.text.trim()),
                                  estimatedDuration:
                                      durationController.text.trim().isNotEmpty
                                          ? durationController.text.trim()
                                          : null,
                                );

                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        child: _applicationController.isSubmitting.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Submit Application'),
                      ),
                    )),
                const SizedBox(height: AppDimensions.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: Obx(() {
        if (_jobController.isLoadingDetail.value &&
            _jobController.currentJob.isEmpty) {
          return AppShimmer.list(count: 6);
        }

        final job = _jobController.currentJob;

        if (job.isEmpty) {
          return AppErrorWidget(
            message: 'Job not found',
            onRetry: () => _jobController.loadJobDetail(widget.jobId),
          );
        }

        return _buildJobContent(job);
      }),
      bottomNavigationBar: Obx(() {
        final job = _jobController.currentJob;
        if (job.isEmpty || job['status'] != 'open') return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.only(
            left: AppDimensions.screenPadding,
            right: AppDimensions.screenPadding,
            bottom: MediaQuery.of(context).padding.bottom + AppDimensions.md,
            top: AppDimensions.md,
          ),
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
          child: SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: _showApplySheet,
              child: const Text('Apply Now'),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildJobContent(Map<String, dynamic> job) {
    final title = job['title'] ?? 'Untitled Job';
    final description = job['description'] ?? '';
    final category = job['category']?['name'] ?? '';
    final budgetMin = (job['budget_min'] ?? 0.0).toDouble();
    final budgetMax = (job['budget_max'] ?? 0.0).toDouble();
    final urgency = job['urgency'] ?? 'normal';
    final location = job['location_text'] ?? '';
    final createdAt = DateTime.tryParse(job['created_at'] ?? '');
    final expiresAt = DateTime.tryParse(job['expires_at'] ?? '');
    final images = List<String>.from(job['images'] ?? []);
    final client = job['client'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and urgency
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: AppTextStyles.h3),
              ),
              const SizedBox(width: AppDimensions.sm),
              AppStatusBadge.urgency(urgency),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Category
          if (category.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                category,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),

          // Budget
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.primary),
                const SizedBox(width: AppDimensions.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Budget Range', style: AppTextStyles.caption),
                    Text(
                      '${AppConstants.currencySymbol}${budgetMin.toStringAsFixed(0)} - ${AppConstants.currencySymbol}${budgetMax.toStringAsFixed(0)}',
                      style: AppTextStyles.price,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Images
          if (images.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimensions.sm),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    child: AppCachedImage(
                      imageUrl: images[index],
                      width: 260,
                      height: 200,
                      borderRadius: AppDimensions.radiusMd,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.md),
          ],

          // Description
          const Text('Description', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.sm),
          Text(
            description.isNotEmpty ? description : 'No description provided.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.lg),

          // Details
          const Text('Details', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.sm),
          AppCard(
            child: Column(
              children: [
                if (location.isNotEmpty)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: location,
                  ),
                if (createdAt != null)
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Posted',
                    value: _formatDate(createdAt),
                  ),
                if (expiresAt != null)
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Expires',
                    value: _formatDate(expiresAt),
                    isLast: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Client info
          if (client != null) ...[
            const Text('Posted By', style: AppTextStyles.h4),
            const SizedBox(height: AppDimensions.sm),
            AppCard(
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: client['avatar_url'],
                    name: client['full_name'],
                    size: AppDimensions.avatarLg,
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client['full_name'] ?? 'Client',
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        if (client['created_at'] != null)
                          Text(
                            'Member since ${_formatMemberSince(DateTime.tryParse(client['created_at']))}',
                            style: AppTextStyles.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Extra padding for bottom button
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatMemberSince(DateTime? date) {
    if (date == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppDimensions.sm),
              Text(label, style: AppTextStyles.bodySmall),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.labelMedium,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
