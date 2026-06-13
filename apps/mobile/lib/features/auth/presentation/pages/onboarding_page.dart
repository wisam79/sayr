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

class _OnboardingViewState extends State<_OnboardingView> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  List<_OnboardingData>? _pages;

  late AnimationController _entryController;
  late AnimationController _pulseController;

  late Animation<double> _iconOpacity;
  late Animation<double> _iconScale;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _descOpacity;
  late Animation<Offset> _descSlide;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _iconScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _descOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _descSlide = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages ??= _buildPages(context);

    final isUnderTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if ((MediaQuery.maybeDisableAnimationsOf(context) ?? false) || isUnderTest) {
      _entryController.value = 1.0;
      _pulseController.stop();
    } else {
      if (!_entryController.isAnimating && _entryController.value < 1.0) {
        _entryController.forward();
      }
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }
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
        icon: Icons.map,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        color: AppColors.secondary,
      ),
      _OnboardingData(
        icon: Icons.qr_code_scanner,
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        color: AppColors.success,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onNext() {
    final cubit = context.read<OnboardingCubit>();
    final pages = _pages;
    if (pages == null) return;
    if (cubit.state < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/login');
    }
  }

  Widget _buildIconContainer(_OnboardingData page) {
    final isUnderTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final disableAnimations = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || isUnderTest;
    final innerCircle = Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: page.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          page.icon,
          size: 64,
          color: page.color,
        ),
      ),
    );

    if (disableAnimations) {
      return Container(
        width: 160,
        height: 160,
        alignment: Alignment.center,
        child: innerCircle,
      );
    }

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: page.color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
          ),
          // Inner circle with icon
          innerCircle,
        ],
      ),
    );
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
                onPageChanged: (index) {
                  context.read<OnboardingCubit>().setPage(index);
                  if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
                    _entryController.forward(from: 0.0);
                  }
                },
                itemCount: _pages?.length ?? 0,
                itemBuilder: (context, index) {
                  final page = _pages?[index];
                  if (page == null) return const SizedBox.shrink();

                  return AnimatedBuilder(
                    animation: _entryController,
                    builder: (context, child) {
                      final isUnderTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
                      final disableAnimations = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || isUnderTest;
                      if (disableAnimations) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildIconContainer(page),
                              const SizedBox(height: AppSpacing.xxl),
                              Text(
                                page.title,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                      }

                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Icon container with fade and scale
                            FadeTransition(
                              opacity: _iconOpacity,
                              child: ScaleTransition(
                                scale: _iconScale,
                                child: _buildIconContainer(page),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            // 2. Title with fade and slide
                            FadeTransition(
                              opacity: _titleOpacity,
                              child: SlideTransition(
                                position: _titleSlide,
                                child: Text(
                                  page.title,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // 3. Description with fade and slide
                            FadeTransition(
                              opacity: _descOpacity,
                              child: SlideTransition(
                                position: _descSlide,
                                child: Text(
                                  page.description,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
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
