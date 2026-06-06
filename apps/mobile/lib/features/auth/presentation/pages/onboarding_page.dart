import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/onboarding_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Page responsible for showing onboarding screens to new users.
class OnboardingPage extends StatelessWidget {
  /// Creates an [OnboardingPage].
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final PageController _pageController = PageController();
  List<_OnboardingData>? _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages ??= _buildPages(context);
  }

  List<_OnboardingData> _buildPages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _OnboardingData(
        icon: Icons.directions_bus_filled,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        color: AppColors.primary,
      ),
      _OnboardingData(
        icon: Icons.location_on,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        color: AppColors.secondary,
      ),
      _OnboardingData(
        icon: Icons.security,
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        color: AppColors.success,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    final cubit = context.read<OnboardingCubit>();
    final pages = _pages;
    if (pages == null) return;
    if (cubit.state < pages.length - 1) {
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.skip),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    context.read<OnboardingCubit>().setPage(index),
                itemCount: _pages?.length ?? 0,
                itemBuilder: (context, index) {
                  final page = _pages?[index];
                  if (page == null) return const SizedBox.shrink();
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
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            BlocBuilder<OnboardingCubit, int>(
              builder: (context, currentPage) {
                final pages = _pages;
                if (pages == null) return const SizedBox.shrink();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: BlocBuilder<OnboardingCubit, int>(
                builder: (context, currentPage) {
                  final pages = _pages;
                  final isLast =
                      pages != null && currentPage == pages.length - 1;
                  return PrimaryButton(
                    label: isLast ? l10n.getStarted : l10n.next,
                    onPressed: _onNext,
                  );
                },
              ),
            ),
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
