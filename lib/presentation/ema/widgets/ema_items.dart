/// Ítems EMA reutilizables (tarea 2.14).
///
/// Widgets de presentación portados del prototipo "Contigo"
/// (`src/screens/ema.tsx`): el ítem de rango continuo ([EmaRangeItem]) y el
/// ítem binario Sí/No ([EmaBinaryItem]). Consumen los tokens del tema
/// (`lib/app/theme.dart`) y exponen su valor a las tecnologías de asistencia
/// con `Semantics` nativo de Flutter (Requirements 5.2, 5.3, 5.4). La pantalla
/// del flujo EMA (tarea 2.17) los compone; aquí solo viven los ítems y su
/// comportamiento/accesibilidad.
library;

export 'ema_binary_item.dart';
export 'ema_range_item.dart';
