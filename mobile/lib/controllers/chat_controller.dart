import 'dart:io';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/storage_repository.dart';
import '../data/services/realtime_service.dart';
import '../widgets/common/app_snackbar.dart';

class ChatController extends GetxController {
  final _chatRepo = Get.find<ChatRepository>();
  final _realtimeService = Get.find<RealtimeService>();

  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxMap<String, bool> typingUsers = <String, bool>{}.obs;

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _typingChannel;
  String? _activeConversationId;

  String get _userId => supabase.auth.currentUser!.id;

  Future<void> loadConversations() async {
    try {
      isLoading.value = true;
      final data = await _chatRepo.getConversations();
      // Add 'other_user' field for each conversation
      for (final conv in data) {
        final p1 = conv['participant1'] as Map<String, dynamic>?;
        final p2 = conv['participant2'] as Map<String, dynamic>?;
        final p1Id = conv['participant_one']?.toString();
        if (p1Id == _userId) {
          conv['other_user'] = p2 ?? {};
        } else {
          conv['other_user'] = p1 ?? {};
        }
      }
      conversations.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load conversations');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openConversation(String conversationId) async {
    try {
      _activeConversationId = conversationId;
      isLoading.value = true;
      messages.clear();

      final data = await _chatRepo.getMessages(conversationId);
      messages.assignAll(data.reversed.toList());

      // Mark as read
      await _chatRepo.markMessagesRead(conversationId);

      // Subscribe to new messages
      _messageChannel?.unsubscribe();
      _messageChannel = _realtimeService.subscribeToMessages(
        conversationId,
        (newMessage) {
          messages.add(newMessage);
          // Auto mark as read
          _chatRepo.markMessagesRead(conversationId);
        },
      );

      // Subscribe to typing
      _typingChannel?.unsubscribe();
      _typingChannel = _realtimeService.subscribeToTyping(
        conversationId,
        (userId, isTyping) {
          if (userId != _userId) {
            typingUsers[userId] = isTyping;
          }
        },
      );
    } catch (e) {
      AppSnackbar.error('Failed to load messages');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage(String content, {String type = 'text', String? mediaUrl}) async {
    if (_activeConversationId == null) return;
    try {
      isSending.value = true;
      await _chatRepo.sendMessage(
        _activeConversationId!,
        content,
        type: type,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
      AppSnackbar.error('Failed to send message');
    } finally {
      isSending.value = false;
    }
  }

  /// Sends an image message. Uploads file to Supabase storage, then sends.
  Future<void> sendImageMessage(File imageFile) async {
    if (_activeConversationId == null) return;
    try {
      isSending.value = true;
      final storageRepo = Get.find<StorageRepository>();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$_userId/$timestamp.jpg';
      final publicUrl = await storageRepo.uploadFile('chat-images', path, imageFile);
      await _chatRepo.sendMessage(
        _activeConversationId!,
        'Sent an image',
        type: 'image',
        mediaUrl: publicUrl,
      );
    } catch (e) {
      AppSnackbar.error('Failed to send image');
    } finally {
      isSending.value = false;
    }
  }

  /// Sends a location message
  Future<void> sendLocationMessage(String address) async {
    if (_activeConversationId == null) return;
    try {
      isSending.value = true;
      await _chatRepo.sendMessage(
        _activeConversationId!,
        address,
        type: 'location',
      );
    } catch (e) {
      AppSnackbar.error('Failed to send location');
    } finally {
      isSending.value = false;
    }
  }

  void sendTypingIndicator(bool isTyping) {
    if (_activeConversationId == null) return;
    _realtimeService.sendTypingIndicator(_activeConversationId!, _userId, isTyping);
  }

  Future<String?> startConversation(String otherUserId, {String? jobId}) async {
    try {
      final conversation = await _chatRepo.getOrCreateConversation(otherUserId, jobId: jobId);
      return conversation['id'] as String;
    } catch (e) {
      AppSnackbar.error('Failed to start conversation');
      return null;
    }
  }

  void closeConversation() {
    _messageChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _activeConversationId = null;
    messages.clear();
    typingUsers.clear();
  }

  @override
  void onClose() {
    closeConversation();
    super.onClose();
  }
}
