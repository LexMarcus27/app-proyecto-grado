import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/ema/ema.dart';
import '../../domain/journey/journey.dart';
import '../../domain/metrics/metrics.dart';
import '../../domain/network/network.dart';
import '../widgets/widgets.dart';
import 'network_builder_controller.dart';
import 'network_charts.dart';

/// Flujo en vivo del `JourneyState` para la pantalla del mapa de red.
///
/// Expone [JourneyRepository.watchJourney] como `StreamProvider` para que la UI
/// lo observe de forma reactiva (se recarga sola si el recorrido cambia, p. ej.
/// al alternar el escenario demo, al generar el mapa o al simular una
/// invitación).
final networkJourneyProvider = StreamProvider.autoDispose<JourneyState>(
  (ref) => ref.watch(journeyRepositoryProvider).watchJourney(),
);

/// Referencia EMA actualmente guardada (solo identificadores), o `null`.
///
/// Se usa para mostrar cuál es la persona de referencia activa. Se expone como
/// `FutureProvider` que puede recargarse tras confirmar una nueva selección
/// (`ref.invalidate`).
final savedEmaReferenceProvider = FutureProvider.autoDispose<EmaReference?>(
  (ref) => ref.watch(emaReferenceStoreProvider).loadReference(),
);

/// Vistas de resultados del mapa (pestañas del prototipo).
enum _ResultTab { closeness, quality, list }

/// "Tu mapa de red" completo (tarea 3.12), portado de `SocialNetworkScreen`
/// (vista `results` y flujo `choose`/`invite`/`sent` de `src/screens/network.tsx`).
///
/// Muestra los gráficos de **cercanía** y **calidad** en `CustomPainter`
/// alimentados por [NetworkMetricsCalculator.metricsFor], más una **lista** con
/// el estado de invitación de cada vínculo. Integra la construcción ya
/// implementada (si el mapa no está generado, ofrece construirlo) y conserva la
/// **selección/cambio de la Referencia_EMA con confirmación explícita**
/// (Requirements 5.7/5.9). El flujo de invitaciones es una Funcion_Simulada
/// (deja la invitación en `pending`); una invitación aceptada por sí sola no
/// habilita las acciones que requieren Asociacion_Activa (Requirement 9.9/9.10).
class NetworkMapScreen extends ConsumerWidget {
  const NetworkMapScreen({super.key});

  static const FeatureLayerInfo invitationLayer = FeatureLayerInfo(
    featureId: 'network-invitation',
    layer: FeatureLayer.simulada,
    label:
        'Invitaciones simuladas: el envío no entrega ningún mensaje real y solo '
        'representa el estado "pendiente" para probar el flujo.',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(networkJourneyProvider);
    final savedReference = ref.watch(savedEmaReferenceProvider).value;

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            _Header(onBack: () => _handleBack(context)),
            Expanded(
              child: journeyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    _ErrorBody(onBack: () => _handleBack(context)),
                data: (journey) => _NetworkBody(
                  journey: journey,
                  savedReference: savedReference,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.pcsHome);
    }
  }
}

