import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../app/session_controller.dart';
import '../../app/theme.dart';
import '../../domain/auth/auth_service.dart';
import '../widgets/widgets.dart';

/// Pantalla de activación por código (Requirement 11), portada del
/// `MobileScreen01` del prototipo con la propuesta visual M1: marca con hilo,
/// tarjeta blanca con planta, seis casillas para el código, nota de
/// privacidad y herramientas de demostración plegadas.
///
/// Reproduce el flujo del prototipo: el código se muestra en mayúsculas,
/// centrado y espaciado; "Continuar" dispara una verificación simulada
/// ([AuthService.activate]) que, mientras resuelve, muestra "Verificando..." y
/// deshabilita el botón. Si el código es demasiado corto se muestra el mensaje
/// de error del prototipo (verbatim) sin navegar. En caso de éxito se establece
/// la sesión y las guardas del router enrutan al inicio del rol resuelto.
///
/// La activación opera en la Capa_Simulada: se muestra el indicador de
/// simulación persistente ([SimulationIndicator]) según el metadato de capa de
/// la feature. Se conservan además los accesos de desarrollo (galería de
/// componentes y controles de demostración).
class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  /// Metadato de capa de la feature de activación: simulada (Requirement 3.4).
  static const FeatureLayerInfo featureLayer = FeatureLayerInfo(
    featureId: 'activation',
    layer: FeatureLayer.simulada,
    label:
        'Activación simulada: cualquier código válido abre una sesión de '
        'demostración. No hay verificación real.',
  );

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focus = FocusNode();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Repinta las casillas al entrar o salir del campo.
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_loading) return;
    final code = _codeController.text;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final session = await ref.read(authServiceProvider).activate(code);
      if (!mounted) return;
      // Éxito: establece la sesión; las guardas del router enrutan por rol.
      ref.read(sessionControllerProvider.notifier).setSession(session);
    } on ActivationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _codeController.text;
    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusBar(),
              const SizedBox(height: 18),
              // Marca con hilo decorativo de fondo (propuesta M1).
              SizedBox(
                height: 130,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      left: -20,
                      right: -20,
                      top: 48,
                      height: 90,
                      child: ExcludeSemantics(
                        child: CustomPaint(painter: _BackgroundThreadPainter()),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.topCenter,
                      child: ContigoLogo(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      top: -14,
                      right: -24,
                      child: HomePlant(width: 120, height: 112),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 96),
                          child: Text(
                            'Activa tu cuenta',
                            style: TextStyle(
                              fontFamily: ContigoTheme.displayFontFamily,
                              fontFamilyFallback:
                                  ContigoTheme.displayFontFallback,
                              fontSize: 42,
                              height: 1.12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              color: Color(0xFF242126),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Ingresa el código que recibiste para empezar de forma '
                          'segura.',
                          style: TextStyle(
                            fontSize: 17,
                            height: 26 / 17,
                            color: ContigoColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'Código de activación',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ContigoColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CodeBoxes(
                          controller: _codeController,
                          focusNode: _focus,
                          code: code,
                          focused: _focus.hasFocus,
                          error: _error != null,
                          onChanged: (_) => setState(() {
                            if (_error != null) _error = null;
                          }),
                          onSubmitted: (_) => _handleContinue(),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ej: A3K9X2',
                          style: TextStyle(
                            fontSize: 13,
                            color: ContigoColors.inkMuted,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: ContigoColors.clay,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: ContigoColors.clay,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 22),
                        ResourcePillButton(
                          label: _loading ? 'Verificando...' : 'Continuar',
                          color: ContigoColors.brand,
                          onPressed: _loading ? null : _handleContinue,
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF963D1B),
                              textStyle: const TextStyle(
                                fontFamily: ContigoTheme.bodyFontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () {},
                            child: const Text('Necesito ayuda con mi código'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _PrivacyNote(
                text:
                    'Tu información es privada y solo se usa para '
                    'brindarte el acompañamiento autorizado.',
              ),
              const SizedBox(height: 26),
              DemoToolsPanel(
                children: [
                  const Text(
                    'Códigos de demo: cualquier código → PCS. Código que '
                    'empiece con «C» → cuidador/a.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 19 / 13,
                      color: ContigoColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () =>
                            context.pushNamed(AppRoute.componentGallery),
                        child: const Text('Ver componentes'),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.pushNamed(AppRoute.demoControls),
                        child: const Text('Controles de demostración'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Aviso de simulación de la activación (Capa_Simulada).
              Semantics(
                container: true,
                label: 'Indicador de simulación',
                child: Text(
                  ActivationScreen.featureLayer.label ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 21 / 14,
                    color: ContigoColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seis casillas del código de activación (propuesta M1). Un campo de texto
/// transparente encima recibe el teclado; las casillas muestran cada carácter
/// y resaltan la siguiente por escribir.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.code,
    required this.focused,
    required this.error,
    required this.onChanged,
    required this.onSubmitted,
  });

  static const int length = 6;

  final TextEditingController controller;
  final FocusNode focusNode;
  final String code;
  final bool focused;
  final bool error;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _box(i)),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: Semantics(
                label: 'Código de activación',
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autocorrect: false,
                  enableSuggestions: false,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  maxLength: length,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [_UpperCaseTextFormatter()],
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(int i) {
    final char = i < code.length ? code[i] : '';
    final active = focused && i == code.length.clamp(0, length - 1);
    final borderColor = error
        ? ContigoColors.clay
        : active
        ? ContigoColors.sage
        : const Color(0xFFD9CDC2);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: active ? 2 : 1.5),
      ),
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: ContigoColors.ink,
        ),
      ),
    );
  }
}

/// Hilo punteado que cruza detrás de la marca y la tarjeta.
class _BackgroundThreadPainter extends CustomPainter {
  const _BackgroundThreadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.95)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.55,
        size.width * 0.45,
        size.height * 0.9,
        size.width * 0.62,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        -size.height * 0.15,
        size.width,
        size.height * 0.45,
      );
    final paint = Paint()
      ..color = const Color(0xFFE6C3AC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 0.1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundThreadPainter old) => false;
}

/// Formateador que fuerza mayúsculas en el campo del código, equivalente al
/// `toUpperCase()` del prototipo en cada cambio del input.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Nota de privacidad del prototipo (`PrivacyNote`): ícono de candado y texto
/// apagado centrado. Se define localmente al no existir un widget compartido.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.lock_outline, size: 20, color: ContigoColors.sage),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
              fontSize: 15,
              height: 22 / 15,
              color: ContigoColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}
