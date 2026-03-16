import '../../config/supabase_config.dart';

class SkillRepository {
  /// Fetches all categories ordered by sort_order.
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await supabase
          .from('categories')
          .select()
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Fetches skills filtered by [categoryId].
  Future<List<Map<String, dynamic>>> getSkillsByCategory(
    String categoryId,
  ) async {
    try {
      final response = await supabase
          .from('skills')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Failed to get skills for category $categoryId: $e');
    }
  }

  /// Fetches all active skills with their associated category.
  Future<List<Map<String, dynamic>>> getAllSkills() async {
    try {
      final response = await supabase
          .from('skills')
          .select('*, categories(*)')
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get all skills: $e');
    }
  }

  /// Fetches skill names for the given list of [ids].
  Future<List<String>> getSkillNamesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await supabase
          .from('skills')
          .select('id, name')
          .inFilter('id', ids);
      final results = List<Map<String, dynamic>>.from(response);
      return results.map((r) => r['name']?.toString() ?? '').toList();
    } catch (e) {
      return [];
    }
  }

  /// Adds a skill to a worker's profile.
  Future<void> addWorkerSkill(Map<String, dynamic> skillData) async {
    try {
      await supabase.from('worker_skills').insert(skillData);
    } catch (e) {
      throw Exception('Failed to add worker skill: $e');
    }
  }

  /// Removes a worker skill by its [workerSkillId].
  Future<void> removeWorkerSkill(String workerSkillId) async {
    try {
      await supabase
          .from('worker_skills')
          .delete()
          .eq('id', workerSkillId);
    } catch (e) {
      throw Exception(
          'Failed to remove worker skill $workerSkillId: $e');
    }
  }

  /// Updates a worker skill by [id] with [data].
  Future<void> updateWorkerSkill(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await supabase.from('worker_skills').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update worker skill $id: $e');
    }
  }
}
