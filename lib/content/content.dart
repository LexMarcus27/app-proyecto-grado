/// Scaffold de carga de Contenido_Clinico verbatim y metadatos de
/// Estado_Validacion_Contenido por tipo de contenido (tarea 1.6).
///
/// Exporta:
/// - [ClinicalContentType]: tipos de Contenido_Clinico.
/// - [ContentValidationStatus] / [ContentValidationMetadata]: metadatos de
///   validación por tipo de contenido.
/// - [ContentValidationRegistry]: registro por tipo de contenido.
/// - [ClinicalContentLoader] y afines: mecanismo de carga verbatim extensible.
/// - [AppMedia]: rutas tipadas de los recursos multimedia del prototipo
///   (videos del relato del plan de seguridad y de la guía de mensajes de
///   cuidado, avatar del acompañante / CompanionNote), declarados en
///   `pubspec.yaml` y preservados verbatim (tarea 1.7).
library;

export 'app_media.dart';
export 'clinical_content_loader.dart';
export 'clinical_content_type.dart';
export 'content_validation_registry.dart';
export 'content_validation_status.dart';
