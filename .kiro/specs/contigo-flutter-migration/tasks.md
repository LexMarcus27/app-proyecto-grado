# Implementation Plan: Migración Contigo a Flutter

## Overview

Plan de implementación para migrar el prototipo "Contigo" a una app móvil Flutter con los roles PCS y Cuidador. El trabajo se organiza en cuatro etapas, ejecutadas en estricto orden secuencial: (1) base del proyecto y estilo visual portado del prototipo —completa antes de continuar—, (2) recorrido EMA completo de extremo a extremo con sus dependencias mínimas, (3) los demás módulos, y (4) integración posterior con Firebase.

La arquitectura separa dominio (Dart puro), presentación (Flutter) y acceso a datos (interfaces del dominio con implementaciones simuladas/locales intercambiables por Firebase vía overrides de Riverpod). La lógica de dominio portada reusa las pruebas del prototipo como pruebas de ejemplo en `dart test`; el property-based testing es selectivo (POMP, completitud EMA, autorización por tupla, rotación de pasos de conexión).

Las pruebas portadas de **autorización** y **EMA** son **obligatorias** (sub-pasos no opcionales del portado de dominio). Las pruebas adicionales —property-based testing selectivo y las demás suites portadas (métricas, mensajes, conexión, notificaciones)— se marcan con `*` como opcionales. La etapa Firebase también se marca `*` por depender de decisiones de alcance pendientes.

## Tasks

- [x] 1. Base del proyecto y estilo visual
  - [x] 1.1 Crear el proyecto Flutter y la estructura de carpetas del diseño
    - Inicializar el proyecto Flutter para iOS y Android.
    - Crear las carpetas `lib/domain`, `lib/data`, `lib/presentation`, `lib/app` y `lib/content` conforme a la estructura propuesta en el diseño.
    - Configurar `dart test` como framework de pruebas del dominio.
    - _Requirements: 1.1_

  - [x] 1.2 Agregar dependencias base del proyecto
    - Añadir `flutter_riverpod` (estado + DI), `go_router` (navegación), `equatable` (igualdad por valor de modelos inmutables) y `shared_preferences` (persistencia local inicial).
    - Añadir una librería de property-based testing para Dart en `dev_dependencies` para uso selectivo posterior.
    - _Requirements: 1.1, 1.5_

  - [x] 1.3 Montar el app shell con ProviderScope y go_router
    - Configurar `ProviderScope` en la raíz de la app (`lib/app`).
    - Definir `go_router` con rutas nombradas por pantalla y guardas por rol (PCS/Cuidador), denegando acceso a roles no soportados sin cargar datos de otros roles.
    - Declarar los providers de interfaces de repositorio con `throw UnimplementedError` para ser sobreescritos en la composición de la app.
    - _Requirements: 1.2, 1.3, 1.4_

  - [x] 1.4 Portar el estilo visual del prototipo (tema)
    - Definir el `ThemeData` con la paleta y la tipografía del prototipo.
    - Asegurar que las tarjetas de notificación cumplan contraste WCAG ≥ 4.5:1 entre texto y fondo a nivel de tema.
    - _Requirements: 2.3, 12.5_

  - [x] 1.5 Crear los componentes de UI reutilizables equivalentes al prototipo
    - Implementar StatusBar, botones, tarjetas, CompanionNote y el indicador de simulación persistente (componente que la UI muestra según el metadato de capa por feature).
    - _Requirements: 2.3, 3.4_

  - [x] 1.6 Montar el scaffold de carga de Contenido_Clinico
    - Crear en `lib/content` el mecanismo de carga del Contenido_Clinico verbatim (sin alterar, truncar ni reordenar) y los metadatos de Estado_Validacion_Contenido por tipo de contenido.
    - Registrar que el banco EMA `daily-nine-v2` fue suministrado tras revisión del evaluador y marcar umbrales/cortes como Contenido_Validacion_Pendiente a nivel de metadatos.
    - _Requirements: 2.1, 2.2, 2.4, 2.5, 2.6_

  - [x] 1.7 Importar y cablear los recursos multimedia del prototipo
    - Incorporar al bundle de assets de Flutter los recursos multimedia del prototipo preservándolos verbatim: videos del relato del plan de seguridad "Las crisis también pasan", video(s) de la guía de mensajes de cuidado y la imagen de avatar del acompañante (CompanionNote).
    - Declarar los assets en `pubspec.yaml` y exponerlos desde `lib/content` para que las pantallas narrativas y de guía los consuman sin alterarlos.
    - _Requirements: 2.1, 2.3, 7.6, 8.3_

  - [ ]* 1.8 Prueba de igualdad verbatim del Contenido_Clinico
    - **Property 1: Igualdad verbatim del Contenido_Clinico**
    - **Validates: Requirements 2.1, 2.2**

