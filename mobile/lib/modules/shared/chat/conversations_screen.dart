import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/chat_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_loading.dart';
import '../../../widgets/common/app_shimmer.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatController _chatController = Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    _chatController.loadConversations();
  }

  Future<void> _onRefresh() async {
    await _chatController.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Obx(() {
        if (_chatController.isLoading.value &&
            _chatController.conversations.isEmpty) {
          return _buildShimmerList();
        }

        if (_chatController.conversations.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                AppEmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No conversations yet',
                  subtitle:
                      'Start a conversation by contacting a worker or client.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.sm,
            ),
            itemCount: _chatController.conversations.length,
            separatorBuilder: (_, __) => const Divider(
              height: AppDimensions.dividerThickness,
              indent: 76,
              endIndent: AppDimensions.screenPadding,
            ),
            itemBuilder: (context, index) {
              final conversation = _chatController.conversations[index];
              return _ConversationTile(
                conversation: conversation,
                onTap: () {
                  final conversationId = conversation['id'] as String;
                  context.push(
                    AppRoutes.chatConversation
                        .replaceFirst(':id', conversationId),
                  );
                },
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      itemCount: 8,
      itemBuilder: (_, __) => AppShimmer.listItem(),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser =
        conversation['other_user'] as Map<String, dynamic>? ?? {};
    final String name = otherUser['full_name'] ?? 'Unknown';
    final String? avatarUrl = otherUser['avatar_url'];
    final String lastMessage =
        conversation['last_message'] as String? ?? '';
    final int unreadCount =
        (conversation['unread_count'] as int?) ?? 0;
    final bool hasUnread = unreadCount > 0;

    final DateTime? lastMessageAt = conversation['last_message_at'] != null
        ? DateTime.tryParse(conversation['last_message_at'] as String)
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: AppDimensions.listItemPadding,
        ),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: AppDimensions.avatarMd,
              showOnlineBadge: true,
              isOnline: otherUser['is_online'] == true,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: hasUnread
                              ? AppTextStyles.labelLarge
                              : AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageAt != null)
                        Text(
                          timeago.format(lastMessageAt, locale: 'en_short'),
                          style: AppTextStyles.caption.copyWith(
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: hasUnread
                              ? AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                )
                              : AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: AppDimensions.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99
                                  ? '99+'
                                  : unreadCount.toString(),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
