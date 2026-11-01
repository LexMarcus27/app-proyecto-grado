import 'clinical_content_type.dart';
import 'content_validation_registry.dart';
import 'content_validation_status.dart';

/// Fragmento de Contenido_Clinico suministrado, cargado **verbatim**.
///
/// Un fragmento es una unidad ordenada de contenido de un tipo dado (p. ej. un
/// ítem del banco EMA, una página del relato, una página de la guía de mensajes
/// de cuidado). El [body] se conserva idéntico carácter por carácter al recurso
/// fuente suministrado: el mecanismo de carga no altera, trunca, reordena ni
/// parafrasea el texto (Requirement 2.1).
class ClinicalContentFragment {
  const ClinicalContentFragment({
    required this.contentType,
    required this.key,
    required this.body,
  });

  /// Tipo de Contenido_Clinico al que pertenece el fragmento.
  final ClinicalContentType contentType;

  /// Identificador estable del fragmento dentro de su tipo (p. ej. el id del
  /// ítem EMA o el número de página). Define el **orden** de presentación sin
  /// que el cargador lo reordene.
  final String key;

  /// Cuerpo del contenido, preservado verbatim (carácter por carácter).
  final String body;
}

/// Mecanismo de carga del Contenido_Clinico **verbatim**.
///
/// Diseño del scaffold (tarea 1.6):
/// - El cargador recibe fuentes de contenido ([ClinicalContentSource]) por tipo
///   de contenido y devuelve los fragmentos **tal cual** fueron suministrados,
///   preservando orden y texto (sin alterar, truncar ni reordenar;
///   Requirement 2.1).
/// - Es **Dart puro** (no depende de Flutter ni de Firebase), de modo que el
///   dominio y las pruebas con `dart test` pueden ejercitarlo.
/// - Es **extensible**: las tareas de feature posteriores registran los cuerpos
///   de texto reales de cada tipo de contenido aportando una
///   [ClinicalContentSource]; este scaffold provee la estructura y los
///   metadatos de validación por tipo de contenido (Estado_Validacion_Contenido).
/// - Si se detecta una discrepancia respecto a la fuente suministrada, se
///   conserva el texto original suministrado (Requirement 2.2): el cargador no
///   reemplaza ni normaliza el contenido.
class ClinicalContentLoader {
  ClinicalContentLoader({
    ContentValidationRegistry? validationRegistry,
    Map<ClinicalContentType, ClinicalContentSource>? sources,
  }) : _validationRegistry =
           validationRegistry ?? ContentValidationRegistry.defaults,
       _sources = <ClinicalContentType, ClinicalContentSource>{...?sources};

  final ContentValidationRegistry _validationRegistry;
  final Map<ClinicalContentType, ClinicalContentSource> _sources;

  /// Registra (o reemplaza) la fuente de contenido de un tipo. Lo usan las
  /// tareas de feature posteriores para aportar los cuerpos de texto verbatim.
  void registerSource(
    ClinicalContentType contentType,
    ClinicalContentSource source,
  ) {
    _sources[contentType] = source;
  }

  /// `true` si existe una fuente registrada para [contentType].
  bool hasSource(ClinicalContentType contentType) =>
      _sources.containsKey(contentType);

  /// Metadato de Estado_Validacion_Contenido del tipo de contenido.
  ContentValidationMetadata? validationMetadataFor(
    ClinicalContentType contentType,
  ) => _validationRegistry.metadataFor(contentType);

  /// Carga los fragmentos del tipo de contenido **verbatim y en orden**.
  ///
  /// Devuelve la lista de fragmentos tal como los entrega la fuente registrada,
  /// sin alterar el texto ni reordenarlos. Lanza [StateError] si no hay fuente
  /// registrada para ese tipo (el contenido real lo aportan tareas
  /// posteriores).
  List<ClinicalContentFragment> load(ClinicalContentType contentType) {
    final source = _sources[contentType];
    if (source == null) {
      throw StateError(
        'No hay fuente de Contenido_Clinico registrada para $contentType. '
        'Las tareas de feature posteriores deben registrar su '
        'ClinicalContentSource verbatim.',
      );
    }
    // Se devuelve una lista no modificable con los fragmentos en el mismo orden
    // que entrega la fuente: el cargador no reordena ni altera el contenido.
    return List<ClinicalContentFragment>.unmodifiable(source.fragments());
  }
}

/// Fuente de Contenido_Clinico de un tipo concreto.
///
/// Una fuente entrega los fragmentos **en orden** y **verbatim**. Las tareas de
/// feature posteriores implementan fuentes concretas con los cuerpos de texto
/// suministrados (banco EMA, relato, guía de mensajes, modo crisis).
abstract class ClinicalContentSource {
  /// Fragmentos del contenido, en el orden de presentación, sin alterar.
  List<ClinicalContentFragment> fragments();
}

/// Fuente en memoria a partir de una lista de fragmentos ya suministrados.
///
/// Útil para registrar contenido verbatim definido en Dart y para las pruebas.
/// Conserva el orden y el texto exactos de los fragmentos recibidos.
class InMemoryClinicalContentSource implements ClinicalContentSource {
  InMemoryClinicalContentSource(List<ClinicalContentFragment> fragments)
    : _fragments = List<ClinicalContentFragment>.unmodifiable(fragments);

  final List<ClinicalContentFragment> _fragments;

  @override
  List<ClinicalContentFragment> fragments() => _fragments;
}
