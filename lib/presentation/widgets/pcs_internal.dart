import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'contigo_button.dart';
import 'status_bar.dart';
import 'support_button.dart';

/// Tokens de las pantallas internas del PCS (`.pcs-internal-*`, `index.css`).
abstract final class PcsColors {
  static const Color canvas = Color(0xFFFAF7F2);
  static const Color ink = Color(0xFF242328);
  static const Color text = Color(0xFF52555D);
  static const Color border = Color(0xFFE5DED5);
  static const Color peach = Color(0xFFFCEDDF);
  static const Color peachIcon = Color(0xFFF8DCC6);
  static const Color accentDark = Color(0xFF963D1B);
  static const Color terracotta = ContigoColors.terracotta;
  static const Color secondaryBorder = Color(0xFFDDBCA6);
  static const Color lilac = Color(0xFFF0EEFA);
  static const Color lilacText = Color(0xFF59439A);
}

/// Estilos serif de los títulos internos del PCS (Georgia → Lora).
abstract final class PcsText {
  static const TextStyle display = TextStyle(
    fontFamily: ContigoTheme.displayFontFamily,
    fontFamilyFallback: ContigoTheme.displayFontFallback,
    fontSize: 30,
    height: 34 / 30,
    fontWeight: FontWeight.w700,
    color: PcsColors.ink,
  );

  static const TextStyle featured = TextStyle(
    fontFamily: ContigoTheme.displayFontFamily,
    fontFamilyFallback: ContigoTheme.displayFontFallback,
    fontSize: 23,
    height: 27 / 23,
    fontWeight: FontWeight.w700,
    color: PcsColors.ink,
  );

  static const TextStyle cloud = TextStyle(
    fontFamily: ContigoTheme.displayFontFamily,
    fontFamilyFallback: ContigoTheme.displayFontFallback,
    fontSize: 22,
    height: 26 / 22,
    fontWeight: FontWeight.w700,
    color: PcsColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 23 / 15,
    color: PcsColors.text,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 12,
    height: 19 / 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
    color: PcsColors.accentDark,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: PcsColors.ink,
  );
}

/// Estructura de las pantallas internas del PCS: lienzo `#FAF7F2`, botón
/// redondo de volver, píldora del módulo y botón flotante «Necesito apoyo»
/// (`.pcs-internal-screen` + `.pcs-support-dock`).
class PcsInternalScaffold extends StatelessWidget {
  const PcsInternalScaffold({
    super.key,
    required this.backLabel,
    required this.onBack,
    required this.child,
    this.moduleLabel,
    this.moduleIcon,
    this.showSupport = true,
  });

  final String backLabel;
  final VoidCallback onBack;
  final String? moduleLabel;
  final IconData? moduleIcon;
  final bool showSupport;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PcsColors.canvas,
      floatingActionButton: showSupport ? SupportButton.pcs(context) : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  PcsRoundBackButton(label: backLabel, onPressed: onBack),
                  if (moduleLabel != null) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: PcsModuleLabel(
                        label: moduleLabel!,
                        icon: moduleIcon,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: showSupport ? supportButtonHeight + 16 : 0,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón redondo de volver (`.pcs-round-back`).
class PcsRoundBackButton extends StatelessWidget {
  const PcsRoundBackButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: PcsColors.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back, color: PcsColors.ink, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Píldora del módulo (`.pcs-module-label`).
class PcsModuleLabel extends StatelessWidget {
  const PcsModuleLabel({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: PcsColors.peach,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: PcsColors.accentDark),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PcsColors.accentDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón en píldora de las pantallas internas (`.pcs-primary` /
/// `.pcs-secondary`).
class PcsPillButton extends StatelessWidget {
  const PcsPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  /// Color de fondo del primario (por defecto terracota).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final background = secondary ? Colors.white : (color ?? PcsColors.terracotta);
    final foreground = secondary ? PcsColors.accentDark : Colors.white;
    final border = secondary
        ? const BorderSide(color: PcsColors.secondaryBorder, width: 1.5)
        : BorderSide(color: background, width: 2);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: background,
        shape: StadiumBorder(side: border),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ícono circular de acción (`.pcs-action-icon`).
class PcsActionIcon extends StatelessWidget {
  const PcsActionIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: PcsColors.peachIcon,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(icon, size: 20, color: PcsColors.terracotta),
    );
  }
}

/// Botón «Habilidades» lila (`.pcs-skills`).
class PcsSkillsButton extends StatelessWidget {
  const PcsSkillsButton({super.key, required this.onPressed, this.label = 'Habilidades'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PcsColors.lilac,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 18, color: PcsColors.lilacText),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PcsColors.lilacText,
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

/// Hoja inferior sencilla con título, texto y un botón de cierre, usada para
/// los contenidos pendientes de validación (p. ej. «Habilidades
/// interpersonales»).
Future<void> showPendingContentSheet(
  BuildContext context, {
  required String title,
  String body =
      'Este contenido será proporcionado y validado por el equipo investigador.',
  String closeLabel = 'Volver',
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(body, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            ContigoButton(
              label: closeLabel,
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      );
    },
  );
}
