import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// Widget raíz de la App_Contigo.
///
/// Monta `MaterialApp.router` con el `go_router` de [routerProvider] y el
/// `ThemeData` portado del prototipo ([ContigoTheme.light]), que fija la paleta
/// y la tipografía del prototipo (Requirement 2.3) y el contraste WCAG de las
/// tarjetas de notificación (Requirement 12.5).
class ContigoApp extends ConsumerWidget {
  const ContigoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Contigo',
      theme: ContigoTheme.light(),
      routerConfig: router,
    );
  }
}
