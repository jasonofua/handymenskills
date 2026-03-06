import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../widgets/common/app_snackbar.dart';

class ConnectivityController extends GetxController {
  final RxBool isConnected = true.obs;
  StreamSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    _checkConnectivity();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    isConnected.value = !result.contains(ConnectivityResult.none);
  }

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    final connected = !result.contains(ConnectivityResult.none);
    if (isConnected.value && !connected) {
      AppSnackbar.warning('No internet connection');
    } else if (!isConnected.value && connected) {
      AppSnackbar.success('Back online');
    }
    isConnected.value = connected;
  }
}
