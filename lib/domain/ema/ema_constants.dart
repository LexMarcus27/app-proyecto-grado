import 'ema_item.dart';

/// Versión del banco diario EMA.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `EMA_VERSION`). La cadena
/// `daily-nine-v2` identifica el banco oficial de nueve ítems suministrado tras
/// la revisión del evaluador y es usada para el reinicio diario del borrador y
/// la validación de completitud.
const String emaVersion = 'daily-nine-v2';

/// Ventana temporal del registro EMA.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `EMA_TIME_WINDOW`). Texto
/// clínico preservado carácter por carácter.
const String emaTimeWindow =
    'Pensando en hoy, desde que te despertaste hasta ahora';

/// Ayuda para cambiar la persona de referencia del EMA.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `EMA_REFERENCE_HELP`). Texto
/// clínico preservado carácter por carácter.
const String emaReferenceHelp =
    'Podrás cambiar esta elección en Conoce tu red → Tu mapa de red. Abre la ficha de una persona cercana vinculada y elige Seleccionar para registro EMA.';

/// Banco oficial de nueve ítems diarios.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `EMA_ITEMS`). Orden, ids,
/// tipos, bloques y textos clínicos se preservan exactamente: tres ítems
/// binarios del bloque `self` (ideación), seguidos del bloque `relationship`
/// (tres rangos) y del bloque `connection` (tres rangos).
const List<EmaItem> emaItems = [
  EmaItem(
    id: 'daily-ideation-01',
    kind: EmaItemKind.binary,
    block: EmaItemBlock.self,
    text: 'Hoy, ¿has pensado en hacer algo para terminar con tu vida?',
  ),
  EmaItem(
    id: 'daily-ideation-02',
    kind: EmaItemKind.binary,
    block: EmaItemBlock.self,
    text: 'Hoy, ¿has pensado en cómo podrías terminar con tu vida?',
  ),
  EmaItem(
    id: 'daily-ideation-03',
    kind: EmaItemKind.binary,
    block: EmaItemBlock.self,
    text:
        'Hoy, ¿has tenido la intención, aunque sea mínima, de llevar a cabo estos pensamientos?',
  ),
  EmaItem(
    id: 'daily-relationship-01',
    kind: EmaItemKind.range,
    block: EmaItemBlock.relationship,
    text:
        'Hoy te has sentido cómodo/a contándole a esta persona cosas que no les cuentas a otras personas.',
  ),
  EmaItem(
    id: 'daily-relationship-02',
    kind: EmaItemKind.range,
    block: EmaItemBlock.relationship,
    text: 'Hoy has sido abierto y cariñoso con esta persona.',
  ),
  EmaItem(
    id: 'daily-relationship-03',
    kind: EmaItemKind.range,
    block: EmaItemBlock.relationship,
    text: 'Hoy has expresado a esta persona tus sentimientos hacia ella.',
  ),
  EmaItem(
    id: 'daily-connection-01',
    kind: EmaItemKind.range,
    block: EmaItemBlock.connection,
    text: 'Hoy, ha sido fácil relacionarme con otros.',
  ),
  EmaItem(
    id: 'daily-connection-02',
    kind: EmaItemKind.range,
    block: EmaItemBlock.connection,
    text: 'Hoy, he tenido a alguien con quien compartir mis sentimientos.',
  ),
  EmaItem(
    id: 'daily-connection-03',
    kind: EmaItemKind.range,
    block: EmaItemBlock.connection,
    text: 'Hoy, me ha sido fácil conectar con otros cuando lo he necesitado.',
  ),
];
