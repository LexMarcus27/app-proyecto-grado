// Smoke test del app shell: ProviderScope + go_router arrancan en la pantalla
// de activación cuando no hay sesión.

import 'package:contigo/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('arranca en la pantalla de activación sin sesión', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ContigoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Activación'), findsOneWidget);
    expect(find.text('Entrar como PCS'), findsOneWidget);
    expect(find.text('Entrar como Cuidador'), findsOneWidget);
  });

  testWidgets('entrar como PCS navega al inicio del PCS', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ContigoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como PCS'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio PCS'), findsOneWidget);
  });

  testWidgets('entrar como Cuidador navega al inicio del Cuidador', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ContigoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como Cuidador'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio Cuidador'), findsOneWidget);
  });
}
