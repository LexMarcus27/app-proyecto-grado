// Pruebas de los escenarios demo (tarea 2.10).
//
// Verifican que las semillas de los dos escenarios ejercitan los dos caminos
// del bloque de relación del EMA:
//   - withActiveLink  -> validCaregivers NO vacío (contiene demo-m).
//   - withoutActiveLink -> validCaregivers vacío (omisión del bloque).
// Dart puro.
import 'package:contigo/domain/journey/journey.dart';
import 'package:test/test.dart';

void main() {
  group('seedForScenario', () {
    test(
      'withActiveLink: validCaregivers contiene a demo-m y es fortalecible',
      () {
        final seed = seedForScenario(DemoScenario.withActiveLink);
        final valid = validCaregivers(seed);

        expect(valid, isNotEmpty);
        expect(valid.map((p) => p.id), contains('demo-m'));
        expect(canStrengthenRelationship(seed, 'demo-m'), isTrue);
      },
    );

    test('withActiveLink: equivale al recorrido demo del prototipo', () {
      expect(
        seedForScenario(DemoScenario.withActiveLink),
        createDemoJourney(),
      );
    });

    test('withoutActiveLink: validCaregivers es vacío', () {
      final seed = seedForScenario(DemoScenario.withoutActiveLink);
      expect(validCaregivers(seed), isEmpty);
      expect(canStrengthenRelationship(seed, 'demo-m'), isFalse);
    });

    test(
      'withoutActiveLink: conserva el mapa (personas) pero sin asociaciones '
      'activas',
      () {
        final seed = seedForScenario(DemoScenario.withoutActiveLink);
        // Preserva el mapa: mismas personas que el demo con vínculo.
        expect(
          seed.people.map((p) => p.id),
          createDemoJourney().people.map((p) => p.id),
        );
        // Pero ninguna asociación queda activa.
        expect(seed.associations, isNotEmpty);
        expect(seed.associations.every((a) => !a.active), isTrue);
      },
    );

    test('scenarioHasActiveLink refleja la invariante de cada escenario', () {
      expect(scenarioHasActiveLink(DemoScenario.withActiveLink), isTrue);
      expect(scenarioHasActiveLink(DemoScenario.withoutActiveLink), isFalse);
    });
  });
}