/// Cabecera con afordancia de volver, título y subtítulo (estilo del prototipo).
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 18, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back),
            color: ContigoColors.terracotta,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tu mapa de red',
                  style: (textTheme.headlineSmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'A tu propio ritmo',
                  style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: ContigoColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuerpo de la pantalla: resultados del mapa (gráficos/lista) si está generado;
/// estado vacío con acceso a construir o a seleccionar referencia en otro caso.
class _NetworkBody extends ConsumerStatefulWidget {
  const _NetworkBody({required this.journey, required this.savedReference});

  final JourneyState journey;
  final EmaReference? savedReference;

  @override
  ConsumerState<_NetworkBody> createState() => _NetworkBodyState();
}

class _NetworkBodyState extends ConsumerState<_NetworkBody> {
  _ResultTab _tab = _ResultTab.closeness;

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    final textTheme = Theme.of(context).textTheme;
    final linked = validCaregivers(journey);
    final assessed = assessedPeople(journey);
    final mapReady = journey.mapGenerated && assessed.isNotEmpty;

    // El acceso al mapa completo depende de que la **red esté generada**, no de
    // tener vínculos activos: una red generada muestra gráficos, lista, detalles
    // e invitaciones aunque no haya ninguna Asociacion_Activa. El requisito de
    // vínculo activo se conserva solo en las acciones que lo necesitan (la
    // selección de Referencia_EMA y las acciones dirigidas a persona).
    if (!mapReady) {
      return _UnbuiltState(journey: journey, savedReference: widget.savedReference);
    }

    final entries = assessed
        .map((p) => MapEntry(p, NetworkMetricsCalculator.metricsFor(p)))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // --- Selección/cambio de la Referencia_EMA (confirmación explícita),
        // conservada de la entrada mínima del mapa (Requirements 5.7/5.9). Solo
        // se ofrece con una Asociacion_Activa elegible; sin ella, se informa
        // que no hay referencia elegible (distinto de "sin red"). ---
        if (linked.isNotEmpty) ...[
          Text(
            'Elige la persona de referencia para tu registro diario.',
            style: (textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 16),
          for (final person in linked) ...[
            _PersonEntry(
              person: person,
              isCurrentReference: widget.savedReference?.personId == person.id &&
                  isEmaReferenceActive(journey, widget.savedReference),
              onSelect: () => _selectReference(journey, person),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 16),
        ] else ...[
          ContigoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin persona de referencia elegible',
                    style: textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  'Tu mapa está generado, pero ninguna persona tiene una '
                  'asociación activa para elegirla como referencia de tu '
                  'registro diario. Puedes explorar el mapa e invitar a '
                  'personas cercanas; una invitación aceptada por sí sola no '
                  'habilita esta selección.',
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // --- Mapa de red completo: gráficos de cercanía y calidad (3.12). ---
        Text(
          'Explora las vistas para observar tu red desde distintas '
          'perspectivas. Ninguna califica el valor de una persona.',
          style: (textTheme.bodyMedium ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 13),
        _TabBar(current: _tab, onSelect: (t) => setState(() => _tab = t)),
        const SizedBox(height: 13),
        if (_tab == _ResultTab.closeness) ...[
          _ChartHitTarget(
            aspectRatio: 320 / 330,
            painter: ClosenessMapPainter(entries: entries),
            onPersonTap: _openDetail,
            semanticsEntries: entries,
          ),
          const SizedBox(height: 10),
          Text(
            'La distancia muestra qué tan cercana percibes actualmente la '
            'relación. No califica el valor de la persona.',
            style: (textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 12),
          const _Legend(),
        ] else if (_tab == _ResultTab.quality) ...[
          _ChartHitTarget(
            aspectRatio: 320 / 360,
            painter: QualityGridPainter(entries: entries),
            onPersonTap: _openDetail,
            semanticsEntries: entries,
          ),
          const SizedBox(height: 10),
          Text(
            'Una relación puede tener aspectos positivos y difíciles al mismo '
            'tiempo. Esta vista ayuda a observar ambas dimensiones, no a '
            'juzgar a la persona.',
            style: (textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 12),
          const _Legend(),
        ] else ...[
          for (final entry in entries)
            _PersonListRow(
              person: entry.key,
              metrics: entry.value,
              journey: journey,
              onTap: () => _openDetail(entry.key),
            ),
        ],
        const SizedBox(height: 20),
        ContigoButton(
          label: 'Gestionar invitaciones y vínculos',
          fullWidth: true,
          onPressed: () => _openInvitations(entries),
        ),
      ],
    );
  }

  /// Confirma la Referencia_EMA desde el mapa y, al guardar, regresa a la  /// Confirma la Referencia_EMA desde el mapa y, al guardar, regresa a la
  /// pantalla anterior (el flujo EMA), conservando el comportamiento de la
  /// entrada mínima (2.15): tras confirmar un cambio, el registro continúa.
  Future<void> _selectReference(
    JourneyState journey,
    NetworkPerson person,
  ) async {
    final navigator = Navigator.of(context);
    // Muestra el diálogo de confirmación explícita (no persiste por sí mismo).
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmReferenceDialog(
        candidate: person,
        currentReference: widget.savedReference,
        journey: journey,
        hasCurrent: widget.savedReference != null,
      ),
    );
    if (confirmed != true) return; // cancelar: permanece en el mapa
    final reference = emaReferenceForPerson(journey, person.id);
    if (reference == null) return;
    await ref.read(emaReferenceStoreProvider).saveReference(reference);
    ref.invalidate(savedEmaReferenceProvider);
    // Tras confirmar y guardar, regresa al flujo EMA (comportamiento 2.15).
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _openDetail(NetworkPerson person) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: ContigoColors.surface,
      builder: (_) => _PersonDetailSheet(
        personId: person.id,
        savedReference: widget.savedReference,
      ),
    );
  }

  Future<void> _openInvitations(
    List<MapEntry<NetworkPerson, NetworkMetrics>> entries,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: ContigoColors.surface,
      builder: (_) => _InvitationsSheet(entries: entries),
    );
  }
}

/// Lienzo del gráfico con **hit-testing accesible**: dibuja el gráfico y
/// convierte un toque en la persona cuyo nodo está más cerca, abriendo su
/// detalle (como los nodos pulsables del prototipo). Expone además un nodo de
/// semántica por persona (``role=button`` con "nombre, anillo, clasificación")
/// para lectores de pantalla, conservando la accesibilidad del prototipo.
class _ChartHitTarget extends StatelessWidget {
  const _ChartHitTarget({
    required this.aspectRatio,
    required this.painter,
    required this.onPersonTap,
    required this.semanticsEntries,
  });

  final double aspectRatio;
  final NetworkChartPainter painter;
  final ValueChanged<NetworkPerson> onPersonTap;
  final List<MapEntry<NetworkPerson, NetworkMetrics>> semanticsEntries;

  @override
  Widget build(BuildContext context) {
    final positions = painter.nodePositions();
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / NetworkChartPainter.viewBox;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final local = details.localPosition;
              // Traduce a coordenadas del viewBox para comparar con los nodos.
              final vx = local.dx / scale;
              final vy = local.dy / scale;
              int? best;
              double bestDist = double.infinity;
              for (var i = 0; i < positions.length; i++) {
                final d = (positions[i] - Offset(vx, vy)).distance;
                if (d < bestDist) {
                  bestDist = d;
                  best = i;
                }
              }
              // Radio de toque generoso (nodo + etiqueta), en unidades viewBox.
              if (best != null && bestDist <= 26) {
                onPersonTap(painter.entries[best].key);
              }
            },
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: painter)),
                // Capa de semántica: un botón por persona sobre su nodo.
                for (var i = 0; i < positions.length && i < semanticsEntries.length; i++)
                  Positioned(
                    left: positions[i].dx * scale - 22,
                    top: positions[i].dy * scale - 22,
                    width: 44,
                    height: 44,
                    child: Semantics(
                      button: true,
                      label:
                          '${semanticsEntries[i].key.name}, '
                          '${semanticsEntries[i].value.ring.label}, '
                          '${semanticsEntries[i].value.classification.label}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onPersonTap(semanticsEntries[i].key),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Barra de pestañas de resultados (cercanía/calidad/lista), estilo del prototipo.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});

  final _ResultTab current;
  final ValueChanged<_ResultTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget tab(_ResultTab tab, String label) {
      final selected = current == tab;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkWell(
            onTap: () => onSelect(tab),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? ContigoColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
                  color: selected
                      ? ContigoColors.terracotta
                      : ContigoColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ContigoColors.notifQuestionsBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab(_ResultTab.closeness, 'Mapa de cercanía'),
          const SizedBox(width: 5),
          tab(_ResultTab.quality, 'Calidad relacional'),
          const SizedBox(width: 5),
          tab(_ResultTab.list, 'Lista'),
        ],
      ),
    );
  }
}

