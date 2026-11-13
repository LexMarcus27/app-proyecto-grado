import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/journey.dart';
import '../../domain/network/network.dart';
import '../widgets/widgets.dart';
import 'network_builder_controller.dart';
import 'network_map_screen.dart';

/// Etapas del constructor guiado del mapa de red (orden del prototipo
/// `network.tsx`): generador de nombres, revisión de la lista, avance y
/// caracterización por persona.
enum _BuildStage { intro, names, review, summary, personIntro, characterize }

/// Construcción guiada del mapa de red (tarea 3.11, corrección E3-W13-02),
/// portada del flujo de `SocialNetworkScreen` (`src/screens/network.tsx`).
///
/// Reproduce el recorrido activo del prototipo: las **diez** preguntas del
/// generador de nombres (una por pantalla, con omitir/continuar), la **revisión**
/// de las personas capturadas (editar/eliminar) y la **caracterización por
/// persona**, cuyo paso 1 de 19 es "¿Quién es {nombre} para ti?" (sin
/// preseleccionar "Familia") seguido de los mismos 18 ítems. El avance se
/// conserva (reanudación). Generar con al menos una relación completa sigue
/// siendo válido. El cómputo de resultados es una Funcion_Simulada.
class NetworkBuilderScreen extends ConsumerStatefulWidget {
  const NetworkBuilderScreen({super.key, this.editPersonId});

  /// Persona cuyas respuestas se editan desde el detalle de resultados
  /// («Editar respuestas»): abre directamente su caracterización.
  final String? editPersonId;

  static const FeatureLayerInfo featureLayer = FeatureLayerInfo(
    featureId: 'network-build',
    layer: FeatureLayer.simulada,
    label:
        'Construcción simulada del mapa: el cómputo de resultados es de '
        'demostración, a partir de las respuestas que registras aquí.',
  );

  @override
  ConsumerState<NetworkBuilderScreen> createState() =>
      _NetworkBuilderScreenState();
}

class _NetworkBuilderScreenState extends ConsumerState<NetworkBuilderScreen> {
  _BuildStage _stage = _BuildStage.intro;
  bool _entryResolved = false;

  /// Etapa (e ítem) con que se abrió la pantalla: volver desde ella sale a la
  /// pantalla anterior en lugar de recorrer las etapas previas del constructor
  /// (p. ej. al reabrir un mapa empezado, que entra por el avance).
  _BuildStage _entryStage = _BuildStage.intro;
  int _entryItemIndex = 0;
  int _nameIndex = 0;

  /// Respuesta elegida en el ítem actual, pendiente de confirmar con
  /// «Continuar» (`selectedAnswer` del prototipo, F09).
  int? _pendingAnswer;
  final TextEditingController _nameField = TextEditingController();

  // Caracterización en curso.
  String? _currentPersonId;
  int _itemIndex = 0; // 0 = categoría (paso 1); 1..18 = ítems (pasos 2..19).

