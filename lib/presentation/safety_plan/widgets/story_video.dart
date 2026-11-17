import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme.dart';

/// Reproductor del video del relato del plan de seguridad (portado de
/// `StoryVideo` en `src/screens/safety-plan-story.tsx`).
///
/// Reproduce el `.mp4` empacado en el bundle con controles de play/pausa. Si el
/// video no carga, muestra el mensaje de respaldo del prototipo y permite
/// continuar con el contenido. Conserva la nota "Puedes pausar el video y
/// avanzar a tu propio ritmo".
class StoryVideo extends StatefulWidget {
  const StoryVideo({
    super.key,
    required this.asset,
    required this.title,
    this.accent = ContigoColors.terracotta,
    this.caption,
    this.playAtCorner = false,
    this.footer,
  });

  /// Ruta del asset de video empacado (p. ej. `AppMedia.safetyPlanStoryVideo1`).
  final String asset;

  /// Título de la página, usado como etiqueta de accesibilidad del video.
  final String title;

  /// Color del botón de reproducir.
  final Color accent;

  /// Leyenda bajo el video («Video · …»). Por defecto, `Video · [title]`.
  final String? caption;

  /// Si es `true`, el botón de reproducir se ubica en la esquina inferior
  /// derecha (mensajes de cuidado) en lugar del centro.
  final bool playAtCorner;

  /// Contenido adicional dentro de la tarjeta, bajo la leyenda.
  final Widget? footer;

  @override
  State<StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends State<StoryVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(StoryVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      final previous = _controller;
      if (previous != null) unawaited(_safeDispose(previous));
      _controller = null;
      _failed = false;
      _initialize();
    }
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.asset(widget.asset);
    try {
      await controller.initialize();
      if (!mounted) {
        unawaited(_safeDispose(controller));
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      // Muestra el respaldo de inmediato: NO esperamos a `dispose()`. En
      // video_player 2.14.1, si `createWithOptions` falla antes de entregar un
      // ID, el completador de creación queda pendiente y `dispose()` lo
      // esperaría indefinidamente, dejando la UI atascada en el indicador de
      // carga (hallazgo E3-W10-03). La limpieza del controlador se hace en
      // segundo plano y con sus propios errores controlados.
      if (mounted) setState(() => _failed = true);
      unawaited(_safeDispose(controller));
    }
  }

  /// Libera el controlador sin propagar errores ni bloquear la interfaz.
  ///
  /// `dispose()` puede completar fuera del ciclo normal (o quedar pendiente si
  /// la creación nativa nunca entregó un ID); se aísla aquí para conservar la
  /// limpieza de recursos sin que un error asíncrono escape.
  Future<void> _safeDispose(VideoPlayerController controller) async {
    try {
      await controller.dispose();
    } catch (_) {
      // Ignorado: la liberación de un controlador que nunca se creó del todo
      // no debe convertirse en un error no controlado.
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(_safeDispose(controller));
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    Widget media;
    if (_failed) {
      media = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        color: ContigoColors.notifMeetingBg,
        child: Semantics(
          liveRegion: true,
          child: Text(
            'No pudimos cargar el video. Puedes abrirlo por separado o '
            'continuar con el contenido.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.clay),
          ),
        ),
      );
    } else if (ready) {
      final playing = controller.value.isPlaying;
      media = Semantics(
        label: 'Video: ${widget.title}',
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: GestureDetector(
            onTap: _togglePlay,
            child: Stack(
              children: [
                Positioned.fill(child: VideoPlayer(controller)),
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: playing ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Align(
                      alignment: widget.playAtCorner
                          ? const Alignment(0.92, 0.9)
                          : Alignment.center,
                      child: _PlayButton(
                        color: widget.accent,
                        playing: playing,
                        onPressed: _togglePlay,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      media = SizedBox(
        height: 240,
        child: Container(
          color: const Color(0xFFFBF8F4),
          alignment: Alignment.center,
          child: CircularProgressIndicator(color: widget.accent),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8DFD5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          media,
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0E8E0)),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, widget.footer == null ? 16 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.playAtCorner) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.play_arrow_outlined,
                      size: 18,
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.caption ?? 'Video · ${widget.title}',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 19 / 14,
                      fontWeight: FontWeight.w600,
                      color: ContigoColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: widget.footer,
            ),
        ],
      ),
    );
  }
}

/// Botón circular grande de reproducir/pausar con aro blanco.
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.color,
    required this.playing,
    required this.onPressed,
  });

  final Color color;
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Pausar video' : 'Reproducir video',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            size: 34,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
