import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/chat_controller.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_loading.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _chatController.openConversation(widget.conversationId);

    // Auto-scroll when new messages arrive
    ever(_chatController.messages, (_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTyping) {
      _chatController.sendTypingIndicator(false);
    }
    _chatController.closeConversation();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatController.sendTypingIndicator(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _chatController.sendTypingIndicator(false);
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatController.sendMessage(text);
    _messageController.clear();

    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      _chatController.sendTypingIndicator(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Obx(() {
        final conversations = _chatController.conversations;
        final conversation = conversations.firstWhereOrNull(
          (c) => c['id'] == widget.conversationId,
        );
        final otherUser =
            conversation?['other_user'] as Map<String, dynamic>? ?? {};
        final String name = otherUser['full_name'] ?? 'Chat';
        final String? avatarUrl = otherUser['avatar_url'];

        return Row(
          children: [
            AppAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: AppDimensions.avatarSm,
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (otherUser['is_online'] == true)
                    Text(
                      'Online',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      if (_chatController.isLoading.value &&
          _chatController.messages.isEmpty) {
        return const AppLoading();
      }

      if (_chatController.messages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDimensions.md),
                Text(
                  'No messages yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Send a message to start the conversation.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: AppDimensions.sm,
        ),
        itemCount: _chatController.messages.length,
        itemBuilder: (context, index) {
          final message = _chatController.messages[index];
          final bool isSent =
              message['sender_id'] == _authController.userId;

          // Show date separator if needed
          Widget? dateSeparator;
          if (index == 0 || _shouldShowDateSeparator(index)) {
            dateSeparator = _buildDateSeparator(message);
          }

          return Column(
            children: [
              if (dateSeparator != null) dateSeparator,
              _MessageBubble(
                message: message,
                isSent: isSent,
              ),
            ],
          );
        },
      );
    });
  }

  bool _shouldShowDateSeparator(int index) {
    final current = _chatController.messages[index];
    final previous = _chatController.messages[index - 1];
    final currentDate = DateTime.tryParse(current['created_at'] ?? '');
    final previousDate = DateTime.tryParse(previous['created_at'] ?? '');
    if (currentDate == null || previousDate == null) return false;
    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }

  Widget _buildDateSeparator(Map<String, dynamic> message) {
    final date = DateTime.tryParse(message['created_at'] ?? '');
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Obx(() {
      final hasTypingUsers = _chatController.typingUsers.values.any(
        (isTyping) => isTyping,
      );

      if (!hasTypingUsers) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: AppDimensions.xs,
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              child: _TypingDots(),
            ),
            const SizedBox(width: AppDimensions.xs),
            Text(
              'typing...',
              style: AppTextStyles.caption.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.sm,
        right: AppDimensions.sm,
        top: AppDimensions.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: AppColors.textSecondary,
            onPressed: _onAttachmentPressed,
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusLg,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Obx(() => _buildSendButton()),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final isSending = _chatController.isSending.value;

    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          onTap: isSending ? null : _sendMessage,
          child: Center(
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(
                    Icons.send,
                    color: AppColors.white,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  void _onAttachmentPressed() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttachmentOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        // Camera action placeholder
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.photo,
                      label: 'Gallery',
                      color: AppColors.info,
                      onTap: () {
                        Navigator.pop(context);
                        // Gallery action placeholder
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.insert_drive_file,
                      label: 'Document',
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        // Document action placeholder
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.location_on,
                      label: 'Location',
                      color: AppColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        // Location action placeholder
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSent;

  const _MessageBubble({
    required this.message,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    final String content = message['content'] ?? '';
    final DateTime? createdAt =
        DateTime.tryParse(message['created_at'] ?? '');
    final bool isRead = message['is_read'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isSent) const Spacer(flex: 2),
          Flexible(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSent
                    ? AppColors.primary
                    : AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppDimensions.radiusLg),
                  topRight: const Radius.circular(AppDimensions.radiusLg),
                  bottomLeft: isSent
                      ? const Radius.circular(AppDimensions.radiusLg)
                      : const Radius.circular(4),
                  bottomRight: isSent
                      ? const Radius.circular(4)
                      : const Radius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: isSent
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSent
                          ? AppColors.white
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (createdAt != null)
                        Text(
                          DateFormat('HH:mm').format(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSent
                                ? AppColors.white.withValues(alpha: 0.7)
                                : AppColors.textHint,
                          ),
                        ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead
                              ? AppColors.secondaryLight
                              : AppColors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isSent) const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return _AnimatedDot(animation: _animations[index]);
      }),
    );
  }
}

class _AnimatedDot extends AnimatedWidget {
  const _AnimatedDot({required Animation<double> animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(
          alpha: 0.4 + (animation.value * 0.6),
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
