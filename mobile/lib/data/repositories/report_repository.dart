import '../../config/supabase_config.dart';

class ReportRepository {
  /// Creates a new report (e.g., reporting a user, job, or content).
  Future<void> createReport(Map<String, dynamic> data) async {
    try {
      await supabase.from('reports').insert(data);
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  /// Fetches reports submitted by the current user, paginated.
  Future<List<Map<String, dynamic>>> getMyReports({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('reports')
          .select('*')
          .eq('reporter_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get reports: $e');
    }
  }

  /// Fetches a single report by ID.
  Future<Map<String, dynamic>> getReportById(String reportId) async {
    try {
      final response = await supabase
          .from('reports')
          .select('*')
          .eq('id', reportId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to get report $reportId: $e');
    }
  }
}
