/// Implementación de sesión (en memoria) de [EmaDraftStore].
library;

import '../../domain/ema/ema_draft.dart';
import '../../domain/repositories/repositories.dart';

/// [EmaDraftStore] de **sesión**: conserva el borrador EMA solo en memoria.
///
/// No realiza ninguna escritura en disco (ni `shared_preferences` ni otro
/// almacenamiento): en modo demo las respuestas clínicas del EMA no se
/// persisten (ver requisito 6 y design.md). El almacén solo guarda el último
/// borrador recibido; el reinicio por cambio de día lo aplica el dominio
/// (`prepareEmaDay`) sobre lo que devuelve [loadTodayDraft].
class InMemoryEmaDraftStore implements EmaDraftStore {
  EmaDraft? _draft;

  @override
  Future<EmaDraft?> loadTodayDraft() async => _draft;

  @override
  Future<void> saveDraft(EmaDraft draft) async {
    _draft = draft;
  }

  @override
  Future<void> clear() async {
    _draft = null;
  }
}
