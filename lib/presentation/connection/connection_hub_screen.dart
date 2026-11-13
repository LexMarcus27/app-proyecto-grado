import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../domain/connection/connection.dart';
import '../../domain/journey/journey.dart';
import '../../domain/metrics/metrics.dart';
import '../authorization/gating.dart';
import '../caring_messages/caring_messages_controller.dart';
import '../widgets/widgets.dart';
import 'connection_selection.dart';

/// Íconos de los pasos de conexión (`icons` de `connection-hub.tsx`).
const Map<ConnectionStep, IconData> connectionStepIcons = {
  ConnectionStep.message: Icons.chat_bubble_outline,
  ConnectionStep.received: Icons.favorite_border,
  ConnectionStep.contact: Icons.people_outline,
  ConnectionStep.meeting: Icons.calendar_today_outlined,
  ConnectionStep.skills: Icons.menu_book_outlined,
};

/// Hub de conexión del PCS «Tejiendo vínculos» (M21), portado de
/// `ConnectionHubScreen` (`src/screens/connection-hub.tsx`) y
/// `ConnectionPersonScreen` (`src/screens/connection-person.tsx`).
///
/// - Vista inicial: nota del acompañante, paso destacado «Un paso para hoy»
///   que rota cíclicamente con «Otro paso» (Requirement 8.9) y la rejilla
///   «Otros pasos».
/// - Mensaje/contacto/encuentro abren la vista de selección de persona
///   (pequeño mapa + lista), conservando la intención; desde ahí cada acción
///   abre la conexión con esa persona (M8). Las acciones quedan deshabilitadas
///   sin Asociacion_Activa vigente (Requirement 8.10).
/// - Recibidos abre la bandeja (sin gating, Requirement 8.11); habilidades,
///   el recurso pendiente de validación.
class ConnectionHubScreen extends ConsumerStatefulWidget {
  const ConnectionHubScreen({super.key, this.initialStep});

  /// Paso con el que se abre el hub (p. ej. desde el resultado del EMA):
  /// mensaje/contacto/encuentro abren directamente la selección de persona.
  final ConnectionStep? initialStep;

  @override
  ConsumerState<ConnectionHubScreen> createState() =>
      _ConnectionHubScreenState();
}

