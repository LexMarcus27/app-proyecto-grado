import 'package:contigo/app/theme.dart';
import 'package:contigo/presentation/widgets/companion_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: ContigoTheme.light(),
    home: Scaffold(body: child),
  );
}

/// Busca el `SizedBox` de la ventana del avatar con el tamaño exacto [size].
///
/// En el entorno de prueba no hay bundle de assets, así que el avatar usa su
/// fallback grácil: un `SizedBox` del tamaño de la ventana de la pose (sin
/// pintar ni lanzar). Ese tamaño es, justamente, lo que debemos verificar: las
/// ventanas de recorte del prototipo (62×65 bienvenida, 62×60 afecto).
Finder _windowOfSize(Size size) {
  return find.byWidgetPredicate(
    (w) => w is SizedBox && w.width == size.width && w.height == size.height,
  );
}

void main() {
  group('CompanionNote', () {
    testWidgets('renderiza el mensaje dentro de la nube', (tester) async {
      await tester.pumpWidget(
        _host(const CompanionNote(child: Text('Hola, estoy contigo'))),
      );

      expect(find.text('Hola, estoy contigo'), findsOneWidget);
    });

    testWidgets('usa la ventana de recorte de la pose de bienvenida (62×65)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CompanionNote(child: Text('mensaje'))),
      );

      // Ventana de la pose welcome: 62×65 (ver src/index.css líneas 699-700).
      expect(_windowOfSize(const Size(62, 65)), findsOneWidget);
    });

    testWidgets('usa la ventana de recorte de la pose de afecto (62×60)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CompanionNote(affection: true, child: Text('mensaje'))),
      );

      // Ventana de la pose affection: 62×60 (ver src/index.css líneas 699-700).
      expect(_windowOfSize(const Size(62, 60)), findsOneWidget);
    });

    testWidgets('recorta con ClipRect (no deja desbordar el sprite)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CompanionNote(child: Text('mensaje'))),
      );

      // El avatar envuelve su render en un ClipRect para acotar la ventana a la
      // pose; sin él, el sprite se desbordaría fuera de la ventana.
      expect(find.byType(ClipRect), findsWidgets);
    });

    testWidgets('el avatar es decorativo (excluido de la semántica)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CompanionNote(child: Text('mensaje accesible'))),
      );

      // El contenido del mensaje sí es accesible.
      expect(find.text('mensaje accesible'), findsOneWidget);
      // El avatar se excluye de la semántica (aria-hidden en el prototipo).
      expect(find.byType(ExcludeSemantics), findsWidgets);
      final semantics = tester.getSemantics(find.text('mensaje accesible'));
      expect(semantics.label, contains('mensaje accesible'));
    });
  });
}
