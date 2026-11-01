import 'clinical_content_type.dart';
import 'content_validation_status.dart';

/// Registro de Estado_Validacion_Contenido **por tipo de contenido**
/// (Requirement 2.4): cada tipo de Contenido_Clinico tiene exactamente una
/// entrada de metadatos, en lugar de un único estado global.
///
/// Este registro es la fuente de verdad a nivel de metadatos del proyecto. En
/// particular, deja constancia de que:
/// - El banco EMA `daily-nine-v2` fue **suministrado tras revisión del
///   evaluador**, sin presentarse como validación clínica formal
///   (Requirement 2.5).
/// - Los textos narrativos suministrados (relato del plan de seguridad y
///   guion/ejemplos de mensajes de cuidado) se preservan **verbatim** con su
///   propio estado de validación (Requirement 2.5).
/// - Los **umbrales y cortes** no validados (evaluación de relación y métricas
///   de red) quedan marcados como **Contenido_Validacion_Pendiente**
///   (Requirement 2.6, 9.6, 10.2).
///
/// El registro no muestra un descargo de "pendiente de validación clínica" en
/// toda la interfaz: es un metadato que la documentación y la UI consultan de
/// forma selectiva (Requirement 2.6).
class ContentValidationRegistry {
  const ContentValidationRegistry._(this._entries);

  final Map<ClinicalContentType, ContentValidationMetadata> _entries;

  /// Identificador del banco EMA suministrado (EMA_VERSION), registrado como
  /// metadato de origen del contenido EMA.
  static const String emaVersion = 'daily-nine-v2';

  /// Registro por defecto con una entrada por tipo de contenido.
  static final ContentValidationRegistry defaults = ContentValidationRegistry._(
    Map.unmodifiable(<ClinicalContentType, ContentValidationMetadata>{
      ClinicalContentType.emaBank: const ContentValidationMetadata(
        contentType: ClinicalContentType.emaBank,
        status: ContentValidationStatus.suppliedAfterEvaluatorReview,
        sourceLabel: 'Banco EMA $emaVersion',
        note:
            'El banco EMA "$emaVersion" fue suministrado tras revisión del '
            'evaluador; se registra como contenido suministrado, no como '
            'validación clínica formal (Requirement 2.5).',
      ),
      ClinicalContentType.safetyPlanStory: const ContentValidationMetadata(
        contentType: ClinicalContentType.safetyPlanStory,
        status: ContentValidationStatus.suppliedVerbatim,
        sourceLabel: 'Relato del plan de seguridad "Las crisis también pasan"',
        note:
            'Texto narrativo suministrado; se preserva verbatim página por '
            'página, sin alterar ni reordenar (Requirement 2.5, 7.6).',
      ),
      ClinicalContentType.caringMessagesGuide: const ContentValidationMetadata(
        contentType: ClinicalContentType.caringMessagesGuide,
        status: ContentValidationStatus.suppliedVerbatim,
        sourceLabel: 'Guía y ejemplos de mensajes de cuidado',
        note:
            'Guion y ejemplos suministrados; se preservan verbatim, sin '
            'alterar ni truncar (Requirement 2.5, 8.3).',
      ),
      ClinicalContentType.crisisModeText: const ContentValidationMetadata(
        contentType: ClinicalContentType.crisisModeText,
        status: ContentValidationStatus.suppliedVerbatim,
        sourceLabel: 'Textos de modo crisis y respiración',
        note:
            'Contenido textual del modo crisis y de la respiración; se '
            'preserva idéntico al definido en el prototipo (Requirement 12.6).',
      ),
      ClinicalContentType.relationEvaluationThresholds:
          const ContentValidationMetadata(
            contentType: ClinicalContentType.relationEvaluationThresholds,
            status: ContentValidationStatus.validationPending,
            sourceLabel: 'Umbrales de la evaluación de relación',
            note:
                'Umbrales "de orientación demostrativa"; marcados como '
                'Contenido_Validacion_Pendiente, no como resultado clínico '
                'definitivo (Requirement 2.6, 10.2).',
          ),
      ClinicalContentType.networkMetricsCutoffs: const ContentValidationMetadata(
        contentType: ClinicalContentType.networkMetricsCutoffs,
        status: ContentValidationStatus.validationPending,
        sourceLabel: 'Cortes de anillo y reglas de clasificación (metricsFor)',
        note:
            'Cortes numéricos de anillo y reglas de clasificación de las '
            'métricas de red; marcados como Contenido_Validacion_Pendiente, '
            'sin convertirse en lógica clínica definitiva (Requirement 2.6, '
            '9.6).',
      ),
    }),
  );

  /// Devuelve el metadato de validación registrado para [contentType], o `null`
  /// si el tipo de contenido no tiene entrada registrada.
  ContentValidationMetadata? metadataFor(ClinicalContentType contentType) =>
      _entries[contentType];

  /// Todas las entradas de metadatos registradas, una por tipo de contenido.
  Iterable<ContentValidationMetadata> get entries => _entries.values;

  /// Tipos de contenido marcados como Contenido_Validacion_Pendiente
  /// (umbrales/cortes no validados).
  Iterable<ContentValidationMetadata> get pendingEntries =>
      _entries.values.where((entry) => entry.isValidationPending);
}
