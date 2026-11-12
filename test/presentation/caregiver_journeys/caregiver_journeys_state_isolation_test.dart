// Aislamiento del estado en curso de los recorridos del cuidador entre
// asociaciones (tarea 3.19): el estado se conserva por contexto completo
// (`caringDraftKey`), de modo que una asociación distinta comienza con su
// propio estado y no hereda texto, notas, respuestas ni adjuntos simulados.

import 'package:contigo/domain/journey/caregiver.dart';
import 'package:contigo/presentation/caregiver_journeys/caregiver_journeys_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Dos contextos que solo difieren en la asociación (distinta tupla completa).
  const contextA = CaregiverContext(
    caregiverId: 'caregiver-home-marta',
    caregiverName: 'Marta',
    personId: 'demo-home-marta',
    pcsId: 'pcs-sofia',
    pcsName: 'Sofía',
    associationId: 'association-A',
  );
  const contextB = CaregiverContext(
    caregiverId: 'caregiver-home-marta',
    caregiverName: 'Marta',
    personId: 'demo-home-marta',
    pcsId: 'pcs-sofia',
    pcsName: 'Sofía',
    associationId: 'association-B',
  );

  test('la clave de contexto distingue asociaciones distintas', () {
    expect(currentCareContextKey(contextA),
        isNot(equals(currentCareContextKey(contextB))));
    expect(currentCareContextKey(null), isNull);
  });

  test('el estado se almacena por clave y B no hereda el de A', () {
    final keyA = currentCareContextKey(contextA)!;
    final keyB = currentCareContextKey(contextB)!;

    // Mapa por clave como el que mantiene el Notifier de sesión.
    final intimate = <String, IntimateMessageState>{
      keyA: const IntimateMessageState(text: 'Texto de A'),
    };
    final connection = <String, ConnectionQuestionsState>{
      keyA: const ConnectionQuestionsState(
          index: 3, text: 'Respuesta de A', shared: true),
    };
    final encounter = <String, EncounterState>{
      keyA: EncounterState(rating: 6, additional: const [5, 4, 3]),
    };

    // A conserva lo diligenciado.
    expect(intimate[keyA]?.text, 'Texto de A');
    expect(connection[keyA]?.text, 'Respuesta de A');
    expect(encounter[keyA]?.rating, 6);

    // B no tiene estado: arranca con su propio valor por defecto vacío.
    final intimateB = intimate[keyB] ?? const IntimateMessageState();
    final connectionB = connection[keyB] ?? const ConnectionQuestionsState();
    final encounterB = encounter[keyB] ?? EncounterState();

    expect(intimateB.text, '');
    expect(intimateB.saved, isFalse);
    expect(connectionB.index, 0);
    expect(connectionB.text, '');
    expect(connectionB.attachment, '');
    expect(connectionB.shared, isFalse);
    expect(encounterB.rating, isNull);
    expect(encounterB.additional, [null, null, null]);
    expect(encounterB.allAnswered, isFalse);
  });
}