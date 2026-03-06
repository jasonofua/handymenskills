import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class AppLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoading({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }

  static Widget fullScreen({String? message}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoading(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
