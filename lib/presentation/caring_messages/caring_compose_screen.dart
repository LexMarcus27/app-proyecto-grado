import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../content/caring_messages_content.dart';
import '../../domain/caring_messages/caring_messages.dart';
import '../../domain/journey/caregiver.dart';
import '../safety_plan/widgets/story_video.dart';
import '../widgets/widgets.dart';
import 'caring_messages_controller.dart';

/// Vistas del recurso de mensajes de cuidado del cuidador.
enum _ComposeView { welcome, guide, origin, compose, review, sent }

/// Vista a la que vuelve «Cómo empezó todo» (`originReturnView`, F11).
enum _OriginReturn { welcome, compose, guide }

/// Pantalla del cuidador para redactar un **mensaje para tejer cercanía**
/// (tarea 3.18), portada de `CaringMessageScreen` (`src/screens/caring-message.tsx`).
///
/// Incluye la guía con su **video verbatim**, los ejemplos que se **añaden de
/// forma aditiva** al borrador, las preguntas con notas privadas (que **no** se
/// envían) y el **envío simulado** sobre `CaringMessageRepository`. Es la
/// contraparte para *componer* cercanía, distinta de la **bandeja de recibidos**
/// del PCS (Requirement 8.6, 8.11).
class CaringComposeScreen extends ConsumerStatefulWidget {
  const CaringComposeScreen({super.key});

  @override
  ConsumerState<CaringComposeScreen> createState() => _CaringComposeScreenState();
}

class _CaringComposeScreenState extends ConsumerState<CaringComposeScreen> {
  _ComposeView _view = _ComposeView.welcome;
  int _guidePage = 0;

  /// Guion del video desplegado (parte 1 de la guía).
  bool _showScript = false;

  /// `true` si la guía se abrió **desde el editor** (""Consultar ejemplos"" /
  /// ""Preguntas para inspirarme""): en ese caso el pie de la guía ofrece
  /// ""Volver a mi mensaje"" y regresar conserva el texto y las ideas añadidas.
  /// `false` si se abrió desde la bienvenida (navegación normal de la guía).
  bool _guideFromCompose = false;

  String _sentText = '';
  String? _notice;
  String? _sendError;

  /// Clave completa del vínculo que el editor refleja actualmente. Si el vínculo
  /// cambia (nueva asociación del mismo cuidador) mientras la pantalla está
  /// abierta, se reinicia el editor/vista previa para no arrastrar el contenido
  /// del vínculo anterior.
  String? _activeKey;

  /// Contexto y texto capturados al pulsar "Revisar mensaje". Un cambio de
  /// vínculo invalida la revisión y obliga a revisar de nuevo antes de enviar.
  String? _reviewedKey;
  String _reviewedText = '';

  /// Partes de la guía ya recorridas. "Cómo empezó todo" (los orígenes) solo se
  /// habilita tras recorrer las seis partes (portado del prototipo).
  final Set<int> _visitedGuidePages = <int>{};

  /// `true` si la guía ya se recorrió en esta sesión **para el vínculo
  /// vigente** (estado de sesión por vínculo, F10) o en esta visita.
  bool _guideReviewedFor(String? key) =>
      _visitedGuidePages.length >= _guideTitles.length ||
      (key != null && ref.read(caringGuidesReviewedProvider).contains(key));

  bool get _guideReviewed => _guideReviewedFor(_activeKey);

  /// Vista de retorno de «Cómo empezó todo» (F11).
  _OriginReturn _originReturn = _OriginReturn.welcome;

  void _openOrigin(_OriginReturn from) => setState(() {
        _originReturn = from;
        _view = _ComposeView.origin;
        _notice = null;
      });

  /// Registra la guía como revisada para el vínculo vigente cuando se han
  /// recorrido sus seis partes.
  void _syncGuideReviewed() {
    final key = _activeKey;
    if (key != null && _visitedGuidePages.length >= _guideTitles.length) {
      ref.read(caringGuidesReviewedProvider.notifier).markReviewed(key);
    }
  }

