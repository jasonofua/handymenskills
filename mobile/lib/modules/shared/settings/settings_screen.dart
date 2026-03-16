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
        title: const Text('Settings', style: AppTextStyles.h4),
      ),
      body: ListView(
        children: [
          // Profile section — centered
          _buildProfileSection(context, authController),
          const SizedBox(height: AppDimensions.lg),

          // Account Settings section
          _buildSectionHeader('ACCOUNT SETTINGS'),
          const SizedBox(height: AppDimensions.sm),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Preferences',
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Privacy & Security',
            onTap: () => _showInfoDialog(
              context,
              title: 'Privacy & Security',
              content: 'Privacy settings will be available in a future update.',
            ),
          ),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payment Methods',
            onTap: () => _showInfoDialog(
              context,
              title: 'Payment Methods',
              content: 'Payment method management will be available in a future update.',
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Support & About section
          _buildSectionHeader('SUPPORT & ABOUT'),
          const SizedBox(height: AppDimensions.sm),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () => _showInfoDialog(
              context,
              title: 'Help & Support',
              content:
                  'Contact us at support@handymenskills.ng or call +234 800 000 0000 for assistance.',
            ),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _showInfoDialog(
              context,
              title: 'Terms of Service',
              content:
                  'The Terms of Service page will be displayed here. This would typically open a web view or navigate to a dedicated terms screen.',
            ),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Privacy Policy',
            onTap: () => _showInfoDialog(
              context,
              title: 'Privacy Policy',
              content:
                  'The Privacy Policy page will be displayed here. This would typically open a web view or navigate to a dedicated privacy screen.',
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Dark Mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: const Icon(Icons.dark_mode_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: AppDimensions.md),
                const Expanded(
                  child: Text('Dark Mode',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                Obx(() => Switch.adaptive(
                      value: themeController.isDark,
                      activeColor: AppColors.primary,
                      onChanged: (_) => themeController.toggleTheme(),
                    )),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Sign Out
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            child: SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: OutlinedButton(
                onPressed: () => _confirmSignOut(context, authController),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.buttonRadius),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),

          // Version
          Center(
            child: Text(
              'Handymenskills v1.0.0',
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
      final email = authController.userEmail;
      final avatar = authController.userAvatar;

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: AppDimensions.lg,
        ),
        child: Column(
          children: [
            AppAvatar(
              imageUrl: avatar,
              name: name,
              size: AppDimensions.avatarXl,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              name.isNotEmpty ? name : 'Set up your profile',
              style: AppTextStyles.h3,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(email, style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: AppDimensions.md),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.editProfile),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              child: const Text('Edit Profile',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
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
      child: Text(title, style: AppTextStyles.sectionHeader),
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
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 2,
      ),
      onTap: onTap,
    );
  }
}
