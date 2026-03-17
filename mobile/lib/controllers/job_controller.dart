import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../data/repositories/job_repository.dart';
import '../data/services/realtime_service.dart';
import '../config/constants.dart';
import '../widgets/common/app_snackbar.dart';
import 'auth_controller.dart';

class JobController extends GetxController {
  final _jobRepo = Get.find<JobRepository>();
  final _authController = Get.find<AuthController>();
  final _realtimeService = Get.find<RealtimeService>();

  RealtimeChannel? _myJobsChannel;
  RealtimeChannel? _jobFeedChannel;

  // Job feed (for workers)
  final RxList<Map<String, dynamic>> jobs = <Map<String, dynamic>>[].obs;
  final RxMap<String, bool> appliedJobIds = <String, bool>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  // Client's jobs
  final RxList<Map<String, dynamic>> myJobs = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingMyJobs = false.obs;

  // Current job detail
  final RxMap<String, dynamic> currentJob = <String, dynamic>{}.obs;
  final RxBool isLoadingDetail = false.obs;

  // Filters
  final RxString selectedCategory = ''.obs;
  final RxString selectedUrgency = ''.obs;
  final RxDouble filterBudgetMin = 0.0.obs;
  final RxDouble filterBudgetMax = 0.0.obs;
  final RxString searchQuery = ''.obs;

  // Creating/editing
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    _myJobsChannel?.unsubscribe();
    _jobFeedChannel?.unsubscribe();
    super.onClose();
  }

  void _subscribeRealtime() {
    final userId = _authController.userId;
    if (userId.isEmpty) return;

    // Client: listen for changes on their own jobs
    _myJobsChannel = _realtimeService.subscribeToMyJobs(
      userId,
      (updated) {
        final id = updated['id']?.toString();
        if (id == null) return;
        final index = myJobs.indexWhere((j) => j['id'] == id);
        if (index != -1) {
          myJobs[index] = {...myJobs[index], ...updated};
          myJobs.refresh();
        }
        if (currentJob['id'] == id) {
          currentJob.assignAll({...currentJob, ...updated});
        }
      },
      (_) => loadMyJobs(),
    );

    // Worker: listen for new open jobs in the feed
    _jobFeedChannel = _realtimeService.subscribeToJobFeed(
      () {
        if (jobs.isNotEmpty) loadJobs(refresh: true);
      },
    );
  }

  Future<void> loadJobs({bool refresh = false}) async {
    try {
      if (refresh) {
        isLoading.value = true;
        hasMore.value = true;
      } else {
        if (!hasMore.value) return;
        isLoadingMore.value = true;
      }

      final offset = refresh ? 0 : jobs.length;
      final data = await _jobRepo.getJobs(
        status: 'open',
        categoryId: selectedCategory.value.isNotEmpty ? selectedCategory.value : null,
        urgency: selectedUrgency.value.isNotEmpty ? selectedUrgency.value : null,
        budgetMin: filterBudgetMin.value > 0 ? filterBudgetMin.value : null,
        budgetMax: filterBudgetMax.value > 0 ? filterBudgetMax.value : null,
        limit: AppConstants.defaultPageSize,
        offset: offset,
      );

      if (refresh) {
        jobs.assignAll(data);
        // Load which jobs this worker has applied to
        await _loadAppliedJobIds();
      } else {
        jobs.addAll(data);
      }
      hasMore.value = data.length >= AppConstants.defaultPageSize;
    } catch (e) {
      AppSnackbar.error('Failed to load jobs');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Loads all job IDs the current worker has applied to.
  Future<void> _loadAppliedJobIds() async {
    try {
      final userId = _authController.userId;
      if (userId.isEmpty) return;

      // Get the worker_profile ID for this user
      final wp = await supabase
          .from('worker_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (wp == null) return;

      final workerProfileId = wp['id'] as String;

      // Get all job IDs this worker has applied to
      final apps = await supabase
          .from('applications')
          .select('job_id')
          .eq('worker_id', workerProfileId);

      final map = <String, bool>{};
      for (final app in apps) {
        map[app['job_id'] as String] = true;
      }
      appliedJobIds.assignAll(map);
    } catch (_) {}
  }

  /// Mark a job as applied locally (called after successful application).
  void markJobAsApplied(String jobId) {
    appliedJobIds[jobId] = true;
  }

  Future<void> searchJobs(String query, {double? lat, double? lng}) async {
    try {
      isLoading.value = true;
      searchQuery.value = query;
      final data = await _jobRepo.searchJobs(
        query,
        lat: lat,
        lng: lng,
        radiusKm: 50,
        categoryId: selectedCategory.value.isNotEmpty ? selectedCategory.value : null,
        urgency: selectedUrgency.value.isNotEmpty ? selectedUrgency.value : null,
        budgetMin: filterBudgetMin.value > 0 ? filterBudgetMin.value : null,
        budgetMax: filterBudgetMax.value > 0 ? filterBudgetMax.value : null,
      );
      jobs.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Search failed');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadJobDetail(String jobId) async {
    try {
      isLoadingDetail.value = true;
      final data = await _jobRepo.getJobById(jobId);
      currentJob.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load job details');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> loadMyJobs() async {
    try {
      isLoadingMyJobs.value = true;
      final data = await _jobRepo.getMyJobs(_authController.userId);
      myJobs.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load your jobs');
    } finally {
      isLoadingMyJobs.value = false;
    }
  }

  Future<Map<String, dynamic>?> createJob(Map<String, dynamic> data) async {
    try {
      isSaving.value = true;
      data['client_id'] = _authController.userId;
      final job = await _jobRepo.createJob(data);
      myJobs.insert(0, job);
      AppSnackbar.success('Job posted successfully');
      return job;
    } catch (e) {
      AppSnackbar.error('Failed to post job');
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      isSaving.value = true;
      await _jobRepo.updateJob(jobId, data);
      final index = myJobs.indexWhere((j) => j['id'] == jobId);
      if (index != -1) {
        myJobs[index] = {...myJobs[index], ...data};
        myJobs.refresh();
      }
      AppSnackbar.success('Job updated');
    } catch (e) {
      AppSnackbar.error('Failed to update job');
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteJob(String jobId) async {
    try {
      await _jobRepo.updateJob(jobId, {'status': 'cancelled'});
      myJobs.removeWhere((j) => j['id'] == jobId);
      AppSnackbar.success('Job deleted');
      return true;
    } catch (e) {
      AppSnackbar.error('Failed to delete job');
      return false;
    }
  }

  void clearFilters() {
    selectedCategory.value = '';
    selectedUrgency.value = '';
    filterBudgetMin.value = 0;
    filterBudgetMax.value = 0;
    searchQuery.value = '';
  }
}