- [x] 2. Recorrido EMA completo con dependencias mínimas
  - [x] 2.1 Portar el modelo de journey y la autorización mínima para la referencia EMA
    - Portar `Person`/`NetworkPerson`, `CareAssociation` (con `active`) e `InvitationStatus` con sus 6 valores verbatim (not-invited, pending, accepted, declined, cancelled, expired).
    - Portar `canStrengthenRelationship` y `validCaregivers` (necesarios para el gating de referencia EMA).
    - _Requirements: 4.1, 4.2_

  - [x] 2.2 Portar las pruebas de autorización/journey del prototipo (obligatorias)
    - Portar las suites de caregiver/journey del prototipo a `dart test` como pruebas de ejemplo y ejecutarlas en verde.
    - Pruebas obligatorias del portado de dominio de autorización.
    - _Requirements: 4.1, 4.2_

  - [x] 2.3 Portar el dominio EMA (daily-nine-v2)
    - Implementar el banco de 9 ítems verbatim (3 binarios + 2 bloques de 3 rangos), `EmaDraft` (version, day, reference, relationshipOmission, answers, questionIndex, completed) y `EmaReference` con los 4 identificadores.
    - Implementar reglas puras: reinicio de borrador por cambio de día, omisión del bloque de relación, distinción entre omitido / "No" / valor 0, y completitud (completo si y solo si todos los ítems presentados están respondidos). Sin scoring ni selección derivada.
    - _Requirements: 5.1, 5.2, 5.11, 5.12, 5.13, 5.14, 5.15_

  - [x] 2.4 Portar las pruebas EMA del prototipo (obligatorias)
    - Portar las suites EMA del prototipo a `dart test` como pruebas de ejemplo y ejecutarlas en verde.
    - Pruebas obligatorias del portado de dominio EMA.
    - _Requirements: 5.1, 5.11, 5.12, 5.13, 5.14_

  - [ ]* 2.5 Propiedad de completitud del EMA
    - **Property 5: Completitud del EMA** (completo si y solo si todos los ítems presentados tienen respuesta)
    - **Validates: Requirements 5.13, 5.14**

  - [ ]* 2.6 Pruebas de distinción de omisión y reinicio diario
    - **Property 6: Distinción entre omisión y respuesta válida** y **Property 8: Reinicio diario del borrador**
    - **Validates: Requirements 5.11, 5.12**

  - [x] 2.7 Implementar JourneyRepository local y su provider
    - Implementar `JourneyRepository` sobre `shared_preferences` (persiste `JourneyState`), con `watchJourney`, `loadJourney`, `updateAssociations`, `updateInvitationStatus`, `resetDemo`.
    - Registrar el provider de Riverpod y su override con la implementación local.
    - _Requirements: 6.1_

  - [x] 2.8 Implementar EmaReferenceStore (solo IDs) y EmaDraftStore de sesión
    - Implementar `EmaReferenceStore` sobre `shared_preferences` almacenando únicamente identificadores de persona (sin contenido de respuestas) con round-trip de IDs.
    - Implementar `EmaDraftStore` en memoria/sesión con rollover por día y persistencia de avance (`questionIndex`).
    - Registrar sus providers de Riverpod.
    - _Requirements: 6.1, 6.4_

  - [ ]* 2.9 Propiedad de Referencia_EMA solo con identificadores
    - **Property 9: Referencia_EMA solo con identificadores** (round-trip de IDs, sin respuestas EMA)
    - **Validates: Requirements 6.4**

  - [x] 2.10 Crear la sesión demo y los datos semilla para ejercitar el EMA
    - Implementar una sesión demo mínima con datos ficticios (seed) que alimente el `JourneyRepository` local y permita correr el recorrido EMA de extremo a extremo.
    - Incluir al menos dos escenarios demo: (a) CON una persona vinculada activa (invitación `accepted` + asociación `active`) para ejercitar la selección y el bloque de relación, y (b) SIN ninguna persona vinculada activa para ejercitar la omisión del bloque.
    - Exponer el seed vía `resetDemo` para reinicializar los escenarios; estos datos alimentan las pantallas EMA y las pruebas portadas.
    - _Requirements: 5.5, 5.8, 5.10, 6.1_

  - [x] 2.11 Implementar la selección de Referencia_EMA
    - Pantalla de selección que elige una única persona de referencia entre las personas con vínculo activo, presentada solo la primera vez (antes del primer registro) y recordada entre registros.
    - _Requirements: 5.5, 5.6_

  - [x] 2.12 Implementar la revisión de referencia obsoleta
    - Caso sin personas activas: pantalla de revisión con "Ir a Tu mapa de red" (primaria) y "Continuar con el registro de hoy" (secundaria) que omite el bloque de relación solo ese día sin alterar la referencia guardada.
    - Caso con otra persona activa: dirigir a "Tu mapa de red" para confirmar nueva referencia, sin ofrecer la omisión del bloque.
    - _Requirements: 5.7, 5.8, 5.9, 5.10_

  - [ ]* 2.13 Propiedad de omisión por ausencia de vínculo
    - **Property 7: Omisión por ausencia de vínculo preserva la referencia**
    - **Validates: Requirements 5.10**

  - [x] 2.14 Implementar los ítems EMA (rango y binario) con accesibilidad
    - Barra de rango continua con etiquetas solo en los extremos ("Nada cierta"/"Completamente cierta"), sin números visibles, sin preselección, iniciando sin responder.
    - Exponer el valor interno 0–100 a tecnologías de asistencia mediante `Semantics` (teclado, lector de pantalla, puntero) sin mostrarlo como número visible.
    - Ítems binarios Sí/No.
    - _Requirements: 5.3, 5.4, 5.2_

  - [x] 2.15 Implementar la entrada mínima al mapa de red para confirmar referencia
    - Vista mínima del mapa de red suficiente para confirmar/cambiar la Referencia_EMA con confirmación explícita del usuario (el mapa completo y las métricas llegan en la etapa 3). Mantener esta dependencia mínima.
    - Debe estar disponible antes de completar el flujo EMA de extremo a extremo, porque la confirmación de la Referencia_EMA depende de este mapa mínimo.
    - _Requirements: 5.7, 5.9_

  - [x] 2.16 Implementar el primer registro sin persona vinculada (camino sin vínculo)
    - Ejercitar de extremo a extremo el primer registro cuando no existe ninguna persona vinculada activa: la revisión/entrada ofrece "Ir a Tu mapa de red" como acción PRIMARIA y "Continuar con el registro de hoy" como acción SECUNDARIA.
    - Al elegir "Continuar con el registro de hoy", presentar únicamente los 6 ítems restantes (omitir el bloque de relación solo ese día) sin alterar la Referencia_EMA guardada, usando el escenario demo sin vínculo activo.
    - _Requirements: 5.8, 5.10_

  - [x] 2.17 Implementar el flujo EMA de extremo a extremo
    - Progreso por `questionIndex`, bloqueo de cierre mientras haya ítems presentados sin responder, marcado de completitud, reinicio por cambio de día y vista de resultado/siguientes pasos.
    - Cerrar el recorrido EMA de extremo a extremo apoyándose en el mapa mínimo (2.15) para la confirmación de referencia y en los escenarios demo con y sin vínculo activo (2.10).
    - Mantener las respuestas clínicas solo de sesión en modo demo, sin calcular ni mostrar puntuación.
    - Mostrar el indicador de simulación donde aplique.
    - _Requirements: 5.12, 5.13, 5.14, 5.15, 3.4, 6.1_