class _ConnectionHubScreenState extends ConsumerState<ConnectionHubScreen> {
  ConnectionStep _step = ConnectionStep.message;
  late bool _peopleView;
  late ConnectionAction _intent;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStep;
    _peopleView = initial == ConnectionStep.message ||
        initial == ConnectionStep.contact ||
        initial == ConnectionStep.meeting;
    _intent = switch (initial) {
      ConnectionStep.contact => ConnectionAction.contact,
      ConnectionStep.meeting => ConnectionAction.meeting,
      _ => ConnectionAction.message,
    };
    if (initial == ConnectionStep.skills) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openSkills();
      });
    }
  }

  void _openSkills() =>
      showPendingContentSheet(context, title: 'Habilidades interpersonales');

  void _openStep(ConnectionStep step) {
    switch (step) {
      case ConnectionStep.received:
        context.goNamed(AppRoute.caringInbox);
      case ConnectionStep.skills:
        _openSkills();
      case ConnectionStep.message:
      case ConnectionStep.contact:
      case ConnectionStep.meeting:
        setState(() {
          _intent = switch (step) {
            ConnectionStep.contact => ConnectionAction.contact,
            ConnectionStep.meeting => ConnectionAction.meeting,
            _ => ConnectionAction.message,
          };
          _peopleView = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyAsync = ref.watch(gatingJourneyProvider);
    final receivedCount = ref.watch(visibleCaringMessagesCountProvider);

    return PcsInternalScaffold(
      backLabel: _peopleView ? 'Volver a Tejiendo vínculos' : 'Volver al inicio',
      onBack: () => _peopleView
          ? setState(() => _peopleView = false)
          : context.goNamed(AppRoute.pcsHome),
      moduleLabel: 'Tejiendo vínculos',
      moduleIcon: Icons.link,
      child: journeyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
        data: (journey) {
          final gating = CareGating(journey);
          if (_peopleView) {
            return ConnectionPersonSelector(
              key: ValueKey(_intent),
              journey: journey,
              gating: gating,
              intent: _intent,
              onSkills: _openSkills,
            );
          }
          final people = gating.authorizedPeople;
          final person = people.isEmpty
              ? null
              : people.firstWhere(
                  (p) => p.id == journey.selectedPersonId,
                  orElse: () => people.first,
                );
          final featured = connectionStepContent(_step, name: person?.name);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              const CompanionNote(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tejer vínculos se hace paso a paso y de muchas formas.',
                      style: PcsText.body,
                    ),
                    SizedBox(height: 8),
                    Text('¿Qué paso quieres dar hoy?', style: PcsText.cloud),
                  ],
                ),
              ),
              _FeaturedStep(
                content: featured,
                icon: connectionStepIcons[_step]!,
                onPrimary: () => _openStep(_step),
                onOther: () =>
                    setState(() => _step = nextConnectionStep(_step)),
              ),
              const SizedBox(height: 22),
              const Text('Otros pasos', style: PcsText.sectionTitle),
              const SizedBox(height: 12),
              _StepGrid(
                receivedCount: receivedCount,
                onTap: _openStep,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Paso destacado «Un paso para hoy» (`.pcs-featured-step`).
class _FeaturedStep extends StatelessWidget {
  const _FeaturedStep({
    required this.content,
    required this.icon,
    required this.onPrimary,
    required this.onOther,
  });

  final ConnectionStepContent content;
  final IconData icon;
  final VoidCallback onPrimary;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(14, 17, 14, 17),
      decoration: BoxDecoration(
        color: PcsColors.peach,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Un paso para hoy'.toUpperCase(), style: PcsText.eyebrow),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PcsActionIcon(icon: icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content.title, style: PcsText.featured),
                      const SizedBox(height: 6),
                      Text(content.description, style: PcsText.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 14,
                child: PcsPillButton(label: content.button, onPressed: onPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: PcsPillButton(
                  label: 'Otro paso',
                  secondary: true,
                  onPressed: onOther,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rejilla «Otros pasos» (`.pcs-step-grid`): dos columnas y el último paso a
/// lo ancho.
class _StepGrid extends StatelessWidget {
  const _StepGrid({required this.receivedCount, required this.onTap});

  final int receivedCount;
  final ValueChanged<ConnectionStep> onTap;

  @override
  Widget build(BuildContext context) {
    final steps = ConnectionStep.values;
    Widget tile(ConnectionStep step, {bool wide = false}) {
      var label = connectionStepContent(step).tile;
      if (step == ConnectionStep.received && receivedCount > 0) {
        label = '$label ($receivedCount)';
      }
      final children = [
        Icon(connectionStepIcons[step], color: PcsColors.terracotta),
        SizedBox(width: wide ? 10 : 0, height: wide ? 0 : 10),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              height: 21 / 15,
              fontWeight: FontWeight.w600,
              color: PcsColors.ink,
            ),
          ),
        ),
      ];
      return Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: PcsColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onTap(step),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: wide ? 74 : 113),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: wide
                    ? Row(children: children)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
              ),
            ),
          ),
        ),
      );
    }

    final paired = steps.sublist(0, steps.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContigoTileGrid(gap: 10, children: [for (final s in paired) tile(s)]),
        const SizedBox(height: 10),
        tile(steps.last, wide: true),
      ],
    );
  }
}

/// Acciones dirigidas a la persona elegida (`actions` de
/// `connection-person.tsx`).
const List<(ConnectionAction, String, String, IconData)> _personActions = [
  (
    ConnectionAction.message,
    'Mensaje para tejer cercanía',
    'Ideas para escribirle hoy',
    Icons.chat_bubble_outline,
  ),
  (
    ConnectionAction.contact,
    'Llamar o enviar audio',
    'Prepara una forma de acercarte',
    Icons.phone_outlined,
  ),
  (
    ConnectionAction.meeting,
    'Proponer un encuentro',
    'Algo sencillo para verse',
    Icons.calendar_today_outlined,
  ),
];

/// Selección de persona de la red (`ConnectionPersonScreen`): pequeño mapa de
/// círculos, lista completa y panel con las formas de acercarse.
class ConnectionPersonSelector extends ConsumerStatefulWidget {
  const ConnectionPersonSelector({
    super.key,
    required this.journey,
    required this.gating,
    required this.intent,
    required this.onSkills,
  });

  final JourneyState journey;
  final CareGating gating;
  final ConnectionAction intent;
  final VoidCallback onSkills;

