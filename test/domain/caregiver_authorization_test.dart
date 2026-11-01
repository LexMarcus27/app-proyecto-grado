// Pruebas de autorización del cuidador portadas del prototipo.
//
// Portado verbatim del prototipo (`tests/caregiver.test.mjs`). Cada caso del
// prototipo se replica como un `test(...)` idiomático de Dart con `expect(...)`.
// Pruebas de ejemplo obligatorias del portado de dominio de autorización
// (tarea 2.2). Dart puro, sin Flutter ni Firebase.
import 'package:contigo/domain/journey/journey.dart';
import 'package:test/test.dart';

void main() {
  group('autorización del cuidador (portado de caregiver.test.mjs)', () {
    test(
      'el acceso del cuidador exige aceptación y la tupla exacta '
      'cuidador/PCS/persona activa',
      () {
        final linked = simulateCaregiverLink(
          emptyJourney,
          CaregiverDemoMode.active,
        );

        final context = caregiverContext(linked, DemoCaregiver.id);
        expect(context, isNotNull);
        expect(context!.pcsName, 'Sofía');
        expect(context.caregiverName, 'Marta');

        expect(caregiverContext(linked, 'another-caregiver'), isNull);

        // Cada cambio de un solo campo de la asociación rompe la tupla exacta.
        final changes = <CareAssociation Function(CareAssociation)>[
          (a) => a.copyWith(pcsId: 'another-pcs'),
          (a) => a.copyWith(caregiverId: 'another-caregiver'),
          (a) => a.copyWith(personId: 'another-person'),
          (a) => a.copyWith(active: false),
        ];
        for (final change in changes) {
          final altered = linked.copyWith(
            associations: [
              for (final a in linked.associations) change(a),
            ],
          );
          expect(caregiverContext(altered, DemoCaregiver.id), isNull);
        }

        // Si todas las personas quedan en invitación `pending`, no hay contexto.
        final pending = linked.copyWith(
          people: [
            for (final p in linked.people)
              p.copyWith(invitationStatus: InvitationStatus.pending),
          ],
        );
        expect(caregiverContext(pending, DemoCaregiver.id), isNull);
      },
    );

    test(
      'los estados vacío, solo-aceptado y revocado no exponen herramientas '
      'vinculadas',
      () {
        expect(caregiverContext(emptyJourney, DemoCaregiver.id), isNull);

        for (final mode in [
          CaregiverDemoMode.acceptedOnly,
          CaregiverDemoMode.revoked,
        ]) {
          expect(
            caregiverContext(
              simulateCaregiverLink(emptyJourney, mode),
              DemoCaregiver.id,
            ),
            isNull,
          );
        }

        final active = simulateCaregiverLink(
          emptyJourney,
          CaregiverDemoMode.active,
        );
        expect(
          caregiverContext(
            simulateCaregiverLink(active, CaregiverDemoMode.revoked),
            DemoCaregiver.id,
          ),
          isNull,
        );
      },
    );

    test(
      'las simulaciones demo preservan el mapa del PCS y no mutan su entrada',
      () {
        final original = createDemoJourney();
        // Clon de referencia por valor para verificar la ausencia de mutación.
        final snapshot = original.copyWith();

        var result = simulateCaregiverLink(original, CaregiverDemoMode.active);

        // No mutación: la entrada queda idéntica (igualdad por valor Equatable).
        expect(original, equals(snapshot));

        expect(result.onboardingStatus, original.onboardingStatus);
        expect(result.selectedPersonId, original.selectedPersonId);

        // Las personas y asociaciones originales se conservan en el resultado.
        for (final person in original.people) {
          expect(result.people, contains(person));
        }
        for (final association in original.associations) {
          expect(result.associations, contains(association));
        }

        // Re-simular no duplica a Marta: exactamente una persona y una
        // asociación con el id del cuidador demo.
        result = simulateCaregiverLink(result, CaregiverDemoMode.acceptedOnly);
        result = simulateCaregiverLink(result, CaregiverDemoMode.active);
        expect(
          result.people.where((p) => p.caregiverId == DemoCaregiver.id).length,
          1,
        );
        expect(
          result.associations
              .where((a) => a.caregiverId == DemoCaregiver.id)
              .length,
          1,
        );
      },
    );

    test(
      'cambiar la identidad del cuidador resuelve solo su propia asociación',
      () {
        final result = simulateCaregiverLink(
          createDemoJourney(),
          CaregiverDemoMode.active,
        );

        expect(caregiverContext(result, 'caregiver-m')?.caregiverName, 'M.');
        // La asociación de Carmen está inactiva: no hay contexto.
        expect(caregiverContext(result, 'caregiver-carmen'), isNull);
        expect(
          caregiverContext(result, DemoCaregiver.id)?.caregiverName,
          'Marta',
        );
      },
    );
  });
}
