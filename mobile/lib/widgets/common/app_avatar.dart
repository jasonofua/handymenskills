import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showOnlineBadge;
  final bool isOnline;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppDimensions.avatarMd,
    this.showOnlineBadge = false,
    this.isOnline = false,
    this.onTap,
  });

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          _buildAvatar(),
          if (showOnlineBadge) _buildOnlineBadge(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsAvatar(),
          errorWidget: (_, __, ___) => _initialsAvatar(),
        ),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: AppColors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineBadge() {
    final badgeSize = size * 0.25;
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: isOnline ? AppColors.success : AppColors.textHint,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
        ),
      ),
    );
  }
}
