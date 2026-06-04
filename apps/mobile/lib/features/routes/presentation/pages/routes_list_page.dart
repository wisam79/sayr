import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/routes_bloc.dart';
import '../bloc/routes_event.dart';
import '../bloc/routes_state.dart';

class RoutesListPage extends StatelessWidget {
  const RoutesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routesTitle),
      ),
      body: BlocBuilder<RoutesBloc, RoutesState>(
        builder: (context, state) {
          return switch (state) {
            RoutesInitial() => const LoadingWidget(),
            RoutesLoading() => const LoadingWidget(),
            RoutesError(:final failure) => AppErrorWidget(
                message: failure.message ?? 'حدث خطأ',
                onRetry: () {
                  context.read<RoutesBloc>().add(const RoutesLoadRequested());
                },
              ),
            RoutesLoaded(:final routes) when routes.isEmpty => const EmptyState(
                icon: Icons.directions_bus_outlined,
                title: 'لا توجد خطوط متاحة',
                subtitle: 'حاول مرة أخرى لاحقاً',
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
                        // TODO: Navigate to route details
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
