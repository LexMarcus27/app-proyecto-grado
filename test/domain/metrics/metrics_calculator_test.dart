// Prueba del dominio de métricas de red (tarea 3.8): fórmulas POMP exactas,
// asignación de anillo/clasificación/forma/color y exclusión de vínculos sin
// los 18 ítems. Los cortes son Contenido_Validacion_Pendiente (Requirement 9.6).

import 'package:contigo/domain/journey/invitation_status.dart';
import 'package:contigo/domain/journey/network_person.dart';
import 'package:contigo/domain/journey/person_status.dart';
import 'package:contigo/domain/metrics/metrics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Construye una persona evaluada (18 ítems) a partir de un mapa pregunta→valor
/// (preguntas 2..19). Los índices se mapean como `answers[pregunta - 2]`.
NetworkPerson _person({
  required Map<int, int> byQuestion,
  PersonStatus status = PersonStatus.complete,
}) {
  final answers = List<int?>.generate(18, (i) {
    final question = i + 2;
    return byQuestion[question];
  });
  return NetworkPerson(
    id: 'p',
    name: 'P',
    answers: answers,
    status: status,
    invitationStatus: InvitationStatus.notInvited,
  );
}

/// Asigna el mismo valor a una lista de preguntas.
Map<int, int> _fill(List<int> questions, int value) =>
    {for (final q in questions) q: value};

const _closeness = [4, 5, 6, 13, 14];
const _positivity = [10, 11, 15];
const _negativity = [7, 9, 12, 16, 17, 18];

void main() {
  group('NetworkMetricsCalculator.pomp (vía metricsFor)', () {
    test('todos los ítems al máximo dan POMP 1.0', () {
      final person = _person(byQuestion: {
        for (var q = 2; q <= 19; q++) q: 6,
      });
      final m = NetworkMetricsCalculator.metricsFor(person);
      expect(m.closeness, closeTo(1.0, 1e-9));
      expect(m.positivity, closeTo(1.0, 1e-9));
      expect(m.negativity, closeTo(1.0, 1e-9));
    });

    test('todos los ítems al mínimo dan POMP 0.0', () {
      final person = _person(byQuestion: {
        for (var q = 2; q <= 19; q++) q: 1,
      });
      final m = NetworkMetricsCalculator.metricsFor(person);
      expect(m.closeness, 0.0);
      expect(m.positivity, 0.0);
      expect(m.negativity, 0.0);
    });

    test('finalCloseness = max(0, closeness - 0.4 * negativity)', () {
      // closeness = 1.0, negativity = 1.0 -> max(0, 1 - 0.4) = 0.6
      final person = _person(byQuestion: {
        ..._fill(_closeness, 6),
        ..._fill(_negativity, 6),
        ..._fill(_positivity, 6),
        2: 6,
        19: 6,
      });
      final m = NetworkMetricsCalculator.metricsFor(person);
      expect(m.finalCloseness, closeTo(0.6, 1e-9));
    });
  });

  group('clasificación, forma y color', () {
    test('positividad alta y negatividad baja -> Mayormente positiva (circle)',
        () {
      final person = _person(byQuestion: {
        ..._fill(_positivity, 6),
        ..._fill(_negativity, 1),
        ..._fill(_closeness, 6),
        2: 4,
        19: 3,
      });
      final m = NetworkMetricsCalculator.metricsFor(person);
      expect(m.classification, NetworkClassification.mayormentePositiva);
      expect(m.shape, NetworkShape.circle);
      expect(m.colorValue, 0xFF7C9473);
    });

    test('positividad y negatividad altas -> Ambivalente (diamond)', () {
      final person = _person(byQuestion: {
        ..._fill(_positivity, 6),
        ..._fill(_negativity, 6),
        ..._fill(_closeness, 4),
        2: 4,
        19: 4,
      });
      final m = NetworkMetricsCalculator.metricsFor(person);
      expect(m.classification, NetworkClassification.ambivalente);
      expect(m.shape, NetworkShape.diamond);
      expect(m.colorValue, 0xFF9B84A8);
    });

    test('positividad baja y negatividad alta -> Mayormente negativa (triangle)',
        () {
      final person = _person(byQuestion: {
        ..._fill(_positivity, 1),
        ..._fill(_negativity, 6),
        ..._fill(_closeness, 3),
        2: 3,
        19: 4,
      });
      final m = NetworkMetricsCalculator.metricsFor(person);
      expect(m.classification, NetworkClassification.mayormenteNegativa);
      expect(m.shape, NetworkShape.triangle);
      expect(m.colorValue, 0xFFC97B76);
    });

    test('positividad y negatividad bajas -> Baja intensidad (square)', () {
      final person = _person(byQuestion: {
        ..._fill(_positivity, 1),
        ..._fill(_negativity, 1),
        ..._fill(_closeness, 2),
        2: 2,
        19: 2,
      });
      final m = NetworkMetricsCalculator.metricsFor(person);
      expect(m.classification, NetworkClassification.bajaIntensidad);
      expect(m.shape, NetworkShape.square);
      expect(m.colorValue, 0xFF6E88A6);
    });
  });

  group('anillo (cortes de validación pendiente)', () {
    test('finalCloseness >= 0.7 -> Íntimo', () {
      final person = _person(byQuestion: {
        ..._fill(_closeness, 6),
        ..._fill(_negativity, 1),
        ..._fill(_positivity, 6),
        2: 6,
        19: 6,
      });
      final m = NetworkMetricsCalculator.metricsFor(person);
      expect(m.finalCloseness, greaterThanOrEqualTo(0.7));
      expect(m.ring, NetworkRing.intimo);
    });
  });

  group('exclusión de vínculos sin los 18 ítems (isAssessed)', () {
    test('una persona con un ítem nulo no está evaluada', () {
      final byQuestion = {for (var q = 2; q <= 19; q++) q: 4};
      byQuestion.remove(10); // deja un null en answers[8]
      final person = _person(byQuestion: byQuestion);
      expect(NetworkMetricsCalculator.isAssessed(person), isFalse);
    });

    test('una persona no completa no está evaluada', () {
      final person = _person(
        byQuestion: {for (var q = 2; q <= 19; q++) q: 4},
        status: PersonStatus.inProgress,
      );
      expect(NetworkMetricsCalculator.isAssessed(person), isFalse);
    });

    test('metricsForAll excluye las no evaluadas sin interrumpir el resto', () {
      final ok = _person(byQuestion: {for (var q = 2; q <= 19; q++) q: 4})
          .copyWith(id: 'ok');
      final partialQuestions = {for (var q = 2; q <= 19; q++) q: 4}
        ..remove(12);
      final bad = _person(byQuestion: partialQuestions).copyWith(id: 'bad');
      final result = NetworkMetricsCalculator.metricsForAll([bad, ok]);
      expect(result.keys.map((p) => p.id), ['ok']);
    });
  });
}