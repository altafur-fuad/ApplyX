import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

/// Onboarding data model for each page.
class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// Onboarding screen — 3 short visual steps.
///
/// design.md § 6.2:
/// 1. Define your goal.
/// 2. Let your agents do the research.
/// 3. Review and approve actions.
/// CTA: "Get Started"
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.flag_outlined,
      title: 'Define your goal',
      description:
          'Tell us what you\'re looking for — internships, research opportunities, hackathons — in your own words.',
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_outlined,
      title: 'Let your agents work',
      description:
          'Your AI agents research opportunities, check eligibility, compare your profile, and prepare application materials.',
    ),
    _OnboardingPage(
      icon: Icons.verified_user_outlined,
      title: 'Review and approve',
      description:
          'You stay in control. Review what the agents found and approve actions before anything is sent externally.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onGetStarted() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: TextButton(
                    onPressed: _onGetStarted,
                    child: Text(
                      'Skip',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPageView(page: _pages[index]);
                  },
                ),
              ),

              // Indicators
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: AppColors.primary,
                    dotColor: AppColors.border,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                    spacing: 6,
                  ),
                ),
              ),

              // CTA button
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.section),
                child: AppPrimaryButton(
                  label: _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Next',
                  onPressed: _onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual onboarding page content.
class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with subtle gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.aiAccent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              page.icon,
              size: 52,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            page.title,
            style: AppTypography.h1(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            page.description,
            style: AppTypography.body(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
