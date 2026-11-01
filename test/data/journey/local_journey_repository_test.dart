import 'package:contigo/data/journey/journey_json.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/journey/care_association.dart';
import 'package:contigo/domain/journey/invitation_status.dart';
import 'package:contigo/domain/journey/journey_demo.dart';
import 'package:contigo/domain/journey/journey_state.dart';
import 'package:contigo/domain/journey/network_person.dart';
import 'package:contigo/domain/journey/onboarding_status.dart';
import 'package:contigo/domain/journey/person_status.dart';
import 'package:contigo/domain/journey/relationship_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `JourneyState` de muestra que ejercita enums con `wireValue`, asociaciones
/// (activa e inactiva), respuestas con `null` y persona seleccionada.
JourneyState _sampleJourney() {
  return const JourneyState(
    mapStarted: true,
    mapGenerated: true,
    people: [
      NetworkPerson(
        id: 'demo-m',
        name: 'M.',
        relationshipType: RelationshipType.trabajoOEstudio,
        answers: [6, null, 5, 0, 2],
        status: PersonStatus.inProgress,
        invitationStatus: InvitationStatus.accepted,
        caregiverId: 'caregiver-m',
      ),
      NetworkPerson(
        id: 'demo-alex',
        name: 'Alex',
        answers: [],
        status: PersonStatus.pending,
        invitationStatus: InvitationStatus.notInvited,
      ),
    ],
    selectedPersonId: 'demo-m',
    associations: [
      CareAssociation(
        id: 'association-demo-m',
        pcsId: 'pcs-sofia',
        caregiverId: 'caregiver-m',
        personId: 'demo-m',
        active: true,
      ),
      CareAssociation(
        id: 'association-demo-carmen',
        pcsId: 'pcs-sofia',
        caregiverId: 'caregiver-carmen',
        personId: 'demo-carmen',
        active: false,
      ),
    ],
    onboardingStatus: OnboardingStatus.inProgress,
    onboardingWelcomeShown: true,
    activityInProgress: false,
    dailyCheckInPending: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JourneyJson', () {
    test('round-trip preserva enums por wireValue', () {
      final journey = _sampleJourney();
      final decoded = JourneyJson.journeyFromJson(
        JourneyJson.journeyToJson(journey),
      );
      expect(decoded, journey);
    });

    test('serializa enums con sus cadenas del prototipo (no el .name)', () {
      final json = JourneyJson.journeyToJson(_sampleJourney());
      expect(json['onboardingStatus'], 'in-progress');
      final person = (json['people'] as List).first as Map<String, dynamic>;
      expect(person['status'], 'in-progress');
      expect(person['invitationStatus'], 'accepted');
      expect(person['relationshipType'], 'Trabajo o estudio');
    });

    test('round-trip del recorrido demo completo', () {
      final demo = createDemoJourney();
      final decoded = JourneyJson.journeyFromJson(
        JourneyJson.journeyToJson(demo),
      );
      expect(decoded, demo);
    });
  });

  group('LocalJourneyRepository', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test('loadJourney devuelve emptyJourney cuando no hay nada almacenado',
        () async {
      final repo = LocalJourneyRepository(prefs);
      expect(await repo.loadJourney(), emptyJourney);
      await repo.dispose();
    });

    test('save seguido de load preserva el JourneyState exactamente', () async {
      final repo = LocalJourneyRepository(prefs);
      final journey = _sampleJourney();

      await repo.save(journey);
      final loaded = await repo.loadJourney();

      expect(loaded, journey);
      // Verificación profunda de piezas con wireValue y asociaciones.
      expect(loaded.associations.length, 2);
      expect(loaded.associations[0].active, isTrue);
      expect(loaded.associations[1].active, isFalse);
      expect(loaded.people[0].invitationStatus, InvitationStatus.accepted);
      expect(loaded.people[0].relationshipType,
          RelationshipType.trabajoOEstudio);
      expect(loaded.people[0].answers, [6, null, 5, 0, 2]);
      await repo.dispose();
    });

    test('un repositorio nuevo lee lo que otro guardó (persistencia real)',
        () async {
      final writer = LocalJourneyRepository(prefs);
      await writer.save(_sampleJourney());
      await writer.dispose();

      final reader = LocalJourneyRepository(prefs);
      expect(await reader.loadJourney(), _sampleJourney());
      await reader.dispose();
    });

    test('watchJourney emite el valor actual y luego cada cambio', () async {
      final repo = LocalJourneyRepository(prefs);
      final updated = _sampleJourney();

      final emissions = <JourneyState>[];
      final sub = repo.watchJourney().listen(emissions.add);

      // Permite que la emisión inicial (asíncrona) se procese.
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [emptyJourney]);

      await repo.save(updated);
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [emptyJourney, updated]);

      await sub.cancel();
      await repo.dispose();
    });

    test('updateAssociations reemplaza solo las asociaciones y emite',
        () async {
      final repo = LocalJourneyRepository(prefs);
      await repo.save(_sampleJourney());

      const nuevas = [
        CareAssociation(
          id: 'association-nueva',
          pcsId: 'pcs-sofia',
          caregiverId: 'caregiver-x',
          personId: 'demo-alex',
          active: true,
        ),
      ];
      await repo.updateAssociations(nuevas);

      final loaded = await repo.loadJourney();
      expect(loaded.associations, nuevas);
      // El resto del estado se conserva.
      expect(loaded.people, _sampleJourney().people);
      await repo.dispose();
    });

    test('updateInvitationStatus actualiza la persona indicada', () async {
      final repo = LocalJourneyRepository(prefs);
      await repo.save(_sampleJourney());

      await repo.updateInvitationStatus('demo-alex', InvitationStatus.pending);

      final loaded = await repo.loadJourney();
      final alex = loaded.people.firstWhere((p) => p.id == 'demo-alex');
      final m = loaded.people.firstWhere((p) => p.id == 'demo-m');
      expect(alex.invitationStatus, InvitationStatus.pending);
      expect(m.invitationStatus, InvitationStatus.accepted); // sin cambios
      await repo.dispose();
    });

    test('resetDemo persiste el seed (emptyJourney por defecto)', () async {
      final repo = LocalJourneyRepository(prefs);
      await repo.save(_sampleJourney());

      await repo.resetDemo();

      expect(await repo.loadJourney(), emptyJourney);
      await repo.dispose();
    });

    test('resetDemo usa el seed inyectado cuando se provee', () async {
      final seed = createDemoJourney();
      final repo = LocalJourneyRepository(prefs, seed: seed);

      await repo.resetDemo();

      expect(await repo.loadJourney(), seed);
      await repo.dispose();
    });

    test('load degrada a emptyJourney ante almacenamiento corrupto', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalJourneyRepository.defaultStorageKey: 'no-es-json-valido {',
      });
      final corruptPrefs = await SharedPreferences.getInstance();
      final repo = LocalJourneyRepository(corruptPrefs);

      expect(await repo.loadJourney(), emptyJourney);
      await repo.dispose();
    });
  });
}
