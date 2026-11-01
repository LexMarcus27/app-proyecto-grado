import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/ema/ema.dart';
import '../../domain/journey/journey.dart';
import '../network/network_map_screen.dart';
import '../widgets/widgets.dart';
import 'ema_no_link_first_run_view.dart';
import 'ema_reference_selection.dart';

/// Pantalla de selección de la Referencia_EMA (tarea 2.11).
///
/// Portado del estado `choosing` del prototipo (`src/screens/ema.tsx`): la UI
/// que se presenta **antes del primer registro** para que el PCS elija una
/// única persona de referencia entre las personas con vínculo activo
/// ([validCaregivers]). La elección se recuerda entre registros guardando solo
/// identificadores (Requirements 5.5 y 5.6; persistencia de solo IDs, 6.4).
///
/// Qué hace y qué NO hace en esta etapa:
/// - Presenta el encabezado/prompt del prototipo, la lista de radio de personas
///   con vínculo activo, el botón primario "Continuar con la persona elegida"
///   (deshabilitado hasta elegir) y la nota [emaReferenceHelp] verbatim.
/// - Al continuar recomputa la referencia con [emaReferenceForPerson]; si el
///   vínculo cambió por debajo (resultado `null`) muestra el aviso del prototipo
///   y **no** persiste ni avanza; en otro caso guarda la referencia vía
///   [EmaReferenceStore.saveReference] y continúa.
/// - **No** construye el flujo EMA de extremo a extremo (tarea 2.17). La
///   decisión de *cuándo* mostrar esta pantalla vive en la función pura
///   [shouldShowEmaReferenceSelection] para que 2.17 haga el gating; aquí solo
///   se renderiza la selección.
///
/// Continuación ("Continuar"): esta pantalla se usa empujada (push) desde el
/// futuro flujo EMA. Como 2.17 aún no existe, al continuar hace
/// `Navigator.pop(context, reference)` devolviendo la [EmaReference] recién
/// guardada; así 2.17 podrá empujarla con `await` y cablear la continuación real
/// sin cambiar esta pantalla. Si no hay a dónde volver (p. ej. se alcanzó por
/// ruta directa), navega al inicio del PCS.
///
/// Caso sin personas con vínculo activo (camino sin vínculo del primer
/// registro, tarea 2.16): cuando [validCaregivers] está vacío, esta pantalla
/// renderiza la vista compartida [EmaNoLinkFirstRunView] con la copia del
/// prototipo, la acción PRIMARIA "Ir a Tu mapa de red" y el enlace SECUNDARIO
/// "Continuar con el registro de hoy". El enlace secundario aplica
/// [omitEmaRelationship] al borrador de **sesión** (reusa el dominio y refleja
/// el cableado de la revisión obsoleta de 2.12) y vuelve con ese borrador
/// omitido, sin alterar ninguna referencia guardada (en primer registro no hay
/// ninguna).
class EmaReferenceSelectionScreen extends ConsumerStatefulWidget {
  const EmaReferenceSelectionScreen({super.key});

  @override
  ConsumerState<EmaReferenceSelectionScreen> createState() =>
      _EmaReferenceSelectionScreenState();
}

