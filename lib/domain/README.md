# domain

Modelos inmutables + lógica pura + interfaces de repositorio.

El dominio es **Dart puro**: no importa `package:flutter` ni `package:firebase_*`.
Esto mantiene la lógica portada del prototipo testeable con `dart test`.

Contiene:
- Modelos inmutables (`JourneyState`, `EmaDraft`, `SafetyPlanDraft`, `RelationMetrics`, ...).
- Lógica pura (`metricsFor`, `canStrengthenRelationship`, completitud EMA,
  `nextConnectionStep`, elegibilidad de notificaciones).
- Interfaces de repositorio/servicio (`JourneyRepository`, `AuthService`,
  `CaringMessageRepository`, ...).