/// Leyenda de calidad relacional (forma + color por clasificación), verbatim.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Ejemplos de métricas por clasificación (solo forma/color se usan aquí).
    final items = <(NetworkPerson, String)>[
      (_legendPerson(const [6, 6, 6, 6, 6, 1, 6, 1, 6, 6, 6, 6, 6, 6, 1, 1, 1, 1]), 'Mayormente positiva'),
      (_legendPerson(const [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]), 'Ambivalente'),
      (_legendPerson(const [1, 1, 1, 1, 1, 6, 1, 6, 1, 1, 6, 1, 1, 1, 6, 6, 6, 6]), 'Mayormente negativa'),
      (_legendPerson(const [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]), 'Baja intensidad'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final (person, label) in items)
          Row(
            children: [
              LegendMarker(metrics: NetworkMetricsCalculator.metricsFor(person)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.ink),
                ),
              ),
            ],
          ),
      ],
    );
  }

  NetworkPerson _legendPerson(List<int> answers) => NetworkPerson(
        id: 'legend',
        name: 'Leyenda',
        answers: List<int?>.from(answers),
        status: PersonStatus.complete,
        invitationStatus: InvitationStatus.notInvited,
      );
}

/// Fila de la lista de resultados con su marcador, clasificación y estado de
/// invitación. Abre el detalle de la persona al tocar.
class _PersonListRow extends StatelessWidget {
  const _PersonListRow({
    required this.person,
    required this.metrics,
    required this.journey,
    required this.onTap,
  });

