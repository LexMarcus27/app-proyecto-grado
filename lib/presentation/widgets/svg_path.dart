import 'dart:ui';

/// Intérprete mínimo de datos de trazado SVG (`d`) para portar a
/// `CustomPainter` las ilustraciones vectoriales del prototipo (plantas del
/// inicio, avatares) sin añadir dependencias.
///
/// Admite los comandos `M m L l H h V v C c S s Z z`, que son los que usan esas
/// ilustraciones. No admite arcos (`A`), cuadráticas (`Q`/`T`).
Path parseSvgPath(String data) {
  final path = Path();
  final tokens = RegExp(r'[MmLlHhVvCcSsZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
      .allMatches(data)
      .map((m) => m.group(0)!)
      .toList();

  var i = 0;
  var command = '';
  var x = 0.0, y = 0.0;
  var startX = 0.0, startY = 0.0;
  double? lastCtrlX, lastCtrlY;

  bool isCommand(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double next() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (isCommand(tokens[i])) {
      command = tokens[i++];
    }
    final rel = command.toLowerCase() == command;
    switch (command.toUpperCase()) {
      case 'M':
        var nx = next(), ny = next();
        if (rel) {
          nx += x;
          ny += y;
        }
        path.moveTo(nx, ny);
        x = startX = nx;
        y = startY = ny;
        lastCtrlX = null;
        // Pares adicionales tras M se interpretan como L.
        command = rel ? 'l' : 'L';
      case 'L':
        var nx = next(), ny = next();
        if (rel) {
          nx += x;
          ny += y;
        }
        path.lineTo(nx, ny);
        x = nx;
        y = ny;
        lastCtrlX = null;
      case 'H':
        var nx = next();
        if (rel) nx += x;
        path.lineTo(nx, y);
        x = nx;
        lastCtrlX = null;
      case 'V':
        var ny = next();
        if (rel) ny += y;
        path.lineTo(x, ny);
        y = ny;
        lastCtrlX = null;
      case 'C':
        var x1 = next(), y1 = next(), x2 = next(), y2 = next();
        var nx = next(), ny = next();
        if (rel) {
          x1 += x;
          y1 += y;
          x2 += x;
          y2 += y;
          nx += x;
          ny += y;
        }
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lastCtrlX = x2;
        lastCtrlY = y2;
        x = nx;
        y = ny;
      case 'S':
        var x2 = next(), y2 = next(), nx = next(), ny = next();
        if (rel) {
          x2 += x;
          y2 += y;
          nx += x;
          ny += y;
        }
        final x1 = lastCtrlX == null ? x : 2 * x - lastCtrlX;
        final y1 = lastCtrlY == null ? y : 2 * y - lastCtrlY;
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lastCtrlX = x2;
        lastCtrlY = y2;
        x = nx;
        y = ny;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        lastCtrlX = null;
      default:
        // Comando no admitido: se descarta el token para no entrar en bucle.
        i++;
    }
  }
  return path;
}