- [ ] 3. Demás módulos
  - [ ] 3.1 Activación demo y enrutamiento por rol
    - Implementar `AuthService` simulado: convertir a mayúsculas, rechazar códigos < 4 caracteres (permanecer en pantalla con el mensaje de error existente), "C" → Cuidador, otro → PCS, con verificación simulada breve antes de enrutar.
    - Enrutar al inicio según el rol y mostrar indicador de simulación.
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 3.4_

  - [ ]* 3.2 Propiedad de enrutamiento determinista de activación
    - **Property 20: Enrutamiento determinista de activación**
    - **Validates: Requirements 11.2, 11.3, 11.4, 11.5**

  - [ ] 3.3 Implementar el onboarding del PCS
    - Implementar el flujo de onboarding del prototipo con sus estados de recorrido: no iniciado, en progreso y completado, mostrando la bienvenida según corresponda.
    - Ramificar desde el inicio del PCS según el estado de onboarding (coherente con `home.tsx`), persistiendo el estado en el `JourneyState`/almacenamiento local.
    - _Requirements: 1.2, 2.3, 8.7_

  - [ ] 3.4 Implementar el inicio del PCS (home hub de rol)
    - Pantalla de inicio del PCS con tiles de navegación reales (EMA, plan de seguridad, mapa de red, tejiendo vínculos, bandeja de mensajes de cuidado), avatares derivados de `journey.people` y ramificación por estado de onboarding.
    - Presentar la notificación simulada in-app como banner (Funcion_Simulada) con indicador de simulación.
    - _Requirements: 1.2, 2.3, 3.4, 8.7, 8.8_

  - [ ] 3.5 Implementar el inicio del cuidador (home hub con gating)
    - Pantalla de inicio del cuidador con tiles de los seis recorridos; los tiles dependientes de asociación quedan deshabilitados salvo que exista Asociacion_Activa válida (gating por asociación activa como núcleo).
    - Incluir el selector de perfil y el panel demo de simulación de estados ("active" | "accepted-only" | "revoked") para alternar los escenarios de vínculo.
    - _Requirements: 1.2, 2.3, 3.4, 8.1, 8.2_

  - [ ] 3.6 Cablear la lógica de autorización compartida (gating)
    - Conectar `canStrengthenRelationship` a los flujos de conexión del Cuidador y del PCS: deshabilitar acciones de mensaje/contacto/encuentro cuando la tupla exacta (pcsId, caregiverId, personId) no tenga invitación `accepted` y asociación `active`; ocultar contenido de cuidado tras revocación.
    - _Requirements: 4.1, 4.2, 4.5_

  - [ ]* 3.7 Propiedades de autorización y ocultamiento tras revocación
    - **Property 3: Autorización por asociación activa** (PBT, coincidencia exacta de tupla) y **Property 4: Ocultamiento tras revocación**
    - **Validates: Requirements 4.1, 4.2, 4.5, 8.2, 8.10, 10.4, 10.5**

  - [ ] 3.8 Portar el dominio de métricas de red (metricsFor)
    - Implementar `metricsFor` con las fórmulas exactas: `pomp`, `closeness`, `positivity`, `negativity`, `importance`, `finalCloseness`, asignación de anillo y clasificación; exclusión de vínculos sin los 18 ítems sin interrumpir el resto.
    - Marcar cortes y reglas como Contenido_Validacion_Pendiente en metadatos.
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7_

  - [ ]* 3.9 Portar las pruebas de métricas del prototipo
    - Portar las suites de métricas del prototipo a `dart test` como pruebas de ejemplo.
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.7_

  - [ ]* 3.10 Propiedades de POMP y derivaciones
    - **Property 14: Rango y derivaciones de POMP**, **Property 15: finalCloseness no negativo**, **Property 16: Asignación única de anillo**, **Property 17: Asignación única de clasificación**, **Property 18: Exclusión de vínculos con datos insuficientes**
    - **Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 9.7**

  - [ ] 3.11 Implementar la construcción del mapa de red (generador de nombres, evaluación y generateResults)
    - Implementar el flujo completo de construcción/generación del mapa de red del prototipo: preguntas del generador de nombres para capturar personas, evaluación por persona (los 18 ítems de la relación) y `generateResults` que produce los vínculos evaluados a partir de las respuestas.
    - Operar el cómputo de resultados como Funcion_Simulada con indicador de simulación donde aplique; distinto de la entrada mínima al mapa (2.15) y del dominio de métricas (3.8), que alimenta con los datos aquí construidos.
    - _Requirements: 9.1, 9.7, 9.8, 3.4_

  - [ ] 3.12 Implementar el mapa de red completo y los gráficos
    - Pantalla del mapa de red con gráficos de cercanía y calidad en `CustomPainter` alimentados por `metricsFor`.
    - Flujo de invitaciones como Funcion_Simulada (estados pending/accepted/declined solo como datos locales) con indicador de envío simulado.
    - _Requirements: 9.8, 9.9, 9.10, 3.4_

  - [ ] 3.13 Implementar el plan de seguridad
    - Editor sobre `SafetyPlanDraft` (pasos, contactos, actividades, entorno) como borrador de sesión; aislamiento de escenarios demo (modificar uno no altera los demás).
    - Importación de contactos del SO como Funcion_Simulada (permisos fingidos, sin agregar contactos reales) con indicador.
    - Presentar el relato narrativo verbatim (incluidos sus videos) sin alterar ni reordenar.
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [ ]* 3.14 Propiedad de aislamiento entre escenarios del plan
    - **Property 10: Aislamiento entre escenarios de demostración del plan**
    - **Validates: Requirements 7.3**

  - [ ] 3.15 Portar el dominio de mensajes de cuidado
    - Implementar contenido guía verbatim, seguimiento de lectura, preguntas de reflexión, inserción aditiva de ejemplos (añade sin sobrescribir) y `CaringMessageRecord` que conserva identificadores (id, caregiverId, caregiverName, pcsId, pcsName, personId, associationId), texto y estado de entrega, excluyendo notas privadas y preguntas de reflexión.
    - _Requirements: 8.3, 8.4, 8.5_

  - [ ]* 3.16 Portar las pruebas de mensajes de cuidado del prototipo
    - Portar las suites de mensajes de cuidado del prototipo a `dart test` como pruebas de ejemplo.
    - _Requirements: 8.3, 8.4, 8.5_

  - [ ]* 3.17 Propiedades de inserción aditiva y registro sin datos privados
    - **Property 11: Inserción aditiva de ejemplos** y **Property 12: Registro de mensaje de cuidado sin datos privados**
    - **Validates: Requirements 8.4, 8.5**

  - [ ] 3.18 Implementar mensajes de cuidado y bandeja del PCS
    - Pantallas del Cuidador para redactar mensajes de cuidado (envío como Funcion_Simulada con indicador) sobre `CaringMessageRepository`, incluida la guía con su video verbatim.
    - Bandeja de mensajes recibidos del PCS (caring-message inbox) sin gating de Asociacion_Activa.
    - _Requirements: 8.6, 8.8, 8.11, 3.4_

  - [ ] 3.19 Implementar los recorridos del cuidador dependientes de asociación
    - Plan de acompañamiento, registro de vínculo, evaluación de encuentros, mensajes íntimos y preguntas de conexión, todos con gating por Asociacion_Activa (deshabilitados sin tupla válida).
    - Adjuntos de audio/foto como Funcion_Simulada con indicador.
    - _Requirements: 8.1, 8.2, 10.3, 10.4, 10.5, 3.4_

  - [ ] 3.20 Portar el dominio de conexión e implementar "Tejiendo vínculos"
    - Portar `CONNECTION_STEPS` y `nextConnectionStep` (rotación cíclica sin exigir completar el paso actual).
    - Hub de conexión del PCS con pasos mensaje/recibido/contacto/encuentro/habilidades; "Otro paso"/"Un paso para hoy" rota sin completar; acciones dirigidas a persona con gating; bandeja de recibidos sin gating.
    - _Requirements: 8.7, 8.9, 8.10, 8.11_

  - [ ]* 3.21 Portar las pruebas de conexión del prototipo
    - Portar las suites de conexión del prototipo a `dart test` como pruebas de ejemplo.
    - _Requirements: 8.9_

  - [ ]* 3.22 Propiedad de rotación cíclica de pasos de conexión
    - **Property 13: Rotación cíclica de pasos de conexión** (PBT)
    - **Validates: Requirements 8.9**

  - [ ] 3.23 Implementar evaluación de relación y preguntas para conectar
    - Recorrido de pasos en el orden del prototipo, avanzando solo cuando el paso actual esté completo; resultados con indicador de Contenido_Validacion_Pendiente (umbrales no definitivos); adjuntos de audio/foto simulados; gating y bloqueo de acciones sin Asociacion_Activa conservando el estado.
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ]* 3.24 Propiedad de avance monótono de pasos de evaluación
    - **Property 19: Avance monótono de pasos de evaluación**
    - **Validates: Requirements 10.1**

  - [ ] 3.25 Portar el dominio de notificaciones
    - Implementar plantillas y reglas de elegibilidad: sin personas vinculadas activas (`validCaregivers` vacío) solo recordatorios; sustitución del marcador de persona solo por persona vinculada activa; omisión si no existe tal persona.
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

  - [ ]* 3.26 Portar las pruebas de notificaciones del prototipo
    - Portar las suites de notificaciones del prototipo a `dart test` como pruebas de ejemplo.
    - _Requirements: 12.2, 12.3, 12.4_

  - [ ]* 3.27 Propiedades de elegibilidad y resolución del marcador de notificaciones
    - **Property 21: Elegibilidad de notificaciones sin red activa** y **Property 22: Resolución del marcador de persona**
    - **Validates: Requirements 12.2, 12.3, 12.4**

  - [ ] 3.28 Implementar notificaciones simuladas y modo crisis/respiración
    - Pantallas de notificaciones simuladas (sin envíos externos) con tarjetas de contraste WCAG ≥ 4.5:1.
    - Pantallas de modo crisis y respiración con contenido textual verbatim del prototipo.
    - _Requirements: 12.1, 12.5, 12.6_

