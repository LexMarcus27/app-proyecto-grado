import 'package:flutter/material.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../widgets/widgets.dart';

/// Habilidad de respiración pausada (tarea 3.28), portada de `MobileScreen07`.
///
/// Contenido textual **verbatim** del prototipo, con el marcador de
/// instrucciones clínicas pendiente de validación (`[[...]]`) preservado.
/// Incluye un círculo que late con un conmutador de "Reducir movimiento"
/// (accesibilidad) y las opciones de duración. Las acciones de contacto son
/// simuladas.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  bool _animating = true;
  String? _duration = '2 minutos';

  static const List<String> _durations = ['1 minuto', '2 minutos', 'Sin tiempo'];

  @override
  void initState() {
    super.initState();
    _animation.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Contactar', style: textTheme.titleLarge),
              const SizedBox(height: 16),
              ContigoButton(
                label: 'Enviar un mensaje',
                fullWidth: true,
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 10),
              ContigoButton(
                label: 'Llamar',
                variant: ContigoButtonVariant.secondary,
                fullWidth: true,
                icon: const Icon(Icons.call_outlined),
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 10),
              ContigoButton(
                label: 'Ahora no',
                variant: ContigoButtonVariant.tertiary,
                fullWidth: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
  void _toggleAnimation() {
    setState(() {
      _animating = !_animating;
      if (_animating) {
        _animation.repeat(reverse: true);
      } else {
        _animation.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.goBack(AppRoute.crisisMode),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Volver a mi plan'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Respiración pausada', style: textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Puedes detenerte o elegir otra opción cuando quieras.',
                      style: (textTheme.bodyMedium ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted),
                    ),
                    const SizedBox(height: 28),
                    Center(child: _BreathingCircle(animation: _animation)),
                    const SizedBox(height: 20),
                    Center(
                      child: ContigoButton(
                        label: _animating
                            ? 'Reducir movimiento'
                            : 'Activar animación',
                        variant: ContigoButtonVariant.secondary,
                        small: true,
                        icon: Icon(
                          _animating ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: _toggleAnimation,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ContigoColors.notifReminderBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instrucciones', style: textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Text(
                            '[[INSTRUCCIONES CLÍNICAS BREVES POR VALIDAR]]',
                            style: (textTheme.bodyMedium ?? const TextStyle())
                                .copyWith(
                              color: ContigoColors.inkMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Duración (opcional)',
                      style: (textTheme.bodySmall ?? const TextStyle())
                          .copyWith(
                        color: ContigoColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final d in _durations) ...[
                          Expanded(
                            child: _DurationChip(
                              label: d,
                              selected: _duration == d,
                              onTap: () => setState(
                                () => _duration = _duration == d ? null : d,
                              ),
                            ),
                          ),
                          if (d != _durations.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                    ContigoButton(
                      label: 'Terminé por ahora',
                      fullWidth: true,
                      onPressed: () => context.goBack(AppRoute.crisisMode),
                    ),
                    const SizedBox(height: 10),
                    ContigoButton(
                      label: 'Probar otra habilidad',
                      variant: ContigoButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => context.goBack(AppRoute.crisisMode),
                    ),
                    const SizedBox(height: 10),
                    ContigoButton(
                      label: 'Contactar a alguien',
                      variant: ContigoButtonVariant.tertiary,
                      fullWidth: true,
                      onPressed: () => _showContactOptions(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo que late suavemente (inhala/exhala). Respeta el conmutador de
/// movimiento: cuando el [animation] está detenido, queda en reposo.
class _BreathingCircle extends StatelessWidget {
  const _BreathingCircle({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // El rótulo del centro se construye una sola vez y se pasa como `child`;
    // el escalado lo aplica el builder tanto al halo exterior como al círculo
    // central, de modo que el movimiento sea claramente perceptible (hallazgo
    // E3-W11-01). Se conserva la cadencia de 4 s por sentido del controlador.
    return SizedBox(
      height: 220,
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(animation.value);
            // Halo exterior: 60% -> 100% del diámetro base (amplitud amplia y
            // visible). Círculo central: 78% -> 100%, para que también "respire".
            final outerScale = 0.6 + 0.4 * t;
            final innerScale = 0.78 + 0.22 * t;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200 * outerScale,
                  height: 200 * outerScale,
                  decoration: const BoxDecoration(
                    color: ContigoColors.notifQuestionsBg,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 140 * innerScale,
                  height: 140 * innerScale,
                  decoration: const BoxDecoration(
                    color: ContigoColors.terracotta,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: child,
                ),
              ],
            );
          },
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Inhala',
                  style: (textTheme.titleSmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.surface),
                ),
                Text(
                  'suavemente',
                  style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: ContigoColors.surface.withValues(alpha: 0.8),
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ContigoColors.notifQuestionsBg : ContigoColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? ContigoColors.terracotta : ContigoColors.notifMeetingBg,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
            color: selected ? ContigoColors.terracotta : ContigoColors.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}