/// Dominio de notificaciones de demostración, portado verbatim del prototipo
/// (`src/notifications.ts`). Dart puro, sin dependencias de Flutter ni Firebase.
///
/// Reglas de elegibilidad y de sustitución del marcador de persona
/// (Requirement 12.2, 12.3). No realiza envíos externos (Capa_Simulada): la
/// generación/entrega vive en la capa de datos/UI (tarea 3.28).
library;

export 'notification_logic.dart';
export 'notification_template.dart';