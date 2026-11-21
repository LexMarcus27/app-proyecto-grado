import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/connection/connection.dart';
import '../../domain/journey/journey.dart';
import '../authorization/gating.dart';
import '../widgets/widgets.dart';
import 'connection_selection.dart';
import 'pcs_connection_questions_controller.dart' show pcsLinkKey;


// Tokens del prototipo (`C` de `ui.tsx`).
// Propuesta A: acento terracota (`.pcs-primary`) y fondos melocotón.
const Color _brand = ContigoColors.terracotta;
const Color _brandSoft = Color(0xFFF9E4D7);
const Color _chipBorder = Color(0xFFDDB9A3);
const Color _cardBorder = Color(0xFFECE3DA);
const Color _border = Color(0xFFDFD4C9);
const Color _soft = Color(0xFFF1E9DF);
const Color _warmSoft = Color(0xFFF8ECD4);
const Color _warmText = Color(0xFF805C1D);
const Color _ochre = Color(0xFFD3A24C);
const Color _success = Color(0xFF536B50);
const Color _successSoft = Color(0xFFE5EDE2);

/// Tiempo del borrador simulado (el prototipo usa un temporizador local de
/// 1,8 s; no hay modelo de IA real, A12).
const Duration simulatedDraftDelay = Duration(milliseconds: 1800);

/// Conexión con una persona (M8), portada de `MobileScreen08`
/// (`src/screens/mobile.tsx`).
///
/// Ofrece recibidos, llamada/audio simulados, preguntas para conectar, un
/// borrador **simulado** de mensaje para tejer cercanía (generar, editar,
/// regenerar, copiar y marcar como preparado), actividades propias y la
/// preparación/revisión de una invitación a un encuentro. Nada se envía ni se
/// abre fuera de la app (A02). Todo el estado vive en la pantalla (sesión): al
/// salir se descarta, de modo que otra asociación no hereda borradores.
///
/// Sin autorización vigente para la persona (revocación, invitación sin
/// asociación) muestra la selección de personas vinculadas activas.
class ConnectionPersonScreen extends ConsumerWidget {
  const ConnectionPersonScreen({super.key, this.personId, this.initialAction});

  final String? personId;
  final ConnectionAction? initialAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(gatingJourneyProvider);
    return journeyAsync.when(
      loading: () => const Scaffold(
        backgroundColor: ContigoColors.canvas,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('No se pudo cargar: $e'))),
      data: (journey) {
        final gating = CareGating(journey);
        final id = personId ?? journey.selectedPersonId;
        NetworkPerson? person;
        for (final p in journey.people) {
          if (p.id == id) person = p;
        }
        if (person == null || !gating.canStrengthen(person.id)) {
          return _NoAccessView(gating: gating);
        }
        // La vista se identifica por el vínculo completo (PCS, persona y
        // asociación autorizada) además de la intención: si la asociación se
        // reemplaza por otra de la misma persona sin pasar por la revocación,
        // la vista se reinicia y no arrastra el estado de la anterior
        // (auditoría 3, S3-H05).
        return _ConnectionView(
          key: ValueKey(
            '${pcsLinkKey(journey, person.id)}:${initialAction?.wireValue}',
          ),
          recipient: person.name,
          initialAction: initialAction,
        );
      },
    );
  }
}

/// Vista sin acceso: elegir una persona cercana vinculada activamente.
class _NoAccessView extends ConsumerWidget {
  const _NoAccessView({required this.gating});

  final CareGating gating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = gating.authorizedPeople;
    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      floatingActionButton: SupportButton.pcs(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            const StatusBar(),
            const SizedBox(height: 46),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _brandSoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.link, color: _brand, size: 30),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              available.isNotEmpty
                  ? 'Elige una persona cercana'
                  : 'Todavía no hay personas cercanas vinculadas',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                height: 30 / 23,
                fontWeight: FontWeight.w800,
                color: ContigoColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              available.isNotEmpty
                  ? 'Solo aparecen las personas que aceptaron y tienen una '
                      'asociación activa contigo.'
                  : 'Una invitación enviada o aceptada no basta. Estas '
                      'herramientas se habilitan cuando la persona queda '
                      'vinculada activamente contigo.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 22 / 14,
                color: ContigoColors.inkMuted,
              ),
            ),
            const SizedBox(height: 20),
            for (final person in available)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: ContigoActionCard(
                  semanticLabel:
                      'Elegir a ${person.name}, persona cercana vinculada',
                  padding: const EdgeInsets.all(16),
                  onPressed: () async {
                    await selectConnectionPerson(ref, person.id);
                    if (!context.mounted) return;
                    context.pushReplacementNamed(
                      AppRoute.connectionPerson,
                      queryParameters: {'p': person.id},
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: _brand),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          person.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const _Chip(label: 'Asociado'),
                    ],
                  ),
                ),
              ),
            if (available.isEmpty)
              ContigoButton(
                label: 'Ver mi red e invitaciones',
                fullWidth: true,
                onPressed: () => context.pushNamed(AppRoute.networkMap),
              ),
            const SizedBox(height: 9),
            ContigoButton(
              label: 'Volver a Tejiendo vínculos',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => context.goBack(AppRoute.connectionHub),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _successSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _success,
        ),
      ),
    );
  }
}

