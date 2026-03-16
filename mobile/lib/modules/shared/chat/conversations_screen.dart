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
import '../../../widgets/common/app_shimmer.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController.loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _chatController.loadConversations();
  }

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _chatController.conversations;
    return _chatController.conversations.where((c) {
      final otherUser = c['other_user'] as Map<String, dynamic>? ?? {};
      final name = (otherUser['full_name'] ?? '').toString().toLowerCase();
      final lastMsg = (c['last_message'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          lastMsg.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Messages', style: AppTextStyles.h4),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            onSelected: (value) {
              // Placeholder for menu actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Archived chats'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              0,
              AppDimensions.screenPadding,
              AppDimensions.md,
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),

          // Conversation list
          Expanded(
            child: Obx(() {
              if (_chatController.isLoading.value &&
                  _chatController.conversations.isEmpty) {
                return _buildShimmerList();
              }

              if (_chatController.conversations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.primary,
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

              final conversations = _filteredConversations;

              if (conversations.isEmpty && _searchQuery.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        'No results for "$_searchQuery"',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.sm,
                  ),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(
                      left: 82,
                      right: AppDimensions.screenPadding,
                    ),
                    child: Divider(
                      height: AppDimensions.dividerThickness,
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
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
          ),
        ],
      ),
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
    final bool isOnline = otherUser['is_online'] == true;

    final DateTime? lastMessageAt = conversation['last_message_at'] != null
        ? DateTime.tryParse(conversation['last_message_at'] as String)
        : null;

    return Material(
      color: hasUnread
          ? AppColors.primary.withValues(alpha: 0.03)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
            vertical: AppDimensions.listItemPadding,
          ),
          child: Row(
            children: [
              // Avatar with online indicator
              AppAvatar(
                imageUrl: avatarUrl,
                name: name,
                size: AppDimensions.avatarMd + 4,
                showOnlineBadge: true,
                isOnline: isOnline,
              ),
              const SizedBox(width: AppDimensions.md),

              // Name + message
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
                        const SizedBox(width: AppDimensions.sm),
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
                              fontSize: 11,
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
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
