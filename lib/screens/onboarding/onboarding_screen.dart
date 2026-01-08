import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/local_storage_service.dart';
import '../../l10n/app_localizations.dart';

/// Écran d'onboarding
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPageData> _getPages(AppLocalizations? l10n) => [
    OnboardingPageData(
      icon: Icons.account_balance_wallet,
      title: l10n?.onboardingTrackTitle ?? 'Track your expenses',
      description: l10n?.onboardingTrackDesc ?? 'Add your expenses in less than 10 seconds and keep control of your money.',
      color: AppColors.primary,
    ),
    OnboardingPageData(
      icon: Icons.pie_chart,
      title: l10n?.onboardingVisualizeTitle ?? 'Visualize your finances',
      description: l10n?.onboardingVisualizeDesc ?? 'Clear charts to understand where your money goes each month.',
      color: AppColors.secondary,
    ),
    OnboardingPageData(
      icon: Icons.lightbulb,
      title: l10n?.onboardingTipsTitle ?? 'Personalized tips',
      description: l10n?.onboardingTipsDesc ?? 'Receive smart tips to better manage your budget.',
      color: AppColors.warning,
    ),
    OnboardingPageData(
      icon: Icons.emoji_events,
      title: l10n?.onboardingGoalsTitle ?? 'Achieve your goals',
      description: l10n?.onboardingGoalsDesc ?? 'Set savings goals and track your progress with badges.',
      color: AppColors.success,
    ),
  ];

  void _nextPage(int pageCount) {
    if (_currentPage < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await LocalStorageService.setOnboardingComplete(true);
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _getPages(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(l10n?.skip ?? 'Skip'),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(pages[index]);
                },
              ),
            ),
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? pages[_currentPage].color
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Next button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _nextPage(pages.length),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pages[_currentPage].color,
                  ),
                  child: Text(
                    _currentPage == pages.length - 1
                        ? (l10n?.getStarted ?? 'Get Started')
                        : (l10n?.next ?? 'Next'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
