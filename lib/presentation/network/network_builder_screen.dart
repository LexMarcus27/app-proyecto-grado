import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/journey.dart';
import '../../domain/network/network.dart';
import '../widgets/widgets.dart';
import 'network_builder_controller.dart';
import 'network_map_screen.dart';

/// Construcción del mapa de red (tarea 3.11), portada del flujo de
/// `src/screens/network.tsx` (generador de nombres, evaluación y
/// `generateResults`).
///
/// Captura personas con las preguntas del generador de nombres, evalúa cada una
/// con los 18 ítems de la relación y genera el mapa. El cómputo de resultados es
/// una Funcion_Simulada, por lo que muestra el indicador de simulación. Si el
/// mapa ya está generado, ofrece abrir "Tu mapa de red".
class NetworkBuilderScreen extends ConsumerWidget {
  const NetworkBuilderScreen({super.key});

  static const FeatureLayerInfo featureLayer = FeatureLayerInfo(
    featureId: 'network-build',
    layer: FeatureLayer.simulada,
    label:
        'Construcción simulada del mapa: el cómputo de resultados es de '
        'demostración, a partir de las respuestas que registras aquí.',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final journeyAsync = ref.watch(networkJourneyProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: journeyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
          data: (journey) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.goNamed(AppRoute.pcsHome),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Volver al inicio',
                    ),
                    Expanded(
                      child: Text('Construir mi mapa', style: textTheme.titleLarge),
                    ),
                  ],
                ),
              ),
              SimulationIndicator.forFeature(NetworkBuilderScreen.featureLayer),
              Expanded(
                child: _BuilderBody(journey: journey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuilderBody extends ConsumerWidget {
  const _BuilderBody({required this.journey});

  final JourneyState journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final assessed = assessedPeople(journey);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (journey.mapGenerated) ...[
            Text('Tu mapa ya está generado.', style: textTheme.titleSmall),
            const SizedBox(height: 10),
            ContigoButton(
              label: 'Ir a Tu mapa de red',
              fullWidth: true,
              onPressed: () => context.goNamed(AppRoute.networkMap),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
          ],
          Text(
            'Reconoce a las personas de tu red respondiendo estas preguntas. '
            'Puedes agregar a quienes aparezcan al pensarlas.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          // Preguntas del generador de nombres (verbatim, como guía).
          for (final q in nameGeneratorQuestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle, size: 6, color: ContigoColors.sage),
                  ),
                  Expanded(child: Text(q, style: textTheme.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ContigoButton(
            label: 'Agregar una persona',
            variant: ContigoButtonVariant.secondary,
            fullWidth: true,
            icon: const Icon(Icons.person_add_alt),
            onPressed: () => _addPerson(context, ref),
          ),
          const SizedBox(height: 20),
          Text('Personas en tu mapa', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          if (journey.people.isEmpty)
            Text(
              'Aún no has agregado personas.',
              style: (textTheme.bodySmall ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            )
          else
            for (final person in journey.people)
              _PersonRow(
                person: person,
                onEvaluate: () => _evaluate(context, ref, person),
              ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ContigoButton(
            label: 'Generar mi mapa',
            fullWidth: true,
            onPressed: assessed.isEmpty ? null : () => _generate(context, ref),
          ),
          if (assessed.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Evalúa al menos a una persona (sus 18 ítems) para generar el mapa.',
              style: (textTheme.bodySmall ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addPerson(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_NewPerson>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => const _AddPersonSheet(),
    );
    if (result == null) return;
    await ref
        .read(networkBuilderControllerProvider)
        .addPerson(result.name, result.type);
  }

  Future<void> _evaluate(
    BuildContext context,
    WidgetRef ref,
    NetworkPerson person,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EvaluationScreen(personId: person.id),
      ),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final ok = await ref.read(networkBuilderControllerProvider).generate();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // cierra el indicador
    if (ok) context.goNamed(AppRoute.networkMap);
  }
}

class _NewPerson {
  const _NewPerson(this.name, this.type);
  final String name;
  final RelationshipType type;
}

class _AddPersonSheet extends StatefulWidget {
  const _AddPersonSheet();

  @override
  State<_AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends State<_AddPersonSheet> {
  final TextEditingController _name = TextEditingController();
  RelationshipType _type = RelationshipType.familia;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
          Text('Agregar una persona', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RelationshipType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Tipo de relación',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final t in RelationshipType.values)
                DropdownMenuItem(value: t, child: Text(t.wireValue)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 16),
          ContigoButton(
            label: 'Agregar',
            fullWidth: true,
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              Navigator.of(context).pop(_NewPerson(_name.text.trim(), _type));
            },
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.onEvaluate});

  final NetworkPerson person;
  final VoidCallback onEvaluate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = isPersonAssessed(person);
    final answered = person.answers.where((a) => a != null).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ContigoCard(
        onTap: onEvaluate,
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
                    done
                        ? 'Evaluación completa'
                        : 'Evaluación: $answered de $relationshipItemCount',
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ContigoColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Cuestionario de evaluación de la relación (18 ítems en escala de 6 puntos).
class _EvaluationScreen extends ConsumerStatefulWidget {
  const _EvaluationScreen({required this.personId});

  final String personId;

  @override
  ConsumerState<_EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<_EvaluationScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = relationshipQuestions.length;
    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      appBar: AppBar(
        title: Text('Ítem ${_index + 1} de $total'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(relationshipQuestions[_index], style: textTheme.titleMedium),
              const SizedBox(height: 16),
              for (var i = 0; i < relationshipScale.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ContigoButton(
                    label: relationshipScale[i],
                    variant: ContigoButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => _answer(i + 1, total),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _answer(int value, int total) async {
    await ref
        .read(networkBuilderControllerProvider)
        .answer(widget.personId, _index, value);
    if (!mounted) return;
    if (_index < total - 1) {
      setState(() => _index += 1);
    } else {
      Navigator.of(context).pop();
    }
  }
}