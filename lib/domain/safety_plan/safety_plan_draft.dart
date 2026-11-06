import 'package:equatable/equatable.dart';

/// Contacto del plan de seguridad (portado de `SafetyPlanContact`,
/// `src/safety-plan.ts`). Modelo inmutable con igualdad por valor.
class SafetyPlanContact extends Equatable {
  const SafetyPlanContact({
    required this.name,
    required this.label,
    required this.phone,
  });

  /// Nombre de la persona de contacto.
  final String name;

  /// Etiqueta/relación del contacto (p. ej. "Familiar").
  final String label;

  /// Teléfono del contacto.
  final String phone;

  @override
  List<Object?> get props => [name, label, phone];
}

/// Títulos de los pasos del plan de seguridad, portados verbatim del prototipo
/// (`SAFETY_PLAN_STEP_TITLES`, `src/safety-plan.ts`). El orden se preserva.
const List<String> safetyPlanStepTitles = [
  'Señales y situaciones que reconozco',
  'Lo que puedo hacer por mi cuenta',
  'Personas y lugares que pueden acompañarme',
  'Ayuda profesional y líneas de atención',
];

/// Borrador del plan de seguridad (portado de `SafetyPlanDraft`,
/// `src/safety-plan.ts`).
///
/// Es un borrador **de sesión**: nunca se persiste en el almacenamiento local
/// del mapa del PCS (Requirement 7.1, 7.5). Modelo inmutable; las ediciones
/// producen copias con [copyWith].
class SafetyPlanDraft extends Equatable {
  const SafetyPlanDraft({
    required this.stepTexts,
    required this.contacts,
    required this.activities,
    required this.environment,
  });

  /// Texto por cada paso del plan (misma longitud y orden que
  /// [safetyPlanStepTitles]).
  final List<String> stepTexts;

  /// Contactos de apoyo del plan.
  final List<SafetyPlanContact> contacts;

  /// Actividades que ayudan a la persona.
  final List<String> activities;

  /// Descripción del entorno a asegurar.
  final String environment;

  SafetyPlanDraft copyWith({
    List<String>? stepTexts,
    List<SafetyPlanContact>? contacts,
    List<String>? activities,
    String? environment,
  }) {
    return SafetyPlanDraft(
      stepTexts: stepTexts ?? this.stepTexts,
      contacts: contacts ?? this.contacts,
      activities: activities ?? this.activities,
      environment: environment ?? this.environment,
    );
  }

  @override
  List<Object?> get props => [stepTexts, contacts, activities, environment];
}

/// Crea un borrador del plan de seguridad (portado de `createSafetyPlanDraft`).
///
/// Si [withExampleInformation] es `false` (por defecto) devuelve un borrador
/// vacío con un texto en blanco por cada paso. Si es `true` devuelve los
/// ejemplos ficticios del prototipo, disponibles solo a través de la simulación
/// demo (no son datos reales ni se persisten).
SafetyPlanDraft createSafetyPlanDraft({bool withExampleInformation = false}) {
  if (!withExampleInformation) {
    return SafetyPlanDraft(
      stepTexts: List<String>.filled(safetyPlanStepTitles.length, ''),
      contacts: const [],
      activities: const [],
      environment: '',
    );
  }
  return const SafetyPlanDraft(
    stepTexts: [
      'Me siento abrumada cuando estoy sola por mucho tiempo o cuando no he dormido bien.',
      'Respiración pausada · Caminar en el parque · Escuchar música tranquila',
      '',
      '',
    ],
    contacts: [
      SafetyPlanContact(
        name: 'Mamá',
        label: 'Familiar',
        phone: '+57 300 000 0001',
      ),
      SafetyPlanContact(
        name: 'Jorge',
        label: 'Amigo de confianza',
        phone: '+57 300 000 0002',
      ),
    ],
    activities: ['Caminar juntos en el parque', 'Tomar un café'],
    environment: '',
  );
}

/// `true` si el borrador contiene alguna información (portado de
/// `safetyPlanHasInformation`): algún paso con texto, algún contacto, alguna
/// actividad o un entorno no vacío.
bool safetyPlanHasInformation(SafetyPlanDraft plan) {
  return plan.stepTexts.any((text) => text.trim().isNotEmpty) ||
      plan.contacts.isNotEmpty ||
      plan.activities.isNotEmpty ||
      plan.environment.trim().isNotEmpty;
}

/// Etiqueta del enlace al plan según si ya tiene información (portado de
/// `safetyPlanLinkLabel`, `src/safety-plan-story.ts`).
String safetyPlanLinkLabel(bool hasInformation) {
  return hasInformation
      ? 'Ir a mi plan para desenredar'
      : 'Construir mi plan para desenredar';
}