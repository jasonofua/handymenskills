import '../../config/supabase_config.dart';

class ChatRepository {
  /// Gets an existing conversation with [otherUserId] or creates a new one.
  /// Optionally associates the conversation with a [jobId].
  Future<Map<String, dynamic>> getOrCreateConversation(
    String otherUserId, {
    String? jobId,
  }) async {
    try {
      final params = <String, dynamic>{
        'other_user_id': otherUserId,
      };
      if (jobId != null) {
        params['job_id'] = jobId;
      }

      final response = await supabase.rpc(
        'get_or_create_conversation',
        params: params,
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw Exception(
          'Failed to get or create conversation with $otherUserId: $e');
    }
  }

  /// Fetches all conversations for the current user with the other
  /// participant's profile information.
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('conversations')
          .select(
              '*, participant1:profiles!conversations_participant_one_fkey(*), participant2:profiles!conversations_participant_two_fkey(*)')
          .or('participant_one.eq.$userId,participant_two.eq.$userId')
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  /// Fetches messages for a [conversationId], paginated.
  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await supabase
          .from('messages')
          .select('*, profiles!messages_sender_id_fkey(*)')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Failed to get messages for conversation $conversationId: $e');
    }
  }

  /// Sends a message to a conversation and returns the created message record.
  Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
    String? mediaUrl,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = <String, dynamic>{
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content,
        'type': type,
      };
      if (mediaUrl != null) {
        data['media_url'] = mediaUrl;
      }

      final response =
          await supabase.from('messages').insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Marks all unread messages in a conversation as read via RPC.
  Future<void> markMessagesRead(String conversationId) async {
    try {
      await supabase.rpc('mark_messages_read', params: {
        'conversation_id': conversationId,
      });
    } catch (e) {
      throw Exception(
          'Failed to mark messages as read for $conversationId: $e');
    }
  }
}
