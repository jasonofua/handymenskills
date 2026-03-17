import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/job_controller.dart';
import '../../../controllers/application_controller.dart';
import '../../../controllers/chat_controller.dart';
import '../../../data/repositories/skill_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_bottom_sheet.dart';
import '../../../widgets/common/app_cached_image.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_chip.dart';
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
  final _skillNames = <String>[].obs;
  final _hasApplied = false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _jobController.loadJobDetail(widget.jobId);
      _resolveSkillNames();
      _checkIfApplied();
    });
  }

  Future<void> _checkIfApplied() async {
    // Check from cached map first (instant)
    if (_jobController.appliedJobIds[widget.jobId] == true) {
      _hasApplied.value = true;
      return;
    }
    // Fallback: async check from DB
    final applied = await _applicationController.hasAppliedToJob(widget.jobId);
    _hasApplied.value = applied;
  }

  Future<void> _resolveSkillNames() async {
    final job = _jobController.currentJob;
    final skillIds = List<String>.from(job['skill_ids'] ?? []);
    if (skillIds.isEmpty) return;
    try {
      final names = await Get.find<SkillRepository>().getSkillNamesByIds(skillIds);
      _skillNames.assignAll(names);
    } catch (_) {}
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
                  label: 'Message to Client',
                  hint: 'Briefly describe your experience and why you\'re a good fit for this job...',
                  controller: coverLetterController,
                  maxLines: 4,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please write a short message';
                    }
                    if (value.trim().length < 20) {
                      return 'Message must be at least 20 characters';
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
                                  _hasApplied.value = true;
                                  _jobController.markJobAsApplied(widget.jobId);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: const Text('Job Detail'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              final job = _jobController.currentJob;
              final title = job['title'] ?? 'Check out this job';
              Clipboard.setData(
                ClipboardData(
                    text: 'Check out this job: $title on HandySkills'),
              );
              Get.snackbar('Copied', 'Job link copied to clipboard',
                  snackPosition: SnackPosition.BOTTOM);
            },
            icon: const Icon(Icons.share_outlined, size: 22),
          ),
        ],
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
        if (job.isEmpty || job['status'] != 'open') {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.only(
            left: AppDimensions.screenPadding,
            right: AppDimensions.screenPadding,
            bottom: MediaQuery.of(context).padding.bottom + AppDimensions.sm,
            top: AppDimensions.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Chat icon button
              Container(
                height: AppDimensions.buttonHeight,
                width: AppDimensions.buttonHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.buttonRadius),
                ),
                child: IconButton(
                  onPressed: () async {
                    final clientId = job['client_id'] as String?;
                    if (clientId == null) return;
                    final chatController = Get.find<ChatController>();
                    final conversationId = await chatController
                        .startConversation(clientId, jobId: widget.jobId);
                    if (conversationId != null && context.mounted) {
                      context.push(AppRoutes.chatConversation
                          .replaceFirst(':id', conversationId));
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              // Apply Now / Applied button
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeight,
                  child: Obx(() => ElevatedButton(
                    onPressed: _hasApplied.value ? null : _showApplySheet,
                    style: _hasApplied.value
                        ? ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success.withValues(alpha: 0.15),
                            disabledBackgroundColor: AppColors.success.withValues(alpha: 0.15),
                            disabledForegroundColor: AppColors.success,
                          )
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_hasApplied.value) ...[
                          const Icon(Icons.check_circle, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(_hasApplied.value ? 'Applied' : 'Apply Now'),
                      ],
                    ),
                  )),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildJobContent(Map<String, dynamic> job) {
    final title = job['title'] ?? 'Untitled Job';
    final description = job['description'] ?? '';
    final categoryData = job['categories'] as Map<String, dynamic>?;
    final category = categoryData?['name'] ?? '';
    final budgetMin = (job['budget_min'] ?? 0.0).toDouble();
    final budgetMax = (job['budget_max'] ?? 0.0).toDouble();
    final urgency = job['urgency'] ?? 'normal';
    final address = job['address'] ?? '';
    final city = job['city'] ?? '';
    final state = job['state'] ?? '';
    final location = [address, city, state]
        .where((s) => s.isNotEmpty)
        .join(', ');
    final createdAt = DateTime.tryParse(job['created_at'] ?? '');
    final rawImageUrls = job['image_urls'];
    final images = rawImageUrls is List
        ? List<String>.from(rawImageUrls)
        : <String>[];
    final client = job['profiles'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Client info section --
          if (client != null) ...[
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
                        if (client['is_verified'] == true)
                          Row(
                            children: [
                              Icon(Icons.verified,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'VERIFIED CLIENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        if (client['created_at'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Member since ${_formatMemberSince(DateTime.tryParse(client['created_at']))}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
          ],

          // -- Urgency + Category badges row --
          Row(
            children: [
              AppStatusBadge.urgency(urgency),
              if (category.isNotEmpty) ...[
                const SizedBox(width: AppDimensions.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    category,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // -- Job title (large) --
          Text(title, style: AppTextStyles.h2),
          const SizedBox(height: AppDimensions.md),

          // -- Budget + Location info cards side-by-side --
          Row(
            children: [
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(AppDimensions.sm + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Text('Budget', style: AppTextStyles.caption),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Text(
                        '${AppConstants.currencySymbol}${budgetMin.toStringAsFixed(0)} - ${AppConstants.currencySymbol}${budgetMax.toStringAsFixed(0)}',
                        style: AppTextStyles.priceSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(AppDimensions.sm + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.info,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Text('Location', style: AppTextStyles.caption),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Text(
                        location.isNotEmpty ? location : 'Not specified',
                        style: AppTextStyles.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // -- Posted time + location text --
          if (createdAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.md),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Posted ${_timeAgo(createdAt)}',
                    style: AppTextStyles.caption,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(width: AppDimensions.md),
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        location,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // -- Images --
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
            const SizedBox(height: AppDimensions.lg),
          ],

          // -- Job Description section --
          Text(
            'JOB DESCRIPTION',
            style: AppTextStyles.sectionHeader,
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            description.isNotEmpty ? description : 'No description provided.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // -- Required Skills section --
          Obx(() {
            final skills = _skillNames;
            if (skills.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REQUIRED SKILLS',
                  style: AppTextStyles.sectionHeader,
                ),
                const SizedBox(height: AppDimensions.sm),
                Wrap(
                  spacing: AppDimensions.sm,
                  runSpacing: AppDimensions.sm,
                  children: skills
                      .map((skill) => AppChip(
                            label: skill,
                            isSelected: true,
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppDimensions.lg),
              ],
            );
          }),

          // Extra padding for bottom button
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return _formatDate(dateTime);
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
