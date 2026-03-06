import 'package:supabase_flutter/supabase_flutter.dart';

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
}
