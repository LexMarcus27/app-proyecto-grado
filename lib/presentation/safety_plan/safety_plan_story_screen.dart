import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../content/safety_plan_story.dart';
import '../../domain/safety_plan/safety_plan_draft.dart';
import '../widgets/widgets.dart';
import 'safety_plan_controller.dart';
import 'widgets/story_video.dart';

/// Relato narrativo del plan de seguridad ("Las crisis también pasan"),
/// portado de `SafetyPlanStoryScreen` (`src/screens/safety-plan-story.tsx`).
///
/// Presenta las siete páginas del relato **verbatim** y en orden (incluidos sus
/// videos), con avance página a página. En la última página el botón principal
/// lleva al editor del plan con la etiqueta según si ya hay información
/// ([safetyPlanLinkLabel]). El texto no se altera ni reordena (Requirement 7.6).
class SafetyPlanStoryScreen extends ConsumerStatefulWidget {
  const SafetyPlanStoryScreen({super.key});

  @override
  ConsumerState<SafetyPlanStoryScreen> createState() =>
      _SafetyPlanStoryScreenState();
}

class _SafetyPlanStoryScreenState extends ConsumerState<SafetyPlanStoryScreen> {
  int _pageIndex = 0;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _pageIndex = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final page = safetyPlanStory[_pageIndex];
    final isLast = _pageIndex == safetyPlanStory.length - 1;
    final planAsync = ref.watch(safetyPlanControllerProvider);
    final hasInformation =
        safetyPlanHasInformation(planAsync.value ?? createSafetyPlanDraft());

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            // Cabecera: salida, kicker, título y progreso.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.goNamed(AppRoute.pcsHome),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Salir del recurso'),
                    ),
                  ),
                  Text(
                    'Recursos narrativos · Plan para desenredar',
                    style: (textTheme.labelMedium ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(safetyPlanStoryTitle, style: textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  _StoryProgress(
                    total: safetyPlanStory.length,
                    current: _pageIndex,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pantalla ${_pageIndex + 1} de ${safetyPlanStory.length}',
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.title, style: textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (page.video != null) ...[
                      StoryVideo(asset: page.video!, title: page.title),
                      const SizedBox(height: 16),
                    ],
                    for (final paragraph in page.paragraphs) ...[
                      Text(paragraph, style: textTheme.bodyLarge),
                      const SizedBox(height: 14),
                    ],
                    if (page.listHeading != null) ...[
                      Text(page.listHeading!, style: textTheme.titleSmall),
                      const SizedBox(height: 10),
                    ],
                    if (page.items != null)
                      for (final item in page.items!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 7, right: 10),
                                child: _Bullet(),
                              ),
                              Expanded(
                                child: Text(item, style: textTheme.bodyLarge),
                              ),
                            ],
                          ),
                        ),
                    if (page.closing != null) ...[
                      const SizedBox(height: 6),
                      Text(page.closing!, style: textTheme.bodyLarge),
                    ],
                    if (isLast) ...[
                      const SizedBox(height: 20),
                      _DemoPlanStateControls(hasInformation: hasInformation),
                    ],
                  ],
                ),
              ),
            ),
            // Navegación inferior.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: ContigoColors.surface,
                border: Border(
                  top: BorderSide(color: ContigoColors.notifMeetingBg),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ContigoButton(
                      label: 'Anterior',
                      variant: ContigoButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: _pageIndex == 0
                          ? null
                          : () => _goToPage(_pageIndex - 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ContigoButton(
                      label: isLast
                          ? safetyPlanLinkLabel(hasInformation)
                          : 'Siguiente',
                      fullWidth: true,
                      onPressed: () => isLast
                          ? context.goNamed(AppRoute.safetyPlanEditor)
                          : _goToPage(_pageIndex + 1),
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
}

/// Barra de progreso del relato: un segmento por página, resaltando las leídas.
class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Avance del recurso. Pantalla ${current + 1} de $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current
                      ? ContigoColors.sage
                      : ContigoColors.notifMeetingBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: ContigoColors.sage,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Controles de demostración del estado del plan (portados del bloque
/// `<details>` del prototipo, visible solo en modo demo). Permiten simular un
/// plan vacío o con información ficticia; cada simulación reemplaza el plan de
/// prueba y solo dura en la sesión. Opera en la Capa_Simulada.
class _DemoPlanStateControls extends ConsumerWidget {
  const _DemoPlanStateControls({required this.hasInformation});

  final bool hasInformation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(safetyPlanControllerProvider.notifier);
    return ContigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Probar el estado del plan', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Datos ficticios para probar un plan vacío o con información. Cada '
            'simulación reemplaza el plan de prueba; los cambios solo duran en '
            'esta sesión.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 8),
          Text(
            hasInformation
                ? 'Plan con información, aunque esté incompleto'
                : 'Plan sin diligenciar',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          ContigoButton(
            label: 'Simular plan sin diligenciar',
            variant: ContigoButtonVariant.secondary,
            small: true,
            fullWidth: true,
            onPressed: () => controller.replaceWith(createSafetyPlanDraft()),
          ),
          const SizedBox(height: 8),
          ContigoButton(
            label: 'Simular plan con información',
            variant: ContigoButtonVariant.secondary,
            small: true,
            fullWidth: true,
            onPressed: () => controller.replaceWith(
              createSafetyPlanDraft(withExampleInformation: true),
            ),
          ),
        ],
      ),
    );
  }
}