  @override
  ConsumerState<ConnectionPersonSelector> createState() =>
      _ConnectionPersonSelectorState();
}

class _ConnectionPersonSelectorState
    extends ConsumerState<ConnectionPersonSelector> {
  late String? _selectedId = widget.journey.selectedPersonId;
  final _panelKey = GlobalKey();

  void _select(String id) {
    setState(() => _selectedId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _panelKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  Future<void> _open(NetworkPerson person, ConnectionAction action) async {
    // Reevalúa la autorización exacta en el lanzamiento (incluida revocación).
    final journey = ref.read(gatingJourneyProvider).value ?? widget.journey;
    final launch = connectionLaunch(journey, person.id, action);
    if (launch == null) return;
    await selectConnectionPerson(ref, person.id);
    if (!mounted) return;
    context.goNamed(
      AppRoute.connectionPerson,
      queryParameters: {'p': launch.personId, 'a': launch.action.wireValue},
    );
  }

  void _openNetwork() {
    context.goNamed(
      widget.journey.mapGenerated ? AppRoute.networkMap : AppRoute.networkBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    final people = journey.people;
    NetworkPerson? selected;
    for (final p in people) {
      if (p.id == _selectedId) selected = p;
    }
    final canOpen = selected != null && widget.gating.canStrengthen(selected.id);
    final ring = selected != null && NetworkMetricsCalculator.isAssessed(selected)
        ? NetworkMetricsCalculator.metricsFor(selected).ring
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        const Text('¿Te serviría sentirte acompañada?', style: PcsText.display),
        const SizedBox(height: 12),
        const Text(
          'Toca a alguien de tu tejido para ver formas de acercarte.',
          style: PcsText.body,
        ),
        const SizedBox(height: 18),
        if (people.isEmpty)
          _EmptyNetwork(onOpenNetwork: _openNetwork)
        else ...[
          _PersonMap(
            people: people.take(8).toList(),
            selectedId: _selectedId,
            onSelect: _select,
          ),
          const SizedBox(height: 12),
          Semantics(
            container: true,
            label: 'Todas las personas de tu red',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final person in people)
                  _PersonChip(
                    name: person.name,
                    selected: person.id == _selectedId,
                    onTap: () => _select(person.id),
                  ),
              ],
            ),
          ),
          if (people.length > 8) ...[
            const SizedBox(height: 10),
            const Text(
              'El mapa muestra las primeras ocho personas; puedes elegir '
              'cualquiera desde la lista.',
              style: TextStyle(fontSize: 12, height: 18 / 12, color: Color(0xFF626169)),
            ),
          ],
          const SizedBox(height: 18),
          if (selected == null)
            const _DashedBox(
              child: Text(
                'Elige una persona del mapa o de la lista para ver las opciones.',
                style: PcsText.body,
              ),
            )
          else
            Container(
              key: _panelKey,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Semantics(
                container: true,
                label: 'Formas de acercarte a ${selected.name}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.name,
                              style: PcsText.display.copyWith(fontSize: 26, height: 30 / 26),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              ring != null
                                  ? 'Círculo ${ring.label.toLowerCase()} de tu red'
                                  : 'Persona de tu red',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 19 / 13,
                                color: PcsColors.text,
                              ),
                            ),
                          ],
                        ),
                        PcsSkillsButton(onPressed: widget.onSkills),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!canOpen)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PcsColors.peach,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Para usar estas herramientas, esta persona debe '
                              'aceptar la invitación y tener un vínculo activo '
                              'contigo.',
                              style: PcsText.body,
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF7F3D23),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              onPressed: _openNetwork,
                              child: const Text(
                                'Revisar mi red e invitaciones',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final (action, title, subtitle, icon) in _personActions)
                      _PersonAction(
                        title: title,
                        subtitle: subtitle,
                        icon: icon,
                        suggested: action == widget.intent,
                        onTap: canOpen ? () => _open(selected!, action) : null,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EmptyNetwork extends StatelessWidget {
  const _EmptyNetwork({required this.onOpenNetwork});

  final VoidCallback onOpenNetwork;

  @override
  Widget build(BuildContext context) {
    return _DashedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tu tejido puede empezar con una persona',
            style: TextStyle(fontSize: 19, height: 25 / 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Todavía no hay personas en tu red. Puedes conocerla e invitar a '
            'alguien cuando quieras.',
            style: PcsText.body,
          ),
          const SizedBox(height: 14),
          PcsPillButton(label: 'Conocer mi red', onPressed: onOpenNetwork),
        ],
      ),
    );
  }
}

