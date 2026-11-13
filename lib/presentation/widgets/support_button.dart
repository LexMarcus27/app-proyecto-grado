import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

/// Rojo del botón flotante de apoyo del prototipo (`#B32622`).
const Color _supportRed = Color(0xFFB32622);

/// Altura del botón (`SUPPORT_BUTTON_HEIGHT = 56`).
const double supportButtonHeight = 56;

/// Espacio inferior que debe reservar el contenido desplazable para que su
/// última acción quede por encima del botón flotante
/// (`supportContentPadding` del prototipo).
const double supportContentPadding = supportButtonHeight + 44;

/// Botón flotante persistente de apoyo, portado de `FloatingSupportBtn`
/// (`src/ui.tsx`): pastilla roja con ícono de salvavidas y etiqueta.
///
/// - PCS: «Necesito apoyo» → modo crisis ([SupportButton.pcs]).
/// - Cuidador: «Proveer apoyo» → plan de acompañamiento, deshabilitado sin
///   vínculo activo ([SupportButton.caregiver]).
///
/// Se usa en el `floatingActionButton` del `Scaffold`, que lo sitúa por encima
/// de la navegación inferior y del teclado.
class SupportButton extends StatelessWidget {
  const SupportButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  /// Botón del PCS: abre el modo crisis.
  factory SupportButton.pcs(BuildContext context) => SupportButton(
        label: 'Necesito apoyo',
        onPressed: () => context.goNamed(AppRoute.crisisMode),
      );

  /// Botón del cuidador: abre el plan de acompañamiento si [enabled].
  factory SupportButton.caregiver(BuildContext context, {required bool enabled}) =>
      SupportButton(
        label: 'Proveer apoyo',
        onPressed: enabled
            ? () => context.goNamed(AppRoute.caregiverSupportPlan)
            : null,
      );

  final String label;

  /// `null` deshabilita el botón (opacidad .65, como el prototipo).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.65,
        child: Material(
          color: _supportRed,
          shape: const StadiumBorder(),
          elevation: 6,
          shadowColor: _supportRed.withValues(alpha: 0.35),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onPressed,
            child: Container(
              constraints: const BoxConstraints(minHeight: supportButtonHeight),
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.support, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
