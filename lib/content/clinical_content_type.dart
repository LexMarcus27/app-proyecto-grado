/// Tipos de Contenido_Clinico suministrado que la App_Contigo preserva
/// **verbatim** (carácter por carácter), sin alterar, truncar, reordenar ni
/// parafrasear (Requirement 2.1).
///
/// Cada tipo de contenido tiene su propio [Estado_Validacion_Contenido]
/// registrado a nivel de metadatos del proyecto (Requirement 2.4): no existe un
/// único estado global, sino un estado por tipo de contenido.
///
/// La fuente autoritativa de estos tipos es `docs/analisis-prototipo.md`:
/// - El banco EMA (`EMA_VERSION = "daily-nine-v2"`), provisto tras revisión del
///   evaluador.
/// - El relato narrativo del plan de seguridad ("Las crisis también pasan").
/// - El guion y los ejemplos de la guía de mensajes de cuidado.
/// - Los textos de modo crisis y de respiración.
/// - Los umbrales/cortes de la evaluación de relación y de las métricas de red,
///   cuya validación clínica está **pendiente** (Contenido_Validacion_Pendiente,
///   Requirement 2.6 y 9.6).
enum ClinicalContentType {
  /// Banco de ítems EMA de la versión `daily-nine-v2`
  /// (3 binarios + 2 bloques de 3 rangos).
  emaBank,

  /// Relato narrativo del plan de seguridad ("Las crisis también pasan"),
  /// preservado verbatim página por página (Requirement 7.6).
  safetyPlanStory,

  /// Guion educativo y ejemplos de la guía de mensajes de cuidado,
  /// preservados verbatim (Requirement 8.3).
  caringMessagesGuide,

  /// Textos del modo crisis y de la pantalla de respiración,
  /// preservados verbatim (Requirement 12.6).
  crisisModeText,

  /// Umbrales y cortes de la evaluación de relación ("orientación
  /// demostrativa"), cuya validación clínica está pendiente (Requirement 10.2).
  relationEvaluationThresholds,

  /// Cortes de anillo y reglas de clasificación de las métricas de red
  /// (`metricsFor`), cuya validación clínica está pendiente (Requirement 9.6).
  networkMetricsCutoffs,
}
