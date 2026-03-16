import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/dispute_controller.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../widgets/common/app_button.dart';
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

  String? _selectedCategory;
  final List<String> _photoUrls = [];

  final _disputeCategories = [
    'Service not completed',
    'Poor quality of work',
    'Worker did not show up',
    'Overcharged for service',
    'Damage to property',
    'Unprofessional behavior',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;

    final reason = _selectedCategory != null
        ? '$_selectedCategory: ${_reasonController.text.trim()}'
        : _reasonController.text.trim();

    final success = await _disputeController.createDispute(
      bookingId: widget.bookingId,
      reason: reason,
      evidence: _photoUrls,
    );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Dispute Form', style: AppTextStyles.h4),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading
              Text(
                'Help us resolve this',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'Please provide details about the issue you experienced. Our team will review your dispute and work towards a fair resolution.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              // Reason dropdown
              _buildReasonDropdown(),
              const SizedBox(height: AppDimensions.lg),

              // Detailed description
              _buildDescriptionSection(),
              const SizedBox(height: AppDimensions.lg),

              // Supporting photos
              _buildPhotosSection(),
              const SizedBox(height: AppDimensions.lg),

              // Info box
              _buildInfoBox(),
              const SizedBox(height: AppDimensions.xl),

              // Submit button
              _buildSubmitButton(),
              const SizedBox(height: AppDimensions.md),

              // Support link
              _buildSupportLink(),

              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REASON FOR DISPUTE',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppDimensions.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            hint: Text(
              'Select a reason',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.md,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            items: _disputeCategories
                .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: AppTextStyles.bodyMedium),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETAILED DESCRIPTION',
          style: AppTextStyles.sectionHeader,
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

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUPPORTING PHOTOS',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Add photos as evidence (optional)',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppDimensions.md),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: [
            // Existing photos
            ..._photoUrls.asMap().entries.map((entry) {
              return _PhotoTile(
                imageUrl: entry.value,
                onRemove: () {
                  setState(() {
                    _photoUrls.removeAt(entry.key);
                  });
                },
              );
            }),
            // Add photo button
            if (_photoUrls.length < 5)
              GestureDetector(
                onTap: () async {
                  final source = await showModalBottomSheet<ImageSource>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Camera'),
                            onTap: () => Navigator.pop(ctx, ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Gallery'),
                            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (source == null) return;
                  final image = await ImagePicker().pickImage(source: source, imageQuality: 70);
                  if (image != null) {
                    try {
                      final storageRepo = Get.find<StorageRepository>();
                      final timestamp = DateTime.now().millisecondsSinceEpoch;
                      final path = 'disputes/${widget.bookingId}/$timestamp.jpg';
                      final publicUrl = await storageRepo.uploadFile('dispute-evidence', path, File(image.path));
                      setState(() {
                        _photoUrls.add(publicUrl);
                      });
                    } catch (e) {
                      AppSnackbar.error('Failed to upload photo');
                    }
                  }
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary.withValues(alpha: 0.6),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.info,
              size: 18,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How disputes work',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Once submitted, our team will review the dispute within 24-48 hours. Both parties will be notified and may be asked to provide additional information.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildSupportLink() {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final mailtoUrl = Uri.parse(
            'mailto:support@handymenskills.com?subject=Urgent%20Dispute%20Help&body=Booking%20ID:%20${widget.bookingId}',
          );
          try {
            await launchUrl(mailtoUrl);
          } catch (_) {
            AppSnackbar.info('Could not open email app');
          }
        },
        icon: const Icon(
          Icons.headset_mic_outlined,
          size: 18,
          color: AppColors.primary,
        ),
        label: Text(
          'Need urgent help? Contact Support',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.imageUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Image.network(
            imageUrl,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