  static const List<String> _guideTitles = [
    'Un flotador en medio del mar',
    'Cómo acompañan estos mensajes',
    'Ideas para tu mensaje',
    'Antes de escribir',
    'Lo que quieres transmitir',
    'Preguntas para encontrar tu mensaje',
  ];

  // Nombre del PCS del contexto de cuidado (demo): "Sofía".
  static const String _pcsName = 'Sofía';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Borrador del vínculo vigente; `null` si el vínculo se revocó (se reevalúa
    // en vivo mientras la pantalla está abierta).
    final draft = ref.watch(currentCaringDraftProvider);
    final controller = ref.read(caringDraftControllerProvider.notifier);
    final linkActive = draft != null;

    // Clave completa del vínculo vigente (o `null` si no hay vínculo activo).
    final currentContext = ref.watch(currentCaringContextProvider);
    final currentKey =
        currentContext == null ? null : caringDraftKey(currentContext);
    ref.watch(caringGuidesReviewedProvider);

    // Si la clave del vínculo cambió mientras la pantalla estaba abierta,
    // reinicia el editor y la vista previa y descarta la revisión capturada.
    if (currentKey != _activeKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          // Otra asociación no hereda la lectura de esta visita.
          if (_activeKey != null) _visitedGuidePages.clear();
          _activeKey = currentKey;
          _reviewedKey = null;
          _reviewedText = '';
          _sendError = null;
          _notice = null;
          // Vuelve al inicio del recurso para no mostrar el borrador anterior.
          if (_view == _ComposeView.compose ||
              _view == _ComposeView.review ||
              _view == _ComposeView.sent) {
            _view = _ComposeView.welcome;
          }
        });
      });
    }

    final title = switch (_view) {
      _ComposeView.guide => _guideTitles[_guidePage],
      _ComposeView.origin => 'Cómo empezó todo',
      _ComposeView.compose => 'Escribe tu mensaje',
      _ComposeView.review => 'Revisa tu mensaje',
      _ComposeView.sent => 'Envío simulado',
      _ComposeView.welcome => 'Mensajes de cuidado',
    };

    final inGuide = _view == _ComposeView.guide && linkActive;

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabecera del recurso (propuesta M26).
                    Row(
                      children: [
                        ResourceCircleButton(
                          icon: Icons.arrow_back,
                          tooltip: 'Volver a Tejiendo vínculos',
                          onPressed: () =>
                              context.goBack(AppRoute.caregiverConnections),
                        ),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: ResourceChip(
                            label: 'Para $_pcsName',
                            palette: _palette,
                            leading: HomeAvatar(index: 0, size: 28),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'MENSAJES DE CUIDADO',
                      style: TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _palette.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (inGuide) ...[
                      ResourceProgress(
                        total: _guideTitles.length,
                        current: _guidePage,
                        palette: _palette,
                        semanticLabel:
                            'Avance de la guía. Parte ${_guidePage + 1} de '
                            '${_guideTitles.length}',
                      ),
                      const SizedBox(height: 24),
                    ],
                    ResourceStepHeading(
                      number: inGuide ? _guidePage + 1 : null,
                      title: title,
                      caption: inGuide
                          ? 'Parte ${_guidePage + 1} de ${_guideTitles.length}'
                          : null,
                      palette: _palette,
                    ),
                    const SizedBox(height: 22),
                    if (linkActive)
                      _buildView(context, textTheme, draft, controller)
                    else
                      _buildRevoked(textTheme),
                  ],
                ),
              ),
            ),
            _buildFooter(
              context,
              linkActive && draft.text.trim().isNotEmpty,
              linkActive: linkActive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildView(
    BuildContext context,
    TextTheme textTheme,
    draft,
    controller,
  ) {
    switch (_view) {
      case _ComposeView.welcome:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CompanionNote(child: Text(CaringContent.avatarLine)),
            const SizedBox(height: 12),
            Text(
              'Un mensaje sencillo puede ayudarte a cuidar tu relación con '
              '$_pcsName. Puedes conocer la guía o empezar a escribir.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ContigoButton(
              label: 'Conocer los mensajes de cuidado',
              fullWidth: true,
              onPressed: () => _openGuide(0),
            ),
            const SizedBox(height: 10),
            ContigoButton(
              label: draft.text.trim().isNotEmpty
                  ? 'Continuar mi borrador'
                  : 'Crear un mensaje',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => setState(() => _view = _ComposeView.compose),
            ),
            if (_guideReviewed) ...[
              const SizedBox(height: 10),
              ContigoButton(
                label: 'Cómo empezó todo',
                variant: ContigoButtonVariant.tertiary,
                fullWidth: true,
                onPressed: () => _openOrigin(_OriginReturn.welcome),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('Otras formas de conectar', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            // Otros recorridos de conexión dependientes de asociación (3.19).
            ContigoButton(
              label: 'Preguntas para conectar',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(Icons.people_outline),
              onPressed: () =>
                  context.pushNamed(AppRoute.caregiverConnectionQuestions),
            ),
            const SizedBox(height: 8),
            ContigoButton(
              label: 'Registrar encuentro',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(Icons.event_outlined),
              onPressed: () => context.pushNamed(AppRoute.caregiverEncounter),
            ),
            const SizedBox(height: 8),
            // Mensaje íntimo: distinto del mensaje de cuidado (tarea 3.19).
            ContigoButton(
              label: 'Escribir un mensaje íntimo',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(Icons.mail_outline),
              onPressed: () =>
                  context.pushNamed(AppRoute.caregiverIntimateMessage),
            ),
          ],
        );
      case _ComposeView.guide:
        return _buildGuide(textTheme, draft, controller);
      case _ComposeView.origin:
        return _buildOrigin(textTheme);
      case _ComposeView.compose:
        return _buildCompose(textTheme, draft, controller);
      case _ComposeView.review:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprueba el destinatario y el texto antes de confirmar.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ContigoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'De ${DemoCaregiver.name} para $_pcsName',
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _reviewedText.isNotEmpty ? _reviewedText : draft.text,
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta es una simulación. El mensaje aparecerá en la bandeja de '
              'prueba de PCS durante esta sesión; no se envía a una persona '
              'real.',
              style: (textTheme.bodySmall ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            ),
            if (_sendError != null) ...[
              const SizedBox(height: 10),
              Text(
                _sendError!,
                style: (textTheme.bodySmall ?? const TextStyle())
                    .copyWith(color: ContigoColors.clay),
              ),
            ],
          ],
        );
      case _ComposeView.sent:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CompanionNote(
              affection: true,
              child: Text(
                'Tu mensaje quedó disponible en la bandeja de prueba de '
                '$_pcsName.',
              ),
            ),
            const SizedBox(height: 12),
            ContigoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'De ${DemoCaregiver.name} para $_pcsName · Envío simulado',
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(_sentText, style: textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No se envió a una persona real. Se borrará al recargar.',
              style: (textTheme.bodySmall ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            ),
            const SizedBox(height: 16),
            ContigoButton(
              label: 'Escribir otro mensaje',
              fullWidth: true,
              onPressed: () => setState(() => _view = _ComposeView.compose),
            ),
          ],
        );
    }
  }

  Widget _buildGuide(TextTheme textTheme, draft, controller) {
    final children = <Widget>[];
    switch (_guidePage) {
      case 0:
        children.addAll([
          StoryVideo(
            asset: 'assets/media/caring-messages/metafora.mp4',
            title: 'Mensajes de cuidado: un flotador en medio del mar',
            accent: ContigoColors.brand,
            playAtCorner: true,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Guion del video, verbatim (portado del prototipo).
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ContigoColors.ink,
                    side: const BorderSide(color: Color(0xFFDDD3C8)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    textStyle: const TextStyle(
                      fontFamily: ContigoTheme.bodyFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => setState(() => _showScript = !_showScript),
                  icon: Icon(
                    _showScript ? Icons.expand_less : Icons.format_quote,
                    size: 18,
                    color: ContigoColors.inkMuted,
                  ),
                  label: Text(
                    _showScript ? 'Ocultar el guion' : 'Leer el guion del video',
                  ),
                ),
                if (_showScript) ...[
                  const SizedBox(height: 12),
                  for (final line in CaringContent.videoScript)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(line, style: resourceBody),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          ResourceCard(
            title: '¿Qué son?',
            icon: Icons.waves,
            children: [
              for (var i = 0; i < CaringContent.definition.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                  child: ResourceEmphasisText(
                    // Como React (`replace(/^¿Qué son\?\s*/, "")`): sin repetir
                    // el título.
                    text: CaringContent.definition[i]
                        .replaceFirst(RegExp(r'^¿Qué son\?\s*'), ''),
                    emphasis: 'Solo están ahí, flotando a tu lado.',
                    emphasisColor: _palette.accent,
                    italicSerif: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _NotCard(title: 'Qué no son', text: CaringContent.notAdvice),
        ]);
      case 1:
        for (var i = 0; i < CaringContent.characteristics.length; i++) {
          final c = CaringContent.characteristics[i];
          if (i > 0) children.add(const SizedBox(height: 16));
          children.add(_CharacteristicCard(characteristic: c));
        }
      case 2:
        children.add(Text(
          'Elige una idea si te ayuda. Se añadirá al final de tu borrador y '
          'podrás cambiarla para que sea tuya.',
          style: textTheme.bodyMedium,
        ));
        for (final group in CaringContent.examples) {
          children.add(_GuideSection(
            title: group.title,
            children: [
              for (final msg in group.messages)
                _ExampleRow(
                  text: msg,
                  onAdd: () {
                    controller.appendIdea(msg);
                    setState(() => _notice =
                        'Idea añadida al final del borrador. Puedes editarla al redactar.');
                  },
                ),
            ],
          ));
        }
      case 3:
        children.add(_GuideSection(
          title: 'Un momento para conectar',
          list: _GuideList.ordered,
          paragraphs: CaringContent.preparation,
        ));
      case 4:
        children.addAll([
          CompanionNote(affection: true, child: Text(CaringContent.avatarLine)),
          const SizedBox(height: 10),
          _GuideSection(
            title: 'Estos mensajes buscan',
            list: _GuideList.unordered,
            paragraphs: CaringContent.intentions,
          ),
          _GuideSection(
            title: 'Y muestran que',
            lilac: true,
            list: _GuideList.unordered,
            paragraphs: CaringContent.whatTheyShow,
          ),
        ]);
      case 5:
        children.add(Text(
          'Para encontrar tu mensaje, elige una o varias de estas preguntas. '
          'También puedes escribir directamente.',
          style: textTheme.bodyMedium,
        ));
        children.add(const SizedBox(height: 4));
        children.add(Text(
          'Tus notas son para ti; no se incluyen en el mensaje enviado.',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ));
        children.add(const SizedBox(height: 12));
        children.add(ResourceCard(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          children: [
            for (var i = 0; i < CaringContent.questions.length; i++)
              _QuestionRow(
                question: CaringContent.questions[i],
                selected: draft.selectedQuestions.contains(i),
                note: draft.notes[i] ?? '',
                onToggle: () => controller.toggleQuestion(i),
                onNote: (v) => controller.setNote(i, v),
              ),
          ],
        ));
        children.add(const SizedBox(height: 10));
        children.add(CompanionNote(expression: CompanionExpression.thoughtful, child: Text(CaringContent.honesty)));
        if (_guideReviewed) {
          children.add(const SizedBox(height: 10));
          children.add(_GuideSection(
            title: 'Ya conoces los mensajes de cuidado',
            lilac: true,
            paragraphs: const [
              'Si quieres, ahora puedes descubrir su historia antes de escribir.',
            ],
          ));
          children.add(ContigoButton(
            label: 'Cómo empezó todo',
            variant: ContigoButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => _openOrigin(_OriginReturn.guide),
          ));
        }
    }
    if (_notice != null) {
      children.add(const SizedBox(height: 10));
      children.add(Semantics(
        liveRegion: true,
        child: Text(
          _notice!,
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.sage),
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildCompose(TextTheme textTheme, draft, controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompanionNote(expression: CompanionExpression.thoughtful, child: Text(CaringContent.honesty)),
        const SizedBox(height: 10),
        Text(CaringContent.writingInvitation, style: textTheme.bodyLarge),
        const SizedBox(height: 10),
        Text('Tu mensaje para $_pcsName', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: draft.text,
          minLines: 4,
          maxLines: 10,
          onChanged: controller.setText,
          decoration: InputDecoration(
            filled: true,
            fillColor: ContigoColors.surface,
            hintText: 'Hola $_pcsName, estaba pensando en lo mucho que admiro…',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El borrador se conserva mientras usas la aplicación y se borra al '
          'recargar.',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 12),
        ContigoButton(
          label: 'Preguntas para inspirarme',
          variant: ContigoButtonVariant.secondary,
          small: true,
          fullWidth: true,
          onPressed: () => setState(() {
            _guidePage = 5;
            _guideFromCompose = true;
            _view = _ComposeView.guide;
          }),
        ),
        const SizedBox(height: 8),
        ContigoButton(
          label: 'Consultar ejemplos',
          variant: ContigoButtonVariant.secondary,
          small: true,
          fullWidth: true,
          onPressed: () => setState(() {
            _guidePage = 2;
            _guideFromCompose = true;
            _view = _ComposeView.guide;
          }),
        ),
      ],
    );
  }

  /// Abre la guía en la parte [page], marcándola como visitada.
  void _openGuide(int page) {
    setState(() {
      _guidePage = page;
      _visitedGuidePages.add(page);
      _guideFromCompose = false;
      _view = _ComposeView.guide;
      _notice = null;
    });
    _syncGuideReviewed();
  }

  /// "Cómo empezó todo": los orígenes del prototipo con sus ilustraciones y
  /// párrafos verbatim. Disponible solo tras recorrer las seis partes de la
  /// guía. Las imágenes se toman del bundle (carpeta `caring-messages/`).
  /// "Cómo empezó todo": los orígenes del prototipo con sus ilustraciones y
  /// párrafos verbatim, como línea de tiempo (propuesta M26). Disponible solo
  /// tras recorrer las seis partes de la guía. Las imágenes se toman del bundle
  /// (carpeta `caring-messages/`).
  Widget _buildOrigin(TextTheme textTheme) {
    const origins = CaringContent.origins;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < origins.length; i++)
          _TimelineEntry(
            origin: origins[i],
            date: _originDates[i],
            last: i == origins.length - 1,
          ),
      ],
    );
  }

  Widget _buildRevoked(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('El vínculo ya no está activo', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        Text(
          'La asociación con $_pcsName dejó de estar activa. Por seguridad, el '
          'borrador de este vínculo se ocultó y no es posible enviar un mensaje '
          'mientras no haya una asociación activa.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
  Widget _buildFooter(
    BuildContext context,
    bool hasText, {
    required bool linkActive,
  }) {
    // Con el vínculo revocado, solo se permite salir del recurso.
    if (!linkActive) {
      return _footerBar([
        Expanded(
          child: ContigoButton(
            label: 'Salir del recurso',
            variant: ContigoButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.goBack(AppRoute.caregiverConnections),
          ),
        ),
      ]);
    }
    switch (_view) {
      case _ComposeView.welcome:
      case _ComposeView.sent:
        return _footerBar([
          Expanded(
            child: ContigoButton(
              label: 'Salir del recurso',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => context.goBack(AppRoute.caregiverConnections),
            ),
          ),
        ]);
      case _ComposeView.guide:
        final lastPage = _guidePage == _guideTitles.length - 1;
        return ResourceBottomBar(
          palette: _palette,
          nextLabel: lastPage ? 'Redactar mi mensaje' : 'Siguiente',
          showNextChevron: !lastPage,
          onBack: () => setState(() {
            if (_guidePage == 0) {
              _view = _ComposeView.welcome;
            } else {
              _guidePage -= 1;
            }
            _notice = null;
          }),
          onNext: () => setState(() {
            if (lastPage) {
              _view = _ComposeView.compose;
              _guideFromCompose = false;
            } else {
              _guidePage += 1;
              _visitedGuidePages.add(_guidePage);
            }
            _notice = null;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _syncGuideReviewed());
          }),
          // Si la guía se abrió desde el editor («Consultar ejemplos» /
          // «Preguntas para inspirarme»), se ofrece un regreso directo a la
          // redacción que conserva el texto y las ideas añadidas.
          below: _guideFromCompose
              ? TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: ContigoColors.brand,
                    textStyle: const TextStyle(
                      fontFamily: ContigoTheme.bodyFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => setState(() {
                    _view = _ComposeView.compose;
                    _guideFromCompose = false;
                    _notice = null;
                  }),
                  child: const Text('Volver a mi mensaje'),
                )
              : null,
        );
      case _ComposeView.origin:
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F3),
            border: Border(top: BorderSide(color: Color(0xFFEDE5DC))),
          ),
          child: ResourcePillButton(
            label: switch (_originReturn) {
              _OriginReturn.compose => 'Volver a mi mensaje',
              _OriginReturn.guide => 'Volver a la guía',
              _OriginReturn.welcome => 'Volver al recurso',
            },
            color: ContigoColors.brand,
            outlined: true,
            // Vuelve al punto de origen conservando el borrador (F11).
            onPressed: () => setState(() {
              _view = switch (_originReturn) {
                _OriginReturn.compose => _ComposeView.compose,
                _OriginReturn.guide => _ComposeView.guide,
                _OriginReturn.welcome => _ComposeView.welcome,
              };
            }),
          ),
        );
      case _ComposeView.compose:
        final composeBar = _footerBar([
          Expanded(
            child: ContigoButton(
              label: 'Guardar borrador',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () =>
                  setState(() => _notice = 'Borrador conservado durante esta sesión.'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ContigoButton(
              label: 'Revisar mensaje',
              fullWidth: true,
              onPressed: hasText ? _startReview : null,
            ),
          ),
        ]);
        // Acceso a los orígenes desde el editor solo con la guía revisada.
        if (!_guideReviewed) return composeBar;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: ContigoColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: ContigoButton(
                label: 'Cómo empezó todo',
                variant: ContigoButtonVariant.tertiary,
                small: true,
                fullWidth: true,
                onPressed: () => _openOrigin(_OriginReturn.compose),
              ),
            ),
            composeBar,
          ],
        );
      case _ComposeView.review:
        return _footerBar([
          Expanded(
            child: ContigoButton(
              label: 'Editar',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => setState(() => _view = _ComposeView.compose),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ContigoButton(
              label: 'Simular envío',
              fullWidth: true,
              onPressed: hasText ? _send : null,
            ),
          ),
        ]);
    }
  }

  Widget _footerBar(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F3),
        border: Border(top: BorderSide(color: Color(0xFFEDE5DC))),
      ),
      child: Row(children: children),
    );
  }

  /// Captura el contexto y el texto al pulsar "Revisar mensaje" y pasa a la
  /// vista de revisión. Un cambio de vínculo posterior invalidará esta captura
  /// (el `build` la descarta), obligando a revisar de nuevo antes de enviar.
  void _startReview() {
    final context = ref.read(currentCaringContextProvider);
    final draft = ref.read(currentCaringDraftProvider);
    if (context == null || draft == null || draft.text.trim().isEmpty) return;
    setState(() {
      _reviewedKey = caringDraftKey(context);
      _reviewedText = draft.text.trim();
      _view = _ComposeView.review;
      _sendError = null;
    });
  }

  Future<void> _send() async {
    // El envío exige una revisión vigente: debe existir una captura y el vínculo
    // actual debe coincidir con el que se revisó (misma clave completa).
    final context = ref.read(currentCaringContextProvider);
    if (context == null || _reviewedKey == null) {
      setState(() {
        _sendError = 'Vuelve a revisar el mensaje antes de enviarlo.';
        _view = _ComposeView.compose;
      });
      return;
    }
    final currentKey = caringDraftKey(context);
    if (currentKey != _reviewedKey) {
      // El vínculo cambió entre la revisión y el envío: invalida la revisión.
      setState(() {
        _reviewedKey = null;
        _reviewedText = '';
        _sendError = 'El vínculo cambió. Vuelve a revisar el mensaje antes de enviarlo.';
        _view = _ComposeView.compose;
      });
      return;
    }
    final text = _reviewedText.trim();
    if (text.isEmpty) return;
    final ok = await ref.read(caringSendControllerProvider).simulateSend(
          DemoCaregiver.id,
          text,
          expectedAssociationId: context.associationId,
        );
    if (!mounted) return;
    if (!ok) {
      setState(() => _sendError =
          'No se pudo simular el envío. Comprueba que tu vínculo siga activo.');
      return;
    }
    setState(() {
      _sentText = text;
      _view = _ComposeView.sent;
      _sendError = null;
      _reviewedKey = null;
      _reviewedText = '';
    });
  }
}

/// Paleta del recurso de mensajes de cuidado (propuesta M26).
const ResourcePalette _palette = ResourcePalette.caring;

/// Lila de las tarjetas «Qué no son» / «Y muestran que».
const Color _lilac = Color(0xFFEEE6F2);
const Color _lilacText = Color(0xFF5D49A5);

/// Fechas de la línea de tiempo de los orígenes, en el orden de
/// [CaringContent.origins] (`null` si la entrada no lleva fecha).
const List<String?> _originDates = [
  'Diciembre de 1944',
  null,
  'Finales de los años 60 · 2001',
];

/// Íconos de las secciones de la guía, por título.
const Map<String, IconData> _sectionIcons = {
  'Mostrar cuidado': Icons.favorite_border,
  'Reconocer lo difícil': Icons.volunteer_activism_outlined,
  'Celebrar los avances': Icons.celebration_outlined,
  'Dar ánimo': Icons.wb_sunny_outlined,
  'Recordar la relación': Icons.photo_album_outlined,
  'Un momento para conectar': Icons.self_improvement,
  'Estos mensajes buscan': Icons.flag_outlined,
  'Y muestran que': Icons.visibility_outlined,
  'Ya conoces los mensajes de cuidado': Icons.auto_stories_outlined,
};

/// Tipo de lista de una sección de la guía.
enum _GuideList { none, ordered, unordered }

/// Sección de la guía como tarjeta (propuesta M26): ícono en círculo, título
/// serif y párrafos o lista. La variante [lilac] reproduce el fondo lila
/// (`.caring-section--sage` del prototipo, `#EEE6F2`).
class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.title,
    this.paragraphs = const [],
    this.lilac = false,
    this.list = _GuideList.none,
    this.children = const [],
  });

  final String title;
  final List<String> paragraphs;
  final bool lilac;
  final _GuideList list;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < paragraphs.length; i++) {
      final text = paragraphs[i];
      if (list == _GuideList.none) {
        items.add(Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
          child: Text(text, style: resourceBody),
        ));
      } else {
        items.add(Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (list == _GuideList.ordered)
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lilac ? Colors.white : _palette.soft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: lilac ? _lilacText : _palette.accent,
                    ),
                  ),
                )
              else
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 9, right: 12, left: 4),
                  decoration: BoxDecoration(
                    color: lilac ? _lilacText : _palette.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(child: Text(text, style: resourceBody)),
            ],
          ),
        ));
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ResourceCard(
        title: title,
        icon: _sectionIcons[title],
        iconColor: lilac ? _lilacText : _palette.accent,
        iconBackground: lilac ? Colors.white : _palette.soft,
        titleColor: lilac ? _lilacText : null,
        background: lilac ? _lilac : Colors.white,
        bordered: !lilac,
        children: [...items, ...children],
      ),
    );
  }
}

