import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.md,
        ),
        children: [
          // Profile section
          _buildProfileSection(context, authController),
          const SizedBox(height: AppDimensions.md),

          // Preferences section
          _buildSectionHeader('Preferences'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Obx(() => Switch.adaptive(
                  value: themeController.isDark,
                  activeColor: AppColors.primary,
                  onChanged: (_) => themeController.toggleTheme(),
                )),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          const SizedBox(height: AppDimensions.md),

          // Support section
          _buildSectionHeader('Support'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => context.push(AppRoutes.about),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _openTerms(context),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _openPrivacy(context),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _openHelp(context),
          ),
          const SizedBox(height: AppDimensions.md),

          // Account section
          _buildSectionHeader('Account'),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            showChevron: false,
            onTap: () => _confirmSignOut(context, authController),
          ),

          const SizedBox(height: AppDimensions.xl),

          // App version
          Center(
            child: Text(
              'Artisan Marketplace v1.0.0',
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    AuthController authController,
  ) {
    return Obx(() {
      final name = authController.userName;
      final phone = authController.userPhone;
      final avatar = authController.userAvatar;

      return InkWell(
        onTap: () => context.push(AppRoutes.editProfile),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
            vertical: AppDimensions.md,
          ),
          child: Row(
            children: [
              AppAvatar(
                imageUrl: avatar,
                name: name,
                size: AppDimensions.avatarLg,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Set up your profile',
                      style: AppTextStyles.h4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      'Edit Profile',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppDimensions.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          letterSpacing: 1.2,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  void _openTerms(BuildContext context) {
    _showInfoDialog(
      context,
      title: 'Terms of Service',
      content:
          'The Terms of Service page will be displayed here. This would typically open a web view or navigate to a dedicated terms screen.',
    );
  }

  void _openPrivacy(BuildContext context) {
    _showInfoDialog(
      context,
      title: 'Privacy Policy',
      content:
          'The Privacy Policy page will be displayed here. This would typically open a web view or navigate to a dedicated privacy screen.',
    );
  }

  void _openHelp(BuildContext context) {
    _showInfoDialog(
      context,
      title: 'Help & Support',
      content:
          'Contact us at support@artisanmarketplace.ng or call +234 800 000 0000 for assistance.',
    );
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(
    BuildContext context,
    AuthController authController,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authController.signOut();
              context.go(AppRoutes.login);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.textSecondary)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Icon(
          icon,
          size: 22,
          color: iconColor ?? AppColors.textSecondary,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.caption)
          : null,
      trailing: trailing ??
          (showChevron
              ? const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                )
              : null),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 2,
      ),
      onTap: onTap,
    );
  }
}
