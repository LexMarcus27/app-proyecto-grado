import 'package:equatable/equatable.dart';

import 'ema_reference.dart';

/// Sentinela interno para distinguir "no cambiar" de "poner en null" en
/// [EmaDraft.copyWith] para los campos anulables [EmaDraft.reference] y
/// [EmaDraft.relationshipOmission].
const Object _unset = Object();

/// Borrador diario del registro EMA.
///
/// Portado del prototipo (`src/ema.ts`, interfaz `EmaDraft`). Modelo inmutable
/// con igualdad por valor.
///
/// [answers] está indexada por posición de ítem y cada entrada es `bool`, `int`
/// o `null`: `null` representa un ítem sin responder, mientras que `false` ("No")
/// y `0` (extremo "Nada cierta") cuentan como respuestas explícitas.
class EmaDraft extends Equatable {
  const EmaDraft({
    required this.version,
    required this.day,
    required this.reference,
    required this.relationshipOmission,
    required this.answers,
    required this.questionIndex,
    required this.completed,
  });

  /// Versión del banco del borrador (debe coincidir con `emaVersion`).
  final String version;

  /// Clave de día local (`YYYY-MM-DD`) para el reinicio diario.
  final String day;

  /// Referencia de relación (solo IDs), o `null` si no hay/se omitió.
  final EmaReference? reference;

  /// Omisión del bloque de relación: `"no-active-link"` o `null`.
  final String? relationshipOmission;

  /// Respuestas por ítem: `bool`, `int` o `null` (sin responder).
  final List<Object?> answers;

  /// Posición/avance actual del registro.
  final int questionIndex;

  /// `true` si el registro diario fue finalizado.
  final bool completed;

  /// Devuelve una copia con los campos indicados reemplazados.
  ///
  /// [reference] y [relationshipOmission] admiten establecerse en `null`
  /// explícitamente (a diferencia de otros `copyWith` del proyecto); omitir el
  /// parámetro conserva el valor actual.
  EmaDraft copyWith({
    String? version,
    String? day,
    Object? reference = _unset,
    Object? relationshipOmission = _unset,
    List<Object?>? answers,
    int? questionIndex,
    bool? completed,
  }) {
    return EmaDraft(
      version: version ?? this.version,
      day: day ?? this.day,
      reference: identical(reference, _unset)
          ? this.reference
          : reference as EmaReference?,
      relationshipOmission: identical(relationshipOmission, _unset)
          ? this.relationshipOmission
          : relationshipOmission as String?,
      answers: answers ?? this.answers,
      questionIndex: questionIndex ?? this.questionIndex,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
    version,
    day,
    reference,
    relationshipOmission,
    answers,
    questionIndex,
    completed,
  ];
}
