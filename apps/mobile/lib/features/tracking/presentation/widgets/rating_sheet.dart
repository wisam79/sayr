import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/trip_details_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Bottom sheet for submitting a trip rating.
///
/// The [trip] and [driverName] are required. The sheet calls
/// [TripDetailsCubit.submitTripRating] on submission.
class RatingSheet extends StatefulWidget {
  const RatingSheet({required this.trip, required this.driverName, super.key});

  final Trip trip;
  final String driverName;

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingState {
  const _RatingState({
    required this.selectedRating,
    required this.isSubmitting,
  });
  final int selectedRating;
  final bool isSubmitting;
}

class _RatingSheetState extends State<RatingSheet> {
  final _commentController = TextEditingController();
  final ValueNotifier<_RatingState> _ratingStateNotifier =
      ValueNotifier(const _RatingState(selectedRating: 0, isSubmitting: false));

  @override
  void dispose() {
    _commentController.dispose();
    _ratingStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ValueListenableBuilder<_RatingState>(
          valueListenable: _ratingStateNotifier,
          builder: (context, ratingState, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.rateTrip,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.howWasYourTrip,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (widget.driverName.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.driverName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    final isSelected = starValue <= ratingState.selectedRating;
                    return IconButton(
                      icon: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        color: isSelected ? Colors.amber : AppColors.textMuted,
                        size: 44,
                      ),
                      onPressed: () {
                        _ratingStateNotifier.value = _RatingState(
                          selectedRating: starValue,
                          isSubmitting: ratingState.isSubmitting,
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.ratingCommentHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: l10n.submitRating,
                  isLoading: ratingState.isSubmitting,
                  onPressed: ratingState.selectedRating == 0
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final rootNavigator =
                              Navigator.of(context, rootNavigator: true);
                          final cubit = context.read<TripDetailsCubit>();

                          _ratingStateNotifier.value = _RatingState(
                            selectedRating: ratingState.selectedRating,
                            isSubmitting: true,
                          );
                          final success = await cubit.submitTripRating(
                            tripId: widget.trip.id,
                            driverId: widget.trip.driverId,
                            rating: ratingState.selectedRating,
                            comment: _commentController.text.trim().isEmpty
                                ? null
                                : _commentController.text.trim(),
                          );
                          if (context.mounted) {
                            _ratingStateNotifier.value = _RatingState(
                              selectedRating: ratingState.selectedRating,
                              isSubmitting: false,
                            );
                            if (success) {
                              navigator.pop();
                              unawaited(
                                showDialog<void>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.xl),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 120,
                                              width: 120,
                                              child: Lottie.network(
                                                'https://lottie.host/7ca67c51-57d4-469b-9861-12c8b74681f2/Z7oH1oWwK8.json',
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Icon(
                                                    Icons.check_circle,
                                                    color: AppColors.success,
                                                    size: 80,
                                                  );
                                                },
                                                repeat: false,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            Text(
                                              l10n.ratingSuccess,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                              Future.delayed(const Duration(seconds: 2), () {
                                if (rootNavigator.mounted) {
                                  rootNavigator.pop();
                                }
                              });
                            } else {
                              SayrFlash.error(context, l10n.ratingFailed);
                            }
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
        ),
      ),
    );
  }
}
