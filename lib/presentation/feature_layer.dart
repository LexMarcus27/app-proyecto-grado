/// Metadato de **capa de madurez por funcionalidad** (Requirement 3) que la UI
/// consulta para decidir si debe mostrar el indicador de simulación persistente.
///
/// Distinción crítica (ver `design.md`): estas capas **no** son capas de la
/// arquitectura (presentación / dominio / datos). Son una clasificación del
/// **estado/etapa de implementación de cada feature**: si opera localmente de
/// verdad, está fingida a la espera de backend, o ya está respaldada por
/// Firebase. Que un repositorio esté respaldado por una implementación local o
/// por Firebase es un detalle detrás de la misma interfaz; el indicador de
/// simulación **no** es responsabilidad del repositorio, sino que se deriva de
/// este metadato que la UI consulta (Requirement 3.4).
///
/// Al promover una feature de [FeatureLayer.simulada] a [FeatureLayer.firebase]
/// se cambia únicamente este metadato y el indicador desaparece sin tocar la
/// pantalla (Requirement 3.6, design Property 2).
library;

/// Capas de madurez mutuamente excluyentes de una funcionalidad (Requirement
/// 3.1). Los nombres de los requisitos son `Capa_Local`, `Capa_Simulada` y
/// `Capa_Firebase`; aquí se expresan como valores de enum idiomáticos en Dart.
enum FeatureLayer {
  /// `Capa_Local`: funcionalidad real que opera por completo en el dispositivo
  /// sin backend (flujo EMA, `metricsFor`, editores, gating como lógica de UI).
  local,

  /// `Capa_Simulada`: comportamiento fingido localmente a la espera de backend
  /// (activación demo, envíos, notificaciones, bandeja, contactos, adjuntos).
  /// **Única capa que muestra el indicador de simulación persistente** (3.4).
  simulada,

  /// `Capa_Firebase`: etapa posterior con autenticación/persistencia reales y
  /// reglas de seguridad del lado servidor. Sin indicador de simulación (3.6).
  firebase;

  /// `true` solo para [FeatureLayer.simulada]: la UI debe mostrar el indicador
  /// de simulación persistente para features en esta capa (Requirement 3.4) y
  /// únicamente para ellas (3.6, design Property 2).
  bool get showsSimulationIndicator => this == FeatureLayer.simulada;
}

/// Metadato de capa asociado a una funcionalidad concreta de la app.
///
/// Cada feature incorporada se registra con exactamente una [FeatureLayer]
/// (Requirement 3.1). Una feature sin metadato de capa se trata como **no
/// disponible** (Requirement 3.7, design Property 2); por eso el tipo exige una
/// capa no nula al construirse.
class FeatureLayerInfo {
  const FeatureLayerInfo({
    required this.featureId,
    required this.layer,
    this.label,
  });

  /// Identificador estable de la funcionalidad (p. ej. `caring-messages`,
  /// `activation`, `notifications`). Útil para trazabilidad y pruebas.
  final String featureId;

  /// Capa de madurez asignada a la feature.
  final FeatureLayer layer;

  /// Texto opcional específico de la feature para el indicador de simulación.
  /// Si es `null`, el indicador usa su texto por defecto.
  final String? label;

  /// `true` si la UI de esta feature debe mostrar el indicador de simulación.
  bool get showsSimulationIndicator => layer.showsSimulationIndicator;
}
