import 'package:flutter/material.dart' hide Route;
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../di/di.dart';
import '../../../../l10n/app_localizations.dart';

/// Page showing detailed information about a single route.
class RouteDetailsPage extends StatefulWidget {
  const RouteDetailsPage({this.route, this.routeId, super.key});

  final Route? route;
  final RouteId? routeId;

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  Route? _route;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.route != null) {
      _route = widget.route;
    } else if (widget.routeId != null) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await sl<RouteRepository>().getById(widget.routeId!);
    if (mounted) {
      setState(() {
        _isLoading = false;
        result.fold(
          (failure) =>
              _errorMessage = failure.message ?? 'فشل تحميل تفاصيل الخط',
          (r) => _route = r,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الخط')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _route == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الخط')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'الخط غير موجود'),
              const SizedBox(height: AppSpacing.md),
              if (widget.routeId != null)
                ElevatedButton(
                  onPressed: _loadRoute,
                  child: const Text('إعادة المحاولة'),
                ),
            ],
          ),
        ),
      );
    }

    final route = _route!;

    return Scaffold(
      appBar: AppBar(
        title: Text(route.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            route.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _LocationInfo(
                      icon: Icons.radio_button_checked,
                      color: AppColors.primary,
                      label: l10n.startLocation,
                      value: route.startLocation,
                    ),
                    const Padding(
                      padding: EdgeInsetsDirectional.only(start: 5),
                      child: VerticalDivider(
                        width: 24,
                        thickness: 2,
                        color: AppColors.border,
                      ),
                    ),
                    _LocationInfo(
                      icon: Icons.flag,
                      color: AppColors.secondary,
                      label: l10n.endLocation,
                      value: route.endLocation,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.routeDetails,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DetailRow(
                      icon: Icons.attach_money,
                      label: l10n.price,
                      value: route.price.format(),
                    ),
                    _DetailRow(
                      icon: Icons.event_seat,
                      label: l10n.availableSeats,
                      value: '${route.availableSeats} / ${route.capacity}',
                    ),
                    if (route.departureTime != null)
                      _DetailRow(
                        icon: Icons.schedule,
                        label: l10n.departureTime,
                        value: route.departureTime!,
                      ),
                    if (route.returnTime != null)
                      _DetailRow(
                        icon: Icons.schedule_send,
                        label: l10n.returnTime,
                        value: route.returnTime!,
                      ),
                    if (route.daysOfWeek.isNotEmpty)
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: l10n.operatingDays,
                        value: _formatDays(route.daysOfWeek),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.subscribe,
              icon: Icons.confirmation_number,
              onPressed: route.hasSeats
                  ? () => context.push(
                        '/payment/${route.id.value}/${route.price.inIQD}',
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDays(List<String> days) {
    const dayMap = {
      'sun': 'الأحد',
      'mon': 'الإثنين',
      'tue': 'الثلاثاء',
      'wed': 'الأربعاء',
      'thu': 'الخميس',
      'fri': 'الجمعة',
      'sat': 'السبت',
    };
    return days.map((d) => dayMap[d] ?? d).join('، ');
  }
}

class _LocationInfo extends StatelessWidget {
  const _LocationInfo({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
