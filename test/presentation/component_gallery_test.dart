import 'package:contigo/app/theme.dart';
import 'package:contigo/presentation/shell/component_gallery_screen.dart';
import 'package:contigo/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Monta la galería dentro de un router mínimo con una ruta de origen, para
/// poder probar la acción de volver sin depender del router real de la app.
Widget _host({required GoRouter router}) {
  return MaterialApp.router(
    theme: ContigoTheme.light(),
    routerConfig: router,
  );
}

void main() {
  group('ComponentGalleryScreen', () {
    testWidgets('muestra las secciones de componentes de la Etapa 1', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/ver-componentes',
        routes: [
          GoRoute(
            path: '/ver-componentes',
            builder: (c, s) => const ComponentGalleryScreen(),
          ),
        ],
      );
      await tester.pumpWidget(_host(router: router));
      await tester.pumpAndSettle();

      // Encabezado y barra de estado, siempre visibles arriba.
      expect(find.text('Ver componentes'), findsOneWidget);
      expect(find.byType(StatusBar), findsOneWidget);

      // Las primeras secciones están sobre el pliegue.
      expect(find.text('Tipografía'), findsOneWidget);
      expect(find.text('Botones'), findsOneWidget);
      expect(find.byType(ContigoButton), findsWidgets);

      // El contenido se revisa desplazándose; las secciones inferiores se
      // encuentran tras hacer scroll (comportamiento esperado de la galería).
      final list = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(find.text('Tarjetas'), 200, scrollable: list);
      expect(find.text('Tarjetas'), findsOneWidget);
      expect(find.byType(ContigoCard), findsOneWidget);
      expect(find.byType(ContigoActionCard), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Indicador de simulación'),
        200,
        scrollable: list,
      );
      expect(find.byType(SimulationIndicator), findsWidgets);

      await tester.scrollUntilVisible(find.text('CompanionNote'), 200, scrollable: list);
      expect(find.byType(CompanionNote), findsNWidgets(2));
    });

    testWidgets('la opción de volver regresa a la pantalla de origen', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => c.push('/ver-componentes'),
                  child: const Text('abrir galería'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/ver-componentes',
            builder: (c, s) => const ComponentGalleryScreen(),
          ),
        ],
      );
      await tester.pumpWidget(_host(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir galería'));
      await tester.pumpAndSettle();
      expect(find.text('Ver componentes'), findsOneWidget);

      // Toca el botón de volver (flecha atrás) y vuelve al origen.
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('abrir galería'), findsOneWidget);
    });
  });
}

