import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authController = Get.find<AuthController>();

  String _selectedCountryCode = AppConstants.countryCode;

  static const List<_CountryCode> _countryCodes = [
    _CountryCode(code: '+234', flag: '\u{1F1F3}\u{1F1EC}', name: 'Nigeria'),
    _CountryCode(code: '+233', flag: '\u{1F1EC}\u{1F1ED}', name: 'Ghana'),
    _CountryCode(code: '+254', flag: '\u{1F1F0}\u{1F1EA}', name: 'Kenya'),
    _CountryCode(code: '+27', flag: '\u{1F1FF}\u{1F1E6}', name: 'South Africa'),
    _CountryCode(code: '+1', flag: '\u{1F1FA}\u{1F1F8}', name: 'United States'),
    _CountryCode(code: '+44', flag: '\u{1F1EC}\u{1F1E7}', name: 'United Kingdom'),
  ];

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 11) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final fullPhone = '$_selectedCountryCode$phone';

    try {
      await _authController.signInWithOtp(fullPhone);

      if (!mounted) return;
      context.push(AppRoutes.otp, extra: fullPhone);
    } catch (_) {
      // Error is already handled in AuthController via AppSnackbar
    }
  }

  void _showCountryCodePicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.lg,
                  AppDimensions.screenPadding,
                  AppDimensions.sm,
                ),
                child: Text('Select Country Code', style: AppTextStyles.h4),
              ),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _countryCodes.length,
                itemBuilder: (context, index) {
                  final country = _countryCodes[index];
                  final isSelected = country.code == _selectedCountryCode;
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country.name, style: AppTextStyles.bodyLarge),
                    trailing: Text(
                      country.code,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country.code;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const SizedBox(height: AppDimensions.md),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // App logo
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Title
                Text(
                  'Welcome Back',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  'Enter your phone number to continue',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.xxl),

                // Phone input
                AppTextField(
                  label: 'Phone Number',
                  hint: '8012345678',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: _validatePhone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  prefixIcon: GestureDetector(
                    onTap: _showCountryCodePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: AppDimensions.xs),
                          Text(
                            _selectedCountryCode,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.xs),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppDimensions.xs),
                          Container(
                            width: 1,
                            height: 24,
                            color: AppColors.border,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),

                // Send OTP button
                Obx(
                  () => AppButton(
                    label: 'Send OTP',
                    onPressed: _sendOtp,
                    isLoading: _authController.isLoading.value,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Text(
                        'Register',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
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
      ),
    );
  }
}

// -- Country code data model --

class _CountryCode {
  final String code;
  final String flag;
  final String name;

  const _CountryCode({
    required this.code,
    required this.flag,
    required this.name,
  });
}
