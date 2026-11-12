import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  bool get _guideReviewed => _visitedGuidePages.length >= _guideTitles.length;

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

    // Si la clave del vínculo cambió mientras la pantalla estaba abierta,
    // reinicia el editor y la vista previa y descarta la revisión capturada.
    if (currentKey != _activeKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
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

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.goNamed(AppRoute.caregiverHome),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Volver a Tejiendo vínculos',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Para $_pcsName',
                          style: (textTheme.labelMedium ?? const TextStyle())
                              .copyWith(color: ContigoColors.inkMuted),
                        ),
                        Text(title, style: textTheme.titleLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: linkActive
                    ? _buildView(context, textTheme, draft, controller)
                    : _buildRevoked(textTheme),
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
                onPressed: () => setState(() => _view = _ComposeView.origin),
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
                  context.goNamed(AppRoute.caregiverConnectionQuestions),
            ),
            const SizedBox(height: 8),
            ContigoButton(
              label: 'Registrar encuentro',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(Icons.event_outlined),
              onPressed: () => context.goNamed(AppRoute.caregiverEncounter),
            ),
            const SizedBox(height: 8),
            // Mensaje íntimo: distinto del mensaje de cuidado (tarea 3.19).
            ContigoButton(
              label: 'Escribir un mensaje íntimo',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(Icons.mail_outline),
              onPressed: () =>
                  context.goNamed(AppRoute.caregiverIntimateMessage),
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
    final children = <Widget>[
      _GuideProgress(page: _guidePage, total: _guideTitles.length),
      const SizedBox(height: 12),
    ];
    switch (_guidePage) {
      case 0:
        children.addAll([
          StoryVideo(
            asset: 'assets/media/caring-messages/metafora.mp4',
            title: 'Mensajes de cuidado: un flotador en medio del mar',
          ),
          const SizedBox(height: 8),
          // Guion del video, verbatim (portado del prototipo).
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Leer el guion del video', style: textTheme.titleSmall),
              children: [
                for (final line in CaringContent.videoScript)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(line, style: textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _GuideSection(title: '¿Qué son?', paragraphs: CaringContent.definition),
          _GuideSection(
            title: 'Qué no son',
            paragraphs: [CaringContent.notAdvice],
          ),
        ]);
      case 1:
        for (final c in CaringContent.characteristics) {
          children.add(_GuideSection(title: c.title, paragraphs: c.paragraphs));
        }
      case 2:
        children.add(Text(
          'Elige una idea si te ayuda. Se añadirá al final de tu borrador y '
          'podrás cambiarla para que sea tuya.',
          style: textTheme.bodyMedium,
        ));
        for (final group in CaringContent.examples) {
          children.add(const SizedBox(height: 12));
          children.add(Text(group.title, style: textTheme.titleSmall));
          for (final msg in group.messages) {
            children.add(_ExampleRow(
              text: msg,
              onAdd: () {
                controller.appendIdea(msg);
                setState(() => _notice =
                    'Idea añadida al final del borrador. Puedes editarla al redactar.');
              },
            ));
          }
        }
      case 3:
        children.add(_GuideSection(
          title: 'Un momento para conectar',
          paragraphs: CaringContent.preparation,
        ));
      case 4:
        children.addAll([
          CompanionNote(affection: true, child: Text(CaringContent.avatarLine)),
          const SizedBox(height: 10),
          _GuideSection(
            title: 'Estos mensajes buscan',
            paragraphs: CaringContent.intentions,
          ),
          _GuideSection(
            title: 'Y muestran que',
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
        for (var i = 0; i < CaringContent.questions.length; i++) {
          children.add(_QuestionRow(
            question: CaringContent.questions[i],
            selected: draft.selectedQuestions.contains(i),
            note: draft.notes[i] ?? '',
            onToggle: () => controller.toggleQuestion(i),
            onNote: (v) => controller.setNote(i, v),
          ));
        }
        children.add(const SizedBox(height: 10));
        children.add(CompanionNote(expression: CompanionExpression.thoughtful, child: Text(CaringContent.honesty)));
        if (_guideReviewed) {
          children.add(const SizedBox(height: 10));
          children.add(_GuideSection(
            title: 'Ya conoces los mensajes de cuidado',
            paragraphs: const [
              'Si quieres, ahora puedes descubrir su historia antes de escribir.',
            ],
          ));
          children.add(ContigoButton(
            label: 'Cómo empezó todo',
            variant: ContigoButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => setState(() => _view = _ComposeView.origin),
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
  }

  /// "Cómo empezó todo": los orígenes del prototipo con sus ilustraciones y
  /// párrafos verbatim. Disponible solo tras recorrer las seis partes de la
  /// guía. Las imágenes se toman del bundle (carpeta `caring-messages/`).
  Widget _buildOrigin(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final origin in CaringContent.origins) ...[
          Text(origin.title, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/media/caring-messages/${origin.image}',
              semanticLabel: origin.alt,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 8),
          for (final p in origin.paragraphs) ...[
            Text(p, style: textTheme.bodyMedium),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 12),
        ],
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
            onPressed: () => context.goNamed(AppRoute.caregiverHome),
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
              onPressed: () => context.goNamed(AppRoute.caregiverHome),
            ),
          ),
        ]);
      case _ComposeView.guide:
        final navRow = Row(
          children: [
            Expanded(
              child: ContigoButton(
                label: 'Anterior',
                variant: ContigoButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => setState(() {
                  if (_guidePage == 0) {
                    _view = _ComposeView.welcome;
                  } else {
                    _guidePage -= 1;
                  }
                  _notice = null;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ContigoButton(
                label: _guidePage == _guideTitles.length - 1
                    ? 'Redactar mi mensaje'
                    : 'Siguiente',
                fullWidth: true,
                onPressed: () => setState(() {
                  if (_guidePage == _guideTitles.length - 1) {
                    _view = _ComposeView.compose;
                    _guideFromCompose = false;
                  } else {
                    _guidePage += 1;
                    _visitedGuidePages.add(_guidePage);
                  }
                  _notice = null;
                }),
              ),
            ),
          ],
        );
        // Si la guía se abrió desde el editor (""Consultar ejemplos"" /
        // ""Preguntas para inspirarme""), ofrecer un regreso directo a la
        // redacción que conserva el texto y las ideas añadidas. La navegación
        // normal (Anterior/Siguiente) se mantiene. Desde la bienvenida no se
        // ofrece este atajo.
        if (!_guideFromCompose) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: ContigoColors.surface,
              border:
                  Border(top: BorderSide(color: ContigoColors.notifMeetingBg)),
            ),
            child: navRow,
          );
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: ContigoColors.surface,
            border: Border(top: BorderSide(color: ContigoColors.notifMeetingBg)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              navRow,
              const SizedBox(height: 10),
              ContigoButton(
                label: 'Volver a mi mensaje',
                variant: ContigoButtonVariant.tertiary,
                fullWidth: true,
                onPressed: () => setState(() {
                  _view = _ComposeView.compose;
                  _guideFromCompose = false;
                  _notice = null;
                }),
              ),
            ],
          ),
        );
      case _ComposeView.origin:
        return _footerBar([
          Expanded(
            child: ContigoButton(
              label: 'Volver al recurso',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => setState(() => _view = _ComposeView.welcome),
            ),
          ),
        ]);
      case _ComposeView.compose:
        return _footerBar([
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: ContigoColors.surface,
        border: Border(top: BorderSide(color: ContigoColors.notifMeetingBg)),
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

class _GuideProgress extends StatelessWidget {
  const _GuideProgress({required this.page, required this.total});
  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= page
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
        const SizedBox(height: 6),
        Text(
          'Parte ${page + 1} de $total',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
      ],
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.paragraphs});
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final p in paragraphs) ...[
            Text(p, style: textTheme.bodyMedium),
            const SizedBox(height: 6),
          ],
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
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
          const SizedBox(width: 8),
          ContigoButton(
            label: 'Añadir idea al borrador',
            variant: ContigoButtonVariant.secondary,
            small: true,
            onPressed: onAdd,
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