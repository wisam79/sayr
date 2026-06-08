import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_event.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Page responsible for displaying the list of active routes.
class RoutesListPage extends StatefulWidget {
  /// Creates a [RoutesListPage].
  const RoutesListPage({super.key, this.showAppBar = true});

  /// Whether to show the app bar on this page.
  final bool showAppBar;

  @override
  State<RoutesListPage> createState() => _RoutesListPageState();
}

class _RoutesListPageState extends State<RoutesListPage> {
  @override
  void initState() {
    super.initState();
    context.read<RoutesBloc>().add(const RoutesLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(l10n.routesTitle),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchRoutes,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (query) {
                context.read<RoutesBloc>().add(RoutesSearchRequested(query));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<RoutesBloc, RoutesState>(
              builder: (context, state) {
                return switch (state) {
                  RoutesInitial() || RoutesLoading() => Skeletonizer(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        itemCount: 3,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          return RouteCard(
                            title: 'Baghdad University Campus Route',
                            startLocation: 'Karrada District Baghdad',
                            endLocation: 'Al-Jadriya Campus University',
                            availableSeats: 10,
                            capacity: 25,
                            formattedPrice: '5,000 IQD',
                            hasSeats: true,
                            availableLabel: l10n.available,
                            completedLabel: l10n.full,
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                  RoutesError(:final failure) => AppErrorWidget(
                      message: failure.message ?? l10n.error,
                      title: l10n.error,
                      retryLabel: l10n.retry,
                      onRetry: () {
                        context
                            .read<RoutesBloc>()
                            .add(const RoutesLoadRequested());
                      },
                    ),
                  RoutesLoaded(:final routes) when routes.isEmpty => EmptyState(
                      icon: Icons.directions_bus_outlined,
                      title: l10n.noRoutesAvailable,
                      subtitle: l10n.tryAgainLater,
                    ),
                  RoutesLoaded(:final routes) => RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<RoutesBloc>()
                            .add(const RoutesLoadRequested());
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        itemCount: routes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          return RouteCard(
                            title: route.title,
                            startLocation: route.startLocation,
                            endLocation: route.endLocation,
                            availableSeats: route.availableSeats,
                            capacity: route.capacity,
                            formattedPrice: route.price.format(),
                            hasSeats: route.hasSeats,
                            availableLabel: l10n.available,
                            completedLabel: l10n.full,
                            onTap: () {
                              context.push(
                                '/route/${route.id.value}',
                                extra: route,
                              );
                            },
                          );
                        },
                      ),
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
