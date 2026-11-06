// Smoke test del app shell: ProviderScope + go_router arrancan en la pantalla
// de activación cuando no hay sesión, y la activación por código enruta por rol.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/data/auth/simulated_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta la app con la activación simulada sin retardo, para que las pruebas
/// no dependan de un temporizador de verificación.
Future<void> _pumpApp(WidgetTester tester) async {
  // Las pantallas de inicio por rol leen el JourneyState local; se inyecta un
  // SharedPreferences de prueba para que puedan cargar tras el enrutamiento.
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(
          SimulatedAuthService(verifyDelay: Duration.zero),
        ),
      ],
      child: const ContigoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Escribe un código en el campo de activación y pulsa "Continuar".
Future<void> _activateWith(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pump();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('arranca en la pantalla de activación sin sesión', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Activa tu cuenta'), findsOneWidget);
    expect(find.text('Código de activación'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('un código válido genérico enruta al inicio del PCS', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _activateWith(tester, 'A3K9X2');

    expect(find.text('Inicio PCS'), findsOneWidget);
  });

  testWidgets('un código que empieza con «C» enruta al inicio del Cuidador', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _activateWith(tester, 'C1D2E3');

    expect(find.text('Inicio Cuidador'), findsOneWidget);
  });

  testWidgets('un código demasiado corto muestra el error y no navega', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _activateWith(tester, 'ABC');

    expect(
      find.text('No pudimos validar el código. Revísalo o solicita ayuda.'),
      findsOneWidget,
    );
    // Permanece en la pantalla de activación.
    expect(find.text('Activa tu cuenta'), findsOneWidget);
  });
}