import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.directions_bus_filled,
      title: 'تنقل بسهولة',
      description:
          'احجز اشتراكك على خطوط النقل الجامعي بضغطة زر وتابع رحلتك لحظة بلحظة.',
      color: AppColors.primary,
    ),
    _OnboardingData(
      icon: Icons.location_on,
      title: 'تتبع مباشر',
      description:
          'اعرف موقع الباص في الوقت الحقيقي واحصل على إشعارات عند اقترابه.',
      color: AppColors.secondary,
    ),
    _OnboardingData(
      icon: Icons.security,
      title: 'آمن وموثوق',
      description:
          'نظام تراخيص مسبق الدفع يضمن لك مقعدك ويحمي حقوقك.',
      color: AppColors.success,
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('تخطي'),
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
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 80,
                            color: page.color,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                },
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Action button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              child: PrimaryButton(
                label: _currentPage < _pages.length - 1 ? 'التالي' : 'ابدأ الآن',
                onPressed: _onNext,
                icon: _currentPage == _pages.length - 1
                    ? Icons.check
                    : Icons.arrow_forward,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
