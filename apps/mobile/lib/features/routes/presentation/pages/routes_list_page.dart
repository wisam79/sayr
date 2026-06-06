import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_event.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

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
      body: BlocBuilder<RoutesBloc, RoutesState>(
        builder: (context, state) {
          return switch (state) {
            RoutesInitial() || RoutesLoading() => LoadingWidget(
                message: l10n.loading,
              ),
            RoutesError(:final failure) => AppErrorWidget(
                message: failure.message ?? l10n.error,
                onRetry: () {
                  context.read<RoutesBloc>().add(const RoutesLoadRequested());
                },
              ),
            RoutesLoaded(:final routes) when routes.isEmpty => EmptyState(
                icon: Icons.directions_bus_outlined,
                title: l10n.noRoutesAvailable,
                subtitle: l10n.tryAgainLater,
              ),
            RoutesLoaded(:final routes) => RefreshIndicator(
                onRefresh: () async {
                  context.read<RoutesBloc>().add(const RoutesLoadRequested());
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  itemCount: routes.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return RouteCard(
                      route: routes[index],
                      onTap: () {
                        context.push(
                          '/route/${routes[index].id.value}',
                          extra: routes[index],
                        );
                      },
                    );
                  },
                ),
              ),
          };
        },
      ),
    );
  }
}
