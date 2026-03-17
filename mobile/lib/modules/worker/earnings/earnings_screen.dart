import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_snackbar.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/payment_controller.dart';
import '../../../controllers/worker_profile_controller.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_shimmer.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _paymentController = Get.find<PaymentController>();
  final _workerProfileController = Get.find<WorkerProfileController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _paymentController.loadPaymentHistory(paymentType: 'job_payment'),
      _paymentController.loadPayouts(),
      _paymentController.loadWorkerBalance(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: Obx(() {
          final isLoading = _paymentController.isLoading.value;

          if (isLoading &&
              _paymentController.paymentHistory.isEmpty &&
              _paymentController.payouts.isEmpty) {
            return AppShimmer.list(count: 6);
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              _buildTotalEarningsHero(),
              const SizedBox(height: AppDimensions.md),
              _buildAvailableBalanceCard(),
              const SizedBox(height: AppDimensions.lg),
              _buildMonthlyTrends(),
              const SizedBox(height: AppDimensions.lg),
              _buildPayoutHistory(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTotalEarningsHero() {
    return Obx(() {
      final profile = _workerProfileController.workerProfile;
      final totalEarnings = (profile['total_earnings'] ?? 0.0).toDouble();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [

                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Total Earnings',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              '${AppConstants.currencySymbol}${totalEarnings.toStringAsFixed(2)}',
              style: AppTextStyles.priceHero.copyWith(
                color: AppColors.white,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            // Growth indicator
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up,
                      size: 14, color: AppColors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text(
                    'Lifetime earnings',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAvailableBalanceCard() {
    return Obx(() {
      final availableBalance = _paymentController.workerAvailableBalance.value;

      return AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.success, size: 22),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    '${AppConstants.currencySymbol}${availableBalance.toStringAsFixed(2)}',
                    style: AppTextStyles.price,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: availableBalance >= AppConstants.minWithdrawal
                  ? () => _showWithdrawalBottomSheet(availableBalance)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(0, AppDimensions.buttonSmallHeight),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Withdraw'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMonthlyTrends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MONTHLY TRENDS',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppDimensions.md),
        AppCard(
          child: Obx(() {
            final payments = _paymentController.paymentHistory;
            final monthlyData = _aggregateByMonth(payments);

            if (monthlyData.isEmpty ||
                monthlyData.values.every((v) => v == 0)) {
              return SizedBox(
                height: 160,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_outlined,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: AppDimensions.sm),
                      Text('No earnings data yet',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              );
            }

            final maxVal = monthlyData.values.reduce((a, b) => a > b ? a : b);
            final maxHeight = 120.0;

            return Column(
              children: [
                SizedBox(
                  height: maxHeight + 32,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthlyData.entries.map((entry) {
                      final barHeight = maxVal > 0
                          ? (entry.value / maxVal) * maxHeight
                          : 0.0;
                      final monthNames = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                      ];
                      final monthLabel = entry.key >= 0 && entry.key < 12
                          ? monthNames[entry.key]
                          : '';

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (entry.value > 0)
                                Text(
                                  _formatCompactAmount(entry.value),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Container(
                                height: barHeight < 4 && entry.value > 0
                                    ? 4
                                    : barHeight,
                                decoration: BoxDecoration(
                                  color: entry.value > 0
                                      ? AppColors.primary
                                      : AppColors.border,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                monthLabel,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  String _formatCompactAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  Map<int, double> _aggregateByMonth(List<Map<String, dynamic>> payments) {
    final now = DateTime.now();
    final Map<int, double> monthly = {};

    // Initialize last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      monthly[month.month - 1] = 0;
    }

    for (final payment in payments) {
      final createdAt = DateTime.tryParse(payment['created_at'] ?? '');
      final amount = (payment['amount'] ?? 0.0).toDouble();
      final status = payment['status'] ?? '';
      if (createdAt != null &&
          (status == 'success' || status == 'completed')) {
        final monthKey = createdAt.month - 1;
        if (monthly.containsKey(monthKey)) {
          monthly[monthKey] = (monthly[monthKey] ?? 0) + amount;
        }
      }
    }

    return monthly;
  }

  Widget _buildPayoutHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAYOUT HISTORY',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppDimensions.md),
        Obx(() {
          final payments = _paymentController.paymentHistory;
          final payouts = _paymentController.payouts;

          // Combine and sort transactions
          final allTransactions = <Map<String, dynamic>>[];

          for (final p in payments) {
            allTransactions.add({
              ...p,
              '_type': 'earning',
            });
          }
          for (final p in payouts) {
            allTransactions.add({
              ...p,
              '_type': 'payout',
            });
          }

          allTransactions.sort((a, b) {
            final dateA = DateTime.tryParse(a['created_at'] ?? '') ??
                DateTime(2000);
            final dateB = DateTime.tryParse(b['created_at'] ?? '') ??
                DateTime(2000);
            return dateB.compareTo(dateA);
          });

          if (allTransactions.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle: 'Your earnings and payouts will appear here',
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allTransactions.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.sm),
            itemBuilder: (context, index) {
              final transaction = allTransactions[index];
              return _TransactionTile(transaction: transaction);
            },
          );
        }),
      ],
    );
  }

  void _showWithdrawalBottomSheet(double availableBalance) {
    final amountController = TextEditingController();
    final workerProfile = _workerProfileController.workerProfile;
    final bankName = workerProfile['bank_name']?.toString() ?? '';
    final accountNumber = workerProfile['bank_account_number']?.toString() ?? '';
    final accountName = workerProfile['bank_account_name']?.toString() ?? '';
    final hasBankDetails = bankName.isNotEmpty && accountNumber.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.cardRadius),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.screenPadding,
          right: AppDimensions.screenPadding,
          top: AppDimensions.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Text('Withdraw', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.sm),

            // Available balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  Text('Available: ', style: AppTextStyles.bodySmall),
                  Text(
                    '${AppConstants.currencySymbol}${availableBalance.toStringAsFixed(0)}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            if (!hasBankDetails) ...[
              // No bank details warning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Please add your bank details in your profile before withdrawing.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push(AppRoutes.workerEditProfile);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('Go to Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Amount input
              Text('Amount', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppDimensions.xs),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '${AppConstants.currencySymbol} ',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.sm,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                'Minimum withdrawal: ${AppConstants.currencySymbol}${AppConstants.minWithdrawal.toStringAsFixed(0)}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppDimensions.md),

              // Bank details display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank Details', style: AppTextStyles.labelMedium),
                    const SizedBox(height: AppDimensions.sm),
                    _bankDetailRow('Bank', bankName),
                    _bankDetailRow('Account', accountNumber),
                    _bankDetailRow('Name', accountName),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              // Submit button
              Obx(() => SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: _paymentController.isProcessing.value
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text.trim());
                          if (amount == null || amount <= 0) {
                            AppSnackbar.error('Please enter a valid amount');
                            return;
                          }
                          final success = await _paymentController.requestWithdrawal(
                            amount: amount,
                            bankName: bankName,
                            accountNumber: accountNumber,
                            accountName: accountName,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (success) {
                            _loadData();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    ),
                  ),
                  child: _paymentController.isProcessing.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.white),
                          ),
                        )
                      : const Text('Withdraw'),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final type = transaction['_type'] as String;
    final isEarning = type == 'earning';
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final status = transaction['status'] ?? '';
    final createdAt = DateTime.tryParse(transaction['created_at'] ?? '');
    final description = isEarning
        ? (transaction['payment_type'] ?? 'Job payment')
        : 'Payout to bank';

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.cardPadding,
        vertical: AppDimensions.sm + 2,
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isEarning ? AppColors.success : AppColors.info)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarning ? Icons.arrow_downward : Icons.arrow_upward,
              color: isEarning ? AppColors.success : AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDescription(description),
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (createdAt != null)
                      Text(_formatDate(createdAt),
                          style: AppTextStyles.caption),
                    if (status.isNotEmpty) ...[
                      const SizedBox(width: AppDimensions.sm),
                      _buildStatusIcon(status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isEarning ? '+' : '-'}${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}',
            style: AppTextStyles.labelLarge.copyWith(
              color: isEarning ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'completed':
      case 'verified':
      case 'success':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'pending':
        icon = Icons.schedule;
        color = AppColors.warning;
        break;
      case 'failed':
        icon = Icons.cancel;
        color = AppColors.error;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.textHint;
    }
    return Icon(icon, size: 14, color: color);
  }

  String _formatDescription(String description) {
    return description
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return '${w[0].toUpperCase()}${w.substring(1)}';
        })
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
