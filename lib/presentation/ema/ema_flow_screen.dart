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
import 'ema_flow_gating.dart';
import 'ema_no_link_first_run_view.dart';
import 'ema_reference_selection_screen.dart';
import 'ema_stale_reference_screen.dart';
import 'widgets/ema_items.dart';
import 'widgets/ema_style.dart';

/// Flujo EMA de extremo a extremo (tarea 2.17). Ruta nombrada [AppRoute.ema]
/// (`/ema`), punto de entrada del registro EMA diario del PCS.
///
/// Cierra la Etapa 2 componiendo todo lo ya construido: el dominio EMA puro
/// (banco de ítems, borrador, reglas de completitud y reinicio diario), los
/// ítems de presentación ([EmaRangeItem]/[EmaBinaryItem]), las superficies de
/// gating (selección de referencia 2.11, revisión de referencia obsoleta 2.12,
/// primer registro sin vínculo 2.16) y la entrada mínima al mapa (2.15). El
/// texto clínico y la copia se preservan verbatim respecto al prototipo
/// (`src/screens/ema.tsx`).
///
/// Responsabilidades:
/// - **Entrada / preparación del día**: resuelve el borrador de **sesión**
///   ([EmaDraftStore.loadTodayDraft]) y le aplica [prepareEmaDay] con la
///   referencia guardada para el reinicio por cambio de día; si no hay borrador,
///   crea uno nuevo con [createEmaDraft].
/// - **Compuerta (gating)**: usa la función pura [resolveEmaFlowGate] para
///   decidir qué presentar (revisión obsoleta → selección → camino sin vínculo
///   → cuestionario) y empuja las pantallas/vistas correspondientes con `await`,
///   continuando el flujo con el borrador/resultado devuelto.
/// - **Cuestionario**: progreso "Hilo {n} de {N}" por `questionIndex`, ítem
///   actual con la intro [emaTimeWindow], botones "Tejer y seguir"/"Tejer y
///   terminar" (deshabilitados hasta responder), "Hilo anterior" y una
///   afordancia de salida ("Prefiero responder después"). Avanza/retrocede
///   estrictamente dentro de [emaQuestionIndices] (de ahí los caminos de 9 o 6
///   ítems). Persiste el borrador en la sesión en cada respuesta/avance.
/// - **Resultado**: al completar ([canCompleteEma]) marca `completed`, persiste
///   y muestra una vista de resultado mínima y fiel (sin los próximos pasos de
///   conexión, que son Etapa 3) con un camino de vuelta al inicio.
///
/// Las respuestas clínicas se mantienen **solo de sesión** (almacén en memoria);
/// nunca se escriben en disco. No se calcula ni muestra puntuación.
///
/// ## Reconciliación en vivo del borrador (tarea 2.17, correcciones)
///
/// El flujo observa el recorrido vigo ([networkJourneyProvider]) y la
/// referencia guardada ([savedEmaReferenceProvider]) y reconcilia el borrador
/// de sesión mientras el cuestionario está visible:
///
/// - **Cambio de referencia desde el mapa** (corrección 1): al volver del mapa
///   (o cuando la referencia guardada cambia mientras existe un borrador), se
///   re-lee la referencia guardada y, si difiere de `draft.reference` y el
///   borrador no está completado ni omitido, se aplica [changeEmaReference]
///   (que reinicia solo las respuestas del bloque de relación y recorta
///   `questionIndex` a ≤ 3) y se persiste. Si está completado u omitido,
///   [changeEmaReference] devuelve el borrador intacto y no se toca nada.
/// - **Revocación durante el cuestionario** (corrección 2): si la referencia
///   del borrador deja de estar activa ([isEmaReferenceActive] `false`) mientras
///   se responde, se bloquea la continuación del registro de relación y se
///   presenta la revisión de referencia obsoleta
///   ([EmaStaleReferenceScreen]/[emaStaleReferenceMode]). Caso B (hay otras
///   personas activas) dirige al mapa; Caso A (sin personas activas) ofrece
///   "Continuar con el registro de hoy" aplicando [omitEmaRelationship].
/// - **Cambio de día al reanudar** (corrección 3): además de aplicarse en la
///   entrada, [prepareEmaDay] se reevalúa al (re)construir el cuestionario: si
///   `draft.day` ya no es [emaDayKey], se reinicia a un borrador fresco del día
///   (9 o 6 ítems vacíos) conservando la referencia guardada.
class EmaFlowScreen extends ConsumerStatefulWidget {
  const EmaFlowScreen({super.key});

