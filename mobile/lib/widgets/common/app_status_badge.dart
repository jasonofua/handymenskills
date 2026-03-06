import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  factory AppStatusBadge.booking(String status) {
    final colors = _bookingStatusColors[status] ??
        (bg: AppColors.textHint, text: AppColors.white);
    return AppStatusBadge(
      label: _formatLabel(status),
      color: colors.bg,
      textColor: colors.text,
    );
  }

  factory AppStatusBadge.application(String status) {
    final colors = _applicationStatusColors[status] ??
        (bg: AppColors.textHint, text: AppColors.white);
    return AppStatusBadge(
      label: _formatLabel(status),
      color: colors.bg,
      textColor: colors.text,
    );
  }

  factory AppStatusBadge.job(String status) {
    final colors = _jobStatusColors[status] ??
        (bg: AppColors.textHint, text: AppColors.white);
    return AppStatusBadge(
      label: _formatLabel(status),
      color: colors.bg,
      textColor: colors.text,
    );
  }

  factory AppStatusBadge.urgency(String level) {
    final colors = _urgencyColors[level] ??
        (bg: AppColors.textHint, text: AppColors.white);
    return AppStatusBadge(
      label: _formatLabel(level),
      color: colors.bg,
      textColor: colors.text,
    );
  }

  static String _formatLabel(String status) {
    return status.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  static final _bookingStatusColors = {
    'pending': (bg: AppColors.statusPending, text: AppColors.white),
    'confirmed': (bg: AppColors.statusConfirmed, text: AppColors.white),
    'worker_en_route': (bg: AppColors.statusEnRoute, text: AppColors.white),
    'in_progress': (bg: AppColors.statusInProgress, text: AppColors.white),
    'completed': (bg: AppColors.statusCompleted, text: AppColors.white),
    'client_confirmed': (bg: AppColors.statusClientConfirmed, text: AppColors.white),
    'cancelled': (bg: AppColors.statusCancelled, text: AppColors.white),
    'disputed': (bg: AppColors.statusDisputed, text: AppColors.white),
  };

  static final _applicationStatusColors = {
    'pending': (bg: AppColors.statusPending, text: AppColors.white),
    'accepted': (bg: AppColors.success, text: AppColors.white),
    'rejected': (bg: AppColors.error, text: AppColors.white),
    'withdrawn': (bg: AppColors.textHint, text: AppColors.white),
  };

  static final _jobStatusColors = {
    'draft': (bg: AppColors.textHint, text: AppColors.white),
    'open': (bg: AppColors.success, text: AppColors.white),
    'assigned': (bg: AppColors.info, text: AppColors.white),
    'in_progress': (bg: AppColors.statusInProgress, text: AppColors.white),
    'completed': (bg: AppColors.statusCompleted, text: AppColors.white),
    'cancelled': (bg: AppColors.statusCancelled, text: AppColors.white),
    'expired': (bg: AppColors.textHint, text: AppColors.white),
  };

  static final _urgencyColors = {
    'low': (bg: AppColors.urgencyLow, text: AppColors.white),
    'normal': (bg: AppColors.urgencyNormal, text: AppColors.white),
    'urgent': (bg: AppColors.urgencyUrgent, text: AppColors.white),
    'emergency': (bg: AppColors.urgencyEmergency, text: AppColors.white),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textHint).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