class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6C8BA)),
      ),
      child: child,
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: PcsColors.peach,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? PcsColors.terracotta : const Color(0xFFE5D8CA),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F3A2F),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonAction extends StatelessWidget {
  const _PersonAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.suggested,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool suggested;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: '$title. $subtitle',
        excludeSemantics: true,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Material(
            color: PcsColors.canvas,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
              side: BorderSide(
                color: suggested ? const Color(0xFFD8B599) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(19),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 82),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                  child: Row(
                    children: [
                      PcsActionIcon(icon: icon),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 21 / 15,
                                fontWeight: FontWeight.w800,
                                color: PcsColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 19 / 13,
                                color: PcsColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: PcsColors.terracotta),
                    ],
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

/// Pequeño mapa de círculos con las primeras ocho personas (`.pcs-person-map`).
class _PersonMap extends StatelessWidget {
  const _PersonMap({
    required this.people,
    required this.selectedId,
    required this.onSelect,
  });

  final List<NetworkPerson> people;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  static const _iconColors = [
    (Color(0xFFDCEAF1), Color(0xFF6F9CB3)),
    (Color(0xFFF8DCC6), Color(0xFFB57A58)),
    (Color(0xFFE3DDF5), Color(0xFF8D79C6)),
  ];

  @override
  Widget build(BuildContext context) {
    final nodes = <(NetworkPerson, Offset)>[];
    for (var i = 0; i < people.length; i++) {
      final person = people[i];
      final ring = NetworkMetricsCalculator.isAssessed(person)
          ? NetworkMetricsCalculator.metricsFor(person).ring
          : null;
      final radius = ring == NetworkRing.intimo
          ? 52.0
          : ring == NetworkRing.personal
              ? 90.0
              : 125.0;
      final angle =
          (-110 + i * (360 / math.max(people.length, 3))) * math.pi / 180;
      nodes.add((
        person,
        Offset(160 + math.cos(angle) * radius, 160 + math.sin(angle) * radius),
      ));
    }

    return Semantics(
      container: true,
      label: 'Personas de tu tejido',
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / 320;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PersonMapPainter(
                      nodes: [for (final (p, o) in nodes) (o, p.id == selectedId)],
                    ),
                  ),
                ),
                Positioned(
                  left: 160 * scale - 23,
                  top: 160 * scale - 23,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6045B5),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'Tú',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < nodes.length; i++)
                  Positioned(
                    left: nodes[i].$2.dx * scale - 35,
                    top: nodes[i].$2.dy * scale - 22 * 0.7 - 6,
                    width: 70,
                    child: Semantics(
                      button: true,
                      selected: nodes[i].$1.id == selectedId,
                      label: 'Elegir a ${nodes[i].$1.name}',
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(nodes[i].$1.id),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _iconColors[(i + 1) % 3].$1,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: nodes[i].$1.id == selectedId
                                    ? const [
                                        BoxShadow(
                                          color: PcsColors.terracotta,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 20,
                                color: _iconColors[(i + 1) % 3].$2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              nodes[i].$1.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w600,
                                color: PcsColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PersonMapPainter extends CustomPainter {
  _PersonMapPainter({required this.nodes});

  final List<(Offset, bool)> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 320;
    canvas.save();
    canvas.scale(scale);
    const center = Offset(160, 160);
    final ringStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFE5D8CA);
    canvas.drawCircle(center, 64, Paint()..color = const Color(0xFFFBEADD));
    canvas.drawCircle(center, 64, ringStroke);
    for (final r in [100.0, 140.0]) {
      _dashedCircle(canvas, center, r, ringStroke);
    }
    for (final (offset, selected) in nodes) {
      canvas.drawLine(
        center,
        offset,
        Paint()
          ..color = selected ? PcsColors.terracotta : const Color(0xFFDFC5B0)
          ..strokeWidth = selected ? 3 : 1.5,
      );
    }
    canvas.restore();
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint paint) {
    final circumference = 2 * math.pi * r;
    final count = (circumference / 9).floor();
    final sweep = 4 / r;
    for (var i = 0; i < count; i++) {
      final start = i * 2 * math.pi / count;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PersonMapPainter old) => true;
}
