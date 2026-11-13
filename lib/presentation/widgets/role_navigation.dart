import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';

/// Pestaña de una navegación inferior por rol.
class _Tab {
  const _Tab(this.label, this.icon, this.onTap, {this.current = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool current;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.activeColor,
    required this.semanticLabel,
  });

  final List<_Tab> tabs;
  final Color activeColor;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        decoration: const BoxDecoration(
          color: ContigoColors.surface,
          border: Border(top: BorderSide(color: Color(0xFFE8DED8))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
            child: Row(
              children: [
                for (final tab in tabs)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: tab.current,
                      label: tab.label,
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: tab.current ? null : tab.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab.icon,
                                size: 24,
                                color: tab.current
                                    ? activeColor
                                    : const Color(0xFF626169),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 17 / 12,
                                  fontWeight: tab.current
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: tab.current
                                      ? activeColor
                                      : const Color(0xFF626169),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navegación inferior del inicio del PCS (`HomeBottomNav`, `home.tsx`):
/// Inicio, Vínculos (Tejiendo vínculos), Mi día (registro EMA) y Perfil
/// (hoja sencilla, [onProfile]).
class PcsBottomNav extends StatelessWidget {
  const PcsBottomNav({super.key, required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return _BottomNav(
      semanticLabel: 'Navegación principal',
      activeColor: ContigoColors.violet,
      tabs: [
        _Tab('Inicio', Icons.home_outlined, () {}, current: true),
        _Tab('Vínculos', Icons.all_inclusive,
            () => context.goNamed(AppRoute.connectionHub)),
        _Tab('Mi día', Icons.calendar_today_outlined,
            () => context.goNamed(AppRoute.ema)),
        _Tab('Perfil', Icons.person_outline, onProfile),
      ],
    );
  }
}

/// Pestañas del cuidador.
enum CaregiverTab { inicio, aprender, vinculos, perfil }

/// Navegación inferior del cuidador (`CaregiverBottomNav`, `ui.tsx`): Inicio,
/// Aprender, Vínculos y Perfil.
class CaregiverBottomNav extends StatelessWidget {
  const CaregiverBottomNav({super.key, required this.active});

  final CaregiverTab active;

  @override
  Widget build(BuildContext context) {
    return _BottomNav(
      semanticLabel: 'Navegación del cuidador',
      activeColor: ContigoColors.sage,
      tabs: [
        _Tab('Inicio', Icons.home_outlined,
            () => context.goNamed(AppRoute.caregiverHome),
            current: active == CaregiverTab.inicio),
        _Tab('Aprender', Icons.menu_book_outlined,
            () => context.goNamed(AppRoute.caregiverLearning),
            current: active == CaregiverTab.aprender),
        _Tab('Vínculos', Icons.link,
            () => context.goNamed(AppRoute.caregiverConnections),
            current: active == CaregiverTab.vinculos),
        _Tab('Perfil', Icons.person_outline,
            () => context.goNamed(AppRoute.caregiverProfile),
            current: active == CaregiverTab.perfil),
      ],
    );
  }
}
