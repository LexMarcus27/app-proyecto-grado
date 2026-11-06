// Prueba de la pantalla del editor del plan de seguridad (tarea 3.13):
// edición de un paso e importación simulada de contactos (permisos fingidos,
// sin contactos reales) con indicador de simulación.

import 'package:contigo/app/router.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/presentation/safety_plan/safety_plan_editor_screen.dart';
import 'package:contigo/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _host() {
  final router = GoRouter(
    initialLocation: AppPath.safetyPlanEditor,
    routes: [
      GoRoute(
        name: AppRoute.safetyPlanEditor,
        path: AppPath.safetyPlanEditor,
        builder: (context, state) => const SafetyPlanEditorScreen(),
      ),
      GoRoute(
        name: AppRoute.pcsHome,
        path: AppPath.pcsHome,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Inicio PCS'))),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      theme: ContigoTheme.light(),
      routerConfig: router,
    ),
  );
}

void main() {
  group('SafetyPlanEditorScreen', () {
    testWidgets('muestra las secciones y el indicador de simulación de contactos',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(find.text('Mi plan de seguridad'), findsOneWidget);
      expect(find.text('Personas a quienes puedo pedir ayuda'), findsOneWidget);
      // El indicador de simulación persistente de la importación de contactos.
      expect(find.byType(SimulationIndicator), findsWidgets);
      expect(
        find.textContaining('Importación de contactos simulada'),
        findsOneWidget,
      );
    });

    testWidgets('importar desde contactos agrega el contacto ficticio',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      final addButton = find.text('Agregar desde mis contactos');
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Hoja de permiso simulado.
      expect(find.text('Acceder a tus contactos'), findsOneWidget);
      final allow = find.text('Permitir acceso');
      await tester.ensureVisible(allow);
      await tester.pumpAndSettle();
      await tester.tap(allow);
      await tester.pumpAndSettle();

      // Se agrega el contacto ficticio del prototipo (no un contacto real).
      expect(find.text('Dra. Valentina Ríos'), findsOneWidget);
    });
  });
}