- [ ]* 4. Integración con Firebase (etapa posterior)
  - [ ]* 4.1 Agregar dependencias y configuración de Firebase
    - Añadir las dependencias de Firebase (Auth, Firestore) y la configuración de proyecto para iOS/Android.
    - _Requirements: 1.6, 3.5_

  - [ ]* 4.2 Implementar los repositorios sobre Firebase tras las mismas interfaces
    - Implementar `AuthService` sobre Firebase Auth (autenticación real que determine el rol) y `JourneyRepository`/`CaringMessageRepository`/demás sobre Firestore, intercambiados vía overrides de Riverpod sin tocar las pantallas; retirar el indicador de simulación al promover cada feature a Capa_Firebase.
    - Depende de las decisiones abiertas de modelo de datos, identidad y sincronización.
    - _Requirements: 1.6, 3.5, 3.6, 11.6, 11.7_

  - [ ]* 4.3 Implementar y probar las reglas de seguridad de Firestore
    - Reglas de seguridad que apliquen la autorización por Asociacion_Activa del lado servidor (rechazar operaciones de cuidado sin tupla exacta con invitación `accepted` y asociación `active`), con independencia del estado del cliente.
    - Añadir unos pocos escenarios de integración representativos.
    - Depende de la decisión abierta de reglas de seguridad y modelo de datos.
    - _Requirements: 4.3, 4.4_

