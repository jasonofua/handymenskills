import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/chat_controller.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_loading.dart';
import '../../../widgets/common/app_snackbar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController.openConversation(widget.conversationId);
    });

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
      backgroundColor: AppColors.background,
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
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Obx(() {
        final conversations = _chatController.conversations;
        final conversation = conversations.firstWhereOrNull(
          (c) => c['id'] == widget.conversationId,
        );
        final otherUser =
            conversation?['other_user'] as Map<String, dynamic>? ?? {};
        final String name = otherUser['full_name'] ?? 'Chat';
        final String? avatarUrl = otherUser['avatar_url'];
        final bool isOnline = otherUser['is_online'] == true;

        return Row(
          children: [
            AppAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: AppDimensions.avatarSm + 4,
              showOnlineBadge: true,
              isOnline: isOnline,
            ),
            const SizedBox(width: AppDimensions.sm + 2),
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
                  if (isOnline)
                    Text(
                      'Online',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          onPressed: () {
            final conversations = _chatController.conversations;
            final conversation = conversations.firstWhereOrNull(
              (c) => c['id'] == widget.conversationId,
            );
            final otherUser = conversation?['other_user'] as Map<String, dynamic>? ?? {};
            final phone = otherUser['phone']?.toString();
            if (phone != null && phone.isNotEmpty) {
              launchUrl(Uri.parse('tel:$phone'));
            } else {
              AppSnackbar.info('Phone number not available');
            }
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 36,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Text(
                  'No messages yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
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
      label = 'TODAY';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'YESTERDAY';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
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
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.sm,
        right: AppDimensions.sm,
        top: AppDimensions.sm + 2,
        bottom: MediaQuery.of(context).padding.bottom + AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
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
          // Attachment button
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(bottom: 2),
            child: Material(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                onTap: _onAttachmentPressed,
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),

          // Message text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),

          // Send button
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                      onTap: () async {
                        Navigator.pop(context);
                        final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          await _chatController.sendImageMessage(File(image.path));
                        }
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.photo,
                      label: 'Gallery',
                      color: AppColors.info,
                      onTap: () async {
                        Navigator.pop(context);
                        final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) {
                          await _chatController.sendImageMessage(File(image.path));
                        }
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.insert_drive_file,
                      label: 'Document',
                      color: AppColors.secondary,
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
                        );
                        if (result != null && result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          final fileName = result.files.single.name;
                          try {
                            final storageRepo = Get.find<StorageRepository>();
                            final timestamp = DateTime.now().millisecondsSinceEpoch;
                            final path = '${_authController.userId}/${timestamp}_$fileName';
                            final publicUrl = await storageRepo.uploadFile('chat-documents', path, file);
                            await _chatController.sendMessage(fileName, type: 'document', mediaUrl: publicUrl);
                          } catch (e) {
                            AppSnackbar.error('Failed to send document');
                          }
                        }
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.location_on,
                      label: 'Location',
                      color: AppColors.error,
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          LocationPermission permission = await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                          }
                          if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
                            AppSnackbar.error('Location permission denied');
                            return;
                          }
                          final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                          final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
                          final place = placemarks.isNotEmpty ? placemarks.first : null;
                          final address = place != null
                              ? '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
                              : '${position.latitude}, ${position.longitude}';
                          await _chatController.sendLocationMessage(address);
                        } catch (e) {
                          AppSnackbar.error('Failed to get location');
                        }
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
                    : AppColors.white,
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isSent
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(content),
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

  Widget _buildMessageContent(String content) {
    final type = message['type']?.toString() ?? 'text';
    final mediaUrl = message['media_url']?.toString();

    switch (type) {
      case 'image':
        return Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: mediaUrl != null
                  ? CachedNetworkImage(
                      imageUrl: mediaUrl,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 200,
                        height: 150,
                        color: AppColors.background,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 200,
                        height: 150,
                        color: AppColors.background,
                        child: const Icon(Icons.broken_image, color: AppColors.textHint),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      case 'document':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, size: 20, color: isSent ? AppColors.white : AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: isSent ? AppColors.white : AppColors.textPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      case 'location':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 20, color: isSent ? AppColors.white : AppColors.error),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: isSent ? AppColors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      default: // 'text'
        return Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: isSent ? AppColors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        );
    }
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
