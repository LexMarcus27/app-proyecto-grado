/// Componentes de UI reutilizables portados del prototipo "Contigo" (tarea 1.5).
///
/// Equivalentes a los componentes de `src/ui.tsx` y
/// `src/components/companion-note.tsx` del prototipo, más el indicador de
/// simulación persistente (Requirement 3.4) que la UI muestra según el metadato
/// de capa por feature ([FeatureLayer]).
///
/// Todos consumen tokens del tema (`lib/app/theme.dart`) y los recursos
/// multimedia registrados (`lib/content/app_media.dart`); ninguno codifica
/// colores o rutas de asset a mano.
library;

export '../feature_layer.dart';
export 'companion_note.dart';
export 'contigo_button.dart';
export 'contigo_card.dart';
export 'simulation_indicator.dart';
export 'status_bar.dart';
export 'home_art.dart';
export 'role_navigation.dart';
export 'support_button.dart';
export 'tile_grid.dart';
export 'pcs_internal.dart';
