import 'package:supabase_flutter/supabase_flutter.dart';

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
        'job_id': jobId,
        'cover_letter': coverLetter,
        'proposed_price': proposedPrice,
      };
      if (estimatedDuration != null) {
        params['estimated_duration'] = estimatedDuration;
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

  /// Fetches applications submitted by the given [workerId].
  /// Optionally filters by [status].
  Future<List<Map<String, dynamic>>> getMyApplications(
    String workerId, {
    String? status,
  }) async {
    try {
      var query = supabase
          .from('applications')
          .select('*, jobs(*, categories(*), profiles!jobs_client_id_fkey(*))')
          .eq('worker_id', workerId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Failed to get applications for worker $workerId: $e');
    }
  }

  /// Fetches all applications for a specific [jobId] with worker profiles.
  Future<List<Map<String, dynamic>>> getJobApplications(
    String jobId,
  ) async {
    try {
      final response = await supabase
          .from('applications')
          .select('*, profiles(*), worker_profiles(*)')
          .eq('job_id', jobId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Failed to get applications for job $jobId: $e');
    }
  }

  /// Accepts an application by updating its status.
  Future<void> acceptApplication(String applicationId) async {
    try {
      await supabase
          .from('applications')
          .update({'status': 'accepted'}).eq('id', applicationId);
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
