import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_button.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final _errorController = StreamController<ErrorAnimationType>();

  Timer? _countdownTimer;
  int _remainingSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _remainingSeconds = 60;
      _canResend = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_remainingSeconds <= 1) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _remainingSeconds = 0;
              _canResend = true;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _remainingSeconds--;
            });
          }
        }
      },
    );
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _maskedPhone {
    final phone = widget.phone;
    if (phone.length <= 6) return phone;
    final visiblePrefix = phone.substring(0, phone.length - 4);
    return '$visiblePrefix****';
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;

    final success = await _authController.verifyOtp(widget.phone, otp);

    if (!mounted) return;

    if (success) {
      // Check if profile exists (has a name set) to determine next step
      await _authController.refreshProfile();

      if (!mounted) return;

      final hasProfile = _authController.userName.isNotEmpty;
      final hasRole = _authController.userRole.value.isNotEmpty;

      if (hasProfile && hasRole) {
        // Existing user with complete profile
        if (_authController.isWorker) {
          context.go(AppRoutes.workerDashboard);
        } else {
          context.go(AppRoutes.clientDashboard);
        }
      } else if (hasProfile && !hasRole) {
        // Has profile but no role
        context.go(AppRoutes.roleSelection);
      } else {
        // New user - needs registration
        context.go(AppRoutes.register);
      }
    } else {
      _errorController.add(ErrorAnimationType.shake);
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    try {
      await _authController.signInWithOtp(widget.phone);
      _startCountdown();
    } catch (_) {
      // Error is already handled in AuthController via AppSnackbar
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _errorController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.lg),

              // Header icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sms_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              // Title
              Text(
                'Verify Your Number',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'Enter the code sent to $_maskedPhone',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.xxl),

              // OTP input
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                errorAnimationController: _errorController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.scale,
                animationDuration: const Duration(milliseconds: 200),
                enableActiveFill: true,
                autoFocus: true,
                cursorColor: AppColors.primary,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.white,
                  inactiveFillColor: AppColors.background,
                  selectedFillColor: AppColors.white,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  selectedColor: AppColors.primary,
                  errorBorderColor: AppColors.error,
                ),
                onCompleted: _verifyOtp,
                onChanged: (_) {},
              ),
              const SizedBox(height: AppDimensions.lg),

              // Verify button
              Obx(
                () => AppButton(
                  label: 'Verify',
                  onPressed: () => _verifyOtp(_otpController.text),
                  isLoading: _authController.isLoading.value,
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // Resend section
              Column(
                children: [
                  if (!_canResend)
                    Text(
                      'Resend code in $_formattedTime',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (_canResend)
                    Obx(
                      () => TextButton(
                        onPressed: _authController.isLoading.value
                            ? null
                            : _resendOtp,
                        child: Text(
                          'Resend Code',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }
}