/// «Qué no son»: tarjeta lila con ✕ en círculo blanco.
class _NotCard extends StatelessWidget {
  const _NotCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 20, 20),
      decoration: BoxDecoration(
        color: _lilac,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 20, color: _lilacText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: resourceSerif.copyWith(
                    fontSize: 21,
                    height: 26 / 21,
                    color: _lilacText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: resourceBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Íconos de las características, en el orden de
/// [CaringContent.characteristics].
const Map<String, IconData> _characteristicIcons = {
  'No piden algo a cambio': Icons.favorite_border,
  'Pertenencia': Icons.people_outline,
  'Son cortos': Icons.schedule,
  'Son constantes': Icons.waves,
};

/// Tarjeta de una característica de los mensajes (parte 2 de la guía).
///
/// - «No piden algo a cambio»: las frases de lo que no hacen van con ✕ y la
///   última como conclusión.
/// - «Son constantes»: fondo salvia, mensajes apilados y la frase final en
///   serif cursiva.
class _CharacteristicCard extends StatelessWidget {
  const _CharacteristicCard({required this.characteristic});

  final CaringCharacteristic characteristic;

  @override
  Widget build(BuildContext context) {
    final c = characteristic;
    final p = c.paragraphs;
    final constant = c.title == 'Son constantes';
    final List<Widget> body;
    if (c.title == 'No piden algo a cambio' && p.length > 1) {
      body = [
        for (final line in p.sublist(0, p.length - 1))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3, right: 12),
                  child: Icon(Icons.close, size: 18, color: ContigoColors.critical),
                ),
                Expanded(child: Text(line, style: resourceBody)),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(p.last, style: resourceBody),
      ];
    } else if (constant && p.length > 1) {
      body = [
        Text(p.first, style: resourceBody),
        const SizedBox(height: 16),
        const _MessageStack(),
        const SizedBox(height: 16),
        Text(
          p.last,
          style: resourceSerif.copyWith(
            fontSize: 21,
            height: 28 / 21,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: _palette.accent,
          ),
        ),
      ];
    } else {
      body = [
        for (var i = 0; i < p.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: Text(p[i], style: resourceBody),
          ),
      ];
    }
    return ResourceCard(
      title: c.title,
      icon: _characteristicIcons[c.title],
      iconColor: _palette.accent,
      iconBackground: constant ? Colors.white : _palette.soft,
      background: constant ? _palette.soft : Colors.white,
      bordered: !constant,
      children: body,
    );
  }
}

