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
/// `MobileScreen01` del prototipo.
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
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            SimulationIndicator.forFeature(ActivationScreen.featureLayer),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Marca "Contigo" (equivalente a ContigoLogo del prototipo).
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Text(
                          'Contigo',
                          style: (textTheme.displaySmall ?? const TextStyle())
                              .copyWith(color: ContigoColors.terracotta),
                        ),
                      ),
                    ),
                    Text(
                      'Activa tu cuenta',
                      style: (textTheme.headlineMedium ?? const TextStyle())
                          .copyWith(fontSize: 28, height: 34 / 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ingresa el código que recibiste para empezar de forma '
                      'segura.',
                      style: (textTheme.bodyMedium ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Código de activación',
                      style: (textTheme.titleSmall ?? const TextStyle())
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _codeController,
                      autocorrect: false,
                      enableSuggestions: false,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [_UpperCaseTextFormatter()],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _handleContinue(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: ContigoColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ej: A3K9X2',
                        filled: true,
                        fillColor: ContigoColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        border: _inputBorder(ContigoColors.notifMeetingBg),
                        enabledBorder: _inputBorder(
                          _error != null
                              ? ContigoColors.clay
                              : ContigoColors.notifMeetingBg,
                        ),
                        focusedBorder: _inputBorder(
                          _error != null
                              ? ContigoColors.clay
                              : ContigoColors.sage,
                        ),
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
                              style:
                                  (textTheme.bodySmall ?? const TextStyle())
                                      .copyWith(color: ContigoColors.clay),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    ContigoButton(
                      label: _loading ? 'Verificando...' : 'Continuar',
                      fullWidth: true,
                      onPressed: _loading ? null : _handleContinue,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Necesito ayuda con mi código',
                          style:
                              (textTheme.titleSmall ?? const TextStyle())
                                  .copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ContigoColors.terracotta,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PrivacyNote(
                      text:
                          'Tu información es privada y solo se usa para '
                          'brindarte el acompañamiento autorizado.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Códigos de demo: cualquier código → PCS. Código que '
                      'empiece con «C» → cuidador/a.',
                      textAlign: TextAlign.center,
                      style: (textTheme.bodySmall ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // Accesos de desarrollo (no forman parte del prototipo).
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            context.pushNamed(AppRoute.componentGallery),
                        child: const Text('Ver componentes'),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            context.pushNamed(AppRoute.demoControls),
                        child: const Text('Controles de demostración'),
                      ),
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

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1.5),
      );
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.lock_outline,
            size: 16,
            color: ContigoColors.inkMuted,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
        ),
      ],
    );
  }
}