  @override
  ConsumerState<EmaFlowScreen> createState() => _EmaFlowScreenState();
}

/// Metadato de capa del flujo EMA: es `Capa_Local` (opera de verdad en el
/// dispositivo), por lo que el indicador de simulación no se muestra aquí.
const _emaFeatureLayer = FeatureLayerInfo(
  featureId: 'ema',
  layer: FeatureLayer.local,
);

class _EmaFlowScreenState extends ConsumerState<EmaFlowScreen> {
  /// Borrador del día en curso (solo sesión). `null` mientras se prepara.
  EmaDraft? _draft;

  /// `true` mientras se resuelve el borrador y el gating de entrada.
  bool _preparing = true;

  /// `true` si no se pudo cargar el recorrido (p. ej. almacenamiento corrupto).
  bool _loadError = false;

  /// Evita re-ejecutar la preparación/gating de entrada más de una vez.
  bool _entryHandled = false;

  /// `true` mientras se empuja la revisión de referencia obsoleta disparada por
  /// una revocación en vivo (corrección 2), para no empujarla repetidamente.
  bool _reviewingStale = false;

  /// Evita que [_reconcile] se re-entre mientras ya está corriendo.
  bool _reconciling = false;

  @override
  void initState() {
    super.initState();
    // La preparación necesita el `JourneyState`; se lanza tras el primer frame,
    // cuando los providers están disponibles.
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleEntry());
  }

  /// Prepara el borrador del día y resuelve el gating de entrada una sola vez.
  Future<void> _handleEntry() async {
    if (_entryHandled) return;
    _entryHandled = true;

    final JourneyState journey;
    try {
      journey = await ref.read(journeyRepositoryProvider).loadJourney();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = true;
        _preparing = false;
      });
      return;
    }

    final savedReference = await ref
        .read(emaReferenceStoreProvider)
        .loadReference();
    final draftStore = ref.read(emaDraftStoreProvider);

    // Borrador de hoy: reinicio por cambio de día con la referencia guardada,
    // o uno nuevo si no hay ninguno en sesión.
    final stored = await draftStore.loadTodayDraft();
    var draft = stored == null
        ? createEmaDraft(savedReference)
        : prepareEmaDay(stored, savedReference);

    // Cambio de referencia confirmado desde el mapa (corrección 1): si al
    // (re)entrar la referencia guardada difiere de la del borrador y el
    // borrador no está completado ni omitido, se aplica el cambio del dominio
    // (reinicia solo el bloque de relación y recorta questionIndex a ≤ 3).
    // changeEmaReference deja intacto un borrador completado u omitido.
    if (savedReference != null &&
        !sameEmaReference(draft.reference, savedReference)) {
      draft = changeEmaReference(draft, savedReference);
    }
    await draftStore.saveDraft(draft);

    // Compuerta (pura): decide qué superficie presentar antes del cuestionario.
    final gate = resolveEmaFlowGate(
      savedReference: savedReference,
      journey: journey,
      draft: draft,
    );

    if (!mounted) return;

    switch (gate) {
      case EmaFlowGate.staleReference:
        // Revisión de referencia obsoleta (2.12). Caso A (sin personas activas)
        // devuelve un borrador omitido con el que continuamos; Caso B dirige al
        // mapa y no devuelve borrador: en ese caso salimos del flujo.
        final result = await Navigator.of(context).push<EmaDraft>(
          MaterialPageRoute(builder: (_) => const EmaStaleReferenceScreen()),
        );
        if (!mounted) return;
        if (result == null) {
          _exitFlow();
          return;
        }
        draft = result;

      case EmaFlowGate.referenceSelection:
        // Selección de Referencia_EMA (2.11). Devuelve la referencia elegida.
        final reference = await Navigator.of(context).push<EmaReference>(
          MaterialPageRoute(
            builder: (_) => const EmaReferenceSelectionScreen(),
          ),
        );
        if (!mounted) return;
        if (reference == null) {
          _exitFlow();
          return;
        }
        // Fija la referencia recién elegida en el borrador del día.
        draft = draft.reference == null
            ? draft.copyWith(reference: reference)
            : changeEmaReference(draft, reference);
        await draftStore.saveDraft(draft);

      case EmaFlowGate.noLinkFirstRun:
        // Primer registro sin vínculo (2.16): la vista se muestra inline en el
        // cuestionario (no es una pantalla aparte). No hacemos nada aquí: el
        // build renderiza [EmaNoLinkFirstRunView] mientras el borrador no esté
        // omitido.
        break;

      case EmaFlowGate.questionnaire:
        break;
    }

    if (!mounted) return;
    setState(() {
      _draft = draft;
      _preparing = false;
    });
  }

  /// Reconcilia el borrador de sesión con la referencia guardada y el recorrido
  /// vigentes, mientras el cuestionario está visible.
  ///
  /// Aplica, en orden, las tres correcciones de la tarea 2.17:
  /// 1. **Cambio de día al reanudar** (corrección 3): si `draft.day` ya no es
  ///    [emaDayKey], reinicia a un borrador fresco con la referencia guardada
  ///    ([prepareEmaDay]) y persiste.
  /// 2. **Cambio de referencia desde el mapa** (corrección 1): si la referencia
  ///    guardada difiere de `draft.reference`, aplica [changeEmaReference]
  ///    (no-op si el borrador está completado u omitido) y persiste.
  /// 3. **Revocación durante el cuestionario** (corrección 2): si la referencia
  ///    del borrador dejó de estar activa, empuja la revisión de referencia
  ///    obsoleta (bloqueando la continuación del registro de relación).
  ///
  /// Es idempotente: solo escribe/`setState` cuando el borrador cambia, por lo
  /// que puede llamarse en cada `build`/evento del recorrido sin bucles.
  Future<void> _reconcile(JourneyState journey) async {
    final current = _draft;
    if (current == null || _reconciling || _reviewingStale) return;
    _reconciling = true;
    try {
      final savedReference = await ref
          .read(emaReferenceStoreProvider)
          .loadReference();
      if (!mounted) return;

      var next = current;

      // (3) Reinicio por cambio de día al reanudar.
      final today = emaDayKey();
      if (next.day != today) {
        next = prepareEmaDay(next, savedReference, today);
      }

      // (2) Revocación mid-cuestionario: la referencia del borrador se volvió
      // inactiva. No se reconcilia una referencia distinta aquí; se deriva a la
      // revisión obsoleta para bloquear la continuación del registro.
      final hasReference =
          next.reference != null &&
          next.relationshipOmission != 'no-active-link' &&
          !next.completed;
      if (hasReference && !isEmaReferenceActive(journey, next.reference)) {
        if (next != current) {
          await _update(next);
        }
        await _handleStaleDuringQuestionnaire(savedReference, journey);
        return;
      }

      // (1) Cambio de referencia confirmado desde el mapa: aplica el dominio,
      // que preserva el borrador si está completado u omitido o si no cambió.
      if (savedReference != null &&
          next.relationshipOmission != 'no-active-link' &&
          !next.completed &&
          !sameEmaReference(next.reference, savedReference)) {
        next = changeEmaReference(next, savedReference);
      }

      if (next != current) {
        await _update(next);
      }
    } finally {
      _reconciling = false;
    }
  }

  /// Presenta la revisión de referencia obsoleta disparada por una revocación en
  /// vivo (corrección 2) y continúa el flujo con el borrador devuelto.
  ///
  /// Caso A (sin personas activas) devuelve un borrador con el bloque de
  /// relación omitido para hoy ([omitEmaRelationship]); Caso B dirige al mapa y
  /// no devuelve borrador, en cuyo caso salimos del flujo.
  Future<void> _handleStaleDuringQuestionnaire(
    EmaReference? savedReference,
    JourneyState journey,
  ) async {
    if (_reviewingStale || !mounted) return;
    _reviewingStale = true;

    final result = await Navigator.of(context).push<EmaDraft>(
      MaterialPageRoute(builder: (_) => const EmaStaleReferenceScreen()),
    );
    _reviewingStale = false;
    if (!mounted) return;
    if (result == null) {
      // Caso B / cancelación: el usuario fue dirigido al mapa. Salimos del
      // flujo; al volver, la entrada/reconciliación re-evaluará el estado.
      _exitFlow();
      return;
    }
    await _update(result);
  }

  /// Persiste [next] en la sesión y refresca el estado del cuestionario.
  Future<void> _update(EmaDraft next) async {
    await ref.read(emaDraftStoreProvider).saveDraft(next);
    if (!mounted) return;
    setState(() => _draft = next);
  }

  /// Fija la respuesta del ítem [index] y persiste.
  void _answer(int index, Object? value) {
    final current = _draft;
    if (current == null) return;
    _update(setEmaAnswer(current, index, value));
  }

  /// Avanza al siguiente ítem presentado o, en el último, completa el registro.
  void _advance() {
    final current = _draft;
    if (current == null) return;
    final indices = emaQuestionIndices(current);
    final position = indices.indexOf(current.questionIndex);
    if (position < 0) return;

    if (!isEmaAnswer(
      current.questionIndex,
      current.answers[current.questionIndex],
    )) {
      return;
    }

    if (position < indices.length - 1) {
      _update(current.copyWith(questionIndex: indices[position + 1]));
    } else if (canCompleteEma(current)) {
      _update(current.copyWith(completed: true));
    }
  }

  /// Vuelve al ítem presentado anterior.
  void _goBack() {
    final current = _draft;
    if (current == null) return;
    final indices = emaQuestionIndices(current);
    final position = indices.indexOf(current.questionIndex);
    if (position <= 0) return;
    _update(current.copyWith(questionIndex: indices[position - 1]));
  }

  /// Aplica la omisión del bloque de relación para hoy (camino sin vínculo del
  /// primer registro) y continúa con los 6 ítems.
  void _continueWithoutLink(JourneyState journey) {
    final current = _draft;
    if (current == null) return;
    _update(omitEmaRelationship(current, journey));
  }

  /// Sale del flujo conservando el borrador en sesión. Vuelve a la pantalla
  /// anterior si la hay; si no, al inicio del PCS.
  void _exitFlow() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.pcsHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reacciona a cambios del recorrido en vivo (p. ej. una revocación de
    // vínculo mientras se responde) reconciliando el borrador de sesión.
    ref.listen<AsyncValue<JourneyState>>(networkJourneyProvider, (_, next) {
      final journey = next.value;
      if (journey != null) _reconcile(journey);
    });
    // Reacciona a un cambio en la referencia guardada (p. ej. al confirmar otra
    // persona en el mapa y volver): re-lee y aplica el cambio al borrador.
    ref.listen<AsyncValue<EmaReference?>>(savedEmaReferenceProvider, (_, next) {
      final journey = ref.read(networkJourneyProvider).value;
      if (journey != null) _reconcile(journey);
    });

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            SimulationIndicator.forFeature(_emaFeatureLayer),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_preparing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError) {
      return const _ErrorBody();
    }
    final draft = _draft;
    if (draft == null) {
      // El gating derivó a otra pantalla y salimos; nada que mostrar.
      return const SizedBox.shrink();
    }

    // El recorrido en vivo se usa para el nombre de la referencia, el camino
    // sin vínculo y el resumen del resultado.
    final journeyAsync = ref.watch(networkJourneyProvider);
    return journeyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const _ErrorBody(),
      data: (journey) {
        if (draft.completed) {
          return _ResultView(draft: draft, journey: journey, onHome: _exitFlow);
        }
        // Primer registro sin vínculo: mientras el borrador no esté omitido y
        // no haya vínculo activo, se ofrece ir al mapa o continuar hoy.
        if (draft.reference == null &&
            draft.relationshipOmission == null &&
            validCaregivers(journey).isEmpty) {
          return _NoLinkBody(
            onOpenNetwork: () => context.goNamed(AppRoute.networkMap),
            onContinueToday: () => _continueWithoutLink(journey),
            onExit: _exitFlow,
          );
        }
        // Revocación mid-cuestionario (corrección 2): si el borrador tiene una
        // referencia que dejó de estar activa y no está omitido, NO se deja
        // seguir respondiendo el registro de relación: se bloquea mientras la
        // reconciliación empuja la revisión de referencia obsoleta.
        final staleReference =
            draft.reference != null &&
            draft.relationshipOmission != 'no-active-link' &&
            !isEmaReferenceActive(journey, draft.reference);
        if (staleReference) {
          return const Center(child: CircularProgressIndicator());
        }
        return _QuestionnaireBody(
          draft: draft,
          journey: journey,
          onAnswer: _answer,
          onAdvance: _advance,
          onBack: _goBack,
          onExit: _exitFlow,
        );
      },
    );
  }
}

