// Pruebas del sembrado de la sesión demo (tarea 2.10).
//
// Cubren el arranque "sembrar si está vacío" y la conmutación explícita de
// escenario a través del JourneyRepository local.
import 'package:contigo/data/journey/demo_seeder.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/journey/demo_scenario.dart';
import 'package:contigo/domain/journey/journey_authorization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('seedDemoIfEmpty', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test(
      'siembra withActiveLink cuando el almacenamiento está vacío',
      () async {
        final repo = LocalJourneyRepository(prefs);

        final seeded = await seedDemoIfEmpty(repo);

        expect(seeded, isTrue);
        final loaded = await repo.loadJourney();
        expect(loaded, seedForScenario(DemoScenario.withActiveLink));
        expect(validCaregivers(loaded), isNotEmpty);
        await repo.dispose();
      },
    );

    test('NO sobrescribe un recorrido ya almacenado', () async {
      final repo = LocalJourneyRepository(prefs);
      // Simula un estado del usuario ya persistido (escenario sin vínculo).
      final existing = seedForScenario(DemoScenario.withoutActiveLink);
      await repo.save(existing);

      final seeded = await seedDemoIfEmpty(repo);

      expect(seeded, isFalse);
      expect(await repo.loadJourney(), existing);
      await repo.dispose();
    });

    test('puede sembrar explícitamente el escenario sin vínculo', () async {
      final repo = LocalJourneyRepository(prefs);

      final seeded = await seedDemoIfEmpty(
        repo,
        scenario: DemoScenario.withoutActiveLink,
      );

      expect(seeded, isTrue);
      expect(validCaregivers(await repo.loadJourney()), isEmpty);
      await repo.dispose();
    });
  });

  group('applyDemoScenario', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test('alterna entre escenarios sobrescribiendo el recorrido', () async {
      final repo = LocalJourneyRepository(prefs);

      await applyDemoScenario(repo, DemoScenario.withActiveLink);
      expect(validCaregivers(await repo.loadJourney()), isNotEmpty);

      await applyDemoScenario(repo, DemoScenario.withoutActiveLink);
      expect(validCaregivers(await repo.loadJourney()), isEmpty);

      await repo.dispose();
    });
  });
}