class _EmaReferenceSelectionScreenState
    extends ConsumerState<EmaReferenceSelectionScreen> {
  /// Persona marcada en la lista de radio (candidata), sin persistir aún.
  String? _candidateId;

  /// Aviso de estado (p. ej. "El vínculo cambió..."), vacío si no hay ninguno.
  String _notice = '';

  @override
  Widget build(BuildContext context) {
    final journeyAsync = ref.watch(networkJourneyProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            const _Banner(),
            Expanded(
              child: journeyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const _ErrorBody(),
                data: (journey) => _buildBody(context, journey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JourneyState journey) {
    final people = validCaregivers(journey);
    final textTheme = Theme.of(context).textTheme;

    if (people.isEmpty) {
      // Camino sin vínculo del primer registro (tarea 2.16): vista compartida
      // con la copia del prototipo y las dos acciones.
      return EmaNoLinkFirstRunView(
        onOpenNetwork: () => context.goNamed(AppRoute.networkMap),
        onContinueToday: () => _continueToday(context, journey),
      );
    }

    final candidate = _candidateId;
    final hasCandidate =
        candidate != null && people.any((person) => person.id == candidate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Prompt del prototipo (verbatim).
        Text(
          'Por favor, escoge una persona con la cual te sientas cercano/a y '
          'con la que estés vinculada en la aplicación.',
          style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
            color: ContigoColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        // Lista de radio de personas con vínculo activo.
        for (final person in people) ...[
          _ReferenceRadioTile(
            person: person,
            selected: candidate == person.id,
            onSelected: () {
              setState(() {
                _candidateId = person.id;
                _notice = '';
              });
            },
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        ContigoButton(
          label: 'Continuar con la persona elegida',
          fullWidth: true,
          // Deshabilitado hasta que haya una persona elegida.
          onPressed: hasCandidate
              ? () => _continueWithCandidate(context, journey, candidate)
              : null,
        ),
        if (_notice.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Notice(message: _notice),
        ],
        const SizedBox(height: 16),
        // Nota de ayuda del prototipo (verbatim).
        Text(
          emaReferenceHelp,
          style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: ContigoColors.inkMuted,
          ),
        ),
      ],
    );
  }

  /// Recalcula la referencia para la persona elegida y persiste si sigue válida.
  ///
  /// Si [emaReferenceForPerson] devuelve `null` (el vínculo cambió por debajo),
  /// muestra el aviso del prototipo y no persiste ni avanza.
  Future<void> _continueWithCandidate(
    BuildContext context,
    JourneyState journey,
    String personId,
  ) async {
    final reference = emaReferenceForPerson(journey, personId);
    if (reference == null) {
      setState(() {
        _notice = 'El vínculo cambió. Revisa tu red antes de continuar.';
      });
      return;
    }

    await ref.read(emaReferenceStoreProvider).saveReference(reference);
    // Refresca la referencia observada por el mapa/flujo para que la elección
    // recordada se refleje de inmediato (Requirement 5.6).
    ref.invalidate(savedEmaReferenceProvider);

    if (!context.mounted) return;
    // Continuación mínima: devolver la referencia al llamador (el flujo EMA de
    // 2.17 la empujará con `await`). Sin pila, ir al inicio del PCS.
    if (context.canPop()) {
      context.pop(reference);
    } else {
      context.goNamed(AppRoute.pcsHome);
    }
  }

  /// Aplica la omisión del bloque de relación **solo para hoy** (camino sin
  /// vínculo del primer registro, tarea 2.16) y continúa el flujo.
  ///
  /// Mismo cableado que la revisión de referencia obsoleta de 2.12
  /// (`EmaStaleReferenceScreen._continueToday`): toma el borrador de sesión (o
  /// crea uno con [createEmaDraft]), le aplica [omitEmaRelationship] —que solo
  /// surte efecto cuando no hay personas con vínculo activo, dejando 6 ítems
  /// presentados y `relationshipOmission == "no-active-link"`—, lo persiste en
  /// la **sesión** ([EmaDraftStore.saveDraft]) y vuelve con él como resultado
  /// para que 2.17 continúe el registro de 6 ítems. No altera ninguna
  /// [EmaReference] guardada (y en el primer registro no hay ninguna).
  Future<void> _continueToday(
    BuildContext context,
    JourneyState journey,
  ) async {
    final store = ref.read(emaDraftStoreProvider);
    final current = await store.loadTodayDraft() ?? createEmaDraft();
    final omitted = omitEmaRelationship(current, journey);
    await store.saveDraft(omitted);

    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop(omitted);
    } else {
      context.goNamed(AppRoute.pcsHome);
    }
  }
}

/// Banner superior del prototipo: "¿Cómo estoy hoy?" / "Tu tejido de hoy" /
/// "Antes de tu primer registro".
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Cómo estoy hoy?',
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tu tejido de hoy',
            style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
              color: ContigoColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Antes de tu primer registro',
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de radio de una persona con vínculo activo.
class _ReferenceRadioTile extends StatelessWidget {
  const _ReferenceRadioTile({
    required this.person,
    required this.selected,
    required this.onSelected,
  });

  final NetworkPerson person;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: person.name,
      child: ContigoCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onSelected,
        child: Row(
          children: [
            // Indicador de radio (la fila entera es el objetivo táctil; la
            // semántica de grupo excluyente la aporta el Semantics envolvente).
            ExcludeSemantics(
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? ContigoColors.terracotta
                    : ContigoColors.inkMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                person.name,
                style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                  color: ContigoColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso de estado (p. ej. cuando el vínculo cambió por debajo).
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: ContigoColors.clay,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Cuerpo de error: el almacenamiento del recorrido no se pudo leer.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No pudimos cargar tu red en este momento.',
          textAlign: TextAlign.center,
          style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
            color: ContigoColors.ink,
          ),
        ),
      ),
    );
  }
}
