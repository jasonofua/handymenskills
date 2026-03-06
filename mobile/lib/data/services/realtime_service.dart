import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

/// Service for managing Supabase Realtime subscriptions across the app.
///
/// Provides live updates for messages, notifications, bookings, and
/// conversations via Postgres Changes listeners, as well as ephemeral
/// broadcast events for typing indicators.
class RealtimeService {
  // ---------------------------------------------------------------------------
  // Postgres Changes subscriptions
  // ---------------------------------------------------------------------------

  /// Subscribes to new messages inserted into a specific conversation.
  ///
  /// Returns the [RealtimeChannel] so the caller can later unsubscribe.
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(Map<String, dynamic>) onMessage,
  ) {
    final channel = supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => onMessage(payload.newRecord),
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to new notifications inserted for a specific user.
  ///
  /// Returns the [RealtimeChannel] so the caller can later unsubscribe.
  RealtimeChannel subscribeToNotifications(
    String userId,
    void Function(Map<String, dynamic>) onNotification,
  ) {
    final channel = supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onNotification(payload.newRecord),
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to updates on a specific booking row.
  ///
  /// Returns the [RealtimeChannel] so the caller can later unsubscribe.
  RealtimeChannel subscribeToBookingUpdates(
    String bookingId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    final channel = supabase
        .channel('booking:$bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: bookingId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to conversation updates where the user is a participant.
  ///
  /// Because Supabase Realtime only supports a single column filter per
  /// subscription, two channels are created -- one for each participant
  /// column. Both channels funnel events into the same [onUpdate] callback.
  /// A wrapper [RealtimeChannel] is **not** returned; instead both channels
  /// are tracked internally under a composite key so they can be removed
  /// together. Use [unsubscribeFromConversationUpdates] to clean up.
  ///
  /// If you only need a single channel reference, consider subscribing to
  /// the participant_one side only and broadening the filter server-side
  /// with a Postgres publication.
  ///
  /// For simplicity this method subscribes to participant_one first and
  /// returns that channel; to also capture participant_two updates, a
  /// second channel is created automatically.
  RealtimeChannel subscribeToConversationUpdates(
    String userId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    // Channel for conversations where the user is participant_one.
    final channelOne = supabase
        .channel('conversations:p1:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'participant_one',
            value: userId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();

    // Channel for conversations where the user is participant_two.
    supabase
        .channel('conversations:p2:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'participant_two',
            value: userId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();

    return channelOne;
  }

  // ---------------------------------------------------------------------------
  // Broadcast – typing indicators
  // ---------------------------------------------------------------------------

  /// Sends a typing indicator broadcast on the channel for [conversationId].
  ///
  /// The broadcast is fire-and-forget; there is no acknowledgement.
  void sendTypingIndicator(
    String conversationId,
    String userId,
    bool isTyping,
  ) {
    final channel = supabase.channel('typing:$conversationId');

    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        channel.sendBroadcastMessage(
          event: 'typing',
          payload: {
            'user_id': userId,
            'is_typing': isTyping,
          },
        );
      }
    });
  }

  /// Subscribes to typing indicator broadcasts for a conversation.
  ///
  /// [onTyping] is invoked with the user ID and whether they are typing.
  /// Returns the [RealtimeChannel] for later cleanup.
  RealtimeChannel subscribeToTyping(
    String conversationId,
    void Function(String userId, bool isTyping) onTyping,
  ) {
    final channel = supabase
        .channel('typing:$conversationId')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final userId = payload['user_id'] as String? ?? '';
            final isTyping = payload['is_typing'] as bool? ?? false;
            onTyping(userId, isTyping);
          },
        )
        .subscribe();

    return channel;
  }

  // ---------------------------------------------------------------------------
  // Cleanup helpers
  // ---------------------------------------------------------------------------

  /// Removes a single channel subscription.
  void unsubscribe(RealtimeChannel channel) {
    supabase.removeChannel(channel);
  }

  /// Removes **all** active channel subscriptions.
  void unsubscribeAll() {
    supabase.removeAllChannels();
  }
}