  final NetworkPerson person;
  final NetworkMetrics metrics;
  final JourneyState journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ringLower = metrics.ring.label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ContigoCard(
        onTap: onTap,
        child: Row(
          children: [
            LegendMarker(metrics: metrics, size: 34),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    '${person.relationshipType?.wireValue ?? 'Sin tipo'} · '
                    'Cercanía $ringLower · ${metrics.classification.label}',
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                  const SizedBox(height: 7),
                  _InvitationChip(
                    label: invitationLabel(person, journey),
                    variant: invitationVariant(person, journey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ContigoColors.terracotta),
          ],
        ),
      ),
    );
  }
}

/// Distintivo del estado de invitación (colores por variante, estilo prototipo).
class _InvitationChip extends StatelessWidget {
  const _InvitationChip({required this.label, required this.variant});

  final String label;
  final InvitationBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (bg, fg) = switch (variant) {
      InvitationBadgeVariant.ok => (
          ContigoColors.notifReminderBg,
          ContigoColors.notifReminderAccent,
        ),
      InvitationBadgeVariant.warn => (
          ContigoColors.notifClosenessBg,
          ContigoColors.notifClosenessAccent,
        ),
      InvitationBadgeVariant.blue => (
          ContigoColors.notifSocialBg,
          ContigoColors.notifSocialAccent,
        ),
      InvitationBadgeVariant.defaultVariant => (
          ContigoColors.notifQuestionsBg,
          ContigoColors.notifQuestionsAccent,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: (textTheme.labelSmall ?? const TextStyle()).copyWith(color: fg),
      ),
    );
  }
}
/// Tarjeta de selección de Referencia_EMA (confirmación diferida al diálogo).
class _PersonEntry extends StatelessWidget {
  const _PersonEntry({
    required this.person,
    required this.isCurrentReference,
    required this.onSelect,
  });

  final NetworkPerson person;
  final bool isCurrentReference;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final buttonLabel = isCurrentReference
        ? 'Seleccionada para registro EMA'
        : 'Seleccionar para registro EMA';
    return ContigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(person.name, style: textTheme.titleMedium)),
              if (isCurrentReference)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ContigoColors.notifReminderBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Referencia actual',
                    style: (textTheme.labelSmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.notifReminderAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Persona cercana vinculada',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 14),
          ContigoButton(
            label: buttonLabel,
            fullWidth: true,
            small: true,
            variant: isCurrentReference
                ? ContigoButtonVariant.secondary
                : ContigoButtonVariant.primary,
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}

/// Pide confirmación explícita antes de persistir la Referencia_EMA (Req.
/// 5.7/5.9). Solo si el usuario confirma se construye y guarda la referencia.
/// Reutilizable desde el estado vacío y desde el detalle de persona.
/// Devuelve `true` solo si el usuario confirmó **y** se guardó la referencia;
/// `false` si canceló o si no había referencia construible. El llamador usa el
/// valor para decidir si cerrar la hoja y anunciar el éxito.
Future<bool> confirmEmaReference(
  BuildContext context,
  WidgetRef ref,
  JourneyState journey,
  NetworkPerson candidate,
  EmaReference? savedReference,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _ConfirmReferenceDialog(
      candidate: candidate,
      currentReference: savedReference,
      journey: journey,
      hasCurrent: savedReference != null,
    ),
  );
  if (confirmed != true) return false;
  final reference = emaReferenceForPerson(journey, candidate.id);
  if (reference == null) return false;
  await ref.read(emaReferenceStoreProvider).saveReference(reference);
  ref.invalidate(savedEmaReferenceProvider);
  return true;
}

