import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../content/app_media.dart';

/// Nota del acompañante equivalente al componente `CompanionNote` del prototipo
/// (`src/components/companion-note.tsx`).
///
/// Reproduce la maqueta del prototipo: a la izquierda, el avatar del
/// acompañante; a la derecha, una "nube" blanca con el mensaje, alineados por la
/// base. El avatar se toma **siempre** de [AppMedia.companionAvatar] (nunca de
/// un literal de ruta), coherente con el registro de medios (tarea 1.7) y el
/// Requirement 2.3/8.3. Los colores salen del tema ([ContigoColors]).
///
/// El avatar es decorativo (`aria-hidden` en el prototipo); aquí se excluye de
/// la semántica para que el lector de pantalla lea solo el contenido del
/// mensaje.
/// Expresiones del avatar del acompañante del prototipo (lámina de sprites):
/// bienvenida, pensativa y afecto (`caring-avatar--welcome/--thoughtful/
/// --affection`).
enum CompanionExpression { welcome, thoughtful, affection }
class CompanionNote extends StatelessWidget {
  const CompanionNote({
    super.key,
    required this.child,
    this.affection = false,
    this.expression,
  });

  /// Contenido del mensaje mostrado dentro de la nube.
  final Widget child;

  /// Atajo histórico para la pose de afecto. Si [expression] no se indica,
  /// `affection: true` equivale a [CompanionExpression.affection] y `false` a
  /// [CompanionExpression.welcome]. Se conserva por compatibilidad.
  final bool affection;

  /// Expresión del avatar del prototipo: bienvenida, pensativa (thoughtful) o
  /// afecto. Si se indica, tiene prioridad sobre [affection]. Mantiene las tres
  /// expresiones acordadas del prototipo.
  final CompanionExpression? expression;

  CompanionExpression get _expression =>
      expression ??
      (affection
          ? CompanionExpression.affection
          : CompanionExpression.welcome);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ExcludeSemantics(child: _CompanionAvatar(expression: _expression)),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
              decoration: const BoxDecoration(
                color: ContigoColors.surface,
                // Nube con esquina inferior izquierda marcada (24 24 24 5),
                // como en `.pcs-companion-cloud`.
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x06_5B3F2B),
                    blurRadius: 14,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: DefaultTextStyle.merge(
                style:
                    Theme.of(context).textTheme.bodyMedium ??
                    const TextStyle(color: ContigoColors.ink),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pose del avatar recortada de la lámina de sprites.
///
/// El avatar (`assets/media/caring-messages/avatar.png`) es una **lámina de
/// sprites** de 269×179 px con varias poses. El prototipo recorta una ventana
/// fija escalando la lámina completa (`background-size`) y desplazándola
/// (`background-position`); ver `.pcs-companion-note .caring-avatar--welcome` y
/// `--affection` en `src/index.css` (regla de la vista del PCS, líneas 699-700).
///
/// Cada pose define: el tamaño de la **ventana** visible (dstRect), el tamaño
/// al que la lámina completa se escala (`background-size`) y el **offset**
/// (`background-position`). De ahí se derivan el rectángulo fuente a recortar y
/// su escala:
///
/// ```
/// scale = bgSizeW / sheetW
/// srcX  = (-bgPosX) / scale
/// srcY  = (-bgPosY) / scale
/// srcW  = windowW   / scale
/// srcH  = windowH   / scale
/// ```
@immutable
class _SpritePose {
  const _SpritePose({
    required this.windowWidth,
    required this.windowHeight,
    required this.bgSizeWidth,
    required this.bgSizeHeight,
    required this.bgPosX,
    required this.bgPosY,
  });

  /// Pose de bienvenida: ventana 62×65; `background-size: 146px 97px`;
  /// `background-position: 0 0`.
  static const welcome = _SpritePose(
    windowWidth: 62,
    windowHeight: 65,
    bgSizeWidth: 146,
    bgSizeHeight: 97,
    bgPosX: 0,
    bgPosY: 0,
  );

  /// Pose de afecto: ventana 62×60; `background-size: 296px 197px`;
  /// `background-position: -238.7px -13.2px`.
  static const affection = _SpritePose(
    windowWidth: 62,
    windowHeight: 60,
    bgSizeWidth: 296,
    bgSizeHeight: 197,
    bgPosX: -238.7,
    bgPosY: -13.2,
  );

  /// Pose pensativa (`--thoughtful`): ventana 66×82; `background-size:
  /// 376.6px 250.6px`; `background-position: -165.2px -12.6px` (de la lámina de
  /// la burbuja del prototipo, `.caring-avatar--thoughtful`).
  static const thoughtful = _SpritePose(
    windowWidth: 66,
    windowHeight: 82,
    bgSizeWidth: 376.6,
    bgSizeHeight: 250.6,
    bgPosX: -165.2,
    bgPosY: -12.6,
  );

  final double windowWidth;
  final double windowHeight;
  final double bgSizeWidth;
  final double bgSizeHeight;
  final double bgPosX;
  final double bgPosY;

  /// Tamaño de la ventana (destino del recorte).
  Size get window => Size(windowWidth, windowHeight);

  /// Rectángulo fuente a recortar de la lámina de [sheetSize], en píxeles de la
  /// propia lámina, reproduciendo exactamente el recorte CSS del prototipo.
  Rect sourceRect(Size sheetSize) {
    final double scale = bgSizeWidth / sheetSize.width;
    final double srcX = -bgPosX / scale;
    final double srcY = -bgPosY / scale;
    final double srcW = windowWidth / scale;
    final double srcH = windowHeight / scale;
    return Rect.fromLTWH(srcX, srcY, srcW, srcH);
  }
}

/// Avatar del acompañante. El prototipo usa una lámina de sprites con ventanas
/// (`background-size` + `background-position`) para recortar una pose concreta,
/// NO un `cover` de la lámina completa. Aquí se replica fielmente cargando la
/// lámina a una [ui.Image] y pintando solo el rectángulo fuente de la pose en la
/// ventana destino con [Canvas.drawImageRect], preservando el arte suministrado
/// sin distorsión (la relación de aspecto de cada sprite se respeta porque el
/// recorte deriva de las mismas fórmulas del CSS).
class _CompanionAvatar extends StatefulWidget {
  const _CompanionAvatar({required this.expression});

  final CompanionExpression expression;

  @override
  State<_CompanionAvatar> createState() => _CompanionAvatarState();
}

class _CompanionAvatarState extends State<_CompanionAvatar> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  _SpritePose get _pose {
    switch (widget.expression) {
      case CompanionExpression.welcome:
        return _SpritePose.welcome;
      case CompanionExpression.thoughtful:
        return _SpritePose.thoughtful;
      case CompanionExpression.affection:
        return _SpritePose.affection;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  void _resolveImage() {
    const provider = AssetImage(AppMedia.companionAvatar);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;

    final oldListener = _listener;
    if (oldListener != null) {
      _stream?.removeListener(oldListener);
    }

    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) {
          info.image.dispose();
          return;
        }
        setState(() {
          _image?.dispose();
          _image = info.image;
        });
      },
      // Si el asset no está disponible (p. ej. entorno de prueba sin bundle),
      // se conserva el fallback: una ventana vacía, sin lanzar.
      onError: (Object error, StackTrace? stackTrace) {
        if (!mounted) return;
        setState(() => _image = null);
      },
    );

    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) {
      _stream?.removeListener(listener);
    }
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pose = _pose;
    final image = _image;

