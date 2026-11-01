/// Registro tipado de los recursos multimedia del prototipo "Contigo"
/// incorporados al bundle de assets de Flutter y preservados **verbatim**
/// (sin alterar, recomprimir, recortar ni reordenar), conforme a los
/// Requirements 2.1, 2.3, 7.6 y 8.3 y a la tarea 1.7 del plan de migración.
///
/// Propósito: que las pantallas narrativas (relato del plan de seguridad) y de
/// guía (mensajes de cuidado), así como el componente CompanionNote, consuman
/// estos recursos por rutas tipadas y **nunca** mediante literales de ruta
/// esparcidos por la UI. Así se garantiza una única fuente de verdad del origen
/// y se evita que un cambio accidental altere el contenido suministrado.
///
/// Origen y trazabilidad: los binarios provienen del prototipo React en
/// `public/media/` (ver `docs/analisis-prototipo.md`). Se conserva la misma
/// estructura de subcarpetas (`plan-desenredo/`, `caring-messages/`) y los
/// mismos nombres de archivo para mantener la trazabilidad con la fuente:
///
/// | Prototipo (`public/media/…`)            | Bundle Flutter (`assets/media/…`) |
/// | --------------------------------------- | --------------------------------- |
/// | `plan-desenredo/plan-desenredo-1.mp4`   | igual                             |
/// | `plan-desenredo/plan-desenredo-2.mp4`   | igual                             |
/// | `caring-messages/metafora.mp4`          | igual                             |
/// | `caring-messages/avatar.png`            | igual                             |
/// | `caring-messages/preparacion.png`       | igual                             |
/// | `caring-messages/historia-bastogne.png` | igual                             |
/// | `caring-messages/historia-cartas.jpeg`  | igual                             |
/// | `caring-messages/historia-conexion.png` | igual                             |
///
/// Estos recursos están declarados en `pubspec.yaml` (sección `flutter:
/// assets:`) bajo los directorios `assets/media/plan-desenredo/` y
/// `assets/media/caring-messages/`.
///
/// NOTA DE ALCANCE (tarea 1.7): este archivo solo cablea el bundle y expone las
/// rutas. Las pantallas que consumen estos recursos (relato del plan de
/// seguridad, guía de mensajes de cuidado, CompanionNote) se construyen en
/// tareas posteriores (3.13, 3.18, 1.5).
library;

/// Rutas tipadas de los recursos multimedia del bundle.
///
/// Todas las rutas son relativas a la raíz del paquete y coinciden con las
/// entradas declaradas en `pubspec.yaml`, por lo que pueden pasarse
/// directamente a `Image.asset`, `rootBundle.load`, `AssetSource`
/// (video_player / media kit) o `DecorationImage(AssetImage(...))`.
abstract final class AppMedia {
  AppMedia._();

  /// Carpeta raíz de los recursos multimedia dentro del bundle.
  static const String _mediaRoot = 'assets/media';

  // ---------------------------------------------------------------------------
  // Relato del plan de seguridad: "Las crisis también pasan"
  // (pantalla narrativa — `safety-plan-story` en el prototipo).
  // Dos videos insertados verbatim en las páginas 1 y 4 del relato.
  // ---------------------------------------------------------------------------

  static const String _planDesenredoDir = '$_mediaRoot/plan-desenredo';

  /// Video del relato del plan de seguridad usado en la página 1
  /// ("Conoce el plan para desenredar").
  static const String safetyPlanStoryVideo1 =
      '$_planDesenredoDir/plan-desenredo-1.mp4';

  /// Video del relato del plan de seguridad usado en la página 4
  /// ("Prepararnos para los momentos difíciles").
  static const String safetyPlanStoryVideo2 =
      '$_planDesenredoDir/plan-desenredo-2.mp4';

  /// Videos del relato del plan de seguridad en el orden en que aparecen.
  static const List<String> safetyPlanStoryVideos = <String>[
    safetyPlanStoryVideo1,
    safetyPlanStoryVideo2,
  ];

  // ---------------------------------------------------------------------------
  // Guía de mensajes de cuidado (`caring-message` en el prototipo) y avatar del
  // acompañante (CompanionNote). Todos los recursos viven en la misma carpeta
  // `caring-messages/` tal como en el prototipo.
  // ---------------------------------------------------------------------------

  static const String _caringMessagesDir = '$_mediaRoot/caring-messages';

  /// Imagen de avatar del acompañante usada por el componente CompanionNote y
  /// por la guía de mensajes de cuidado.
  static const String companionAvatar = '$_caringMessagesDir/avatar.png';

  /// Video de la guía de mensajes de cuidado (la "metáfora").
  static const String caringMessagesGuideVideo =
      '$_caringMessagesDir/metafora.mp4';

  /// Video(s) de la guía de mensajes de cuidado en el orden en que aparecen.
  static const List<String> caringMessagesGuideVideos = <String>[
    caringMessagesGuideVideo,
  ];

  /// Ilustración de la guía: el avatar respira y se prepara para conectar.
  static const String caringMessagesPreparacion =
      '$_caringMessagesDir/preparacion.png';

  /// Ilustración de la historia "Bastogne" en la guía de mensajes de cuidado.
  static const String caringMessagesHistoriaBastogne =
      '$_caringMessagesDir/historia-bastogne.png';

  /// Ilustración de la historia "Cartas" en la guía de mensajes de cuidado.
  static const String caringMessagesHistoriaCartas =
      '$_caringMessagesDir/historia-cartas.jpeg';

  /// Ilustración de la historia "Conexión" en la guía de mensajes de cuidado.
  static const String caringMessagesHistoriaConexion =
      '$_caringMessagesDir/historia-conexion.png';

  /// Ilustraciones de la guía de mensajes de cuidado en el orden del prototipo.
  static const List<String> caringMessagesIllustrations = <String>[
    caringMessagesPreparacion,
    caringMessagesHistoriaBastogne,
    caringMessagesHistoriaCartas,
    caringMessagesHistoriaConexion,
  ];

  /// Todas las rutas de recursos multimedia declaradas, útil para pruebas de
  /// presencia de assets en el bundle.
  static const List<String> all = <String>[
    safetyPlanStoryVideo1,
    safetyPlanStoryVideo2,
    companionAvatar,
    caringMessagesGuideVideo,
    caringMessagesPreparacion,
    caringMessagesHistoriaBastogne,
    caringMessagesHistoriaCartas,
    caringMessagesHistoriaConexion,
  ];
}
