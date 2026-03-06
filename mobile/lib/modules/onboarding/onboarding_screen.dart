import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.search_rounded,
      title: 'Find Skilled Workers',
      subtitle:
          'Discover verified artisans and professionals near you. '
          'From plumbers to electricians, find the right person for any job.',
    ),
    _OnboardingPageData(
      icon: Icons.task_alt_rounded,
      title: 'Get Jobs Done',
      subtitle:
          'Post your job, receive applications, and hire the best worker. '
          'Track progress in real-time from start to finish.',
    ),
    _OnboardingPageData(
      icon: Icons.lock_rounded,
      title: 'Secure Payments',
      subtitle:
          'Pay safely through our escrow system. Funds are released only '
          'when you confirm the job is completed to your satisfaction.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _onNext() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {
      // Continue even if preferences fail to save
    }

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppDimensions.md,
                  right: AppDimensions.screenPadding,
                ),
                child: TextButton(
                  onPressed: _isLastPage ? null : _onSkip,
                  child: Text(
                    _isLastPage ? '' : 'Skip',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPage(data: page);
                },
              ),
            ),

            // Bottom section: indicator + button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.lg,
                AppDimensions.screenPadding,
                AppDimensions.xl,
              ),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.border,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  AppButton(
                    label: _isLastPage ? 'Get Started' : 'Next',
                    onPressed: _onNext,
                    icon: _isLastPage ? Icons.arrow_forward_rounded : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Data model for onboarding pages --

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// -- Individual onboarding page widget --

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.xxl),
          Text(
            data.title,
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            data.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
