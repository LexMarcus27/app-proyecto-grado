# content

Carga de Contenido_Clinico **verbatim** (sin alterar, truncar ni reordenar) y
metadatos de `Estado_Validacion_Contenido` por tipo de contenido.

## Scaffold (tarea 1.6)

Esta carpeta provee la **estructura** y los **metadatos** de validación; los
cuerpos de texto verbatim de cada tipo de contenido los aportan las tareas de
feature posteriores registrando una `ClinicalContentSource`.

### Piezas

- `clinical_content_type.dart` — `ClinicalContentType`: enumera los tipos de
  Contenido_Clinico (banco EMA, relato del plan de seguridad, guía de mensajes
  de cuidado, textos de modo crisis, umbrales de evaluación de relación, cortes
  de métricas de red).
- `content_validation_status.dart` — `ContentValidationStatus` y
  `ContentValidationMetadata`: estado de validación **por tipo de contenido**
  (Estado_Validacion_Contenido), sin descargo global en la interfaz.
- `content_validation_registry.dart` — `ContentValidationRegistry`: registro con
  una entrada por tipo de contenido. Deja constancia de que el banco EMA
  `daily-nine-v2` fue suministrado tras revisión del evaluador y marca los
  umbrales/cortes como `Contenido_Validacion_Pendiente`.
- `clinical_content_loader.dart` — `ClinicalContentLoader`,
  `ClinicalContentSource`, `ClinicalContentFragment`,
  `InMemoryClinicalContentSource`: mecanismo de carga **verbatim** y extensible
  (Dart puro, sin Flutter/Firebase).
- `content.dart` — barrel de exportación.

### Principios

- **Verbatim (Requirement 2.1):** el cargador devuelve los fragmentos tal cual
  los entrega la fuente, preservando orden y texto carácter por carácter; no
  altera, trunca, reordena ni parafrasea.
- **Discrepancias (Requirement 2.2):** ante una discrepancia con la fuente
  suministrada se conserva el texto original; el cargador no normaliza ni
  reemplaza contenido.
- **Estado por tipo (Requirement 2.4):** cada tipo de contenido tiene su propio
  estado de validación registrado; no hay un único estado global.
- **Banco EMA (Requirement 2.5):** `daily-nine-v2` se registra como suministrado
  tras revisión del evaluador, no como validación clínica formal.
- **Pendiente a nivel de metadatos (Requirement 2.6):** los umbrales y cortes no
  validados se marcan como `Contenido_Validacion_Pendiente` en metadatos, sin
  mostrar un descargo "pendiente de validación clínica" en toda la interfaz.

> Los recursos multimedia (videos del relato, video de la guía, avatar de
> CompanionNote) se incorporan y declaran en `pubspec.yaml` en la **tarea 1.7**,
> no aquí.
