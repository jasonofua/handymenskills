import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class AppBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? color;

  const AppBadge({
    super.key,
    required this.count,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color ?? AppColors.error,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Center(
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
