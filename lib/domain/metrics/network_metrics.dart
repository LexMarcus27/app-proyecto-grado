import 'package:equatable/equatable.dart';

/// Anillo de cercanía asignado a un vínculo evaluado (portado verbatim de
/// `metricsFor` en `src/screens/network.tsx`).
///
/// Los cortes numéricos (`finalCloseness >= 0.7` / `>= 0.35`) son
/// **Contenido_Validacion_Pendiente** (Requirement 2.6, 9.6): quedan
/// registrados como tales en `ContentValidationRegistry` y no constituyen un
/// resultado clínico definitivo. Las cadenas conservan acentos y mayúsculas.
enum NetworkRing {
  intimo('Íntimo'),
  personal('Personal'),
  ocasional('Ocasional');

  const NetworkRing(this.label);

  /// Etiqueta exacta del prototipo.
  final String label;
}

/// Clasificación cualitativa del vínculo según positividad y negatividad
/// (portada verbatim del prototipo). Las reglas de corte en `0.5` son
/// **Contenido_Validacion_Pendiente** (Requirement 2.6, 9.6).
enum NetworkClassification {
  mayormentePositiva('Mayormente positiva'),
  ambivalente('Ambivalente'),
  mayormenteNegativa('Mayormente negativa'),
  bajaIntensidad('Baja intensidad');

  const NetworkClassification(this.label);

  /// Etiqueta exacta del prototipo.
  final String label;
}

/// Forma del marcador del vínculo en el mapa de red (portada del prototipo).
enum NetworkShape {
  circle,
  diamond,
  triangle,
  square,
}

/// Métricas derivadas de la evaluación de la relación de una persona de la red
/// (equivalente al tipo `Metrics` del prototipo, `src/screens/network.tsx`).
///
/// Todas las fórmulas se portan verbatim; la asignación de anillo, de
/// clasificación y de forma/color deriva de cortes marcados como
/// **Contenido_Validacion_Pendiente** (no se tratan como lógica clínica
/// definitiva, Requirement 9.6). El color se expresa como valor ARGB
/// (`colorValue`) para no acoplar el dominio a Flutter; la capa de presentación
/// lo convierte a `Color`.
class NetworkMetrics extends Equatable {
  const NetworkMetrics({
    required this.closeness,
    required this.positivity,
    required this.negativity,
    required this.importance,
    required this.finalCloseness,
    required this.calculatedAmbivalence,
    required this.reportedAmbivalence,
    required this.ring,
    required this.classification,
    required this.shape,
    required this.colorValue,
  });

  /// POMP de cercanía (ítems 4, 5, 6, 13, 14).
  final double closeness;

  /// POMP de positividad (ítems 10, 11, 15).
  final double positivity;

  /// POMP de negatividad (ítems 7, 9, 12, 16, 17, 18).
  final double negativity;

  /// Importancia derivada del ítem 2, normalizada a 0–1.
  final double importance;

  /// Cercanía final: `max(0, closeness - 0.4 * negativity)`.
  final double finalCloseness;

  /// Ambivalencia calculada a partir de positividad/negatividad.
  final double calculatedAmbivalence;

  /// Ambivalencia reportada derivada del ítem 19, normalizada a 0–1.
  final double reportedAmbivalence;

  /// Anillo asignado (corte pendiente de validación).
  final NetworkRing ring;

  /// Clasificación cualitativa (regla pendiente de validación).
  final NetworkClassification classification;

  /// Forma del marcador en el mapa.
  final NetworkShape shape;

  /// Color del marcador como valor ARGB de 32 bits (p. ej. `0xFF7C9473`).
  final int colorValue;

  @override
  List<Object?> get props => [
        closeness,
        positivity,
        negativity,
        importance,
        finalCloseness,
        calculatedAmbivalence,
        reportedAmbivalence,
        ring,
        classification,
        shape,
        colorValue,
      ];
}