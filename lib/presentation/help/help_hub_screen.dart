import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../widgets/widgets.dart';

/// Rosa de marca del prototipo (`C.brand`).
const Color _brand = Color(0xFFA85550);
const Color _brandSoft = Color(0xFFF2E3E0);
const Color _critical = Color(0xFFA3474A);
const Color _criticalSoft = Color(0xFFF6E3E2);
const Color _border = Color(0xFFDFD4C9);

/// Centro «¿Qué necesitas ahora?» (M20), portado de `HelpHubScreen`
/// (`src/screens/help-hub.tsx`). Se abre desde el tile «Necesito ayuda» del
/// inicio del PCS y ofrece:
///
/// - «Ver plan de seguridad» → editor del plan (M5).
/// - «Necesito ayuda ahora» → modo crisis (M6).
/// - «Afrontar una crisis» → relato «Las crisis también pasan» (M25).
class HelpHubScreen extends StatelessWidget {
  const HelpHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const StatusBar(),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-8, 0),
                child: IconButton(
                  tooltip: 'Volver al inicio',
                  icon: const Icon(Icons.arrow_back, color: _brand),
                  onPressed: () => context.goBack(AppRoute.pcsHome),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '¿Qué necesitas ahora?',
              style: TextStyle(
                color: ContigoColors.ink,
                fontSize: 27,
                height: 33 / 27,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Elige la opción que te sirva en este momento.',
              style: TextStyle(
                color: ContigoColors.inkMuted,
                fontSize: 15,
                height: 22 / 15,
              ),
            ),
            const SizedBox(height: 28),
            _HelpOption(
              title: 'Ver plan de seguridad',
              description: 'Consulta o prepara tu plan, incluso sin conexión.',
              icon: Icons.shield_outlined,
              onTap: () => context.pushNamed(AppRoute.safetyPlanEditor),
            ),
            _HelpOption(
              title: 'Necesito ayuda ahora',
              description: 'Abre el apoyo inmediato, paso a paso.',
              icon: Icons.support,
              urgent: true,
              onTap: () => context.pushNamed(AppRoute.crisisMode),
            ),
            _HelpOption(
              title: 'Afrontar una crisis',
              description:
                  'Las crisis también pasan. Conoce tu plan para desenredar.',
              icon: Icons.menu_book_outlined,
              onTap: () => context.pushNamed(AppRoute.safetyPlanStory),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpOption extends StatelessWidget {
  const _HelpOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.urgent = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '$title. $description',
        excludeSemantics: true,
        child: Material(
          color: urgent ? _criticalSoft : ContigoColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12_3A3238),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: urgent ? const Color(0xFFF2CECB) : _brandSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: urgent ? _critical : _brand),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: ContigoColors.ink,
                            fontSize: 16,
                            height: 21 / 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: const TextStyle(
                            color: ContigoColors.inkMuted,
                            fontSize: 13,
                            height: 19 / 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _brand),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
