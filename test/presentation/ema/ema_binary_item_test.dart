import 'dart:ui' show CheckedState;

import 'package:contigo/app/theme.dart';
import 'package:contigo/presentation/ema/widgets/ema_binary_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required bool? value, required ValueChanged<bool> onChanged}) {
  return MaterialApp(
    theme: ContigoTheme.light(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: EmaBinaryItem(value: value, onChanged: onChanged),
      ),
    ),
  );
}

/// Verifica que la opción [label] se expone como radio (grupo mutuamente
/// exclusivo) y, cuando [checked] no es nulo, que su estado coincide.
void _expectRadio(WidgetTester tester, String label, {bool? checked}) {
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(
    data.flagsCollection.isInMutuallyExclusiveGroup,
    isTrue,
    reason: 'La opción "$label" debe ser parte de un grupo de radios',
  );
  if (checked != null) {
    expect(
      data.flagsCollection.isChecked,
      checked ? CheckedState.isTrue : CheckedState.isFalse,
      reason: 'Estado checked inesperado para "$label"',
    );
  }
}

void main() {
  group('EmaBinaryItem', () {
    testWidgets('renderiza las opciones Sí y No', (tester) async {
      await tester.pumpWidget(_host(value: null, onChanged: (_) {}));
      expect(find.text('Sí'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('inicia sin selección (ninguna opción marcada)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(value: null, onChanged: (_) {}));

      _expectRadio(tester, 'Sí', checked: false);
      _expectRadio(tester, 'No', checked: false);
      handle.dispose();
    });

    testWidgets('tocar "Sí" dispara onChanged(true)', (tester) async {
      bool? emitted;
      await tester.pumpWidget(
        _host(value: null, onChanged: (v) => emitted = v),
      );

      await tester.tap(find.text('Sí'));
      await tester.pump();
      expect(emitted, isTrue);
    });

    testWidgets('tocar "No" dispara onChanged(false)', (tester) async {
      bool? emitted;
      await tester.pumpWidget(
        _host(value: null, onChanged: (v) => emitted = v),
      );

      await tester.tap(find.text('No'));
      await tester.pump();
      expect(emitted, isFalse);
    });

    testWidgets('marca la opción seleccionada (radio semantics)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_host(value: true, onChanged: (_) {}));
      _expectRadio(tester, 'Sí', checked: true);
      _expectRadio(tester, 'No', checked: false);

      await tester.pumpWidget(_host(value: false, onChanged: (_) {}));
      _expectRadio(tester, 'Sí', checked: false);
      _expectRadio(tester, 'No', checked: true);

      handle.dispose();
    });
  });
}
