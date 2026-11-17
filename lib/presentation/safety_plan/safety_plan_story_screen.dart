import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
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
/// Sigue la propuesta visual de M25: etiqueta «Plan para desenredar», progreso
/// punteado de siete nodos, número grande y título serif, tarjetas de video,
/// párrafos destacados en serif, curva de la crisis, avisos y listas con ícono,
/// y barra inferior con volver y «Siguiente».
///
/// El texto de cada página se conserva **verbatim** y en orden (Requirement
/// 7.6): la composición solo lo distribuye en bloques (p. ej. la primera
/// oración como párrafo destacado o un fragmento en negrita), sin alterarlo.
/// En la última página el botón principal lleva al editor del plan con la
/// etiqueta según si ya hay información ([safetyPlanLinkLabel]).
class SafetyPlanStoryScreen extends ConsumerStatefulWidget {
  const SafetyPlanStoryScreen({super.key});

  @override
  ConsumerState<SafetyPlanStoryScreen> createState() =>
      _SafetyPlanStoryScreenState();
}

const ResourcePalette _palette = ResourcePalette.plan;

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
    final page = safetyPlanStory[_pageIndex];
    final total = safetyPlanStory.length;
    final isLast = _pageIndex == total - 1;
    final planAsync = ref.watch(safetyPlanControllerProvider);
    final hasInformation =
        safetyPlanHasInformation(planAsync.value ?? createSafetyPlanDraft());

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ResourceChip(
                              label: 'Plan para desenredar',
                              icon: Icons.eco_outlined,
                              palette: _palette,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ResourceCircleButton(
                          icon: Icons.close,
                          tooltip: 'Salir del recurso',
                          onPressed: () => context.goBack(AppRoute.helpHub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      safetyPlanStoryTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _palette.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResourceProgress(
                      total: total,
                      current: _pageIndex,
                      palette: _palette,
                      semanticLabel:
                          'Avance del recurso. Pantalla ${_pageIndex + 1} de $total',
                    ),
                    const SizedBox(height: 24),
                    ResourceStepHeading(
                      number: page.id,
                      title: page.title,
                      caption: 'Pantalla ${_pageIndex + 1} de $total',
                      palette: _palette,
                    ),
                    const SizedBox(height: 22),
                    ..._pageBody(page),
                    if (isLast) ...[
                      const SizedBox(height: 20),
                      _DemoPlanStateControls(hasInformation: hasInformation),
                    ],
                  ],
                ),
              ),
            ),
            ResourceBottomBar(
              palette: _palette,
              nextLabel: isLast ? safetyPlanLinkLabel(hasInformation) : 'Siguiente',
              showNextChevron: !isLast,
              onBack: _pageIndex == 0 ? null : () => _goToPage(_pageIndex - 1),
              onNext: () => isLast
                  ? context.pushNamed(AppRoute.safetyPlanEditor)
                  : _goToPage(_pageIndex + 1),
            ),
          ],
        ),
      ),
    );
  }

  /// Bloques de cada página. Todo el texto proviene de [safetyPlanStory] sin
  /// cambios; aquí solo se decide cómo se presenta.
  List<Widget> _pageBody(SafetyPlanStoryPage page) {
    const gap = SizedBox(height: 20);
    final p = page.paragraphs;
    final blocks = <Widget>[];

    if (page.video != null) {
      blocks.add(StoryVideo(asset: page.video!, title: page.title));
    }

    switch (page.id) {
      case 2:
        final (lead, rest) = _splitFirstSentence(p[0]);
        blocks.addAll([
          ResourceLead(lead),
          gap,
          const _CrisisCurveCard(),
          gap,
          Text(rest, style: _body),
          gap,
          ResourceCallout(
            icon: Icons.vpn_key_outlined,
            text: p[1],
            emphasis: 'No es que no las tengas: es que, con el malestar al '
                'máximo, cuesta más acceder a ellas.',
            palette: _palette,
          ),
        ]);
      case 3:
        final (lead, rest) = _splitFirstSentence(p[0]);
        blocks.addAll([
          ResourceLead(lead),
          gap,
          Text(rest, style: _body),
          gap,
          const _CrisisCurveCard(calming: true),
          gap,
          ResourceCallout(
            icon: Icons.spa_outlined,
            text: p[1],
            emphasis: 'podemos aprender a afrontarlo de otra manera',
            palette: _palette,
          ),
        ]);
      case 5:
        blocks.addAll([
          Text(p[0], style: _body),
          gap,
          ResourceLead(p[1]),
          gap,
          ResourceIconList(
            palette: _palette,
            items: [
              for (var i = 0; i < page.items!.length; i++)
                (_planIcons[i % _planIcons.length], page.items![i]),
            ],
          ),
        ]);
      case 6:
        blocks.addAll([
          ResourceLead(p[0]),
          gap,
          Text(
            page.listHeading!,
            style: resourceSerif.copyWith(fontSize: 21, height: 27 / 21),
          ),
          const SizedBox(height: 14),
          ResourceIconList(
            palette: _palette,
            items: [
              for (final item in page.items!) (Icons.check_circle_outline, item),
            ],
          ),
          gap,
          ResourceCallout(
            icon: Icons.eco_outlined,
            text: page.closing!,
            emphasis: 'Siempre lo tendremos a la mano.',
            palette: _palette,
          ),
        ]);
      case 7:
        blocks.addAll([
          ResourceLead(p[0]),
          gap,
          ResourceCallout(
            icon: Icons.eco_outlined,
            text: p[1],
            emphasis: 'puedes volver a él, cambiarlo y seguir tejiéndolo.',
            palette: _palette,
          ),
        ]);
      default:
        // Páginas sin composición propia: párrafos, lista y cierre en orden.
        for (final paragraph in p) {
          if (blocks.isNotEmpty) blocks.add(gap);
          blocks.add(Text(paragraph, style: _body));
        }
        if (page.listHeading != null) {
          blocks.addAll([gap, ResourceLead(page.listHeading!)]);
        }
        if (page.items != null) {
          blocks.addAll([
            gap,
            ResourceIconList(
              palette: _palette,
              items: [for (final i in page.items!) (Icons.check_circle_outline, i)],
            ),
          ]);
        }
        if (page.closing != null) {
          blocks.addAll([gap, Text(page.closing!, style: _body)]);
        }
    }
    return blocks;
  }
}

