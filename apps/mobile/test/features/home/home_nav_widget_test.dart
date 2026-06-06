import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/home_nav_cubit.dart';

void main() {
  group('HomeNavCubit widget integration', () {
    testWidgets('emits index changes when selectTab is called', (tester) async {
      final cubit = HomeNavCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HomeNavCubit>.value(
            value: cubit,
            child: Scaffold(
              body: Center(
                child: BlocBuilder<HomeNavCubit, int>(
                  builder: (_, index) => Text('Tab $index'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tab 0'), findsOneWidget);

      cubit.selectTab(2);
      await tester.pump();
      expect(find.text('Tab 2'), findsOneWidget);
    });
  });
}
