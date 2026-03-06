import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

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
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _paymentController.loadPaymentHistory(paymentType: 'job_payment'),
      _paymentController.loadPayouts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: RefreshIndicator(
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
              _buildTotalEarningsCard(),
              const SizedBox(height: AppDimensions.lg),
              _buildMonthlyChartPlaceholder(),
              const SizedBox(height: AppDimensions.lg),
              _buildTransactionList(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    return Obx(() {
      final profile = _workerProfileController.workerProfile;
      final totalEarnings = (profile['total_earnings'] ?? 0.0).toDouble();
      final pendingBalance = (profile['pending_balance'] ?? 0.0).toDouble();

      return AppCard(
        color: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: AppColors.white, size: 28),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Total Earnings',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              '${AppConstants.currencySymbol}${totalEarnings.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                'Pending: ${AppConstants.currencySymbol}${pendingBalance.toStringAsFixed(2)}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMonthlyChartPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Earnings', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.sm),
        AppCard(
          child: SizedBox(
            height: 220,
            child: Obx(() {
              final payments = _paymentController.paymentHistory;
              final monthlyData = _aggregateByMonth(payments);

              if (monthlyData.isEmpty ||
                  monthlyData.values.every((v) => v == 0)) {
                return Center(
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
                );
              }

              final maxY = monthlyData.values
                  .reduce((a, b) => a > b ? a : b);
              final roundedMax = maxY == 0
                  ? 10000.0
                  : (maxY * 1.2 / 5000).ceil() * 5000.0;

              return Padding(
                padding: const EdgeInsets.only(top: 16, right: 8),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: roundedMax,
                    barGroups: monthlyData.entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value,
                            color: AppColors.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            const months = [
                              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                            ];
                            final idx = value.toInt();
                            if (idx < 0 || idx > 11) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                months[idx],
                                style: AppTextStyles.caption,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            final label = value >= 1000000
                                ? '${(value / 1000000).toStringAsFixed(1)}M'
                                : value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(0)}k'
                                    : value.toStringAsFixed(0);
                            return Text(
                              '${AppConstants.currencySymbol}$label',
                              style: AppTextStyles.caption,
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: roundedMax / 4,
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${AppConstants.currencySymbol}${rod.toY.toStringAsFixed(0)}',
                            const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
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

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.sm),
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
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = allTransactions[index];
              return _TransactionTile(transaction: transaction);
            },
          );
        }),
      ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isEarning ? AppColors.success : AppColors.info)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarning
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _statusColor(status),
                            fontSize: 10,
                          ),
                        ),
                      ),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'verified':
      case 'success':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