class _ConnectionView extends StatefulWidget {
  const _ConnectionView({
    super.key,
    required this.recipient,
    required this.initialAction,
  });

  final String recipient;
  final ConnectionAction? initialAction;

  @override
  State<_ConnectionView> createState() => _ConnectionViewState();
}

class _ConnectionViewState extends State<_ConnectionView> {
  final _meetingKey = GlobalKey();

  // Mensaje para tejer cercanía (simulado).
  late final TextEditingController _composed;
  bool _loading = false;
  bool _messagePrepared = false;
  String _copyStatus = '';
  Timer? _timer;

  // Actividades.
  final List<String> _myActivities = ['Proponer una llamada corta'];
  static const _suggested = ['Tomar un café juntos', 'Dar una caminata corta'];
  bool _addingActivity = false;
  final _newActivity = TextEditingController();

  // Encuentro.
  String? _selectedMeeting;
  bool _meetingPrepared = false;

  /// Texto de la invitación. Vive en el estado de la pantalla (y no en la
  /// hoja) para que no se libere mientras la hoja aún se anima al cerrarse.
  final _inviteMessage = TextEditingController();

  String get _recipient => widget.recipient;
  String get _draftText =>
      'Hola $_recipient, pensé en ti hoy y quería escribirte. No tienes que '
      'responder ahora. Solo quería que supieras que estoy aquí.';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAction;
    _composed = TextEditingController(
      text: initial == ConnectionAction.contact
          ? 'Hola $_recipient, ¿cómo vas? Quería saludarte y saber cómo estás.'
          : initial == ConnectionAction.message
              ? _draftText
              : '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (initial) {
        case ConnectionAction.message:
          _openComposer(generate: false);
        case ConnectionAction.contact:
          _openContactOptions();
        case ConnectionAction.meeting:
          final ctx = _meetingKey.currentContext;
          if (ctx != null) Scrollable.ensureVisible(ctx);
        case null:
          break;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _composed.dispose();
    _newActivity.dispose();
    _inviteMessage.dispose();
    super.dispose();
  }

  void _generate(StateSetter? sheetSetState) {
    void update(VoidCallback fn) {
      if (!mounted) return;
      setState(fn);
      sheetSetState?.call(() {});
    }

    _timer?.cancel();
    update(() {
      _messagePrepared = false;
      _copyStatus = '';
      _loading = true;
      _composed.clear();
    });
    _timer = Timer(simulatedDraftDelay, () {
      update(() {
        _loading = false;
        _composed.text = _draftText;
      });
    });
  }

