/// Serialización JSON de los modelos de recorrido (journey).
///
/// Vive en la capa de datos para que el dominio (`lib/domain/journey`) quede
/// libre de preocupaciones de serialización. Los enums se serializan con su
/// `wireValue` del prototipo (no con el `.name` de Dart), de modo que los datos
/// persistidos coincidan exactamente con las cadenas del prototipo y hagan
/// round-trip sin pérdida (`not-invited`, `in-progress`, `Trabajo o estudio`,
/// etc.).
library;

import '../../domain/journey/care_association.dart';
import '../../domain/journey/invitation_status.dart';
import '../../domain/journey/journey_state.dart';
import '../../domain/journey/network_person.dart';
import '../../domain/journey/onboarding_status.dart';
import '../../domain/journey/person_status.dart';
import '../../domain/journey/relationship_type.dart';
import 'journey_storage_exception.dart';

/// Conversión entre los modelos de recorrido y mapas JSON.
///
/// Todos los métodos `fromJson` envuelven cualquier dato malformado en
/// [JourneyStorageException] para que la capa de repositorio pueda degradar de
/// forma controlada en lugar de propagar errores crudos.
class JourneyJson {
  const JourneyJson._();

  // --- CareAssociation --------------------------------------------------

  static Map<String, dynamic> associationToJson(CareAssociation a) {
    return <String, dynamic>{
      'id': a.id,
      'pcsId': a.pcsId,
      'caregiverId': a.caregiverId,
      'personId': a.personId,
      'active': a.active,
    };
  }

  static CareAssociation associationFromJson(Map<String, dynamic> json) {
    return CareAssociation(
      id: _string(json, 'id'),
      pcsId: _string(json, 'pcsId'),
      caregiverId: _string(json, 'caregiverId'),
      personId: _string(json, 'personId'),
      active: _bool(json, 'active'),
    );
  }

  // --- NetworkPerson ----------------------------------------------------

  static Map<String, dynamic> personToJson(NetworkPerson p) {
    return <String, dynamic>{
      'id': p.id,
      'name': p.name,
      'relationshipType': p.relationshipType?.wireValue,
      'answers': p.answers,
      'status': p.status.wireValue,
      'invitationStatus': p.invitationStatus.wireValue,
      'caregiverId': p.caregiverId,
    };
  }

  static NetworkPerson personFromJson(Map<String, dynamic> json) {
    return NetworkPerson(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      relationshipType: _optionalEnum(
        json['relationshipType'],
        RelationshipType.fromWire,
        'relationshipType',
      ),
      answers: _answers(json['answers']),
      status: _requiredEnum(json['status'], PersonStatus.fromWire, 'status'),
      invitationStatus: _requiredEnum(
        json['invitationStatus'],
        InvitationStatus.fromWire,
        'invitationStatus',
      ),
      caregiverId: json['caregiverId'] as String?,
    );
  }

  // --- JourneyState -----------------------------------------------------

  static Map<String, dynamic> journeyToJson(JourneyState s) {
    return <String, dynamic>{
      'mapStarted': s.mapStarted,
      'mapGenerated': s.mapGenerated,
      'people': [for (final p in s.people) personToJson(p)],
      'selectedPersonId': s.selectedPersonId,
      'associations': [for (final a in s.associations) associationToJson(a)],
      'onboardingStatus': s.onboardingStatus.wireValue,
      'onboardingWelcomeShown': s.onboardingWelcomeShown,
      'activityInProgress': s.activityInProgress,
      'dailyCheckInPending': s.dailyCheckInPending,
    };
  }

  static JourneyState journeyFromJson(Map<String, dynamic> json) {
    return JourneyState(
      mapStarted: _bool(json, 'mapStarted'),
      mapGenerated: _bool(json, 'mapGenerated'),
      people: _list(json['people'], personFromJson, 'people'),
      selectedPersonId: json['selectedPersonId'] as String?,
      associations: _list(
        json['associations'],
        associationFromJson,
        'associations',
      ),
      onboardingStatus: _requiredEnum(
        json['onboardingStatus'],
        OnboardingStatus.fromWire,
        'onboardingStatus',
      ),
      onboardingWelcomeShown: _bool(json, 'onboardingWelcomeShown'),
      activityInProgress: _bool(json, 'activityInProgress'),
      dailyCheckInPending: _bool(json, 'dailyCheckInPending'),
    );
  }

  // --- Helpers ----------------------------------------------------------

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw JourneyStorageException(
      'Campo "$key" ausente o no es una cadena.',
    );
  }

  static bool _bool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw JourneyStorageException(
      'Campo "$key" ausente o no es un booleano.',
    );
  }

  static List<int?> _answers(Object? raw) {
    if (raw is! List) {
      throw const JourneyStorageException(
        'Campo "answers" ausente o no es una lista.',
      );
    }
    return [
      for (final item in raw)
        if (item == null)
          null
        else if (item is int)
          item
        else if (item is num)
          item.toInt()
        else
          throw JourneyStorageException(
            'Respuesta inválida en "answers": $item',
          ),
    ];
  }

  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
    String field,
  ) {
    if (raw is! List) {
      throw JourneyStorageException(
        'Campo "$field" ausente o no es una lista.',
      );
    }
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>)
          fromJson(item)
        else if (item is Map)
          fromJson(Map<String, dynamic>.from(item))
        else
          throw JourneyStorageException(
            'Elemento inválido en "$field": $item',
          ),
    ];
  }

  static T _requiredEnum<T>(
    Object? raw,
    T Function(String) fromWire,
    String field,
  ) {
    if (raw is! String) {
      throw JourneyStorageException(
        'Campo "$field" ausente o no es una cadena.',
      );
    }
    try {
      return fromWire(raw);
    } on ArgumentError catch (e) {
      throw JourneyStorageException('Campo "$field" inválido: ${e.message}');
    }
  }

  static T? _optionalEnum<T>(
    Object? raw,
    T Function(String) fromWire,
    String field,
  ) {
    if (raw == null) return null;
    return _requiredEnum(raw, fromWire, field);
  }
}
