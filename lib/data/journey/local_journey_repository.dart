/// Implementación local de [JourneyRepository] sobre `shared_preferences`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/journey/care_association.dart';
import '../../domain/journey/invitation_status.dart';
import '../../domain/journey/journey_demo.dart';
import '../../domain/journey/journey_state.dart';
import '../../domain/repositories/repositories.dart';
import 'journey_json.dart';
import 'journey_storage_exception.dart';

/// [JourneyRepository] respaldado por `shared_preferences`.
///
/// Persiste el `JourneyState` como JSON bajo una clave estable. Las lecturas en
/// vivo se exponen por un `StreamController` broadcast que emite el valor
/// cargado y cada cambio posterior (`save`/`update`/`resetDemo`).
///
/// La política de semilla de 2.7 es **mínima**: si no hay nada almacenado,
/// [loadJourney] devuelve `emptyJourney` (no siembra el escenario demo). El
/// escenario demo rico es responsabilidad de la tarea 2.10; aquí [resetDemo]
/// solo persiste [seed] (por defecto `emptyJourney`), de modo que 2.10 pueda
/// inyectar un `seed` más completo sin cambiar esta clase.
class LocalJourneyRepository implements JourneyRepository {
  LocalJourneyRepository(
    this._prefs, {
    this.storageKey = defaultStorageKey,
    JourneyState? seed,
  }) : _seed = seed ?? emptyJourney;

  /// Clave estable de almacenamiento del `JourneyState`.
  static const String defaultStorageKey = 'contigo.journey';

  final SharedPreferences _prefs;

  /// Clave bajo la cual se persiste el `JourneyState` serializado.
  final String storageKey;

  /// Estado semilla usado por [resetDemo]. Por defecto `emptyJourney`.
  final JourneyState _seed;

  final StreamController<JourneyState> _controller =
      StreamController<JourneyState>.broadcast();

  /// Último estado emitido, cacheado para que las nuevas suscripciones reciban
  /// el valor actual de inmediato sin volver a leer el almacenamiento.
  JourneyState? _current;

  @override
  Stream<JourneyState> watchJourney() async* {
    final current = _current ??= await loadJourney();
    yield current;
    yield* _controller.stream;
  }

  @override
  Future<JourneyState> loadJourney() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null) {
      _current = emptyJourney;
      return emptyJourney;
    }
    final journey = _decode(raw);
    _current = journey;
    return journey;
  }

  @override
  Future<void> save(JourneyState journey) async {
    await _persist(journey);
  }

  @override
  Future<void> updateAssociations(List<CareAssociation> associations) async {
    final base = await _loadForMutation();
    await _persist(
      base.copyWith(associations: List<CareAssociation>.from(associations)),
    );
  }

  @override
  Future<void> updateInvitationStatus(
    String personId,
    InvitationStatus status,
  ) async {
    final base = await _loadForMutation();
    final updated = [
      for (final person in base.people)
        if (person.id == personId)
          person.copyWith(invitationStatus: status)
        else
          person,
    ];
    await _persist(base.copyWith(people: updated));
  }

  @override
  Future<void> resetDemo() async {
    await _persist(_seed);
  }

  /// Cierra el `StreamController`. Útil en pruebas o al desechar el repositorio.
  Future<void> dispose() => _controller.close();

  // --- Internos ---------------------------------------------------------

  Future<JourneyState> _loadForMutation() async {
    return _current ?? await loadJourney();
  }

  Future<void> _persist(JourneyState journey) async {
    final encoded = jsonEncode(JourneyJson.journeyToJson(journey));
    await _prefs.setString(storageKey, encoded);
    _current = journey;
    if (!_controller.isClosed) {
      _controller.add(journey);
    }
  }

  /// Decodifica el JSON persistido y lo degrada de forma controlada: ante datos
  /// corruptos vuelve a `emptyJourney` en lugar de propagar el error crudo.
  JourneyState _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const JourneyStorageException(
          'El recorrido persistido no es un objeto JSON.',
        );
      }
      return JourneyJson.journeyFromJson(decoded);
    } on JourneyStorageException {
      return emptyJourney;
    } on FormatException {
      return emptyJourney;
    }
  }
}
