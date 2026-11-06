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
  const StoryVideo({super.key, required this.asset, required this.title});

  /// Ruta del asset de video empacado (p. ej. `AppMedia.safetyPlanStoryVideo1`).
  final String asset;

  /// Título de la página, usado como etiqueta de accesibilidad del video.
  final String title;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_failed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ContigoColors.notifMeetingBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                'No pudimos cargar el video. Puedes abrirlo por separado o '
                'continuar con el contenido.',
                style: (textTheme.bodySmall ?? const TextStyle())
                    .copyWith(color: ContigoColors.clay),
              ),
            ),
          )
        else if (controller != null && controller.value.isInitialized)
          Semantics(
            label: 'Video: ${widget.title}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(controller),
                    GestureDetector(
                      onTap: _togglePlay,
                      child: AnimatedOpacity(
                        opacity: controller.value.isPlaying ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          color: Colors.black26,
                          alignment: Alignment.center,
                          child: Icon(
                            controller.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            size: 56,
                            color: ContigoColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: ContigoColors.notifSocialBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Puedes pausar el video y avanzar a tu propio ritmo.',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
      ],
    );
  }
}