/// Hoja de detalle de una persona: métricas resumidas, estado de invitación,
/// selección de Referencia_EMA (si tiene vínculo activo, con confirmación) e
/// invitación simulada (si procede).
class _PersonDetailSheet extends ConsumerWidget {
  const _PersonDetailSheet({
    required this.personId,
    required this.savedReference,
  });

  final String personId;
  final EmaReference? savedReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final journey = ref.watch(networkJourneyProvider).value;
    if (journey == null) return const SizedBox.shrink();
    NetworkPerson? person;
    for (final p in journey.people) {
      if (p.id == personId) {
        person = p;
        break;
      }
    }
    if (person == null) return const SizedBox.shrink();
    final metrics = NetworkMetricsCalculator.isAssessed(person)
        ? NetworkMetricsCalculator.metricsFor(person)
        : null;
    final linkedActive = canStrengthenRelationship(journey, person.id);
    final isCurrentReference = savedReference?.personId == person.id &&
        isEmaReferenceActive(journey, savedReference);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (metrics != null) ...[
                LegendMarker(metrics: metrics, size: 32),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text(person.name, style: textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: 6),
          _InvitationChip(
            label: invitationLabel(person, journey),
            variant: invitationVariant(person, journey),
          ),
          if (metrics != null) ...[
            const SizedBox(height: 12),
            Text(
              '${person.relationshipType?.wireValue ?? 'Sin tipo'} · '
              'Cercanía ${metrics.ring.label.toLowerCase()} · '
              '${metrics.classification.label}',
              style: (textTheme.bodyMedium ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            ),
          ],
          const SizedBox(height: 16),
          // Selección de Referencia_EMA: solo con vínculo activo (una invitación
          // aceptada por sí sola no habilita esta acción).
          if (linkedActive) ...[
            ContigoButton(
              label: isCurrentReference
                  ? 'Seleccionada para registro EMA'
                  : 'Seleccionar para registro EMA',
              fullWidth: true,
              variant: isCurrentReference
                  ? ContigoButtonVariant.secondary
                  : ContigoButtonVariant.primary,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final saved = await confirmEmaReference(
                    context, ref, journey, person!, savedReference);
                if (!context.mounted) return;
                // Cancelar: la hoja permanece abierta y no se anuncia nada.
                if (!saved) return;
                navigator.pop();
                messenger.showSnackBar(const SnackBar(
                  content: Text('Referencia EMA actualizada.'),
                ));
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ContigoColors.notifQuestionsBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Para elegir a esta persona como referencia de tu registro '
                'diario necesita una asociación activa. Una invitación aceptada '
                'por sí sola no la habilita.',
                style: textTheme.bodyMedium,
              ),
            ),
          ],
          if (canInvite(person)) ...[
            const SizedBox(height: 10),
            ContigoButton(
              label: person.invitationStatus == InvitationStatus.notInvited
                  ? 'Invitar a esta persona cercana'
                  : 'Revisar una nueva invitación',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  backgroundColor: ContigoColors.surface,
                  builder: (_) => _InviteConfirmSheet(personId: personId),
                );
              },
            ),
          ],
          const SizedBox(height: 10),
          ContigoButton(
            label: 'Cerrar',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Hoja "Invitaciones y vínculos": lista de personas evaluadas con su estado;
/// al tocar una que puede invitarse, abre la confirmación simulada.
class _InvitationsSheet extends ConsumerWidget {
  const _InvitationsSheet({required this.entries});

  final List<MapEntry<NetworkPerson, NetworkMetrics>> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final journey = ref.watch(networkJourneyProvider).value;
    if (journey == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Invitaciones y vínculos', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Invita a cada persona por separado o consulta su estado. Estar en '
            'el mapa no envía invitaciones ni vincula a nadie automáticamente.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 14),
          SimulationIndicator.forFeature(NetworkMapScreen.invitationLayer),
          const SizedBox(height: 12),
          for (final entry in entries) ...[
            _InvitationRow(person: entry.key, metrics: entry.value, journey: journey),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow({
    required this.person,
    required this.metrics,
    required this.journey,
  });

  final NetworkPerson person;
  final NetworkMetrics metrics;
  final JourneyState journey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final invitable = canInvite(person);
    return ContigoCard(
      onTap: invitable
          ? () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                backgroundColor: ContigoColors.surface,
                builder: (_) => _InviteConfirmSheet(personId: person.id),
              )
          : null,
      child: Row(
        children: [
          LegendMarker(metrics: metrics, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, style: textTheme.titleSmall),
                const SizedBox(height: 5),
                _InvitationChip(
                  label: invitationLabel(person, journey),
                  variant: invitationVariant(person, journey),
                ),
              ],
            ),
          ),
          if (invitable)
            const Icon(Icons.chevron_right, color: ContigoColors.terracotta),
        ],
      ),
    );
  }
}

