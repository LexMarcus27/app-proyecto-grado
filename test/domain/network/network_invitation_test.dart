// Pruebas del dominio de invitaciones del mapa de red (tarea 3.12), portado de
// `invitationLabel`/`invitationVariant` y el envío simulado de
// `src/screens/network.tsx`. Verifican que una invitación aceptada por sí sola
// no habilita las acciones de asociación activa (Requirement 9.9/9.10).

import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/network/network.dart';
import 'package:flutter_test/flutter_test.dart';

NetworkPerson _person(String id, InvitationStatus status) => NetworkPerson(
      id: id,
      name: id,
      answers: List<int?>.filled(18, 3),
      status: PersonStatus.complete,
      invitationStatus: status,
    );

/// Recorrido con una sola persona [status] y sin asociaciones activas.
JourneyState _journeyWith(InvitationStatus status) => createDemoJourney()
    .copyWith(people: [_person('x', status)], associations: const []);

void main() {
  group('invitationLabel / invitationVariant', () {
    test('vínculo activo: "Persona cercana vinculada" (ok)', () {
      final journey = createDemoJourney();
      final person = journey.people.firstWhere((p) => p.id == 'demo-m');
      expect(invitationLabel(person, journey), 'Persona cercana vinculada');
      expect(invitationVariant(person, journey), InvitationBadgeVariant.ok);
    });

    test('aceptada sin asociación activa: "Vinculación en proceso" (blue)', () {
      final journey = _journeyWith(InvitationStatus.accepted);
      final person = journey.people.single;
      expect(invitationLabel(person, journey), 'Vinculación en proceso');
      expect(invitationVariant(person, journey), InvitationBadgeVariant.blue);
    });

    test('pendiente: "Pendiente de aceptación" (warn)', () {
      final journey = _journeyWith(InvitationStatus.pending);
      final person = journey.people.single;
      expect(invitationLabel(person, journey), 'Pendiente de aceptación');
      expect(invitationVariant(person, journey), InvitationBadgeVariant.warn);
    });

    test('no invitada: "Sin invitación" (default)', () {
      final journey = _journeyWith(InvitationStatus.notInvited);
      final person = journey.people.single;
      expect(invitationLabel(person, journey), 'Sin invitación');
      expect(invitationVariant(person, journey),
          InvitationBadgeVariant.defaultVariant);
    });
  });

  group('canInvite', () {
    test('invita a no-invitada/rechazada/cancelada/expirada', () {
      expect(canInvite(_person('a', InvitationStatus.notInvited)), isTrue);
      expect(canInvite(_person('b', InvitationStatus.declined)), isTrue);
      expect(canInvite(_person('c', InvitationStatus.cancelled)), isTrue);
      expect(canInvite(_person('d', InvitationStatus.expired)), isTrue);
    });
    test('no reinvita a pendiente ni aceptada', () {
      expect(canInvite(_person('e', InvitationStatus.pending)), isFalse);
      expect(canInvite(_person('f', InvitationStatus.accepted)), isFalse);
    });
  });

  group('simulateInvite (Funcion_Simulada)', () {
    test('deja la invitación en pending y no crea asociación', () {
      final journey = _journeyWith(InvitationStatus.notInvited);
      final next = simulateInvite(journey, 'x');
      expect(next.people.single.invitationStatus, InvitationStatus.pending);
      expect(next.associations, isEmpty);
      // Una invitación pendiente no habilita acciones de asociación activa.
      expect(canStrengthenRelationship(next, 'x'), isFalse);
    });

    test('una invitación pendiente no cambia el estado', () {
      final journey = _journeyWith(InvitationStatus.pending);
      final next = simulateInvite(journey, 'x');
      expect(identical(next, journey), isTrue);
    });
  });
}