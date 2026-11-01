/// Dominio EMA (banco diario `daily-nine-v2`).
///
/// Barrel del módulo portado del prototipo (`src/ema.ts`). Dart puro, sin
/// dependencias de Flutter ni Firebase. Incluye el banco de nueve ítems verbatim,
/// los modelos inmutables [EmaDraft]/[EmaReference]/[EmaItem] y las reglas puras
/// (reinicio diario, omisión del bloque de relación, validación de respuestas y
/// completitud).
library;

export 'ema_constants.dart';
export 'ema_draft.dart';
export 'ema_item.dart';
export 'ema_logic.dart';
export 'ema_reference.dart';