/// Confirmación de invitación simulada: muestra el borrador (pendiente de
/// validación) y, al confirmar, deja la invitación en `pending` (no entrega
/// ningún mensaje real ni crea asociación).
class _InviteConfirmSheet extends ConsumerStatefulWidget {
  const _InviteConfirmSheet({required this.personId});
  final String personId;

  @override
  ConsumerState<_InviteConfirmSheet> createState() =>
      _InviteConfirmSheetState();
}

class _InviteConfirmSheetState extends ConsumerState<_InviteConfirmSheet> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final journey = ref.watch(networkJourneyProvider).value;
    NetworkPerson? person;
    if (journey != null) {
      for (final p in journey.people) {
        if (p.id == widget.personId) {
          person = p;
          break;
        }
      }
    }
    if (person == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sent) ...[
            const Icon(Icons.check_circle,
                color: ContigoColors.sage, size: 52),
            const SizedBox(height: 12),
            Text('Invitación simulada · pendiente de aceptación',
                style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'No se entregó ningún mensaje real. La invitación para '
              '${person.name} quedó representada como pendiente únicamente para '
              'probar el flujo. Esto no significa que haya aceptado ni que ya '
              'esté vinculada contigo.',
              style: (textTheme.bodyMedium ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ContigoButton(
              label: 'Cerrar',
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else ...[
            Text('¿Quieres invitar a ${person.name}?',
                style: textTheme.titleLarge),
            const SizedBox(height: 9),
            Text(
              'Revisa el mensaje antes de confirmar. El mapa y tus respuestas '
              'no se compartirán.',
              style: (textTheme.bodyMedium ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            ),
            const SizedBox(height: 14),
            ContigoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Destinatario',
                      style: (textTheme.bodySmall ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted)),
                  const SizedBox(height: 4),
                  Text(person.name, style: textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Text('BORRADOR DE PROTOTIPO · PENDIENTE DE VALIDACIÓN',
                      style: (textTheme.labelSmall ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted)),
                  const SizedBox(height: 6),
                  Text(
                    'Hola, me gustaría invitarte a Contigo como persona cercana '
                    'para compartir herramientas que nos ayuden a cuidar '
                    'nuestra relación. Si aceptas, la aplicación vinculará tu '
                    'cuenta a la mía. Puedes decidir libremente si quieres '
                    'participar.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Este borrador no incluye respuestas, puntuaciones, diagnósticos '
              'ni el motivo privado de tu elección.',
              style: (textTheme.bodySmall ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            ),
            const SizedBox(height: 16),
            SimulationIndicator.forFeature(NetworkMapScreen.invitationLayer),
            const SizedBox(height: 12),
            ContigoButton(
              label: 'Simular envío de invitación',
              fullWidth: true,
              onPressed: () async {
                final ok = await ref
                    .read(networkBuilderControllerProvider)
                    .invite(widget.personId);
                if (!context.mounted) return;
                if (ok) setState(() => _sent = true);
              },
            ),
            const SizedBox(height: 10),
            ContigoButton(
              label: 'Volver sin enviar',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Diálogo de confirmación explícita de la Referencia_EMA (Req. 5.7/5.9).
///
/// Nunca persiste por sí mismo: devuelve `true` solo si el usuario pulsa el
/// botón de confirmar; el llamador es quien guarda la referencia.
class _ConfirmReferenceDialog extends StatelessWidget {
  const _ConfirmReferenceDialog({
    required this.candidate,
    required this.currentReference,
    required this.journey,
    required this.hasCurrent,
  });

  final NetworkPerson candidate;
  final EmaReference? currentReference;
  final JourneyState journey;
  final bool hasCurrent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = hasCurrent
        ? 'Cambiar persona para el registro EMA'
        : 'Seleccionar persona para el registro EMA';
    final confirmLabel = hasCurrent
        ? 'Confirmar cambio para EMA'
        : 'Confirmar selección para EMA';

    String? currentName;
    if (currentReference != null) {
      for (final person in journey.people) {
        if (person.id == currentReference!.personId) {
          currentName = person.name;
          break;
        }
      }
    }

    return AlertDialog(
      backgroundColor: ContigoColors.surface,
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'Persona elegida: ',
              style: (textTheme.bodyMedium ?? const TextStyle())
                  .copyWith(color: ContigoColors.ink),
              children: [
                TextSpan(
                  text: candidate.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (currentReference != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tu selección actual es '
              '${currentName ?? 'una persona que ya no aparece en tu red'}.',
              style: (textTheme.bodyMedium ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Esta será tu persona de referencia para las preguntas sobre tu '
            'relación con alguien cercano.',
            style: (textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
        ],
      ),
      actions: [
        ContigoButton(
          label: 'Cancelar',
          small: true,
          variant: ContigoButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ContigoButton(
          label: confirmLabel,
          small: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Estado cuando la **red aún no está generada**: ofrece construirla. Si ya hay
/// personas con vínculo activo (p. ej. tras aceptar una invitación antes de
/// generar el mapa), conserva además la selección de Referencia_EMA con
/// confirmación explícita. Es un estado distinto de "sin red": aquí el mapa no
/// existe todavía, no es que falte una referencia elegible.
class _UnbuiltState extends ConsumerWidget {
  const _UnbuiltState({required this.journey, required this.savedReference});

  final JourneyState journey;
  final EmaReference? savedReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final linked = validCaregivers(journey);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        ContigoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu mapa todavía no está generado',
                  style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Construye tu mapa de red para ver los gráficos de cercanía y '
                'calidad, la lista, los detalles y las invitaciones.',
                style: (textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(color: ContigoColors.inkMuted),
              ),
              const SizedBox(height: 12),
              ContigoButton(
                label: 'Construir mi mapa',
                fullWidth: true,
                onPressed: () => context.goNamed(AppRoute.networkBuilder),
              ),
            ],
          ),
        ),
        if (linked.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Persona de referencia para tu registro diario',
              style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Elige con quién responder las preguntas de tu registro EMA.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 12),
          for (final person in linked) ...[
            _PersonEntry(
              person: person,
              isCurrentReference: savedReference?.personId == person.id &&
                  isEmaReferenceActive(journey, savedReference),
              onSelect: () => confirmEmaReference(
                  context, ref, journey, person, savedReference),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

/// Cuerpo de error: el almacenamiento del recorrido no se pudo leer.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No pudimos cargar tu mapa de red en este momento.',
              textAlign: TextAlign.center,
              style: (textTheme.titleMedium ?? const TextStyle())
                  .copyWith(color: ContigoColors.ink),
            ),
            const SizedBox(height: 16),
            ContigoButton(label: 'Volver', small: true, onPressed: onBack),
          ],
        ),
      ),
    );
  }
}