  Future<void> _openComposer({bool generate = true}) async {
    var started = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, sheetSetState) {
          if (generate && !started) {
            started = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _generate(sheetSetState));
          }
          return _SheetBody(
            title: 'Mensaje para tejer cercanía con $_recipient',
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: _brand,
                          backgroundColor: _brandSoft,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Generando un borrador...',
                        style: TextStyle(fontSize: 14, color: ContigoColors.inkMuted),
                      ),
                    ],
                  ),
                )
              else ...[
                _WarmNote(
                  'Borrador simulado para $_recipient. Puedes editarlo; no se '
                  'enviará desde este prototipo.',
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Tu mensaje (edítalo como prefieras)',
                  controller: _composed,
                  onChanged: (_) => sheetSetState(() {}),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _OutlineAction(
                        label: 'Regenerar',
                        onPressed: () => _generate(sheetSetState),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OutlineAction(
                        label: 'Copiar',
                        icon: Icons.copy_outlined,
                        onPressed: () async {
                          try {
                            await Clipboard.setData(
                              ClipboardData(text: _composed.text),
                            );
                            _copyStatus = 'Borrador copiado.';
                          } catch (_) {
                            _copyStatus = 'No se pudo copiar. Puedes '
                                'seleccionar el texto y copiarlo manualmente.';
                          }
                          sheetSetState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SolidAction(
                  label: 'Marcar borrador como preparado',
                  color: _success,
                  onPressed: _composed.text.trim().isEmpty
                      ? null
                      : () {
                          setState(() => _messagePrepared = true);
                          Navigator.of(sheetContext).pop();
                        },
                ),
                if (_copyStatus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _copyStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ContigoColors.inkMuted,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const _PrivacyNote(
                  'El mensaje nunca se envía automáticamente. Tú controlas '
                  'cada paso.',
                ),
              ],
            ],
          );
        },
      ),
    );
    _timer?.cancel();
    if (mounted && _loading) setState(() => _loading = false);
  }

  Future<void> _openContactOptions() async {
    var status = '';
    final writeGreeting = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, sheetSetState) => _SheetBody(
          title: 'Contactar a $_recipient',
          children: [
            const Text(
              'Puedes elegir una forma de acercarte. En esta versión, la '
              'llamada y el audio son simulados.',
              style: TextStyle(
                fontSize: 14,
                height: 21 / 14,
                color: ContigoColors.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
            ContigoButton(
              label: 'Simular llamada',
              fullWidth: true,
              icon: const Icon(Icons.phone_outlined),
              onPressed: () => sheetSetState(
                () => status = 'Llamada simulada a $_recipient. No se realizó '
                    'ninguna llamada.',
              ),
            ),
            const SizedBox(height: 10),
            ContigoButton(
              label: 'Simular audio',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => sheetSetState(
                () => status = 'Audio simulado para $_recipient. No se grabó '
                    'ni se envió ningún audio.',
              ),
            ),
            const SizedBox(height: 10),
            ContigoButton(
              label: 'Preparar un saludo escrito',
              variant: ContigoButtonVariant.tertiary,
              fullWidth: true,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 14, color: _success),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (writeGreeting == true && mounted) await _openComposer();
  }

  Future<void> _prepareMeeting() async {
    final activity = _selectedMeeting;
    if (activity == null) return;
    setState(() => _meetingPrepared = false);
    final message = _inviteMessage
      ..text = 'Hola $_recipient, me gustaría que programáramos un espacio para '
          '${activity.toLowerCase()}. ¿Te gustaría? Podemos acordar el momento '
          'que nos funcione. Si ahora no puedes, está bien.';
    final prepared = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, sheetSetState) => _SheetBody(
          title: 'Invitar a $_recipient',
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: _brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actividad elegida',
                          style: TextStyle(fontSize: 11, color: ContigoColors.inkMuted),
                        ),
                        Text(
                          activity,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Mensaje para $_recipient',
              controller: message,
              helper: 'Puedes modificar esta invitación de demostración.',
              onChanged: (_) => sheetSetState(() {}),
            ),
            const SizedBox(height: 14),
            const _PrivacyNote(
              'Este prototipo no enviará el mensaje ni abrirá un chat real.',
            ),
            const SizedBox(height: 16),
            ContigoButton(
              label: 'Revisar invitación para $_recipient',
              fullWidth: true,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: message.text.trim().isEmpty
                  ? null
                  : () async {
                      final ok = await _confirmMeeting(sheetContext, message.text);
                      if (ok == true && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop(true);
                      }
                    },
            ),
            const SizedBox(height: 10),
            ContigoButton(
              label: 'Cancelar',
              variant: ContigoButtonVariant.tertiary,
              fullWidth: true,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (prepared == true && mounted) setState(() => _meetingPrepared = true);
  }

  Future<bool?> _confirmMeeting(BuildContext context, String text) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('¿Confirmar este borrador?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Esta invitación está dirigida a $_recipient. No se enviará ni '
                'abrirá WhatsApp desde el prototipo.',
                style: const TextStyle(fontSize: 14, height: 20 / 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(text, style: const TextStyle(fontSize: 13, height: 19 / 13)),
                ),
              ),
              const SizedBox(height: 18),
              ContigoButton(
                label: 'Marcar borrador como preparado',
                fullWidth: true,
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              const SizedBox(height: 10),
              ContigoButton(
                label: 'Seguir editando',
                variant: ContigoButtonVariant.tertiary,
                fullWidth: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetingOptions = [..._suggested, ..._myActivities];
    if (_selectedMeeting != null && !meetingOptions.contains(_selectedMeeting)) {
      _selectedMeeting = null;
    }
    return Scaffold(
      backgroundColor: ContigoColors.canvasLight,
      floatingActionButton: SupportButton.pcs(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, supportContentPadding + 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusBar(),
              const SizedBox(height: 4),
              // Volver y módulo de origen (propuesta A).
              Row(
                children: [
                  _CircleBackButton(
                    tooltip: 'Volver a Tejiendo vínculos',
                    onPressed: () => context.goBack(AppRoute.connectionHub),
                  ),
                  const SizedBox(width: 12),
                  const _ModuleChip(label: 'Tejiendo vínculos'),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeAvatar(index: 0, size: 62),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conexión con $_recipient',
                          style: const TextStyle(
                            fontFamily: ContigoTheme.displayFontFamily,
                            fontFamilyFallback: ContigoTheme.displayFontFallback,
                            fontSize: 30,
                            height: 36 / 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: ContigoColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Puedes elegir una forma pequeña de acercarte. '
                          'También puedes hacerlo después.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 22 / 15,
                            color: ContigoColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _ActionGroup(
                rows: [
                  _GroupRow(
                    semanticLabel: 'Llamar o enviar audio a $_recipient',
                    icon: Icons.phone_outlined,
                    title: 'Llamar o enviar audio',
                    onTap: _openContactOptions,
                  ),
                  _GroupRow(
                    semanticLabel: 'Preguntas para conectar con $_recipient',
                    icon: Icons.chat_bubble_outline,
                    title: 'Preguntas para conectar',
                    subtitle: 'Un espacio de preguntas para conversar con '
                        '$_recipient y conocerse mejor',
                    onTap: () => context.pushNamed(AppRoute.pcsConnectionQuestions),
                  ),
                  _GroupRow(
                    semanticLabel: 'Ver mensajes de cuidado recibidos',
                    icon: Icons.favorite_border,
                    title: 'Ver mensajes de cuidado',
                    subtitle: 'Vuelve a los mensajes que has recibido',
                    onTap: () => context.pushNamed(AppRoute.caringInbox),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AssistantCard(
                recipient: _recipient,
                prepared: _messagePrepared,
                onHelp: _openComposer,
              ),
              const SizedBox(height: 18),
              _meetingCard(meetingOptions),
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brand,
                    side: const BorderSide(color: _chipBorder, width: 1.5),
                    minimumSize: const Size(120, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: ContigoTheme.bodyFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => context.goBack(AppRoute.connectionHub),
                  child: const Text('Ahora no'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta «Encontrarse»: actividades sugeridas y propias como opciones
  /// seleccionables, destinatario y preparación de la invitación.
  Widget _meetingCard(List<String> options) {
    final selected = _selectedMeeting;
    void select(String activity) => setState(() {
          _selectedMeeting = activity;
          _meetingPrepared = false;
        });
    return _SectionCard(
      key: _meetingKey,
      overline: 'Encontrarse',
      title: 'Programar un encuentro',
      children: [
        Text(
          'Elige una actividad y prepara una invitación para $_recipient'
          '${_recipient.endsWith('.') ? '' : '.'}',
          style: const TextStyle(
            fontSize: 15,
            height: 22 / 15,
            color: ContigoColors.inkMuted,
          ),
        ),
        const SizedBox(height: 14),
        const Text.rich(
          TextSpan(
            text: 'Sugeridas por el equipo',
            style: TextStyle(fontWeight: FontWeight.w700),
            children: [
              TextSpan(
                text: ' · Contenido por validar',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          style: TextStyle(fontSize: 13, height: 18 / 13, color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final activity in _suggested)
              _ActivityChip(
                label: activity,
                selected: selected == activity,
                onTap: () => select(activity),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Mis actividades',
          style: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
            color: ContigoColors.inkMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final activity in List.of(_myActivities))
              _ActivityChip(
                label: activity,
                selected: selected == activity,
                onTap: () => select(activity),
                onDelete: () => setState(() {
                  _myActivities.remove(activity);
                  if (_selectedMeeting == activity) _selectedMeeting = null;
                }),
              ),
            if (!_addingActivity)
              _AddActivityChip(
                onPressed: () => setState(() => _addingActivity = true),
              ),
          ],
        ),
        if (_addingActivity) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brand),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _newActivity,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Ver una película en casa',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ContigoButton(
                      label: 'Guardar',
                      small: true,
                      onPressed: () {
                        final text = _newActivity.text.trim();
                        if (text.isEmpty) return;
                        setState(() {
                          _myActivities.add(text);
                          _newActivity.clear();
                          _addingActivity = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ContigoButton(
                      label: 'Cancelar',
                      small: true,
                      variant: ContigoButtonVariant.tertiary,
                      onPressed: () => setState(() {
                        _newActivity.clear();
                        _addingActivity = false;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F2EC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const HomeAvatar(index: 0, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enviar a',
                      style: TextStyle(fontSize: 12, color: ContigoColors.inkMuted),
                    ),
                    Text(
                      _recipient,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ContigoColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const _Chip(label: 'Contacto de confianza'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PillButton(
          label: 'Preparar mensaje',
          onPressed: selected == null ? null : _prepareMeeting,
        ),
        if (selected == null) ...[
          const SizedBox(height: 8),
          const Text(
            'Elige una actividad para preparar la invitación.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: ContigoColors.inkMuted),
          ),
        ],
        if (_meetingPrepared) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _successSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: _success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Borrador preparado para $_recipient. El envío real está '
                      'pendiente de integración.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _success,
                      ),
                    ),
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

/// Botón circular de volver (propuesta A).
class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: _border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(Icons.arrow_back, color: ContigoColors.ink, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta del módulo de origen («∞ Tejiendo vínculos»).
class _ModuleChip extends StatelessWidget {
  const _ModuleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _brandSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.all_inclusive, size: 18, color: _brand),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _brand,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca que agrupa los accesos rápidos con divisores.
class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1EAE3)),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.semanticLabel,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String semanticLabel;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _brandSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: _brand),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 21 / 16,
                        fontWeight: FontWeight.w700,
                        color: ContigoColors.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: ContigoColors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _brand),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de sección con sobretítulo y título serif («ESCRIBIRLE»,
/// «ENCONTRARSE»).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.overline,
    required this.title,
    required this.children,
  });

  final String overline;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            overline.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: _brand,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: ContigoTheme.displayFontFamily,
              fontFamilyFallback: ContigoTheme.displayFontFallback,
              fontSize: 25,
              height: 31 / 25,
              fontWeight: FontWeight.w700,
              color: ContigoColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Botón principal en pastilla terracota.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _brand,
        disabledBackgroundColor: _brand.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: ContigoTheme.bodyFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// Actividad seleccionable en forma de pastilla. Las actividades propias
/// pueden eliminarse ([onDelete]).
class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : ContigoColors.ink;
    return Material(
      color: selected ? _brand : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? _brand : _chipBorder, width: 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, onDelete == null ? 16 : 6, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                selected: selected,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Eliminar actividad $label',
                  child: InkResponse(
                    onTap: onDelete,
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: selected ? Colors.white : ContigoColors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// «+ Agregar actividad» con borde punteado.
class _AddActivityChip extends StatelessWidget {
  const _AddActivityChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: _chipBorder,
      radius: 999,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 20, color: _brand),
                SizedBox(width: 6),
                Text(
                  'Agregar actividad',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: _brand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta «Escribirle»: asistente simulado para el mensaje de cercanía.
class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.recipient,
    required this.prepared,
    required this.onHelp,
  });

  final String recipient;
  final bool prepared;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      overline: 'Escribirle',
      title: 'Mensaje para tejer cercanía',
      children: [
        const Text(
          'Una herramienta con inteligencia artificial te ayuda a crear un '
          'borrador para comunicarte con alguien de confianza.',
          style: TextStyle(
            fontSize: 15,
            height: 22 / 15,
            color: ContigoColors.inkMuted,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: _warmSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.info_outline, size: 18, color: _warmText),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'La IA propone un borrador. Tú decides qué editar '
                            'y enviar. El mensaje nunca se envía '
                            'automáticamente.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' IA basada en artículos revisados por el equipo '
                            'investigador.',
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    height: 19 / 13,
                    color: _warmText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PillButton(
          label: 'Ayúdame a escribirle',
          icon: Icons.edit_outlined,
          onPressed: onHelp,
        ),
        if (prepared) ...[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: Text(
              'Borrador preparado para $recipient en esta demo. No se ha '
              'enviado.',
              style: const TextStyle(fontSize: 13, color: _success),
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Esta herramienta no reemplaza la orientación profesional ni '
          'ofrece consejos clínicos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 17 / 12,
            color: ContigoColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _WarmNote extends StatelessWidget {
  const _WarmNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _warmSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ochre),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 17 / 12,
          color: _warmText,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 16, color: ContigoColors.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 18 / 12,
              color: ContigoColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.helper,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? helper;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _success, width: 1.5),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: const TextStyle(fontSize: 12, color: ContigoColors.inkMuted),
          ),
        ],
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: _brand,
        side: const BorderSide(color: _border),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: ContigoTheme.bodyFontFamily, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(label),
        ],
      ),
    );
  }
}

class _SolidAction extends StatelessWidget {
  const _SolidAction({required this.label, required this.color, this.onPressed});

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: ContigoTheme.bodyFontFamily, fontSize: 13, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