## Notes

- **Pruebas obligatorias vs. opcionales.** Las pruebas portadas de **autorización** (2.2) y **EMA** (2.4) son **obligatorias**: son sub-pasos no opcionales del portado de dominio y deben quedar en verde. Las **pruebas adicionales son opcionales** (marcadas con `*`): el property-based testing selectivo (POMP, completitud EMA, autorización por tupla, rotación de pasos de conexión) y las demás suites portadas (métricas 3.9, mensajes 3.16, conexión 3.21, notificaciones 3.26).
- La etapa Firebase (4) también se marca `*` por depender de decisiones de alcance pendientes.
- El testing sigue la estrategia simplificada: portar las suites de dominio del prototipo como pruebas de ejemplo (autorización y EMA obligatorias; el resto opcional), y PBT selectivo solo en POMP, completitud EMA, autorización por tupla y rotación de pasos de conexión.
- **El orden entre etapas es estricto:** la etapa 1 (base y estilo) se completa por entero antes de la etapa 2 (EMA de extremo a extremo), que se completa antes de la etapa 3 (demás módulos), que precede a la etapa 4 (Firebase).
- Dentro de la etapa 2, la entrada mínima al mapa de red (2.15) va **antes** del cierre del flujo EMA de extremo a extremo (2.17), porque confirmar la Referencia_EMA requiere tener disponible el mapa mínimo.
- La sesión demo con datos semilla (2.10) provee los escenarios CON y SIN vínculo activo que alimentan las pantallas EMA, el primer registro sin vínculo (2.16) y las pruebas portadas.
- **Refinamientos de la Etapa 2 (correcciones del flujo EMA).** Se reconcilia el borrador en curso al cambiar de referencia desde el mapa (reinicia solo el bloque de relación; conserva registros completados u omitidos); se reevalúa el vínculo en vivo durante el cuestionario y, ante revocación, se muestra la revisión de referencia obsoleta bloqueando la continuación del registro de relación; el reinicio por cambio de día también se aplica al reanudar un registro abierto; se restauró el estilo EMA del prototipo (#3174A1, banner de hilos, deslizador con indicador tras responder sin preselección/números visibles, pastillas y botón primario azul); y se añadieron controles de demostración (`/demo`, alcanzables desde la activación como la galería) para alternar escenarios con/sin vínculo. La revisión visual en el emulador se hace aparte.
- La etapa Firebase se enchufa sobreescribiendo providers de Riverpod sin modificar pantallas.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["1.3", "1.4", "1.6", "1.7"] },
    { "id": 3, "tasks": ["1.5", "1.8"] },
    { "id": 4, "tasks": ["2.1", "2.3"] },
    { "id": 5, "tasks": ["2.2", "2.4", "2.5", "2.6", "2.7", "2.8"] },
    { "id": 6, "tasks": ["2.9", "2.10"] },
    { "id": 7, "tasks": ["2.11", "2.12", "2.14", "2.15"] },
    { "id": 8, "tasks": ["2.13", "2.16"] },
    { "id": 9, "tasks": ["2.17"] },
    { "id": 10, "tasks": ["3.1", "3.8", "3.13", "3.25"] },
    { "id": 11, "tasks": ["3.2", "3.3", "3.5", "3.6", "3.9", "3.14", "3.15", "3.20", "3.26", "3.28"] },
    { "id": 12, "tasks": ["3.4", "3.7", "3.10", "3.11", "3.16", "3.17", "3.18", "3.21", "3.22", "3.27"] },
    { "id": 13, "tasks": ["3.12", "3.19", "3.23"] },
    { "id": 14, "tasks": ["3.24"] },
    { "id": 15, "tasks": ["4.1"] },
    { "id": 16, "tasks": ["4.2"] },
    { "id": 17, "tasks": ["4.3"] }
  ]
}
```