    // Fallback grácil: sin imagen cargada, se reserva la ventana sin pintar.
    if (image == null) {
      return SizedBox.fromSize(size: pose.window);
    }

    // Fondo del entorno del componente: CompanionNote se dibuja sobre el lienzo
    // del Scaffold. Se resuelve del tema para que la mezcla multiply no
    // dependa de las capas que haya debajo durante el scroll (ver [_SpritePainter]).
    final background =
        Theme.of(context).scaffoldBackgroundColor == Colors.transparent
        ? ContigoColors.canvas
        : Theme.of(context).scaffoldBackgroundColor;

    return SizedBox.fromSize(
      size: pose.window,
      child: ClipRect(
        child: CustomPaint(
          size: pose.window,
          painter: _SpritePainter(
            image: image,
            pose: pose,
            background: background,
          ),
        ),
      ),
    );
  }
}

/// Pinta el rectángulo fuente de la pose sobre la ventana destino, replicando el
/// recorte del prototipo con [Canvas.drawImageRect] (no `BoxFit.cover`).
class _SpritePainter extends CustomPainter {
  _SpritePainter({
    required this.image,
    required this.pose,
    required this.background,
  });

  final ui.Image image;
  final _SpritePose pose;

  /// Color de fondo del entorno del componente. `avatar.png` tiene fondo
  /// blanco opaco y el dibujo usa `BlendMode.multiply` para fundir ese blanco
  /// con el lienzo cálido. Si el `multiply` se aplicara directamente sobre el
  /// canvas, el resultado dependería de lo que hubiera pintado debajo y, durante
  /// el scroll, el fondo del avatar parpadearía en blanco. Por eso aquí se pinta
  /// primero este color y la mezcla se compone **dentro del mismo dibujo**,
  /// de forma determinista e independiente de otras capas.
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final Size sheetSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final Rect src = pose.sourceRect(sheetSize);
    final Rect dst = Offset.zero & size;

    // Capa aislada acotada a la ventana: todo lo que se pinte dentro se compone
    // entre sí (fondo + mezcla) y no con lo que haya debajo en el canvas.
    canvas.saveLayer(dst, Paint());

    // 1) Fondo opaco del entorno (lienzo cálido): base conocida de la mezcla.
    canvas.drawRect(dst, Paint()..color = background);

    // 2) Avatar recortado, fundido con multiply sobre ese fondo conocido.
    //    (El prototipo usa mix-blend-mode: multiply;
    //    .pcs-companion-note .caring-avatar, src/index.css línea 560.)
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.high
        ..blendMode = BlendMode.multiply,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpritePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.pose != pose ||
      oldDelegate.background != background;
}

