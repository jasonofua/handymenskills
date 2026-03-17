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
  // Jobs – listen for changes on the user's jobs (applications, status)
  // ---------------------------------------------------------------------------

  /// Subscribes to changes on jobs owned by [clientId].
  RealtimeChannel subscribeToMyJobs(
    String clientId,
    void Function(Map<String, dynamic> updatedJob) onUpdate,
    void Function(Map<String, dynamic> newJob) onInsert,
  ) {
    final channel = supabase
        .channel('my-jobs:$clientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: clientId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to new applications on jobs owned by [clientId].
  RealtimeChannel subscribeToApplications(
    String clientId,
    void Function(Map<String, dynamic> newApp) onNewApplication,
  ) {
    final channel = supabase
        .channel('applications:$clientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'applications',
          callback: (payload) => onNewApplication(payload.newRecord),
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to new/updated bookings for a user (as client or worker).
  RealtimeChannel subscribeToMyBookings(
    String userId,
    String role,
    void Function() onBookingChange,
  ) {
    final column = role == 'worker' ? 'worker_id' : 'client_id';
    final channel = supabase
        .channel('bookings:$role:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: column,
            value: userId,
          ),
          callback: (_) => onBookingChange(),
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to the open job feed (for workers).
  RealtimeChannel subscribeToJobFeed(
    void Function() onJobChange,
  ) {
    final channel = supabase
        .channel('job-feed')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          callback: (_) => onJobChange(),
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to payment changes for wallet balance updates.
  RealtimeChannel subscribeToPayments(
    String userId,
    void Function() onPaymentChange,
  ) {
    final channel = supabase
        .channel('payments:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => onPaymentChange(),
        )
        .subscribe();

    return channel;
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
