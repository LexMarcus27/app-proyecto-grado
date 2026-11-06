import 'package:equatable/equatable.dart';

import '../journey/journey_authorization.dart';
import '../journey/journey_demo.dart';
import '../journey/journey_state.dart';

/// Dominio de conexión ("Tejiendo vínculos"), portado verbatim del prototipo
/// (`src/connection.ts`). Dart puro, sin dependencias de Flutter.

/// Pasos de conexión, en el orden exacto del prototipo (`CONNECTION_STEPS`).
enum ConnectionStep {
  message('message'),
  received('received'),
  contact('contact'),
  meeting('meeting'),
  skills('skills');

  const ConnectionStep(this.wireValue);

  final String wireValue;
}

/// Acciones de conexión dirigidas a una persona (`ConnectionAction`). Solo
/// `message`, `contact` y `meeting` lanzan una acción con gating.
enum ConnectionAction {
  message('message'),
  contact('contact'),
  meeting('meeting');

  const ConnectionAction(this.wireValue);

  final String wireValue;
}

/// Siguiente paso en **rotación cíclica** (portado de `nextConnectionStep`):
/// avanza al siguiente de [ConnectionStep.values] y vuelve al principio tras el
/// último, **sin exigir** completar el paso actual (Requirement 8.9, Property 13).
ConnectionStep nextConnectionStep(ConnectionStep step) {
  final values = ConnectionStep.values;
  return values[(values.indexOf(step) + 1) % values.length];
}

/// Contenido textual de un paso de conexión (portado de
/// `connectionStepContent`), con el nombre de la persona sustituido.
class ConnectionStepContent extends Equatable {
  const ConnectionStepContent({
    required this.title,
    required this.description,
    required this.button,
    required this.tile,
  });

  final String title;
  final String description;
  final String button;
  final String tile;

  @override
  List<Object?> get props => [title, description, button, tile];
}

/// Devuelve el contenido verbatim del [step], usando [name] (o "alguien
/// cercano" si es `null`/vacío) donde el prototipo interpola el nombre.
ConnectionStepContent connectionStepContent(ConnectionStep step, {String? name}) {
  final person = (name == null || name.isEmpty) ? 'alguien cercano' : name;
  switch (step) {
    case ConnectionStep.message:
      return ConnectionStepContent(
        title: 'Escríbele a $person',
        description:
            'Un mensaje corto basta. Si quieres, te ayudo a escribirlo.',
        button: 'Escribir mensaje',
        tile: 'Escribir mensaje para tejer cercanía',
      );
    case ConnectionStep.received:
      return const ConnectionStepContent(
        title: 'Vuelve a tus mensajes de cuidado',
        description:
            'Puedes leer las palabras que otras personas han guardado para ti.',
        button: 'Ver mensajes recibidos',
        tile: 'Ver mensajes de cuidado',
      );
    case ConnectionStep.contact:
      return ConnectionStepContent(
        title: 'Acércate a $person',
        description:
            'Un saludo o una conversación corta pueden ser un primer paso.',
        button: 'Contactar a alguien',
        tile: 'Contactar a alguien',
      );
    case ConnectionStep.meeting:
      return const ConnectionStepContent(
        title: 'Planea un encuentro',
        description:
            'Algo sencillo: un café, caminar o ver una serie en compañía.',
        button: 'Planear un encuentro',
        tile: 'Planear un encuentro',
      );
    case ConnectionStep.skills:
      return const ConnectionStepContent(
        title: 'Aprende una forma de conectar',
        description:
            'Explora habilidades que pueden ayudarte a cuidar tus relaciones.',
        button: 'Explorar habilidades',
        tile: 'Habilidades interpersonales',
      );
  }
}

/// Lanzamiento de una acción de conexión dirigida a [personId]
/// (portado de `connectionLaunch`).
class ConnectionLaunch extends Equatable {
  const ConnectionLaunch({required this.personId, required this.action});
  final String personId;
  final ConnectionAction action;

  @override
  List<Object?> get props => [personId, action];
}

/// Reevalúa la asociación activa exacta **en el momento del lanzamiento**
/// (incluida una revocación previa): devuelve el [ConnectionLaunch] solo si
/// [canStrengthenRelationship] autoriza la tupla; de lo contrario `null`
/// (Requirement 4.1, 8.10). Las acciones permitidas son `message`, `contact` y
/// `meeting`; cualquier otra no lanza.
ConnectionLaunch? connectionLaunch(
  JourneyState state,
  String personId,
  ConnectionAction action, {
  String pcsId = currentPcsId,
}) {
  if (!canStrengthenRelationship(state, personId, pcsId: pcsId)) return null;
  return ConnectionLaunch(personId: personId, action: action);
}