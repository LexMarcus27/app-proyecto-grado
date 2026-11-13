import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Variantes de botón equivalentes al componente `Btn` del prototipo (`ui.tsx`).
///
/// El prototipo define cinco variantes con la paleta de marca. Se preservan los
/// colores y jerarquía (Requirement 2.3), consumidos desde el tema
/// ([ContigoColors]), nunca con literales de color.
enum ContigoButtonVariant {
  /// Acción principal: fondo rosa de marca (`C.brand`), texto blanco. Las
  /// pantallas internas del PCS usan su propio primario terracota
  /// (`.pcs-primary`, `PcsPillButton`).
  primary,

  /// Acción secundaria: fondo suave con texto y borde de marca.
  secondary,

  /// Acción terciaria: sin fondo, solo texto de marca.
  tertiary,

  /// Acción crítica/destructiva: fondo rojo de alerta, texto blanco.
  critical,

  /// Acción fantasma: sin fondo, texto apagado.
  ghost,
}

/// Botón reutilizable portado del prototipo.
///
/// Reproduce el `Btn` del prototipo: radio 12, peso 600, altura 54 (40 en modo
/// [small]), ícono opcional a la izquierda, ancho completo opcional y estado
/// deshabilitado con opacidad reducida. Al estar deshabilitado no dispara
/// [onPressed], igual que el prototipo.
class ContigoButton extends StatelessWidget {
  const ContigoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ContigoButtonVariant.primary,
    this.fullWidth = false,
    this.small = false,
    this.icon,
  });

  /// Texto del botón.
  final String label;

  /// Acción al pulsar. Si es `null`, el botón queda deshabilitado.
  final VoidCallback? onPressed;

  /// Variante visual (ver [ContigoButtonVariant]).
  final ContigoButtonVariant variant;

  /// Si ocupa todo el ancho disponible (`fullWidth` del prototipo).
  final bool fullWidth;

  /// Versión compacta (`small` del prototipo): menor altura y tipografía.
  final bool small;

  /// Ícono opcional mostrado a la izquierda del texto.
  final Widget? icon;

  bool get _disabled => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(variant);
    final height = small ? 40.0 : 54.0;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    final fontSize = small ? 14.0 : 16.0;

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: style.foreground, size: fontSize + 4),
            child: ExcludeSemantics(child: icon!),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              color: style.foreground,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: _disabled ? 0.45 : 1,
      child: Material(
        color: style.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(minHeight: height),
            width: fullWidth ? double.infinity : null,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: style.border == null
                  ? null
                  : Border.all(color: style.border!, width: 1.5),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  _ButtonStyleTokens _styleFor(ContigoButtonVariant variant) {
    switch (variant) {
      case ContigoButtonVariant.primary:
        return const _ButtonStyleTokens(
          background: ContigoColors.brand,
          foreground: ContigoColors.surface,
        );
      case ContigoButtonVariant.secondary:
        return const _ButtonStyleTokens(
          background: ContigoColors.notifQuestionsBg,
          foreground: ContigoColors.brand,
          border: ContigoColors.brandSoft,
        );
      case ContigoButtonVariant.tertiary:
        return const _ButtonStyleTokens(
          background: Colors.transparent,
          foreground: ContigoColors.brand,
        );
      case ContigoButtonVariant.critical:
        return const _ButtonStyleTokens(
          background: ContigoColors.critical,
          foreground: ContigoColors.surface,
        );
      case ContigoButtonVariant.ghost:
        return const _ButtonStyleTokens(
          background: Colors.transparent,
          foreground: ContigoColors.inkMuted,
        );
    }
  }
}

class _ButtonStyleTokens {
  const _ButtonStyleTokens({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}