const TextStyle _body = TextStyle(
  fontSize: 17,
  height: 27 / 17,
  color: ContigoColors.ink,
);

/// Íconos de lo que se aprende con el plan (página 5), en el orden de los
/// elementos: señal, estrategias, apoyos, entorno, contactos y razones.
const List<IconData> _planIcons = [
  Icons.notifications_none,
  Icons.flare,
  Icons.people_outline,
  Icons.shield_outlined,
  Icons.phone_outlined,
  Icons.favorite_border,
];

/// Separa la primera oración (hasta el primer «. ») del resto del párrafo.
(String, String) _splitFirstSentence(String text) {
  final i = text.indexOf('. ');
  if (i < 0) return (text, '');
  return (text.substring(0, i + 1), text.substring(i + 2));
}

/// Tarjeta con la curva de la crisis: sube, llega a su punto más alto y baja.
/// Con [calming], muestra además una curva más baja (el malestar se afronta
/// de otra manera y la curva baja).
class _CrisisCurveCard extends StatelessWidget {
  const _CrisisCurveCard({this.calming = false});

  final bool calming;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 200,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8DFD5)),
        ),
        child: CustomPaint(painter: _CurvePainter(calming: calming)),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.calming});

  final bool calming;

  Path _bell(Size size, double peakHeight) {
    final w = size.width;
    final base = size.height - 6;
    final top = base - peakHeight;
    return Path()
      ..moveTo(0, base)
      ..cubicTo(w * 0.25, base - 4, w * 0.36, top + peakHeight * 0.55, w * 0.44, top + 10)
      ..quadraticBezierTo(w * 0.5, top - 6, w * 0.56, top + 10)
      ..cubicTo(w * 0.64, top + peakHeight * 0.55, w * 0.75, base - 4, w, base);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final accent = _palette.accent;
    final base = size.height - 6;
    canvas.drawLine(
      Offset(0, base + 2),
      Offset(size.width, base + 2),
      Paint()
        ..color = const Color(0xFFF0E8E0)
        ..strokeWidth = 2,
    );

    final high = _bell(size, size.height - 22);
    if (calming) {
      canvas.drawPath(
        high,
        Paint()
          ..color = _palette.dotted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final low = _bell(size, (size.height - 22) * 0.5);
      canvas.drawPath(
        low,
        Paint()
          ..color = _palette.soft
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        low,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    canvas.drawPath(
      high,
      Paint()
        ..color = _palette.soft
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      high,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final peak = Offset(size.width * 0.5, 6);
    final dash = Paint()
      ..color = accent
      ..strokeWidth = 1.6;
    for (var y = peak.dy + 14; y < base; y += 7) {
      canvas.drawLine(Offset(peak.dx, y), Offset(peak.dx, y + 3.5), dash);
    }
    canvas.drawCircle(peak, 10, Paint()..color = Colors.white);
    canvas.drawCircle(
      peak,
      10,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(peak, 3.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) => old.calming != calming;
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
    return DemoToolsPanel(
      title: 'Probar el estado del plan',
      children: [
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
    );
  }
}
