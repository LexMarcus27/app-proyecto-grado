import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/journey/demo_seeder.dart';
import '../../domain/journey/demo_scenario.dart';
import '../network/network_map_screen.dart';
import '../widgets/widgets.dart';

/// Pantalla de desarrollo "Controles de demostración" (Etapa 2).
///
/// No forma parte del producto: es una ayuda de revisión que permite alternar,
/// desde el emulador, entre los dos escenarios demo de la tarea 2.10
/// ([DemoScenario.withActiveLink] y [DemoScenario.withoutActiveLink]) sin tener
/// que reinstalar la app ni limpiar el almacenamiento a mano.
///
/// Reusa por completo el control de la tarea 2.10: lee
/// [demoScenarioControllerProvider] para reflejar el escenario activo y, al
/// elegir una opción, llama a `select(scenario)`, que persiste la semilla
/// correspondiente a través del `journeyRepositoryProvider`. No reimplementa la
/// lógica de escenarios ni toca el dominio EMA.
///
/// Opera en la Capa_Simulada: los datos que alterna son ficticios, por lo que
/// muestra el indicador de simulación persistente (Requirement 3.4).
class DemoScenarioControlsScreen extends ConsumerWidget {
  const DemoScenarioControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final current = ref.watch(demoScenarioControllerProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            // Indicador de simulación persistente: estos datos son ficticios.
            const SimulationIndicator(
              layer: FeatureLayer.simulada,
              label: 'Datos de demostración ficticios: aquí cambias el '
                  'escenario con el que se ejercita el recorrido.',
            ),
            _Header(onBack: () => _handleBack(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text(
                    'Cambia los datos ficticios de demostración para probar el '
                    'recorrido en cada situación. No afecta a ninguna persona '
                    'real.',
                    style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                      color: ContigoColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ScenarioChoice(
                    title: 'Con persona vinculada',
                    description:
                        'Existe una persona vinculada activa (M.). Ejercita la '
                        'selección de referencia y el bloque de relación.',
                    selected: current == DemoScenario.withActiveLink,
                    onSelect: () => _select(
                      ref,
                      DemoScenario.withActiveLink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ScenarioChoice(
                    title: 'Sin persona vinculada',
                    description:
                        'No hay ninguna persona vinculada activa. Ejercita la '
                        'omisión del bloque de relación (camino de 6 ítems).',
                    selected: current == DemoScenario.withoutActiveLink,
                    onSelect: () => _select(
                      ref,
                      DemoScenario.withoutActiveLink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Hint(
                    child: Text.rich(
                      TextSpan(
                        style:
                            (textTheme.bodySmall ?? const TextStyle()).copyWith(
                          color: ContigoColors.inkMuted,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Tras cambiar, abrir ',
                          ),
                          TextSpan(
                            text: '"Mi registro EMA"',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' gatea distinto: con persona vinculada lleva '
                                'a la selección y al cuestionario de 9 ítems; '
                                'sin persona vinculada lleva al camino sin '
                                'vínculo de 6 ítems.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aplica el escenario reusando el controlador de 2.10 y refresca la
  /// referencia EMA mostrada en el mapa de red, ya que cambiar de escenario
  /// puede dejar obsoleta la selección guardada.
  Future<void> _select(WidgetRef ref, DemoScenario scenario) async {
    await ref.read(demoScenarioControllerProvider.notifier).select(scenario);
    ref.invalidate(savedEmaReferenceProvider);
  }

  /// Vuelve a la pantalla anterior; si no hay nada que desapilar, va a la
  /// activación (origen natural del enlace a esta pantalla de desarrollo).
  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.activation);
    }
  }
}

/// Cabecera con afordancia de volver y título.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 18, 11),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back),
            color: ContigoColors.terracotta,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              'Controles de demostración',
              style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
                color: ContigoColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opción de escenario como [ContigoActionCard] seleccionable: muestra un
/// distintivo cuando es el escenario activo y, al tocarla, aplica el escenario.
class _ScenarioChoice extends StatelessWidget {
  const _ScenarioChoice({
    required this.title,
    required this.description,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semanticLabel = selected
        ? '$title. Escenario activo.'
        : '$title. Tocar para activar.';

    return ContigoActionCard(
      semanticLabel: semanticLabel,
      onPressed: onSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style:
                      (textTheme.titleMedium ?? const TextStyle()).copyWith(
                    color: ContigoColors.ink,
                  ),
                ),
              ),
              if (selected) const _ActiveBadge(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distintivo que marca el escenario demo activo.
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ContigoColors.notifReminderBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Activo',
        style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
          color: ContigoColors.notifReminderAccent,
        ),
      ),
    );
  }
}

/// Recuadro suave para la pista de navegación al final de la pantalla.
class _Hint extends StatelessWidget {
  const _Hint({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ContigoColors.notifQuestionsBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
