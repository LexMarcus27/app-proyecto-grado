import 'package:contigo/app/theme.dart';
import 'package:contigo/presentation/widgets/contigo_button.dart';
import 'package:contigo/presentation/widgets/contigo_card.dart';
import 'package:contigo/presentation/widgets/status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: ContigoTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('ContigoButton', () {
    testWidgets('dispara onPressed cuando está habilitado', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(ContigoButton(label: 'Continuar', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Continuar'));
      expect(taps, 1);
    });

    testWidgets('queda deshabilitado cuando onPressed es null', (tester) async {
      await tester.pumpWidget(
        _host(const ContigoButton(label: 'Continuar')),
      );

      // Un botón deshabilitado se atenúa (opacidad < 1).
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Continuar'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, lessThan(1));
    });

    testWidgets('renderiza las cinco variantes sin error', (tester) async {
      for (final variant in ContigoButtonVariant.values) {
        await tester.pumpWidget(
          _host(ContigoButton(
            label: variant.name,
            variant: variant,
            onPressed: () {},
          )),
        );
        expect(find.text(variant.name), findsOneWidget);
      }
    });
  });

  group('ContigoCard / ContigoActionCard', () {
    testWidgets('ContigoCard muestra su contenido', (tester) async {
      await tester.pumpWidget(
        _host(const ContigoCard(child: Text('contenido de tarjeta'))),
      );
      expect(find.text('contenido de tarjeta'), findsOneWidget);
    });

    testWidgets('ContigoActionCard expone rol de botón y etiqueta', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(ContigoActionCard(
          semanticLabel: 'Abrir EMA',
          onPressed: () => taps++,
          child: const Text('EMA diario'),
        )),
      );

      expect(
        find.bySemanticsLabel('Abrir EMA'),
        findsOneWidget,
      );
      await tester.tap(find.text('EMA diario'));
      expect(taps, 1);
    });
  });

  group('StatusBar', () {
    testWidgets('muestra la hora por defecto 9:41', (tester) async {
      await tester.pumpWidget(_host(const StatusBar()));
      expect(find.text('9:41'), findsOneWidget);
    });

    testWidgets('acepta una hora personalizada', (tester) async {
      await tester.pumpWidget(_host(const StatusBar(time: '10:30')));
      expect(find.text('10:30'), findsOneWidget);
    });
  });
}