  @override
  void dispose() {
    _nameField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final journeyAsync = ref.watch(networkJourneyProvider);

    return PopScope(
      // El botón «atrás» del sistema se comporta igual que la flecha.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context);
      },
      child: Scaffold(
        backgroundColor: ContigoColors.canvas,
        body: SafeArea(
          child: journeyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
            data: (journey) {
              // Entrada del prototipo (`openNetwork`): con un mapa empezado y
              // personas, «progress» abre el avance; si no, la introducción.
              if (!_entryResolved) {
                _entryResolved = true;
                NetworkPerson? editing;
                for (final p in journey.people) {
                  if (p.id == widget.editPersonId) editing = p;
                }
                if (editing != null) {
                  // `startAssessment`: con tipo, empieza en el primer ítem.
                  _currentPersonId = editing.id;
                  if (editing.relationshipType == null) {
                    _itemIndex = 0;
                    _stage = _BuildStage.personIntro;
                  } else {
                    _itemIndex = 1;
                    _stage = _BuildStage.characterize;
                  }
                } else if (journey.mapStarted && journey.people.isNotEmpty) {
                  _stage = _BuildStage.summary;
                }
                _entryStage = _stage;
                _entryItemIndex = _itemIndex;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StatusBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _back(context),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Volver',
                        ),
                        Expanded(
                          child: Text(
                            _title(journey),
                            style: textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SimulationIndicator.forFeature(
                    NetworkBuilderScreen.featureLayer,
                  ),
                  Expanded(child: _buildStage(journey)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _title(JourneyState journey) {
    switch (_stage) {
      case _BuildStage.intro:
      case _BuildStage.names:
        return 'Conoce tu red';
      case _BuildStage.personIntro:
        return 'Caracterizar relación';
      case _BuildStage.review:
        return 'Tu lista de personas';
      case _BuildStage.summary:
        return 'Avance de tu mapa';
      case _BuildStage.characterize:
        return 'Caracterizar relación';
    }
  }

  void _back(BuildContext context) {
    final atEntry =
        _stage == _entryStage &&
        (_stage != _BuildStage.characterize || _itemIndex == _entryItemIndex);
    if (atEntry) {
      context.goBack(AppRoute.pcsHome);
      return;
    }
    switch (_stage) {
      case _BuildStage.intro:
        context.goBack(AppRoute.pcsHome);
      case _BuildStage.personIntro:
        setState(() => _stage = _BuildStage.summary);
      case _BuildStage.names:
        if (_nameIndex > 0) {
          setState(() => _nameIndex -= 1);
        } else {
          setState(() => _stage = _BuildStage.intro);
        }
      case _BuildStage.review:
        setState(() => _stage = _BuildStage.names);
      case _BuildStage.summary:
        setState(() => _stage = _BuildStage.review);
      case _BuildStage.characterize:
        if (_itemIndex > 0) {
          setState(() {
            _itemIndex -= 1;
            _pendingAnswer = null;
          });
        } else {
          setState(() => _stage = _BuildStage.summary);
        }
    }
  }

  Widget _buildStage(JourneyState journey) {
    switch (_stage) {
      case _BuildStage.intro:
        return _introStage(journey);
      case _BuildStage.personIntro:
        return _personIntroStage(journey);
      case _BuildStage.names:
        return _namesStage(journey);
      case _BuildStage.review:
        return _reviewStage(journey);
      case _BuildStage.summary:
        return _summaryStage(journey);
      case _BuildStage.characterize:
        return _characterizeStage(journey);
    }
  }

  // ── Introducción «Conoce tu red» (vista `intro` del prototipo) ─────────────

  Widget _introStage(JourneyState journey) {
    const brand = Color(0xFFA85550);
    const brandSoft = Color(0xFFF2E3E0);
    const border = Color(0xFFDFD4C9);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: brandSoft,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.people_outline, color: brand, size: 34),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Antes de empezar, construye tu mapa de red',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              height: 31 / 24,
              fontWeight: FontWeight.w700,
              color: ContigoColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reconoce las personas que forman parte de tu vida. Al terminar, '
            'podrás invitar a personas cercanas con quienes quieras compartir '
            'la aplicación o fortalecer tu relación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 23 / 15,
              color: ContigoColors.inkMuted,
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 16, color: ContigoColors.inkMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Puedes usar nombres, iniciales o apodos. Esta herramienta no '
                  'evalúa a las personas ni te obliga a explicar cada relación.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 18 / 12,
                    color: ContigoColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: ContigoColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: border),
            ),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: const ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 12),
                title: Text(
                  '¿Por qué te preguntamos esto?',
                  style: TextStyle(
                    color: brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                children: [
                  Text(
                    'Observar tu red puede ayudarte a decidir qué relación te '
                    'gustaría cuidar o fortalecer. La decisión siempre será tuya.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 20 / 13,
                      color: ContigoColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          ContigoButton(
            label: 'Construir mi mapa',
            fullWidth: true,
            onPressed: () => setState(() => _stage = _BuildStage.names),
          ),
          if (journey.people.isNotEmpty) ...[
            const SizedBox(height: 10),
            ContigoButton(
              label: 'Continuar un mapa guardado',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => setState(() => _stage = _BuildStage.summary),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ContigoButton(
              label: 'Hacerlo después',
              variant: ContigoButtonVariant.tertiary,
              fullWidth: true,
              onPressed: () => context.goBack(AppRoute.pcsHome),
            ),
          ],
        ],
      ),
    );
  }

  // ── Presentación por persona (vista `person-intro`) ───────────────────────

  Widget _personIntroStage(JourneyState journey) {
    NetworkPerson? person;
    for (final p in journey.people) {
      if (p.id == _currentPersonId) person = p;
    }
    if (person == null) {
      return const Center(child: Text('Selecciona una persona.'));
    }
    final initial = person.name.isEmpty ? '?' : person.name[0].toUpperCase();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF2E3E0),
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFFA85550),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Ahora veremos tu relación con ${person.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              height: 30 / 23,
              fontWeight: FontWeight.w700,
              color: ContigoColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No hay respuestas correctas o incorrectas. Responde según cómo '
            'percibes actualmente esta relación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 23 / 15,
              color: ContigoColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          ContigoButton(
            label: 'Continuar',
            fullWidth: true,
            onPressed: () => setState(() {
              _itemIndex = 0;
              _stage = _BuildStage.characterize;
            }),
          ),
          const SizedBox(height: 8),
          ContigoButton(
            label: 'Guardar y salir',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => context.goBack(AppRoute.pcsHome),
          ),
        ],
      ),
    );
  }

  // ── Generador de nombres: 10 preguntas, una por pantalla ──────────────────

  Widget _namesStage(JourneyState journey) {
    final textTheme = Theme.of(context).textTheme;
    final total = nameGeneratorQuestions.length;
    final isLast = _nameIndex == total - 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pregunta ${_nameIndex + 1} de $total',
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          ContigoCard(
            child: Text(
              nameGeneratorQuestions[_nameIndex],
              style: textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          if (journey.people.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in journey.people)
                  Chip(
                    label: Text(p.name),
                    backgroundColor: ContigoColors.notifQuestionsBg,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text('Nombre, iniciales o apodo', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameField,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: ContigoColors.surface,
                    hintText: 'Ej. Alex o M.',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addFromField(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addFromField,
                icon: const Icon(Icons.add),
                tooltip: 'Añadir esta persona',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ContigoButton(
            label: isLast ? 'Revisar mi lista' : 'Continuar',
            fullWidth: true,
            onPressed: () => _advanceName(isLast),
          ),
          const SizedBox(height: 8),
          ContigoButton(
            label: 'No se me ocurre nadie',
            variant: ContigoButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => _advanceName(isLast),
          ),
          const SizedBox(height: 8),
          ContigoButton(
            label: 'Omitir esta pregunta',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => _advanceName(isLast),
          ),
        ],
      ),
    );
  }

  Future<void> _addFromField() async {
    final name = _nameField.text.trim();
    if (name.isEmpty) return;
    _nameField.clear();
    await ref.read(networkBuilderControllerProvider).addNamedPerson(name);
  }

  Future<void> _advanceName(bool isLast) async {
    // Como el prototipo (`submitNameQuestion`): si hay un nombre escrito, se
    // guarda antes de avanzar, sin exigir pulsar "+".
    final name = _nameField.text.trim();
    if (name.isNotEmpty) {
      _nameField.clear();
      await ref.read(networkBuilderControllerProvider).addNamedPerson(name);
      if (!mounted) return;
    }
    if (isLast) {
      setState(() => _stage = _BuildStage.review);
    } else {
      setState(() => _nameIndex += 1);
    }
  }

  // ── Revisión de la lista ──────────────────────────────────────────────────

  Widget _reviewStage(JourneyState journey) {
    final textTheme = Theme.of(context).textTheme;
    if (journey.people.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu lista todavía está vacía. Puedes volver y añadir a alguien '
              'cuando quieras.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ContigoButton(
              label: 'Volver a las preguntas',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => setState(() {
                _nameIndex = 0;
                _stage = _BuildStage.names;
              }),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Las personas que forman tu red', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Revisa los nombres antes de caracterizar cada relación. Puedes '
            'cambiarlos por iniciales o apodos.',
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          for (final person in journey.people)
            _ReviewRow(
              person: person,
              onRename: (name) => ref
                  .read(networkBuilderControllerProvider)
                  .renamePerson(person.id, name),
              onRemove: () => ref
                  .read(networkBuilderControllerProvider)
                  .removePerson(person.id),
            ),
          const SizedBox(height: 16),
          ContigoButton(
            label: 'Añadir a alguien más',
            variant: ContigoButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => setState(() {
              _nameIndex = nameGeneratorQuestions.length - 1;
              _stage = _BuildStage.names;
            }),
          ),
          const SizedBox(height: 8),
          ContigoButton(
            label: 'Continuar con la caracterización',
            fullWidth: true,
            onPressed: () => setState(() => _stage = _BuildStage.summary),
          ),
        ],
      ),
    );
  }

  // ── Avance del mapa (elegir persona a caracterizar) ───────────────────────

  Widget _summaryStage(JourneyState journey) {
    final textTheme = Theme.of(context).textTheme;
    final assessed = assessedPeople(journey);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elige una persona para continuar. No necesitas terminar todo en '
            'una sola sesión.',
            style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          for (final person in journey.people)
            _SummaryRow(
              person: person,
              onTap: () => _startCharacterization(person),
            ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ContigoButton(
            label: 'Generar mi mapa',
            fullWidth: true,
            onPressed: assessed.isEmpty ? null : () => _generate(context),
          ),
          if (assessed.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Completa la caracterización de al menos una persona (sus 18 '
              'ítems) para generar el mapa.',
              style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                color: ContigoColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ContigoButton(
            label: 'Añadir o editar personas',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => setState(() => _stage = _BuildStage.review),
          ),
        ],
      ),
    );
  }

  void _startCharacterization(NetworkPerson person) {
    setState(() {
      _currentPersonId = person.id;
      // Reanuda: si ya tiene tipo, continúa por el primer ítem sin responder;
      // si no, empieza por el paso 1 (categoría).
      _pendingAnswer = null;
      if (person.relationshipType == null) {
        // Sin tipo: primero la presentación de la persona (`person-intro`).
        _itemIndex = 0;
        _stage = _BuildStage.personIntro;
      } else {
        final firstUnanswered = person.answers.indexWhere((a) => a == null);
        _itemIndex = firstUnanswered < 0 ? 1 : firstUnanswered + 1;
        _stage = _BuildStage.characterize;
      }
    });
  }

  // ── Caracterización por persona: paso 1 categoría + 18 ítems ──────────────

  Widget _characterizeStage(JourneyState journey) {
    final textTheme = Theme.of(context).textTheme;
    NetworkPerson? person;
    for (final p in journey.people) {
      if (p.id == _currentPersonId) {
        person = p;
        break;
      }
    }
    if (person == null) {
      return const Center(child: Text('Selecciona una persona.'));
    }
    final step = _itemIndex + 1; // 1..19
    final progress = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pregunta $step de 19',
          style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: ContigoColors.inkMuted,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );

    if (_itemIndex == 0) {
      // Paso 1 de 19: ¿Quién es {nombre} para ti? (sin preselección).
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            progress,
            ContigoCard(
              child: Text(
                '¿Quién es ${person.name} para ti?',
                style: textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige el ámbito que mejor represente la relación actualmente.',
              style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                color: ContigoColors.inkMuted,
              ),
            ),
            const SizedBox(height: 12),
            for (final type in RelationshipType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryOption(
                  label: type.wireValue,
                  // Sin preselección: solo marca la ya guardada (reanudación).
                  selected: person.relationshipType == type,
                  onTap: () => _selectCategory(person!.id, type),
                ),
              ),
          ],
        ),
      );
    }

    // Pasos 2..19: los 18 ítems de la relación.
    final itemIdx = _itemIndex - 1;
    final saved = person.answers.length > itemIdx
        ? person.answers[itemIdx]
        : null;
    final selected = _pendingAnswer ?? saved;
    final isLastItem = itemIdx == relationshipItemCount - 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          progress,
          ContigoCard(
            child: Text(
              relationshipQuestions[itemIdx],
              style: textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < relationshipScale.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CategoryOption(
                label: relationshipScale[i],
                selected: selected == i + 1,
                // Selecciona; se confirma con «Continuar» (F09).
                onTap: () => setState(() => _pendingAnswer = i + 1),
              ),
            ),
          const SizedBox(height: 8),
          ContigoButton(
            label: isLastItem ? 'Terminar caracterización' : 'Continuar',
            fullWidth: true,
            onPressed: selected == null
                ? null
                : () => _answerItem(person!.id, itemIdx, selected),
          ),
          const SizedBox(height: 4),
          ContigoButton(
            label: 'Guardar y continuar después',
            variant: ContigoButtonVariant.ghost,
            fullWidth: true,
            onPressed: () => context.goBack(AppRoute.pcsHome),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCategory(String personId, RelationshipType type) async {
    await ref
        .read(networkBuilderControllerProvider)
        .setRelationshipType(personId, type);
    if (!mounted) return;
    setState(() => _itemIndex = 1); // avanza al primer ítem
  }

  Future<void> _answerItem(String personId, int itemIdx, int value) async {
    await ref
        .read(networkBuilderControllerProvider)
        .answer(personId, itemIdx, value);
    if (!mounted) return;
    if (itemIdx < relationshipItemCount - 1) {
      setState(() {
        _itemIndex += 1;
        _pendingAnswer = null;
      });
    } else {
      // Terminó los 18 ítems: vuelve al avance.
      setState(() {
        _pendingAnswer = null;
        _stage = _BuildStage.summary;
      });
    }
  }

  Future<void> _generate(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final ok = await ref.read(networkBuilderControllerProvider).generate();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (ok) context.goNamed(AppRoute.networkMap);
  }
}

/// Fila de revisión: nombre editable y eliminar.
class _ReviewRow extends StatefulWidget {
  const _ReviewRow({
    required this.person,
    required this.onRename,
    required this.onRemove,
  });
  final NetworkPerson person;
  final ValueChanged<String> onRename;
  final VoidCallback onRemove;

  @override
  State<_ReviewRow> createState() => _ReviewRowState();
}

class _ReviewRowState extends State<_ReviewRow> {
  bool _editing = false;
  late final TextEditingController _c = TextEditingController(
    text: widget.person.name,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ContigoCard(
        child: _editing
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Guardar nombre',
                    icon: const Icon(Icons.check, color: ContigoColors.sage),
                    onPressed: () {
                      widget.onRename(_c.text);
                      setState(() => _editing = false);
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: ContigoColors.notifQuestionsBg,
                    child: Text(
                      widget.person.name.isNotEmpty
                          ? widget.person.name.characters.first.toUpperCase()
                          : '?',
                      style: const TextStyle(color: ContigoColors.terracotta),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.person.name,
                      style: textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar ${widget.person.name}',
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: ContigoColors.terracotta,
                    ),
                    onPressed: () => setState(() => _editing = true),
                  ),
                  IconButton(
                    tooltip: 'Eliminar ${widget.person.name}',
                    icon: const Icon(Icons.close, color: ContigoColors.clay),
                    onPressed: widget.onRemove,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Fila de avance: persona con su tipo y estado de caracterización.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.person, required this.onTap});
  final NetworkPerson person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = isPersonAssessed(person);
    final answered = person.answers.where((a) => a != null).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ContigoCard(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: done
                  ? ContigoColors.notifReminderBg
                  : ContigoColors.notifQuestionsBg,
              child: Icon(
                done ? Icons.check : Icons.person,
                color: done ? ContigoColors.sage : ContigoColors.terracotta,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: textTheme.titleSmall),
                  Text(
                    person.relationshipType?.wireValue ??
                        'Tipo de relación pendiente',
                    style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                      color: ContigoColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              done
                  ? 'Completa'
                  : person.status == PersonStatus.inProgress
                  ? 'En progreso ($answered/$relationshipItemCount)'
                  : 'Pendiente',
              style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
                color: ContigoColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opción seleccionable (categoría o escala), con estado marcado.
class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? ContigoColors.notifQuestionsBg
              : ContigoColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? ContigoColors.terracotta
                : ContigoColors.notifMeetingBg,
            width: 1.5,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
            color: selected ? ContigoColors.terracotta : ContigoColors.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
