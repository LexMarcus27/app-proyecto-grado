/// Tipo de ítem EMA.
///
/// Portado del prototipo (`src/ema.ts`, campo `kind` de `EMA_ITEMS`):
/// `"binary"` acepta solo respuestas booleanas (Sí/No) y `"range"` acepta un
/// entero finito en `0..100`.
enum EmaItemKind {
  /// Ítem binario Sí/No (respuesta booleana).
  binary,

  /// Ítem de rango continuo (entero `0..100`).
  range,
}

/// Bloque temático al que pertenece un ítem EMA.
///
/// Portado del prototipo (`src/ema.ts`, campo `block` de `EMA_ITEMS`): el banco
/// `daily-nine-v2` se organiza en tres bloques —self (ideación), relationship
/// (relación con la persona de referencia) y connection (conexión social)—.
/// El bloque `relationship` es el único que puede omitirse cuando no hay
/// vínculo activo.
enum EmaItemBlock {
  /// Bloque personal/ideación (ítems binarios).
  self,

  /// Bloque de relación con la persona de referencia (omitible).
  relationship,

  /// Bloque de conexión social.
  connection,
}

/// Ítem del banco diario EMA.
///
/// Portado verbatim del prototipo (`src/ema.ts`, elementos de `EMA_ITEMS`).
/// Modelo inmutable. El texto clínico ([text]) se preserva carácter por
/// carácter respecto del prototipo.
class EmaItem {
  const EmaItem({
    required this.id,
    required this.kind,
    required this.block,
    required this.text,
  });

  /// Identificador estable del ítem (p. ej. `daily-ideation-01`).
  final String id;

  /// Tipo de respuesta admitida ([EmaItemKind.binary] o [EmaItemKind.range]).
  final EmaItemKind kind;

  /// Bloque temático del ítem.
  final EmaItemBlock block;

  /// Texto clínico del ítem, verbatim del prototipo.
  final String text;
}