/// Tres pastillas «Un mensaje» escalonadas que se desvanecen (decorativas).
class _MessageStack extends StatelessWidget {
  const _MessageStack();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(left: 30.0 * i, bottom: 8),
              child: Opacity(
                opacity: 1 - i * 0.22,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 14, color: ContigoColors.brand),
                      SizedBox(width: 8),
                      Text(
                        'Un mensaje',
                        style: TextStyle(fontSize: 14, color: ContigoColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Entrada de la línea de tiempo de «Cómo empezó todo»: nodo con anillo y
/// línea vertical, fecha opcional, título serif, ilustración y párrafos.
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.origin,
    required this.date,
    required this.last,
  });

  final CaringOrigin origin;
  final String? date;
  final bool last;

  /// Cita de la carta del estudio de Motto, resaltada en serif cursiva.
  static const String _quote =
      '"Han pasado unos meses desde que estuviste en el hospital y esperamos '
      'que estés bien. Si quieres escribirnos, nos daría gusto saber de ti"';

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _palette.accent, width: 2.4),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _palette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: last ? Colors.transparent : _palette.dotted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _palette.soft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        date!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _palette.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    origin.title,
                    style: resourceSerif.copyWith(fontSize: 24, height: 30 / 24),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8DFD5)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/media/caring-messages/${origin.image}',
                      semanticLabel: origin.alt,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < origin.paragraphs.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                      child: ResourceEmphasisText(
                        text: origin.paragraphs[i],
                        emphasis: _quote,
                        emphasisColor: _palette.accent,
                        italicSerif: true,
                      ),
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

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({required this.text, required this.onAdd});
  final String text;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    // Idea en su propio recuadro, con el botón debajo (propuesta M26).
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: resourceBody),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: ContigoColors.brand,
                textStyle: const TextStyle(
                  fontFamily: ContigoTheme.bodyFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir idea al borrador'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.question,
    required this.selected,
    required this.note,
    required this.onToggle,
    required this.onNote,
  });

  final String question;
  final bool selected;
  final String note;
  final VoidCallback onToggle;
  final ValueChanged<String> onNote;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: ContigoColors.terracotta,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(question, style: textTheme.bodyMedium)),
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(height: 6),
            TextFormField(
              initialValue: note,
              minLines: 1,
              maxLines: 4,
              onChanged: onNote,
              decoration: const InputDecoration(
                filled: true,
                fillColor: ContigoColors.surface,
                hintText: 'Escribe una idea si te ayuda…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}