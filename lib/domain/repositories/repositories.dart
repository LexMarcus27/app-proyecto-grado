/// Interfaces de repositorio/servicio del dominio.
///
/// El dominio **declara** estas interfaces; la capa de datos las implementa
/// (simuladas/locales ahora, Firebase después). La presentación depende solo de
/// estas interfaces, nunca de implementaciones concretas (ver design.md).
///
/// Las operaciones concretas de cada interfaz (watch/load/save, etc.) se añaden
/// junto con la tarea que porta el dominio correspondiente y su implementación
/// de datos. Aquí se declaran los tipos para poder exponer un provider por
/// interfaz en la composición de la app (`lib/app`), que se sobreescribe con la
/// implementación activa vía `ProviderScope`.
library;

import '../ema/ema_draft.dart';
import '../ema/ema_reference.dart';
import '../journey/care_association.dart';
import '../journey/invitation_status.dart';
import '../journey/journey_state.dart';

/// Lee/guarda el `JourneyState` (mapa de red, asociaciones). Implementación
/// inicial sobre almacenamiento local (persiste).
///
/// Las lecturas en vivo se exponen como `Stream` ([watchJourney]); las
/// operaciones asíncronas devuelven `Future`. Los errores de datos (p. ej. un
/// almacenamiento corrupto) se exponen como excepciones tipadas de la capa de
/// datos, no como estados inválidos del dominio.
abstract class JourneyRepository {
  /// Flujo en vivo del `JourneyState`. Emite el valor actual de inmediato al
  /// suscribirse y cada vez que el estado cambia (tras `save`/`update`/`reset`).
  Stream<JourneyState> watchJourney();

  /// Lee el `JourneyState` persistido. Si no hay nada almacenado devuelve el
  /// recorrido vacío (`emptyJourney`).
  Future<JourneyState> loadJourney();

  /// Persiste el `JourneyState` completo y lo emite por [watchJourney].
  Future<void> save(JourneyState journey);

  /// Reemplaza las asociaciones de cuidado del estado actual y persiste.
  Future<void> updateAssociations(List<CareAssociation> associations);

  /// Actualiza el `invitationStatus` de la persona [personId] en el estado
  /// actual y persiste. Si la persona no existe, el estado no cambia.
  Future<void> updateInvitationStatus(String personId, InvitationStatus status);

  /// Reinicializa el almacenamiento del recorrido a su estado semilla.
  Future<void> resetDemo();
}

/// Lee/guarda la `Referencia_EMA` (solo identificadores de persona).
/// Implementación inicial sobre almacenamiento local (persiste).
///
/// Persiste **únicamente** los cuatro identificadores de [EmaReference] (PCS,
/// persona, cuidador, asociación). Nunca escribe respuestas clínicas ni avance
/// del borrador: esa información es efímera (de sesión) en modo demo (ver
/// requisito 6 y design.md). Una referencia malformada, de otro PCS o con
/// identificadores vacíos se degrada a `null` en la lectura.
abstract class EmaReferenceStore {
  /// Lee la `Referencia_EMA` persistida (solo IDs). Devuelve `null` si no hay
  /// nada almacenado o si lo almacenado no es una referencia válida del PCS
  /// actual.
  Future<EmaReference?> loadReference();

  /// Persiste la [reference] actual guardando solo sus cuatro identificadores.
  Future<void> saveReference(EmaReference reference);

  /// Elimina la referencia persistida.
  Future<void> clear();
}

/// Borrador EMA diario. Implementación inicial en memoria (sesión).
///
/// Es un almacén de **sesión**: mantiene el borrador del día (incluido su
/// avance `questionIndex`) solo en memoria y nunca lo escribe en disco. En modo
/// demo las respuestas clínicas del EMA no se persisten (ver requisito 6 y
/// design.md). El reinicio por cambio de día lo aplica el dominio
/// (`prepareEmaDay`) sobre lo que devuelve [loadTodayDraft]; este almacén solo
/// conserva el borrador de la sesión. Las operaciones devuelven `Future` para
/// mantener la interfaz uniforme con el resto de repositorios.
abstract class EmaDraftStore {
  /// Devuelve el borrador conservado en la sesión, o `null` si no hay ninguno.
  Future<EmaDraft?> loadTodayDraft();

  /// Conserva [draft] en memoria para el resto de la sesión (incluye su avance
  /// `questionIndex`). No realiza ninguna escritura en disco.
  Future<void> saveDraft(EmaDraft draft);

  /// Descarta el borrador conservado en la sesión.
  Future<void> clear();
}

/// `SafetyPlanDraft`. Implementación inicial en memoria (sesión).
abstract class SafetyPlanStore {}

/// Registro/bandeja de mensajes de cuidado. Implementación inicial en memoria
/// con envío fingido (Capa_Simulada).
abstract class CaringMessageRepository {}

/// Envío de mensajes/invitaciones. Implementación inicial no-op simulada
/// (Capa_Simulada).
abstract class MessageSender {}

/// Generación/entrega de notificaciones. Implementación inicial local sin envío
/// externo (Capa_Simulada).
abstract class NotificationService {}

/// Importación de contactos del SO. Implementación inicial con flujo de
/// permisos fingido (Capa_Simulada).
abstract class ContactsService {}
