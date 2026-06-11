import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/boarding/presentation/bloc/boarding_qr_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Student-side page that shows a rotating QR code for boarding.
class BoardingQrPage extends StatelessWidget {
  const BoardingQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoardingQrCubit>(
      create: (_) =>
          BoardingQrCubit(boardingRepository: sl<BoardingRepository>())
            ..start(),
      child: const _BoardingQrView(),
    );
  }
}

class _BoardingQrView extends StatelessWidget {
  const _BoardingQrView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.boardingTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<BoardingQrCubit, BoardingQrState>(
        listenWhen: (prev, curr) {
          final prevRecord =
              prev is BoardingQrReady ? prev.proximityRecord : null;
          final currRecord =
              curr is BoardingQrReady ? curr.proximityRecord : null;
          return prevRecord == null && currRecord != null;
        },
        listener: (context, state) {
          if (state is BoardingQrReady && state.proximityRecord != null) {
            final navigator = Navigator.of(context);
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: Lottie.network(
                            'https://lottie.host/7ca67c51-57d4-469b-9861-12c8b74681f2/Z7oH1oWwK8.json',
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 80,
                              );
                            },
                            repeat: false,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.boardingProximitySuccess,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
            final rootNavigator = Navigator.of(context, rootNavigator: true);
            Future.delayed(const Duration(seconds: 2), () {
              if (rootNavigator.mounted) {
                rootNavigator.pop();
              }
              if (navigator.mounted) {
                navigator.pop();
              }
            });
          }
        },
        child: BlocBuilder<BoardingQrCubit, BoardingQrState>(
          builder: (context, state) {
            return switch (state) {
              BoardingQrInitial() ||
              BoardingQrLoading() =>
                const Center(child: CircularProgressIndicator()),
              BoardingQrNoActiveTrip() => _StatusMessage(
                  icon: Icons.directions_bus_outlined,
                  title: l10n.boardingNoActiveTrip,
                  subtitle: l10n.boardingNoActiveTripHint,
                ),
              BoardingQrError(:final failure) => _StatusMessage(
                  icon: Icons.error_outline,
                  title: l10n.boardingError,
                  subtitle: failure.toLocalizedString(context),
                ),
              BoardingQrReady() => _ReadyView(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state});
  final BoardingQrReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (state.proximityOtp != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bluetooth_searching,
                          color: AppColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.boardingNearBus,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.boardingNearBusHint,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.isSubmittingProximity)
                      const Center(child: CircularProgressIndicator())
                    else
                      SwipeButton.expand(
                        thumb: const Icon(
                          Icons.double_arrow_rounded,
                          color: Colors.white,
                        ),
                        activeThumbColor: AppColors.success,
                        activeTrackColor:
                            AppColors.success.withValues(alpha: 0.1),
                        child: Text(
                          l10n.slideToBoard,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onSwipe: () async {
                          try {
                            final position =
                                await Geolocator.getCurrentPosition(
                              locationSettings: const LocationSettings(
                                accuracy: LocationAccuracy.high,
                                timeLimit: Duration(seconds: 5),
                              ),
                            );
                            if (context.mounted) {
                              await context
                                  .read<BoardingQrCubit>()
                                  .submitProximityCheckIn(
                                    Coordinates(
                                      latitude: position.latitude,
                                      longitude: position.longitude,
                                    ),
                                  );
                            }
                          } on TimeoutException {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.locationUnavailable),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(l10n.locationPermissionRequired),
                                ),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.boardingShowQrToDriver,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: PrettyQrView.data(
                    data: state.token,
                    decoration: const PrettyQrDecoration(
                      shape: PrettyQrSmoothSymbol(
                        color: AppColors.textPrimary,
                      ),
                      image: PrettyQrDecorationImage(
                        image: AssetImage('assets/icons/app_icon.png'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _CountdownIndicator(secondsLeft: state.secondsUntilRefresh),
            const SizedBox(height: 12),
            Text(
              l10n.boardingRotatesAutomatically,
              style:
                  textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownIndicator extends StatelessWidget {
  const _CountdownIndicator({required this.secondsLeft});
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = secondsLeft / 60.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${secondsLeft}s',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
