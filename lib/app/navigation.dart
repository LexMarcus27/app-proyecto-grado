import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navegación de retorno común a las pantallas internas.
///
/// Las pantallas que se abren desde otra (inicio, «Conexión con…», centro de
/// ayuda…) se empujan con `pushNamed`, de modo que la flecha de volver regresa
/// a la última pantalla visitada. Si no hay historial (se llegó con `goNamed`,
/// por ejemplo desde la navegación inferior o un enlace directo), se va al
/// destino natural [fallbackRoute].
extension BackNavigation on BuildContext {
  void goBack(
    String fallbackRoute, {
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    if (canPop()) {
      pop();
    } else {
      goNamed(fallbackRoute, queryParameters: queryParameters);
    }
  }
}
