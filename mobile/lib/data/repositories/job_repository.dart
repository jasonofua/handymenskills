import 'dart:io';

import '../../config/supabase_config.dart';

class JobRepository {
  /// Fetches a paginated list of jobs with optional filters.
  Future<List<Map<String, dynamic>>> getJobs({
    String? status,
    String? categoryId,
    String? urgency,
    double? budgetMin,
    double? budgetMax,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = supabase
          .from('jobs')
          .select('*, categories(*), profiles!jobs_client_id_fkey(*)');

      if (status != null) {
        query = query.eq('status', status);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (urgency != null) {
        query = query.eq('urgency', urgency);
      }
      if (budgetMin != null) {
        query = query.gte('budget_max', budgetMin);
      }
      if (budgetMax != null) {
        query = query.lte('budget_min', budgetMax);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get jobs: $e');
    }
  }

  /// Fetches a single job by [id] with all related data.
  Future<Map<String, dynamic>> getJobById(String id) async {
    try {
      final response = await supabase
          .from('jobs')
          .select(
              '*, categories(*), profiles!jobs_client_id_fkey(*), applications(*, worker_profiles(*, profiles(*))), bookings(*, worker:profiles!bookings_worker_id_fkey(*), reviews(*))')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to get job $id: $e');
    }
  }

  /// Creates a new job and returns the created record.
  Future<Map<String, dynamic>> createJob(
    Map<String, dynamic> data,
  ) async {
    try {
      final response =
          await supabase.from('jobs').insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to create job: $e');
    }
  }

  /// Updates an existing job by [id] with [data].
  Future<void> updateJob(String id, Map<String, dynamic> data) async {
    try {
      await supabase.from('jobs').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update job $id: $e');
    }
  }

  /// Deletes a job by [id].
  Future<void> deleteJob(String id) async {
    try {
      await supabase.from('jobs').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete job $id: $e');
    }
  }

  /// Searches for jobs using full-text or location-based search via RPC.
  Future<List<Map<String, dynamic>>> searchJobs(
    String query, {
    double? lat,
    double? lng,
    int? radiusKm,
    String? categoryId,
    String? urgency,
    double? budgetMin,
    double? budgetMax,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_query_text': query,
      };
      if (lat != null) params['p_lat'] = lat;
      if (lng != null) params['p_lng'] = lng;
      if (radiusKm != null) params['p_radius_km'] = radiusKm;
      if (categoryId != null) params['p_category_id'] = categoryId;
      if (urgency != null) params['p_urgency'] = urgency;
      if (budgetMin != null) params['p_budget_min'] = budgetMin;
      if (budgetMax != null) params['p_budget_max'] = budgetMax;

      final response = await supabase.rpc(
        'search_jobs',
        params: params,
      );
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to search jobs: $e');
    }
  }

  /// Fetches all jobs created by the given [clientId].
  Future<List<Map<String, dynamic>>> getMyJobs(String clientId) async {
    try {
      final response = await supabase
          .from('jobs')
          .select('*, categories(*), bookings(*, reviews(overall_rating))')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get jobs for client $clientId: $e');
    }
  }

  /// Uploads a job image and returns the public URL.
  Future<String> uploadJobImage(String jobId, File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$jobId/$fileName';

      await supabase.storage.from('job-images').upload(filePath, file);

      final publicUrl =
          supabase.storage.from('job-images').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload job image for $jobId: $e');
    }
  }
}
