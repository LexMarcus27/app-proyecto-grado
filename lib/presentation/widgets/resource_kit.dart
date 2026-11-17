import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Piezas comunes de los recursos narrativos paso a paso (propuestas M25 y
/// M26): etiqueta del recurso, botón circular, progreso punteado con nodos,
/// encabezado numerado, tarjetas, avisos destacados, listas con ícono y barra
/// inferior con «Siguiente».
///
/// Cada recurso usa su paleta ([ResourcePalette.plan] terracota para el plan
/// para desenredar y [ResourcePalette.caring] salvia/rosa para mensajes de
/// cuidado).
class ResourcePalette {
  const ResourcePalette({
    required this.accent,
    required this.soft,
    required this.number,
    required this.primary,
    required this.dotted,
  });

  /// Color de acento: sobretítulos, íconos y progreso recorrido.
  final Color accent;

  /// Fondo suave de etiquetas, avisos e íconos.
  final Color soft;

  /// Color del número grande del paso.
  final Color number;

  /// Color del botón principal.
  final Color primary;

  /// Color del tramo punteado del progreso aún no recorrido.
  final Color dotted;

  /// Plan para desenredar: terracota y melocotón.
  static const plan = ResourcePalette(
    accent: Color(0xFFAA461D),
    soft: Color(0xFFFCE9DC),
    number: Color(0xFFF0B48F),
    primary: Color(0xFFAA461D),
    dotted: Color(0xFFE8C2AA),
  );

  /// Mensajes de cuidado: salvia con botón rosa de marca.
  static const caring = ResourcePalette(
    accent: Color(0xFF536B50),
    soft: Color(0xFFE3ECDF),
    number: Color(0xFFA9BF9C),
    primary: ContigoColors.brand,
    dotted: Color(0xFFB9CBAE),
  );
}

/// Título serif de los recursos.
const TextStyle resourceSerif = TextStyle(
  fontFamily: ContigoTheme.displayFontFamily,
  fontFamilyFallback: ContigoTheme.displayFontFallback,
  fontWeight: FontWeight.w700,
  color: Color(0xFF242126),
);

/// Cuerpo de texto de los recursos.
const TextStyle resourceBody = TextStyle(
  fontSize: 16,
  height: 25 / 16,
  color: ContigoColors.ink,
);

/// Etiqueta en pastilla del recurso («Plan para desenredar», «Para Sofía»).
class ResourceChip extends StatelessWidget {
  const ResourceChip({
    super.key,
    required this.label,
    required this.palette,
    this.icon,
    this.leading,
  });

  final String label;
  final ResourcePalette palette;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(leading != null ? 6 : 14, 6, 16, 6),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          if (icon != null) ...[
            Icon(icon, size: 18, color: palette.accent),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular blanco (cerrar, volver).
class ResourceCircleButton extends StatelessWidget {
  const ResourceCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor = ContigoColors.ink,
    this.borderColor = const Color(0xFFE5DCD3),
    this.size = 48,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color iconColor;
  final Color borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          shape: CircleBorder(side: BorderSide(color: borderColor, width: 1.3)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: 22,
                color: enabled ? iconColor : iconColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progreso punteado con un nodo por paso: tramo recorrido sólido, nodo
/// actual con anillo y pasos pendientes huecos sobre una línea punteada.
class ResourceProgress extends StatelessWidget {
  const ResourceProgress({
    super.key,
    required this.total,
    required this.current,
    required this.palette,
    required this.semanticLabel,
  });

  final int total;
  final int current;
  final ResourcePalette palette;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: 24,
        width: double.infinity,
        child: CustomPaint(
          painter: _ProgressPainter(
            total: total,
            current: current,
            palette: palette,
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.total,
    required this.current,
    required this.palette,
  });

  final int total;
  final int current;
  final ResourcePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (total < 2) return;
    const inset = 10.0;
    final y = size.height / 2;
    final step = (size.width - inset * 2) / (total - 1);
    Offset node(int i) => Offset(inset + step * i, y);

    final solid = Paint()
      ..color = palette.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final dots = Paint()
      ..color = palette.dotted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < total - 1; i++) {
      final a = node(i);
      final b = node(i + 1);
      final control = Offset((a.dx + b.dx) / 2, y + (i.isEven ? -4 : 4));
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);
      if (i < current) {
        canvas.drawPath(path, solid);
      } else {
        for (final metric in path.computeMetrics()) {
          var d = 6.0;
          while (d < metric.length - 6) {
            canvas.drawPath(metric.extractPath(d, d + 0.1), dots);
            d += 5;
          }
        }
      }
    }

    for (var i = 0; i < total; i++) {
      final c = node(i);
      if (i < current) {
        canvas.drawCircle(c, 5, Paint()..color = palette.accent);
      } else if (i == current) {
        canvas.drawCircle(c, 9.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          c,
          9.5,
          Paint()
            ..color = palette.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
        canvas.drawCircle(c, 3.8, Paint()..color = palette.accent);
      } else {
        canvas.drawCircle(c, 5.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          c,
          5.5,
          Paint()
            ..color = palette.dotted
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) =>
      old.current != current || old.total != total;
}

/// Encabezado numerado del paso: número grande, título serif y leyenda
/// («Pantalla 2 de 7»).
class ResourceStepHeading extends StatelessWidget {
  const ResourceStepHeading({
    super.key,
    required this.title,
    required this.palette,
    this.number,
    this.caption,
  });

  final int? number;
  final String title;
  final String? caption;
  final ResourcePalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (number != null) ...[
              ExcludeSemantics(
                child: Text(
                  '$number',
                  style: resourceSerif.copyWith(
                    fontSize: 48,
                    height: 1,
                    color: palette.number,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: number != null ? 4 : 0),
                child: Text(
                  title,
                  style: resourceSerif.copyWith(
                    fontSize: 30,
                    height: 35 / 30,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: ContigoColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Párrafo destacado en serif.
class ResourceLead extends StatelessWidget {
  const ResourceLead(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: resourceSerif.copyWith(
        fontSize: 21,
        height: 31 / 21,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Texto con un fragmento resaltado ([emphasis], si aparece literalmente en
/// [text]) en negrita y [emphasisColor]. El texto no se altera.
class ResourceEmphasisText extends StatelessWidget {
  const ResourceEmphasisText({
    super.key,
    required this.text,
    this.emphasis,
    this.emphasisColor,
    this.style = resourceBody,
    this.italicSerif = false,
  });

  final String text;
  final String? emphasis;
  final Color? emphasisColor;
  final TextStyle style;

  /// Si es `true`, el fragmento se muestra en serif cursiva (en lugar de
  /// negrita).
  final bool italicSerif;

  @override
  Widget build(BuildContext context) {
    final e = emphasis;
    final index = e == null ? -1 : text.indexOf(e);
    if (e == null || index < 0) return Text(text, style: style);
    final emphasisStyle = italicSerif
        ? TextStyle(
            fontFamily: ContigoTheme.displayFontFamily,
            fontFamilyFallback: ContigoTheme.displayFontFallback,
            fontStyle: FontStyle.italic,
            color: emphasisColor,
          )
        : TextStyle(fontWeight: FontWeight.w700, color: emphasisColor);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(text: e, style: emphasisStyle),
          TextSpan(text: text.substring(index + e.length)),
        ],
      ),
    );
  }
}

/// Aviso destacado: fondo suave, ícono en círculo blanco y texto con un
/// fragmento en negrita.
class ResourceCallout extends StatelessWidget {
  const ResourceCallout({
    super.key,
    required this.icon,
    required this.text,
    required this.palette,
    this.emphasis,
  });

  final IconData icon;
  final String text;
  final String? emphasis;
  final ResourcePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 20, 20),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: palette.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ResourceEmphasisText(
              text: text,
              emphasis: emphasis,
              emphasisColor: palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de sección con ícono en círculo y título serif opcionales.
class ResourceCard extends StatelessWidget {
  const ResourceCard({
    super.key,
    required this.children,
    this.title,
    this.icon,
    this.iconColor = const Color(0xFF536B50),
    this.iconBackground = const Color(0xFFE3ECDF),
    this.titleColor,
    this.background = Colors.white,
    this.bordered = true,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 22),
  });

  final String? title;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackground;
  final Color? titleColor;
  final Color background;
  final bool bordered;
  final EdgeInsets padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: bordered ? Border.all(color: const Color(0xFFE8DFD5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 21, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: resourceSerif.copyWith(
                      fontSize: 21,
                      height: 26 / 21,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Lista en tarjeta blanca: un ícono en cuadro suave por elemento.
class ResourceIconList extends StatelessWidget {
  const ResourceIconList({
    super.key,
    required this.items,
    required this.palette,
  });

  final List<(IconData, String)> items;
  final ResourcePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8DFD5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0E8E0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(items[i].$1, size: 20, color: palette.accent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      items[i].$2,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 22 / 15,
                        color: ContigoColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón en pastilla (relleno o con borde).
class ResourcePillButton extends StatelessWidget {
  const ResourcePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    this.outlined = false,
    this.trailingIcon,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool outlined;
  final IconData? trailingIcon;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: ContigoTheme.bodyFontFamily,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 20),
          const SizedBox(width: 10),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 22),
        ],
      ],
    );
    if (outlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.45), width: 1.5),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const StadiumBorder(),
          textStyle: textStyle,
        ),
        onPressed: onPressed,
        child: content,
      );
    }
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const StadiumBorder(),
        textStyle: textStyle,
      ),
      onPressed: onPressed,
      child: content,
    );
  }
}

/// Barra inferior del recurso: volver (circular) y botón principal.
class ResourceBottomBar extends StatelessWidget {
  const ResourceBottomBar({
    super.key,
    required this.palette,
    required this.nextLabel,
    required this.onNext,
    this.onBack,
    this.backTooltip = 'Anterior',
    this.showNextChevron = true,
    this.below,
  });

  final ResourcePalette palette;
  final String nextLabel;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String backTooltip;
  final bool showNextChevron;

  /// Acción adicional bajo la fila (p. ej. «Volver a mi mensaje»).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F3),
        border: Border(top: BorderSide(color: Color(0xFFEDE5DC))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ResourceCircleButton(
                icon: Icons.arrow_back,
                tooltip: backTooltip,
                onPressed: onBack,
                iconColor: palette.primary,
                borderColor: palette.primary.withValues(alpha: 0.3),
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResourcePillButton(
                  label: nextLabel,
                  onPressed: onNext,
                  color: palette.primary,
                  trailingIcon: showNextChevron ? Icons.chevron_right : null,
                ),
              ),
            ],
          ),
          if (below != null) ...[const SizedBox(height: 8), below!],
        ],
      ),
    );
  }
}
