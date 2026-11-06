// Pruebas del dominio de conexión (tarea 3.20): rotación cíclica de pasos
// (Property 13), contenido verbatim y gating del lanzamiento. Portado de
// src/connection.ts.

import 'package:contigo/domain/connection/connection.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextConnectionStep (Property 13: rotación cíclica)', () {
    test('avanza en el orden del prototipo y vuelve al inicio', () {
      expect(nextConnectionStep(ConnectionStep.message), ConnectionStep.received);
      expect(nextConnectionStep(ConnectionStep.received), ConnectionStep.contact);
      expect(nextConnectionStep(ConnectionStep.contact), ConnectionStep.meeting);
      expect(nextConnectionStep(ConnectionStep.meeting), ConnectionStep.skills);
      // Tras el último, vuelve al primero (ciclo).
      expect(nextConnectionStep(ConnectionStep.skills), ConnectionStep.message);
    });

    test('tras N pasos (N = número de pasos) regresa al origen', () {
      final n = ConnectionStep.values.length;
      for (final start in ConnectionStep.values) {
        var step = start;
        for (var i = 0; i < n; i++) {
          step = nextConnectionStep(step);
        }
        expect(step, start, reason: 'Un ciclo completo vuelve al inicio');
      }
    });
  });

  group('connectionStepContent', () {
    test('interpola el nombre o usa "alguien cercano"', () {
      expect(
        connectionStepContent(ConnectionStep.message, name: 'Ana').title,
        'Escríbele a Ana',
      );
      expect(
        connectionStepContent(ConnectionStep.message).title,
        'Escríbele a alguien cercano',
      );
    });

    test('los pasos sin nombre (received/skills) son verbatim', () {
      expect(
        connectionStepContent(ConnectionStep.received).title,
        'Vuelve a tus mensajes de cuidado',
      );
      expect(
        connectionStepContent(ConnectionStep.skills).tile,
        'Habilidades interpersonales',
      );
    });
  });

  group('connectionLaunch (gating)', () {
    test('lanza una acción dirigida si hay vínculo activo', () {
      final journey = createDemoJourney();
      final launch =
          connectionLaunch(journey, 'demo-m', ConnectionAction.message);
      expect(launch, isNotNull);
      expect(launch!.personId, 'demo-m');
      expect(launch.action, ConnectionAction.message);
    });

    test('no lanza sin vínculo activo (revocado)', () {
      final revoked = seedForScenario(DemoScenario.withoutActiveLink);
      expect(
        connectionLaunch(revoked, 'demo-m', ConnectionAction.message),
        isNull,
      );
    });

    test('no lanza para una persona sin asociación activa', () {
      final journey = createDemoJourney();
      // demo-carmen: accepted pero asociación inactiva.
      expect(
        connectionLaunch(journey, 'demo-carmen', ConnectionAction.contact),
        isNull,
      );
    });
  });
}