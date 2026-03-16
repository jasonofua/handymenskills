import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final Color? backgroundColor;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.backgroundColor,
  });

  factory AppStatusBadge.booking(String status) {
    final colors = _bookingStatusColors[status] ??
        (bg: const Color(0xFFF3F4F6), text: AppColors.textSecondary);
    return AppStatusBadge(
      label: _formatLabel(status),
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  factory AppStatusBadge.application(String status) {
    final colors = _applicationStatusColors[status] ??
        (bg: const Color(0xFFF3F4F6), text: AppColors.textSecondary);
    return AppStatusBadge(
      label: _formatLabel(status),
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  factory AppStatusBadge.job(String status) {
    final colors = _jobStatusColors[status] ??
        (bg: const Color(0xFFF3F4F6), text: AppColors.textSecondary);
    return AppStatusBadge(
      label: _formatLabel(status),
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  factory AppStatusBadge.urgency(String level) {
    final colors = _urgencyColors[level] ??
        (bg: const Color(0xFFF3F4F6), text: AppColors.textSecondary);
    return AppStatusBadge(
      label: _formatLabel(level),
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  static String _formatLabel(String status) {
    return status.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  // Light background with colored text — matches UI design
  static final _bookingStatusColors = {
    'pending': (bg: const Color(0xFFFEF3C7), text: const Color(0xFFB45309)),
    'confirmed': (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1D4ED8)),
    'worker_en_route': (bg: const Color(0xFFEDE9FE), text: const Color(0xFF7C3AED)),
    'in_progress': (bg: const Color(0xFFFFF7ED), text: const Color(0xFFC2410C)),
    'completed': (bg: const Color(0xFFDCFCE7), text: const Color(0xFF15803D)),
    'client_confirmed': (bg: const Color(0xFFDCFCE7), text: const Color(0xFF047857)),
    'cancelled': (bg: const Color(0xFFFEE2E2), text: const Color(0xFFDC2626)),
    'disputed': (bg: const Color(0xFFFEE2E2), text: const Color(0xFFB91C1C)),
  };

  static final _applicationStatusColors = {
    'pending': (bg: const Color(0xFFFEF3C7), text: const Color(0xFFB45309)),
    'accepted': (bg: const Color(0xFFDCFCE7), text: const Color(0xFF15803D)),
    'rejected': (bg: const Color(0xFFFEE2E2), text: const Color(0xFFDC2626)),
    'withdrawn': (bg: const Color(0xFFF3F4F6), text: const Color(0xFF6B7280)),
  };

  static final _jobStatusColors = {
    'draft': (bg: const Color(0xFFF3F4F6), text: const Color(0xFF6B7280)),
    'open': (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1D4ED8)),
    'assigned': (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1D4ED8)),
    'in_progress': (bg: const Color(0xFFFFF7ED), text: const Color(0xFFC2410C)),
    'completed': (bg: const Color(0xFFDCFCE7), text: const Color(0xFF15803D)),
    'cancelled': (bg: const Color(0xFFFEE2E2), text: const Color(0xFFDC2626)),
    'expired': (bg: const Color(0xFFF3F4F6), text: const Color(0xFF6B7280)),
  };

  static final _urgencyColors = {
    'low': (bg: const Color(0xFFDCFCE7), text: const Color(0xFF15803D)),
    'medium': (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1D4ED8)),
    'high': (bg: const Color(0xFFFEF3C7), text: const Color(0xFFB45309)),
    'emergency': (bg: const Color(0xFFFEE2E2), text: const Color(0xFFDC2626)),
    // Legacy values
    'normal': (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1D4ED8)),
    'urgent': (bg: const Color(0xFFFEF3C7), text: const Color(0xFFB45309)),
  };

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (color ?? AppColors.textHint).withValues(alpha: 0.1);
    final fg = textColor ?? color ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
