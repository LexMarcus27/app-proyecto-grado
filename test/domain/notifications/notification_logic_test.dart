// Pruebas del dominio de notificaciones (tarea 3.25): elegibilidad sin red
// activa (Property 21) y resolución del marcador de persona (Property 22),
// portadas del prototipo (src/notifications.ts).

import 'package:contigo/domain/journey/demo_scenario.dart';
import 'package:contigo/domain/journey/journey_authorization.dart';
import 'package:contigo/domain/notifications/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fuente "aleatoria" determinista que recorre una secuencia de valores en
/// [0,1). Útil para forzar selecciones concretas de tipo/plantilla/persona.
class _SeqRandom {
  _SeqRandom(this.values);
  final List<double> values;
  int _i = 0;
  double next() {
    final v = values[_i % values.length];
    _i++;
    return v;
  }
}

void main() {
  final withLink = seedForScenario(DemoScenario.withActiveLink);
  final withoutLink = seedForScenario(DemoScenario.withoutActiveLink);

  group('Property 21: elegibilidad sin red activa', () {
    test('sin personas vinculadas activas solo salen recordatorios', () {
      expect(validCaregivers(withoutLink), isEmpty);
      // Recorre muchas combinaciones deterministas del generador.
      for (var a = 0.0; a < 1.0; a += 0.1) {
        for (var b = 0.0; b < 1.0; b += 0.1) {
          final rnd = _SeqRandom([a, b, 0.0]);
          final n = createRandomNotification(withoutLink, random: rnd.next);
          expect(n.template.action, NotificationAction.relationships);
          expect(n.template.type, NotificationType.reminder);
          // Un recordatorio no apunta a persona ni deja marcador.
          expect(n.personId, isNull);
          expect(n.text.contains('XXX'), isFalse);
        }
      }
    });

    test('con personas vinculadas activas puede salir una acción dirigida', () {
      expect(validCaregivers(withLink), isNotEmpty);
      // Forzamos el primer tipo no-recordatorio recorriendo tipos.
      var sawDirected = false;
      for (var a = 0.0; a < 1.0; a += 0.05) {
        final rnd = _SeqRandom([a, 0.0, 0.0]);
        final n = createRandomNotification(withLink, random: rnd.next);
        if (n.template.action != NotificationAction.relationships) {
          sawDirected = true;
          break;
        }
      }
      expect(sawDirected, isTrue);
    });
  });

  group('Property 22: resolución del marcador de persona', () {
    test('toda notificación dirigida sustituye XXX por una persona activa', () {
      final activeNames =
          validCaregivers(withLink).map((p) => p.name).toSet();
      for (var a = 0.0; a < 1.0; a += 0.03) {
        for (var b = 0.0; b < 1.0; b += 0.07) {
          final rnd = _SeqRandom([a, b, b]);
          final n = createRandomNotification(withLink, random: rnd.next);
          // Nunca debe quedar el marcador sin resolver.
          expect(n.text.contains('XXX'), isFalse);
          if (n.personName != null) {
            expect(activeNames.contains(n.personName), isTrue);
          }
        }
      }
    });
  });

  group('plantillas y estilo', () {
    test('las plantillas se conservan verbatim y en orden', () {
      expect(notificationTemplates.first.id, 'reminder-directions');
      expect(notificationTemplates.last.id, 'meeting-see');
      expect(notificationTemplates.length, 11);
    });

    test('la plantilla de cercanía usa su subtipo como clave de estilo', () {
      final closeness =
          notificationTemplates.firstWhere((t) => t.id == 'questions-closeness');
      expect(closeness.styleKey, notificationSubtypeCloseness);
    });
  });
}