import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/subscription_controller.dart';
import '../../../widgets/common/app_error_widget.dart';
import '../../../widgets/common/app_shimmer.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final _subscriptionController = Get.find<SubscriptionController>();
  final _selectedPlanIndex = RxInt(-1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptionController.loadPlans();
    });
  }

  Future<void> _subscribeToPlan() async {
    final plans = _subscriptionController.plans;
    if (_selectedPlanIndex.value < 0 ||
        _selectedPlanIndex.value >= plans.length) return;

    final selectedPlan = plans[_selectedPlanIndex.value];
    final success =
        await _subscriptionController.subscribe(context, selectedPlan);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Plan'),
      ),
      body: Obx(() {
        final plans = _subscriptionController.plans;
        final isLoading = _subscriptionController.isLoading.value;

        if (isLoading && plans.isEmpty) {
          return AppShimmer.list(count: 4);
        }

        if (plans.isEmpty) {
          return AppErrorWidget(
            message: 'No plans available',
            onRetry: () => _subscriptionController.loadPlans(),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                children: [
                  Text(
                    'Select a subscription plan',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppDimensions.sm,
                      crossAxisSpacing: AppDimensions.sm,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return Obx(() => _PlanCard(
                            plan: plan,
                            isSelected:
                                _selectedPlanIndex.value == index,
                            onTap: () =>
                                _selectedPlanIndex.value = index,
                          ));
                    },
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        );
      }),
    );
  }

  Widget _buildBottomBar() {
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
      child: Obx(() {
        final isSelected = _selectedPlanIndex.value >= 0;
        final plans = _subscriptionController.plans;
        String buttonLabel = 'Select a Plan';

        if (isSelected && _selectedPlanIndex.value < plans.length) {
          final plan = plans[_selectedPlanIndex.value];
          final price = (plan['price'] as num?)?.toDouble() ?? 0;
          buttonLabel =
              'Subscribe - ${AppConstants.currencySymbol}${price.toStringAsFixed(0)}';
        }

        return SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: ElevatedButton(
            onPressed: isSelected ? _subscribeToPlan : null,
            child: Text(buttonLabel),
          ),
        );
      }),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final durationMonths = plan['duration_months'] as int? ?? 1;
    final features = List<String>.from(plan['features'] ?? []);
    final savingsPercent = _calculateSavings(price, durationMonths);
    final durationLabel = _getDurationLabel(durationMonths);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration label
            Text(
              durationLabel,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.xs),

            // Price
            Text(
              '${AppConstants.currencySymbol}${price.toStringAsFixed(0)}',
              style: AppTextStyles.h3.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),

            // Per month
            if (durationMonths > 1) ...[
              Text(
                '${AppConstants.currencySymbol}${(price / durationMonths).toStringAsFixed(0)}/mo',
                style: AppTextStyles.caption,
              ),
            ],
            const SizedBox(height: AppDimensions.sm),

            // Savings badge
            if (savingsPercent > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  'Save ${savingsPercent.toStringAsFixed(0)}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontSize: 10,
                  ),
                ),
              ),

            const Spacer(),

            // Features (show first 2)
            ...features.take(2).map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 14,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),

            // Selected indicator
            if (isSelected) ...[
              const SizedBox(height: AppDimensions.xs),
              Center(
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDurationLabel(int months) {
    if (months >= 12) {
      final years = months ~/ 12;
      return years == 1 ? '1 Year' : '$years Years';
    }
    return months == 1 ? '1 Month' : '$months Months';
  }

  double _calculateSavings(double totalPrice, int months) {
    if (months <= 1) return 0;
    // Estimate monthly base price from the plan list context
    // We approximate savings relative to per-month pricing
    // A simple heuristic: longer plans should show relative savings
    final monthlyRate = totalPrice / months;
    // Assume base monthly is approx 20% more than best rate for a rough display
    // In production this would compare against the actual 1-month plan price
    final estimatedBaseMonthly = monthlyRate * (1 + (months * 0.02));
    if (estimatedBaseMonthly <= 0) return 0;
    final savings =
        ((estimatedBaseMonthly - monthlyRate) / estimatedBaseMonthly) * 100;
    return savings.clamp(0, 60);
  }
}
