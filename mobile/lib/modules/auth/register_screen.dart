import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../data/constants/nigerian_locations.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_dropdown.dart';
import '../../widgets/common/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _authController = Get.find<AuthController>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _registrationComplete = false;

  String? _selectedState;
  String? _selectedLga;

  // --- Validators ---

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Name must be less than 100 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

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

  // --- Register action ---

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = '+234${_phoneController.text.trim()}';
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();

    try {
      await _authController.signUp(
        email: email,
        password: password,
        metadata: {
          'full_name': name,
          'phone': phone,
          'address': address,
          'city': city,
          'state': _selectedState,
          'role': 'client',
        },
      );

      if (!mounted) return;
      setState(() {
        _registrationComplete = true;
      });
    } catch (_) {
      // Error is already handled in AuthController via AppSnackbar
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          _registrationComplete ? 'Account Verification' : 'Registration',
          style: AppTextStyles.h4,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: _registrationComplete ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  // --- Success View (Email Confirmation) ---

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        // Green circle with email icon
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.lg),

        const Text(
          'Check Your Email',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.md),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              const TextSpan(text: "We've sent a confirmation link to\n"),
              TextSpan(
                text: _emailController.text.trim(),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const TextSpan(
                text:
                    '. Please verify your email to activate your Handymenskills account.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.xl),

        // Go to Sign In button
        AppButton(
          label: 'Go to Sign In',
          trailingIcon: Icons.arrow_forward,
          onPressed: () => context.go(AppRoutes.login),
        ),
        const SizedBox(height: AppDimensions.md),

        // Resend Confirmation Email button
        AppButton(
          label: 'Resend Confirmation Email',
          type: AppButtonType.outline,
          onPressed: () {
            _authController.resendConfirmation(
              email: _emailController.text.trim(),
            );
          },
        ),
        const SizedBox(height: AppDimensions.lg),

        // Help text
        Text(
          "Didn't receive the email? Check your spam folder or contact support@handymenskills.com",
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.xxl),
      ],
    );
  }

  // --- Form View ---

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.md),

          // Title — left aligned per UI
          const Text('Create Account', style: AppTextStyles.h2),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Sign up to find skilled workers near you',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.xl),

          // Full name
          AppTextField(
            label: 'Full name',
            hint: 'John Doe',
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: _validateName,
            suffixIcon:
                const Icon(Icons.person_outline, color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.md),

          // Email
          AppTextField(
            label: 'Email address',
            hint: 'email@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
            suffixIcon:
                const Icon(Icons.mail_outline, color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.md),

          // Phone
          AppTextField(
            label: 'Phone number',
            hint: '8012345678',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: _validatePhone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            prefixIcon: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: AppDimensions.xs),
                  Text(
                    '+234',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.xs),
                  Container(width: 1, height: 24, color: AppColors.border),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Street Address
          AppTextField(
            label: 'Street address',
            hint: '123 Harmony St',
            controller: _addressController,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
            suffixIcon:
                const Icon(Icons.home_outlined, color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.md),

          // City
          AppTextField(
            label: 'City',
            hint: 'Ikeja',
            controller: _cityController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            suffixIcon: const Icon(Icons.location_city_outlined,
                color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.md),

          // State and LGA side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: 'State',
                  hint: 'Select State',
                  value: _selectedState,
                  items: NigerianLocations.states
                      .map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedState = val;
                      _selectedLga = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: AppDropdown<String>(
                  label: 'LGA',
                  hint: 'Select LGA',
                  value: _selectedLga,
                  items: _selectedState != null
                      ? NigerianLocations.lgasForState(_selectedState!)
                          .map((l) =>
                              DropdownMenuItem(value: l, child: Text(l)))
                          .toList()
                      : [],
                  onChanged: _selectedState == null
                      ? null
                      : (val) => setState(() => _selectedLga = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // Password
          AppTextField(
            label: 'Password',
            hint: '\u2022\u2022\u2022\u2022\u2022\u2022',
            controller: _passwordController,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            validator: _validatePassword,
            prefixIcon:
                const Icon(Icons.lock_outline, color: AppColors.textHint),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textHint,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Confirm password
          AppTextField(
            label: 'Confirm password',
            hint: '\u2022\u2022\u2022\u2022\u2022\u2022',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            validator: _validateConfirmPassword,
            prefixIcon:
                const Icon(Icons.lock_reset_outlined, color: AppColors.textHint),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textHint,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          const SizedBox(height: AppDimensions.xxl),

          // Register button
          Obx(
            () => AppButton(
              label: 'Create Account',
              onPressed: _onRegister,
              isLoading: _authController.isLoading.value,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Sign In',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }
}
