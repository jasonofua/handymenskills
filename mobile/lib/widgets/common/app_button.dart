import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';

enum AppButtonType { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final bool isSmall;
  final IconData? icon;
  final IconData? trailingIcon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.isSmall = false,
    this.icon,
    this.trailingIcon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final height = isSmall ? AppDimensions.buttonSmallHeight : AppDimensions.buttonHeight;
    final fontSize = isSmall ? 14.0 : 16.0;

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: type == AppButtonType.primary ? AppColors.white : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: isSmall ? 18 : 20),
                const SizedBox(width: 8),
              ],
              Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: isSmall ? 18 : 20),
              ],
            ],
          );

    final minSize = Size(width ?? double.infinity, height);

    switch (type) {
      case AppButtonType.primary:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            boxShadow: onPressed != null && !isLoading
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(minimumSize: minSize),
            child: child,
          ),
        );
      case AppButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minSize,
            backgroundColor: AppColors.secondary,
          ),
          child: child,
        );
      case AppButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(minimumSize: minSize),
          child: child,
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(minimumSize: minSize),
          child: child,
        );
    }
  }
}
