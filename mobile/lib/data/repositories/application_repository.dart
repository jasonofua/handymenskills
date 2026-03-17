import '../../config/supabase_config.dart';

class ApplicationRepository {
  /// Applies to a job via RPC, which handles validation and status updates.
  Future<void> applyToJob(
    String jobId,
    String coverLetter,
    double proposedPrice, {
    String? estimatedDuration,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_job_id': jobId,
        'p_cover_letter': coverLetter,
        'p_proposed_price': proposedPrice,
      };
      if (estimatedDuration != null) {
        params['p_estimated_duration'] = estimatedDuration;
      }

      await supabase.rpc('apply_to_job', params: params);
    } catch (e) {
      throw Exception('Failed to apply to job $jobId: $e');
    }
  }

  /// Withdraws an application by setting its status to 'withdrawn'.
  Future<void> withdrawApplication(String applicationId) async {
    try {
      await supabase
          .from('applications')
          .update({'status': 'withdrawn'}).eq('id', applicationId);
    } catch (e) {
      throw Exception(
          'Failed to withdraw application $applicationId: $e');
    }
  }

  /// Resolves the worker_profile ID for a given auth user ID.
  Future<String?> _getWorkerProfileId(String userId) async {
    final wp = await supabase
        .from('worker_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    return wp?['id'] as String?;
  }

  /// Fetches applications submitted by the given user (auth [userId]).
  /// Internally resolves the worker_profile ID since applications.worker_id
  /// references worker_profiles.id, not the auth user UUID.
  /// Optionally filters by [status].
  Future<List<Map<String, dynamic>>> getMyApplications(
    String userId, {
    String? status,
  }) async {
    try {
      final workerProfileId = await _getWorkerProfileId(userId);
      if (workerProfileId == null) return [];

      var query = supabase
          .from('applications')
          .select('*, jobs(*, categories(*), profiles!jobs_client_id_fkey(*))')
          .eq('worker_id', workerProfileId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('created_at', ascending: false);
      var results = List<Map<String, dynamic>>.from(response);

      // For accepted applications, exclude those with completed bookings
      // (they should show in Bookings tab, not Applications)
      if (status == 'accepted' || status == null) {
        final doneBookings = await supabase
            .from('bookings')
            .select('application_id')
            .eq('worker_id', userId)
            .inFilter('status', ['completed', 'client_confirmed']);
        final doneAppIds = doneBookings
            .map<String>((b) => b['application_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        if (doneAppIds.isNotEmpty) {
          results = results
              .where((app) => !doneAppIds.contains(app['id']?.toString()))
              .toList();
        }
      }

      return results;
    } catch (e) {
      throw Exception(
          'Failed to get applications for user $userId: $e');
    }
  }

  /// Checks if the user has already applied to a specific job.
  Future<bool> hasAppliedToJob(String userId, String jobId) async {
    try {
      final workerProfileId = await _getWorkerProfileId(userId);
      if (workerProfileId == null) return false;

      final result = await supabase
          .from('applications')
          .select('id')
          .eq('worker_id', workerProfileId)
          .eq('job_id', jobId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Returns the set of job IDs the user has applied to.
  Future<Set<String>> getAppliedJobIds(String userId) async {
    try {
      final workerProfileId = await _getWorkerProfileId(userId);
      if (workerProfileId == null) return {};

      final response = await supabase
          .from('applications')
          .select('job_id')
          .eq('worker_id', workerProfileId)
          .inFilter('status', ['pending', 'accepted', 'under_review']);

      return response.map<String>((r) => r['job_id'] as String).toSet();
    } catch (e) {
      return {};
    }
  }

  /// Fetches all applications for a specific [jobId] with worker profiles.
  Future<List<Map<String, dynamic>>> getJobApplications(
    String jobId,
  ) async {
    try {
      final response = await supabase
          .from('applications')
          .select('*, worker_profiles(*, profiles(*))')
          .eq('job_id', jobId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Failed to get applications for job $jobId: $e');
    }
  }

  /// Accepts an application: updates status, creates a booking,
  /// updates job to in_progress, and rejects other pending applications.
  Future<Map<String, dynamic>> acceptApplication(String applicationId) async {
    try {
      // 1. Get the application details
      final app = await supabase
          .from('applications')
          .select('*')
          .eq('id', applicationId)
          .single();

      final jobId = app['job_id'] as String;
      final workerProfileId = app['worker_id'] as String;
      final agreedPrice = (app['proposed_price'] ?? 0).toDouble();

      // 2. Get the worker's auth user ID from worker_profiles
      final wp = await supabase
          .from('worker_profiles')
          .select('user_id')
          .eq('id', workerProfileId)
          .single();
      final workerUserId = wp['user_id'] as String;

      // 3. Update application status to accepted
      await supabase
          .from('applications')
          .update({'status': 'accepted', 'accepted_at': DateTime.now().toIso8601String()})
          .eq('id', applicationId);

      // 4. Create a booking
      final clientId = supabase.auth.currentUser!.id;
      final bookingResponse = await supabase
          .from('bookings')
          .insert({
            'job_id': jobId,
            'client_id': clientId,
            'worker_id': workerUserId,
            'application_id': applicationId,
            'agreed_price': agreedPrice,
            'status': 'confirmed',
          })
          .select()
          .single();

      // 5. Update job status to in_progress
      await supabase
          .from('jobs')
          .update({'status': 'in_progress'})
          .eq('id', jobId);

      // 6. Reject other pending applications for this job
      await supabase
          .from('applications')
          .update({'status': 'rejected'})
          .eq('job_id', jobId)
          .eq('status', 'pending');

      return bookingResponse;
    } catch (e) {
      throw Exception(
          'Failed to accept application $applicationId: $e');
    }
  }

  /// Rejects an application by updating its status.
  Future<void> rejectApplication(String applicationId) async {
    try {
      await supabase
          .from('applications')
          .update({'status': 'rejected'}).eq('id', applicationId);
    } catch (e) {
      throw Exception(
          'Failed to reject application $applicationId: $e');
    }
  }
}
