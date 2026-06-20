import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/boarding/presentation/bloc/boarding_scanner_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Driver-side page that scans student QR codes and lists boarded passengers.
class BoardingScannerPage extends StatelessWidget {
  /// Creates a [BoardingScannerPage].
  const BoardingScannerPage({required this.tripId, super.key});
  final TripId tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoardingScannerCubit>(
      create: (_) => BoardingScannerCubit(
        boardingRepository: sl<BoardingRepository>(),
        tripId: tripId,
      )..start(),
      child: const _BoardingScannerView(),
    );
  }
}

class _BoardingScannerView extends StatefulWidget {
  const _BoardingScannerView();

  @override
  State<_BoardingScannerView> createState() => _BoardingScannerViewState();
}

class _BoardingScannerViewState extends State<_BoardingScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final cubit = context.read<BoardingScannerCubit>();
    final state = cubit.state;
    if (state is BoardingScannerReady && state.isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    await cubit.processToken(raw);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.boardingScannerTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _controller.toggleTorch,
            tooltip: l10n.boardingToggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _controller.switchCamera,
            tooltip: l10n.boardingSwitchCamera,
          ),
        ],
      ),
      body: BlocConsumer<BoardingScannerCubit, BoardingScannerState>(
        listener: (context, state) {
          if (state is BoardingScannerReady && state.lastScan != null) {
            final scan = state.lastScan!;
            if (scan is BoardingScanSuccess) {
              SystemSound.play(SystemSoundType.click);

              SayrFlash.success(
                context,
                l10n.boardingScanSuccess(scan.record.studentName ?? ''),
              );
            } else if (scan is BoardingScanFailure) {
              SystemSound.play(SystemSoundType.click);

              SayrFlash.error(
                context,
                scan.failure.toLocalizedString(context),
              );
            }
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                context.read<BoardingScannerCubit>().clearLastScan();
              }
            });
          }
        },
        builder: (context, state) {
          final isProcessing =
              state is BoardingScannerReady && state.isProcessing;

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    if (isProcessing)
                      const ColoredBox(
                        color: Colors.black54,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: _PassengerList(state: state),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PassengerList extends StatelessWidget {
  const _PassengerList({required this.state});
  final BoardingScannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final currentState = state;
    if (currentState is BoardingScannerError) {
      return Center(
        child: Text(
          currentState.failure.toLocalizedString(context),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
      );
    }
    final passengers = currentState is BoardingScannerReady
        ? currentState.passengers
        : <BoardingRecord>[];
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.boardingPassengers(passengers.length),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: passengers.isEmpty
                ? Center(
                    child: Text(
                      l10n.boardingNoPassengersYet,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: passengers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = passengers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (record.studentName ?? '?').characters.first,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          record.studentName ?? l10n.boardingUnknownStudent,
                        ),
                        subtitle: Text(
                          DateFormat.Hm().format(record.boardedAt),
                        ),
                        trailing: Icon(
                          record.method == BoardingMethod.qrScan
                              ? Icons.qr_code
                              : Icons.edit,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