/// Nombre visible de la persona de referencia del borrador, o un genérico.
///
/// Portado del prototipo (`referenceName`): toma el nombre de la persona cuyo id
/// coincide con `draft.reference?.personId`; si no se encuentra, usa el texto
/// genérico del prototipo.
String _referenceName(EmaDraft draft, JourneyState journey) {
  final personId = draft.reference?.personId;
  if (personId != null) {
    for (final person in journey.people) {
      if (person.id == personId) return person.name;
    }
  }
  return 'la persona de tu registro';
}

/// Banner superior del cuestionario, fiel al prototipo (`.ema-thread-banner`):
/// fondo celeste `#E4F0F7`, radio 24, relleno ~17x16; eyebrow "¿Cómo estoy
/// hoy?" en mayúsculas/negrita `#2B6087`; título "Tu tejido de hoy" en la fuente
/// serif de títulos (Lora); y la línea "Hilo {position+1} de {N}" en `#52555D`.
/// A la derecha, un indicador de avance ligero con N "hilos" (puntos): los ya
/// cubiertos en azul `#3174A1`, el resto en `#CFE3EE`, equivalente mínimo al SVG
/// de hilos del prototipo.
class _Banner extends StatelessWidget {
  const _Banner({required this.position, required this.total});

  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        decoration: BoxDecoration(
          color: EmaStyle.bannerBg,
          borderRadius: BorderRadius.circular(EmaStyle.bannerRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿Cómo estoy hoy?',
                    style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
                      color: EmaStyle.blueText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tu tejido de hoy',
                    style: (textTheme.headlineSmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.ink),
                  ),
                  const SizedBox(height: 5),
                  Semantics(
                    label: 'Avance del registro',
                    value: 'Hilo ${position + 1} de $total',
                    child: Text(
                      'Hilo ${position + 1} de $total',
                      style: (textTheme.bodyMedium ?? const TextStyle())
                          .copyWith(color: EmaStyle.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ExcludeSemantics(
              child: _ThreadProgress(position: position, total: total),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de avance ligero: una fila de "hilos" (puntos) donde los ítems ya
/// cubiertos se pintan en azul y el resto en celeste, equivalente mínimo al SVG
/// de hilos del prototipo (`.ema-thread-banner svg`).
class _ThreadProgress extends StatelessWidget {
  const _ThreadProgress({required this.position, required this.total});

  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var index = 0; index < total; index++)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index <= position
                    ? EmaStyle.blue
                    : const Color(0xFFCFE3EE),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip de contexto de la referencia para los ítems de relación, fiel al
/// prototipo (`.ema-reference-context`): fondo celeste `#E4F0F7`, texto
/// `#2B6087`, esquinas redondeadas, con un ícono de persona y "Sobre tu relación
/// con **{nombre}**".
class _ReferenceContextChip extends StatelessWidget {
  const _ReferenceContextChip({required this.referenceName});

  final String referenceName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: EmaStyle.bannerBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 20, color: EmaStyle.blueText),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Sobre tu relación con ',
                style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  color: EmaStyle.blueText,
                ),
                children: [
                  TextSpan(
                    text: referenceName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón primario azul del hilo EMA (`.ema-thread-actions .pcs-primary`): fondo
/// `#3174A1`, texto blanco, radio 12, alto mínimo 54 y opacidad .45 al estar
/// deshabilitado (`onPressed == null`). Es local al EMA para no teñir de azul el
/// botón primario de marca (terracota) del resto de la app.
class _EmaThreadPrimaryButton extends StatelessWidget {
  const _EmaThreadPrimaryButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    const radius = BorderRadius.all(Radius.circular(12));
    return Opacity(
      opacity: disabled ? EmaStyle.disabledOpacity : 1,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: label,
        child: Material(
          color: EmaStyle.blue,
          borderRadius: radius,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: EmaStyle.primaryButtonHeight,
              ),
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ContigoColors.surface,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Enlace secundario del hilo EMA en `#52555D` (`.ema-thread-actions
/// .pcs-text-link`/`.ema-defer`): texto subrayado, área táctil ≥ 44.
class _EmaThreadLink extends StatelessWidget {
  const _EmaThreadLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: const TextStyle(
                color: EmaStyle.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra superior con la afordancia de salir ("Salir y continuar después").
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onExit});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onExit,
        tooltip: 'Salir y continuar después',
        icon: const Icon(Icons.close),
        color: ContigoColors.terracotta,
      ),
    );
  }
}

/// Cuerpo del camino sin vínculo del primer registro, dentro del flujo.
class _NoLinkBody extends StatelessWidget {
  const _NoLinkBody({
    required this.onOpenNetwork,
    required this.onContinueToday,
    required this.onExit,
  });

  final VoidCallback onOpenNetwork;
  final VoidCallback onContinueToday;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(onExit: onExit),
        const _Banner(position: 0, total: 6),
        Expanded(
          child: EmaNoLinkFirstRunView(
            onOpenNetwork: onOpenNetwork,
            onContinueToday: onContinueToday,
          ),
        ),
      ],
    );
  }
}

/// Cuerpo del cuestionario: progreso, ítem actual y acciones.
class _QuestionnaireBody extends StatelessWidget {
  const _QuestionnaireBody({
    required this.draft,
    required this.journey,
    required this.onAnswer,
    required this.onAdvance,
    required this.onBack,
    required this.onExit,
  });

  final EmaDraft draft;
  final JourneyState journey;
  final void Function(int index, Object? value) onAnswer;
  final VoidCallback onAdvance;
  final VoidCallback onBack;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final indices = emaQuestionIndices(draft);
    final position = indices.indexOf(draft.questionIndex);
    final item = emaItems[draft.questionIndex];
    final selected = draft.answers[draft.questionIndex];
    final answered = isEmaAnswer(draft.questionIndex, selected);
    final isLast = position == indices.length - 1;
    final omitted = draft.relationshipOmission == 'no-active-link';
    final referenceName = _referenceName(draft, journey);

    // Frase intro del prototipo según tipo/bloque (texto verbatim).
    final String intro;
    if (item.kind == EmaItemKind.binary) {
      intro = '$emaTimeWindow, responde Sí o No.';
    } else if (item.block == EmaItemBlock.relationship) {
      intro =
          '$emaTimeWindow, mueve la barra para indicar qué tan cierta es cada '
          'frase sobre tu relación con $referenceName.';
    } else {
      intro =
          '$emaTimeWindow, mueve la barra para indicar qué tan cierta es cada '
          'frase para ti.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(onExit: onExit),
        _Banner(position: position, total: indices.length),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              if (omitted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Hoy responderás sobre ti y tu conexión con otras personas.',
                    style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                      color: ContigoColors.inkMuted,
                    ),
                  ),
                ),
              if (item.block == EmaItemBlock.relationship)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReferenceContextChip(referenceName: referenceName),
                ),
              // Intro con la ventana temporal + texto del ítem.
              Text(
                intro,
                style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                  color: ContigoColors.inkMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.text,
                style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                  color: ContigoColors.ink,
                ),
              ),
              const SizedBox(height: 20),
              // Ítem binario o de rango, cableado a setEmaAnswer vía onAnswer.
              if (item.kind == EmaItemKind.binary)
                EmaBinaryItem(
                  key: ValueKey(item.id),
                  value: selected is bool ? selected : null,
                  onChanged: (value) => onAnswer(draft.questionIndex, value),
                )
              else
                EmaRangeItem(
                  key: ValueKey(item.id),
                  value: selected is int ? selected : null,
                  onChanged: (value) => onAnswer(draft.questionIndex, value),
                ),
              const SizedBox(height: 24),
              // Botón primario azul del hilo ("Tejer y seguir"/"Tejer y
              // terminar"): fondo `#3174A1` (no la terracota de marca),
              // min-height 54, opacidad .45 al estar deshabilitado.
              _EmaThreadPrimaryButton(
                label: isLast ? 'Tejer y terminar' : 'Tejer y seguir',
                onPressed: answered ? onAdvance : null,
              ),
              if (position > 0) ...[
                const SizedBox(height: 4),
                // Enlace secundario del hilo en `#52555D`
                // (`.ema-thread-actions .pcs-text-link`).
                _EmaThreadLink(label: 'Hilo anterior', onPressed: onBack),
              ],
              const SizedBox(height: 4),
              // Afordancia de salida en `#52555D` (`.ema-defer`); el borrador
              // persiste en sesión.
              _EmaThreadLink(
                label: 'Prefiero responder después',
                onPressed: onExit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vista de resultado/siguientes pasos mínima y fiel (sin los próximos pasos de
/// conexión, que llegan en la Etapa 3).
///
/// Presenta la nota del acompañante del prototipo y un resumen "Tu registro de
/// hoy" con "{respondidos} de {N} hilos" y si se omitió el bloque de relación o
/// cuál fue la persona de referencia (verbatim del `details` del prototipo).
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.draft,
    required this.journey,
    required this.onHome,
  });

  final EmaDraft draft;
  final JourneyState journey;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final indices = emaQuestionIndices(draft);
    final answered = answeredEmaCount(draft);
    final omitted = draft.relationshipOmission == 'no-active-link';
    final referenceName = _referenceName(draft, journey);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Opciones para acercarte a tu tejido',
            style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
              color: ContigoColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CompanionNote(
          affection: true,
          child: Text(
            'Gracias por contarme, Sofía. ¿Te serviría sentirte acompañada? '
            'Elige algo del tamaño que puedas hoy.',
          ),
        ),
        const SizedBox(height: 8),
        // Resumen "Tu registro de hoy" (verbatim del details del prototipo).
        ContigoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu registro de hoy',
                style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                  color: ContigoColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$answered de ${indices.length} hilos respondidos.',
                style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  color: ContigoColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                omitted
                    ? 'Hoy no se incluyó el bloque sobre una persona cercana '
                          'vinculada.'
                    : 'Persona de referencia: $referenceName.',
                style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  color: ContigoColors.inkMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Las respuestas de este prototipo se conservan durante esta '
                'sesión y se borran al recargar. Estas opciones no se '
                'seleccionan a partir de tus respuestas.',
                style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                  color: ContigoColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Nota: los pasos de conexión ("Ver mensajes de cuidado", "Escribir o
        // llamar a alguien cercano", "Proponer un encuentro") llegan en la
        // Etapa 3 (tarea 3.20). Aquí basta un camino de vuelta al inicio.
        Text(
          'Pronto podrás elegir un paso para acercarte a tu red desde aquí.',
          style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: ContigoColors.inkMuted,
          ),
        ),
        const SizedBox(height: 16),
        ContigoButton(
          label: 'Volver al inicio',
          fullWidth: true,
          onPressed: onHome,
        ),
      ],
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
