import 'package:contigo/app/di.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/demo/demo_scenario_controls_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta [DemoScenarioControlsScreen] bajo un `GoRouter` mínimo y un
/// `ProviderScope` cuyo único override es [sharedPreferencesProvider]. Así el
/// `journeyRepositoryProvider` conserva su implementación por defecto
/// (`LocalJourneyRepository` sobre esas `SharedPreferences`) y el
/// `demoScenarioControllerProvider` queda en su valor por defecto, de modo que
/// `select()` persiste la semilla a través del repositorio real.
Widget _host(SharedPreferences prefs) {
  final router = GoRouter(
    initialLocation: '/demo',
    routes: [
      GoRoute(
        path: '/origen',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('origen'))),
      ),
      GoRoute(
        path: '/demo',
        builder: (context, state) => const DemoScenarioControlsScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp.router(
      theme: ContigoTheme.light(),
      routerConfig: router,
    ),
  );
}

void main() {
  group('DemoScenarioControlsScreen', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('muestra ambas opciones de escenario', (tester) async {
      await tester.pumpWidget(_host(prefs));
      await tester.pumpAndSettle();

      expect(find.text('Con persona vinculada'), findsOneWidget);
      expect(find.text('Sin persona vinculada'), findsOneWidget);
    });

    testWidgets(
      'alternar entre escenarios persiste la semilla a través del repositorio',
      (tester) async {
        await tester.pumpWidget(_host(prefs));
        await tester.pumpAndSettle();

        // El repositorio local real respaldado por las mismas SharedPreferences
        // que usa la pantalla (mismo override en el scope).
        final repository = LocalJourneyRepository(prefs);

        // "Sin persona vinculada" → validCaregivers vacío.
        await tester.tap(find.text('Sin persona vinculada'));
        await tester.pumpAndSettle();

        final withoutLink = await repository.loadJourney();
        expect(
          validCaregivers(withoutLink),
          isEmpty,
          reason: 'sin vínculo activo, ninguna persona es cuidadora válida',
        );

        // "Con persona vinculada" → validCaregivers contiene demo-m.
        await tester.tap(find.text('Con persona vinculada'));
        await tester.pumpAndSettle();

        final withLink = await repository.loadJourney();
        final validIds = validCaregivers(withLink).map((p) => p.id).toList();
        expect(validIds, contains('demo-m'));
      },
    );
  });
}
