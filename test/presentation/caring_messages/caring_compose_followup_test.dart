// Pruebas puntuales de las correcciones de seguimiento Wave 12:
// - CompanionNote admite la tercera expresión del avatar (thoughtful).
// - Al enviar se verifica que el contexto revisado siga vigente (misma
//   asociación); un cambio de asociación bloquea ese envío.

import 'package:contigo/app/di.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/caring_messages/caring_messages_controller.dart';
import 'package:contigo/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('CompanionNote admite las tres expresiones del avatar',
      (tester) async {
    for (final expression in CompanionExpression.values) {
      await tester.pumpWidget(MaterialApp(
        theme: ContigoTheme.light(),
        home: Scaffold(
          body: CompanionNote(
            expression: expression,
            child: const Text('Hola'),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(CompanionNote), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('enviar con una asociación distinta de la revisada se rechaza', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalJourneyRepository(prefs);
    final seed = simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active);
    await repo.save(seed);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    container.read(sessionControllerProvider.notifier).setSession(
          const Session(userId: 'demo-cuidador', role: UserRole.cuidador),
        );

    final send = container.read(caringSendControllerProvider);
    // Con una asociación esperada que ya no coincide, el envío se rechaza.
    final rejected = await send.simulateSend(
      'caregiver-home-marta',
      'Mensaje ficticio',
      expectedAssociationId: 'asociacion-que-ya-no-existe',
    );
    expect(rejected, isFalse);
    expect(
      (await container.read(caringMessageRepositoryProvider).loadMessages()),
      isEmpty,
    );

    // Sin esperar una asociación concreta, el envío con vínculo vigente procede.
    final ok = await send.simulateSend('caregiver-home-marta', 'Mensaje ficticio');
    expect(ok, isTrue);
  });
}