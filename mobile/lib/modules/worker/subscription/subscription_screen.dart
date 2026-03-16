import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/subscription_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_shimmer.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionController = Get.find<SubscriptionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptionController.loadMySubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _subscriptionController.loadMySubscription(),
        child: Obx(() {
          if (_subscriptionController.isLoading.value &&
              _subscriptionController.currentSubscription.value == null) {
            return AppShimmer.list(count: 3);
          }

          final subscription =
              _subscriptionController.currentSubscription.value;
          final isActive = _subscriptionController.isActive;
          final isGrace = _subscriptionController.isGracePeriod;

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              // -- Current Plan card --
              if (subscription != null && (isActive || isGrace))
                _buildCurrentPlanCard(subscription)
              else
                _buildNoSubscriptionCard(),
              const SizedBox(height: AppDimensions.lg),

              // -- Upgrade section --
              Text(
                'UPGRADE OR CHANGE PLAN',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: AppDimensions.md),
              _buildPlanTierCards(isActive || isGrace),
              const SizedBox(height: AppDimensions.lg),

              // -- Paystack footer --
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      'Secure payments powered by Paystack',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xxl),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentPlanCard(Map<String, dynamic> subscription) {
    final planName = subscription['plan']?['name'] ??
        subscription['plan_name'] ??
        'Current Plan';
    final planPrice = (subscription['plan']?['price'] ?? 0.0).toDouble();
    final daysRemaining = _subscriptionController.daysRemaining;
    final expiresAt = DateTime.tryParse(subscription['expires_at'] ?? '');
    final isGrace = _subscriptionController.isGracePeriod;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isGrace
              ? [
                  AppColors.warning,
                  AppColors.secondaryDark,
                ]
              : [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: (isGrace ? AppColors.warning : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Status badge + icon --
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  isGrace ? Icons.warning_amber : Icons.workspace_premium,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.25),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  isGrace ? 'GRACE PERIOD' : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // -- Plan name --
          Text(
            planName,
            style: AppTextStyles.h2.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppDimensions.xs),

          // -- Price --
          if (planPrice > 0)
            Text(
              '${AppConstants.currencySymbol}${planPrice.toStringAsFixed(0)}/month',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
              ),
            ),
          const SizedBox(height: AppDimensions.md),

          // -- Divider --
          Container(
            height: 1,
            color: AppColors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppDimensions.md),

          // -- Days remaining + Expiry --
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Days Remaining',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysRemaining > 0 ? daysRemaining.toString() : '0',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              if (expiresAt != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Expires',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(expiresAt),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // -- Grace period warning --
          if (isGrace) ...[
            const SizedBox(height: AppDimensions.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.white, size: 16),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'Your subscription has expired. Renew within ${AppConstants.gracePeriodDays} days to keep access.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionCard() {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.md),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'No Active Subscription',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Subscribe to start applying to jobs and connect with clients.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.md),
        ],
      ),
    );
  }

  Widget _buildPlanTierCards(bool hasSubscription) {
    // Plan tiers - these map to what the backend provides
    final plans = [
      {
        'name': 'Basic',
        'icon': Icons.star_outline,
        'color': AppColors.info,
        'features': [
          'Apply to up to 5 jobs/month',
          'Basic profile listing',
          'Standard support',
        ],
      },
      {
        'name': 'Professional',
        'icon': Icons.workspace_premium,
        'color': AppColors.primary,
        'popular': true,
        'features': [
          'Unlimited job applications',
          'Priority profile listing',
          'Verified badge eligibility',
          'Direct messaging with clients',
        ],
      },
      {
        'name': 'Enterprise',
        'icon': Icons.diamond_outlined,
        'color': AppColors.secondary,
        'features': [
          'Everything in Professional',
          'Featured in search results',
          'Priority support',
          'Analytics dashboard',
          'Team management',
        ],
      },
    ];

    return Column(
      children: plans.map((plan) {
        final isPopular = plan['popular'] == true;
        final color = plan['color'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.md),
          child: AppCard(
            borderColor: isPopular
                ? AppColors.primary.withValues(alpha: 0.3)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Icon(plan['icon'] as IconData,
                          color: color, size: 20),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Text(
                      plan['name'] as String,
                      style: AppTextStyles.h4,
                    ),
                    const Spacer(),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull),
                        ),
                        child: Text(
                          'POPULAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                ...(plan['features'] as List<String>).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonSmallHeight,
                  child: isPopular
                      ? ElevatedButton(
                          onPressed: () =>
                              context.push(AppRoutes.workerPlanSelection),
                          child: Text(hasSubscription
                              ? 'Upgrade'
                              : 'Choose Plan'),
                        )
                      : OutlinedButton(
                          onPressed: () =>
                              context.push(AppRoutes.workerPlanSelection),
                          child: Text(hasSubscription
                              ? 'Switch Plan'
                              : 'Choose Plan'),
                        ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
