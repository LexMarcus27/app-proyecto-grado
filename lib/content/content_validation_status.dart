import 'package:equatable/equatable.dart';

import 'clinical_content_type.dart';

/// Estado de validación de un tipo de Contenido_Clinico, registrado por tipo
/// de contenido a nivel de metadatos del proyecto (Requirement 2.4).
///
/// El estado **no** se presenta como un descargo único en toda la interfaz cada
/// vez que se muestra contenido (Requirement 2.6); es un metadato que la
/// documentación y la UI consultan de forma selectiva.
enum ContentValidationStatus {
  /// Texto narrativo/contenido suministrado que debe preservarse verbatim.
  /// Confirmado por el equipo investigador como suministrado (no como
  /// validación clínica formal). Aplica al relato del plan de seguridad y al
  /// guion/ejemplos de mensajes de cuidado (Requirement 2.5).
  suppliedVerbatim,

  /// Banco EMA `daily-nine-v2`: suministrado tras revisión del evaluador, sin
  /// presentarse como validación clínica formal (Requirement 2.5).
  suppliedAfterEvaluatorReview,

  /// Contenido_Validacion_Pendiente: umbrales y cortes no validados
  /// (evaluación de relación, métricas de red). No se trata como lógica clínica
  /// definitiva (Requirement 2.6, 9.6, 10.2).
  validationPending,
}

/// Metadato de validación de un tipo de contenido concreto
/// (Estado_Validacion_Contenido).
///
/// Es un modelo inmutable de **metadatos**: describe el origen del contenido y
/// su estado de validación, sin incluir el cuerpo del texto (que se carga
/// verbatim mediante el mecanismo de carga de contenido). Cada tipo de
/// contenido tiene exactamente una entrada registrada (Requirement 2.4).
class ContentValidationMetadata extends Equatable {
  const ContentValidationMetadata({
    required this.contentType,
    required this.status,
    required this.sourceLabel,
    required this.note,
  });

  /// Tipo de Contenido_Clinico al que aplica este metadato.
  final ClinicalContentType contentType;

  /// Estado de validación registrado para el tipo de contenido.
  final ContentValidationStatus status;

  /// Etiqueta legible del origen del contenido (p. ej. identificador del banco
  /// EMA o nombre del relato suministrado).
  final String sourceLabel;

  /// Nota de documentación que precisa el origen y el alcance de la validación
  /// (por qué está suministrado/pendiente), sin convertirse en descargo de UI.
  final String note;

  /// `true` si este tipo de contenido está marcado como
  /// Contenido_Validacion_Pendiente (umbrales/cortes no validados).
  bool get isValidationPending =>
      status == ContentValidationStatus.validationPending;

  @override
  List<Object?> get props => [contentType, status, sourceLabel, note];
}
