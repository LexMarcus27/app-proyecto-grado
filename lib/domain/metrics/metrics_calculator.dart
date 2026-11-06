import 'dart:math' as math;

import '../journey/network_person.dart';
import '../journey/person_status.dart';
import 'network_metrics.dart';

/// Cálculo de métricas de red portado verbatim del prototipo
/// (`metricsFor`, `pomp`, `answer`, `isAssessed` en
/// `src/screens/network.tsx` y `src/screens/connection-person.tsx`).
///
/// Dart puro, sin dependencias de Flutter. Los cortes de anillo y las reglas de
/// clasificación son **Contenido_Validacion_Pendiente** (Requirement 9.6);
/// están registrados como tales en `ContentValidationRegistry`.
class NetworkMetricsCalculator {
  const NetworkMetricsCalculator._();

  /// Número de ítems de la evaluación de la relación (preguntas 2 a 19).
  static const int requiredAnswers = 18;

  // Colores de marcador del prototipo (distintos de la paleta de marca), como
  // valores ARGB de 32 bits. `sage` → positiva, `lilac` → ambivalente,
  // `rose` → negativa, `bluePowder` → baja intensidad.
  static const int _sage = 0xFF7C9473;
  static const int _lilac = 0xFF9B84A8;
  static const int _rose = 0xFFC97B76;
  static const int _bluePowder = 0xFF6E88A6;

  /// `clamp` del prototipo: restringe [value] al rango [min]–[max].
  static double _clamp(double value, double min, double max) =>
      math.min(max, math.max(min, value));

  /// Respuesta de la pregunta [questionNumber] (2–19), mapeada a
  /// `answers[questionNumber - 2]`. Un ítem ausente o sin responder produce
  /// `NaN`, igual que el `?? Number.NaN` del prototipo, lo que propaga `NaN` a
  /// las métricas (el vínculo queda excluido por [isAssessed]).
  static double _answer(NetworkPerson person, int questionNumber) {
    final index = questionNumber - 2;
    if (index < 0 || index >= person.answers.length) return double.nan;
    final value = person.answers[index];
    return value == null ? double.nan : value.toDouble();
  }

  /// POMP (Percent Of Maximum Possible) sobre [questionNumbers], verbatim:
  /// `clamp((total - n) / (5 * n), 0, 1)`.
  static double _pomp(NetworkPerson person, List<int> questionNumbers) {
    final total = questionNumbers.fold<double>(
      0,
      (sum, number) => sum + _answer(person, number),
    );
    return _clamp(
      (total - questionNumbers.length) / (5 * questionNumbers.length),
      0,
      1,
    );
  }

  /// `true` si la persona tiene una evaluación completa: estado `complete`,
  /// al menos [requiredAnswers] respuestas y ninguna nula ni no finita. Portado
  /// de `isAssessed` del prototipo. Los vínculos que no lo cumplen se excluyen
  /// del cálculo **sin interrumpir** el resto (Requirement 9.7).
  static bool isAssessed(NetworkPerson person) {
    if (person.status != PersonStatus.complete) return false;
    if (person.answers.length < requiredAnswers) return false;
    return person.answers.every((value) => value != null);
  }

  /// Calcula las [NetworkMetrics] de [person] con las fórmulas exactas del
  /// prototipo. No valida [isAssessed]: las pantallas lo comprueban antes
  /// (`isAssessed(person) ? metricsFor(person) : null`). Para una persona sin
  /// los 18 ítems las métricas se saturan en 0 por el `clamp`.
  static NetworkMetrics metricsFor(NetworkPerson person) {
    final closeness = _pomp(person, const [4, 5, 6, 13, 14]);
    final positivity = _pomp(person, const [10, 11, 15]);
    final negativity = _pomp(person, const [7, 9, 12, 16, 17, 18]);
    final importance = _clamp((_answer(person, 2) - 1) / 5, 0, 1);
    final calculatedAmbivalence =
        (positivity + negativity) / 2 - (positivity - negativity).abs();
    final reportedAmbivalence = _clamp((_answer(person, 19) - 1) / 5, 0, 1);
    final finalCloseness = math.max(0.0, closeness - 0.4 * negativity);
    final ring = finalCloseness >= 0.7
        ? NetworkRing.intimo
        : finalCloseness >= 0.35
            ? NetworkRing.personal
            : NetworkRing.ocasional;

    NetworkMetrics build(
      NetworkClassification classification,
      NetworkShape shape,
      int colorValue,
    ) {
      return NetworkMetrics(
        closeness: closeness,
        positivity: positivity,
        negativity: negativity,
        importance: importance,
        finalCloseness: finalCloseness,
        calculatedAmbivalence: calculatedAmbivalence,
        reportedAmbivalence: reportedAmbivalence,
        ring: ring,
        classification: classification,
        shape: shape,
        colorValue: colorValue,
      );
    }

    if (positivity >= 0.5 && negativity < 0.5) {
      return build(
        NetworkClassification.mayormentePositiva,
        NetworkShape.circle,
        _sage,
      );
    }
    if (positivity >= 0.5 && negativity >= 0.5) {
      return build(
        NetworkClassification.ambivalente,
        NetworkShape.diamond,
        _lilac,
      );
    }
    if (positivity < 0.5 && negativity >= 0.5) {
      return build(
        NetworkClassification.mayormenteNegativa,
        NetworkShape.triangle,
        _rose,
      );
    }
    return build(
      NetworkClassification.bajaIntensidad,
      NetworkShape.square,
      _bluePowder,
    );
  }

  /// Calcula las métricas solo de las personas evaluadas ([isAssessed]) de
  /// [people], excluyendo las demás sin interrumpir el resto (Requirement 9.7).
  /// Devuelve pares persona→métricas en el mismo orden de entrada.
  static Map<NetworkPerson, NetworkMetrics> metricsForAll(
    Iterable<NetworkPerson> people,
  ) {
    final result = <NetworkPerson, NetworkMetrics>{};
    for (final person in people) {
      if (isAssessed(person)) {
        result[person] = metricsFor(person);
      }
    }
    return result;
  }
}