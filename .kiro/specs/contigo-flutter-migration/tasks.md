# Implementation Plan: Migración Contigo a Flutter

> **Estado del envío del 5 de noviembre de 2026:** la última ola implementada es
> **Wave 12 (3.4, 3.11, 3.18), aún NO VERIFICADA** de forma independiente ni
> manualmente en Android. Las casillas de esas tareas indican implementación,
> no aprobación. Kiro reporta análisis limpio y 275 pruebas; este envío no los
> reproduce. La verificación manual solicitada de Wave 11 ya se completó.
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
  - [x] 3.1 Activación demo y enrutamiento por rol
    - Implementar `AuthService` simulado: convertir a mayúsculas, rechazar códigos < 4 caracteres (permanecer en pantalla con el mensaje de error existente), "C" → Cuidador, otro → PCS, con verificación simulada breve antes de enrutar.
    - Enrutar al inicio según el rol y mostrar indicador de simulación.
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 3.4_

  - [ ]* 3.2 Propiedad de enrutamiento determinista de activación
    - **Property 20: Enrutamiento determinista de activación**
    - **Validates: Requirements 11.2, 11.3, 11.4, 11.5**

  - [x] 3.3 Implementar el onboarding del PCS
    - Implementar el flujo de onboarding del prototipo con sus estados de recorrido: no iniciado, en progreso y completado, mostrando la bienvenida según corresponda.
    - Ramificar desde el inicio del PCS según el estado de onboarding (coherente con `home.tsx`), persistiendo el estado en el `JourneyState`/almacenamiento local.
    - _Requirements: 1.2, 2.3, 8.7_

  - [x] 3.4 Implementar el inicio del PCS (home hub de rol)
    - Pantalla de inicio del PCS con tiles de navegación reales (EMA, plan de seguridad, mapa de red, tejiendo vínculos, bandeja de mensajes de cuidado), avatares derivados de `journey.people` y ramificación por estado de onboarding.
    - Presentar la notificación simulada in-app como banner (Funcion_Simulada) con indicador de simulación.
    - _Requirements: 1.2, 2.3, 3.4, 8.7, 8.8_

  - [x] 3.5 Implementar el inicio del cuidador (home hub con gating)
    - Pantalla de inicio del cuidador con tiles de los seis recorridos; los tiles dependientes de asociación quedan deshabilitados salvo que exista Asociacion_Activa válida (gating por asociación activa como núcleo).
    - Incluir el selector de perfil y el panel demo de simulación de estados ("active" | "accepted-only" | "revoked") para alternar los escenarios de vínculo.
    - _Requirements: 1.2, 2.3, 3.4, 8.1, 8.2_

  - [x] 3.6 Cablear la lógica de autorización compartida (gating)
    - Conectar `canStrengthenRelationship` a los flujos de conexión del Cuidador y del PCS: deshabilitar acciones de mensaje/contacto/encuentro cuando la tupla exacta (pcsId, caregiverId, personId) no tenga invitación `accepted` y asociación `active`; ocultar contenido de cuidado tras revocación.
    - _Requirements: 4.1, 4.2, 4.5_

  - [ ]* 3.7 Propiedades de autorización y ocultamiento tras revocación
    - **Property 3: Autorización por asociación activa** (PBT, coincidencia exacta de tupla) y **Property 4: Ocultamiento tras revocación**
    - **Validates: Requirements 4.1, 4.2, 4.5, 8.2, 8.10, 10.4, 10.5**

  - [x] 3.8 Portar el dominio de métricas de red (metricsFor)
    - Implementar `metricsFor` con las fórmulas exactas: `pomp`, `closeness`, `positivity`, `negativity`, `importance`, `finalCloseness`, asignación de anillo y clasificación; exclusión de vínculos sin los 18 ítems sin interrumpir el resto.
    - Marcar cortes y reglas como Contenido_Validacion_Pendiente en metadatos.
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7_

  - [ ]* 3.9 Portar las pruebas de métricas del prototipo
    - Portar las suites de métricas del prototipo a `dart test` como pruebas de ejemplo.
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.7_

  - [ ]* 3.10 Propiedades de POMP y derivaciones
    - **Property 14: Rango y derivaciones de POMP**, **Property 15: finalCloseness no negativo**, **Property 16: Asignación única de anillo**, **Property 17: Asignación única de clasificación**, **Property 18: Exclusión de vínculos con datos insuficientes**
    - **Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 9.7**

  - [x] 3.11 Implementar la construcción del mapa de red (generador de nombres, evaluación y generateResults)
    - Implementar el flujo completo de construcción/generación del mapa de red del prototipo: preguntas del generador de nombres para capturar personas, evaluación por persona (los 18 ítems de la relación) y `generateResults` que produce los vínculos evaluados a partir de las respuestas.
    - Operar el cómputo de resultados como Funcion_Simulada con indicador de simulación donde aplique; distinto de la entrada mínima al mapa (2.15) y del dominio de métricas (3.8), que alimenta con los datos aquí construidos.
    - _Requirements: 9.1, 9.7, 9.8, 3.4_

  - [x] 3.12 Implementar el mapa de red completo y los gráficos
    - Pantalla del mapa de red con gráficos de cercanía y calidad en `CustomPainter` alimentados por `metricsFor`.
    - Flujo de invitaciones como Funcion_Simulada (estados pending/accepted/declined solo como datos locales) con indicador de envío simulado.
    - _Requirements: 9.8, 9.9, 9.10, 3.4_

  - [x] 3.13 Implementar el plan de seguridad
    - Editor sobre `SafetyPlanDraft` (pasos, contactos, actividades, entorno) como borrador de sesión; aislamiento de escenarios demo (modificar uno no altera los demás).
    - Importación de contactos del SO como Funcion_Simulada (permisos fingidos, sin agregar contactos reales) con indicador.
    - Presentar el relato narrativo verbatim (incluidos sus videos) sin alterar ni reordenar.
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [ ]* 3.14 Propiedad de aislamiento entre escenarios del plan
    - **Property 10: Aislamiento entre escenarios de demostración del plan**
    - **Validates: Requirements 7.3**

  - [x] 3.15 Portar el dominio de mensajes de cuidado
    - Implementar contenido guía verbatim, seguimiento de lectura, preguntas de reflexión, inserción aditiva de ejemplos (añade sin sobrescribir) y `CaringMessageRecord` que conserva identificadores (id, caregiverId, caregiverName, pcsId, pcsName, personId, associationId), texto y estado de entrega, excluyendo notas privadas y preguntas de reflexión.
    - _Requirements: 8.3, 8.4, 8.5_

  - [ ]* 3.16 Portar las pruebas de mensajes de cuidado del prototipo
    - Portar las suites de mensajes de cuidado del prototipo a `dart test` como pruebas de ejemplo.
    - _Requirements: 8.3, 8.4, 8.5_

  - [ ]* 3.17 Propiedades de inserción aditiva y registro sin datos privados
    - **Property 11: Inserción aditiva de ejemplos** y **Property 12: Registro de mensaje de cuidado sin datos privados**
    - **Validates: Requirements 8.4, 8.5**

  - [x] 3.18 Implementar mensajes de cuidado y bandeja del PCS
    - Pantallas del Cuidador para redactar mensajes de cuidado (envío como Funcion_Simulada con indicador) sobre `CaringMessageRepository`, incluida la guía con su video verbatim.
    - Bandeja de mensajes recibidos del PCS (caring-message inbox) sin gating de Asociacion_Activa.
    - _Requirements: 8.6, 8.8, 8.11, 3.4_

  - [x] 3.19 Implementar los recorridos del cuidador dependientes de asociación
    - Plan de acompañamiento, registro de vínculo, evaluación de encuentros, mensajes íntimos y preguntas de conexión, todos con gating por Asociacion_Activa (deshabilitados sin tupla válida).
    - Adjuntos de audio/foto como Funcion_Simulada con indicador.
    - _Requirements: 8.1, 8.2, 10.3, 10.4, 10.5, 3.4_

  - [x] 3.20 Portar el dominio de conexión e implementar "Tejiendo vínculos"
    - Portar `CONNECTION_STEPS` y `nextConnectionStep` (rotación cíclica sin exigir completar el paso actual).
    - Hub de conexión del PCS con pasos mensaje/recibido/contacto/encuentro/habilidades; "Otro paso"/"Un paso para hoy" rota sin completar; acciones dirigidas a persona con gating; bandeja de recibidos sin gating.
    - _Requirements: 8.7, 8.9, 8.10, 8.11_

  - [ ]* 3.21 Portar las pruebas de conexión del prototipo
    - Portar las suites de conexión del prototipo a `dart test` como pruebas de ejemplo.
    - _Requirements: 8.9_

  - [ ]* 3.22 Propiedad de rotación cíclica de pasos de conexión
    - **Property 13: Rotación cíclica de pasos de conexión** (PBT)
    - **Validates: Requirements 8.9**

  - [x] 3.23 Implementar evaluación de relación y preguntas para conectar
    - Recorrido de pasos en el orden del prototipo, avanzando solo cuando el paso actual esté completo; resultados con indicador de Contenido_Validacion_Pendiente (umbrales no definitivos); adjuntos de audio/foto simulados; gating y bloqueo de acciones sin Asociacion_Activa conservando el estado.
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ]* 3.24 Propiedad de avance monótono de pasos de evaluación
    - **Property 19: Avance monótono de pasos de evaluación**
    - **Validates: Requirements 10.1**

  - [x] 3.25 Portar el dominio de notificaciones
    - Implementar plantillas y reglas de elegibilidad: sin personas vinculadas activas (`validCaregivers` vacío) solo recordatorios; sustitución del marcador de persona solo por persona vinculada activa; omisión si no existe tal persona.
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

  - [ ]* 3.26 Portar las pruebas de notificaciones del prototipo
    - Portar las suites de notificaciones del prototipo a `dart test` como pruebas de ejemplo.
    - _Requirements: 12.2, 12.3, 12.4_

  - [ ]* 3.27 Propiedades de elegibilidad y resolución del marcador de notificaciones
    - **Property 21: Elegibilidad de notificaciones sin red activa** y **Property 22: Resolución del marcador de persona**
    - **Validates: Requirements 12.2, 12.3, 12.4**

  - [x] 3.28 Implementar notificaciones simuladas y modo crisis/respiración
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
- **Verificación de la Etapa 2 (hallazgos E2-01 a E2-04 corregidos).** E2-01: `EmaFlowScreen` registra un `WidgetsBindingObserver` en `initState` (y lo retira en `dispose`); al recibir `AppLifecycleState.resumed` reevalúa el día, y el día también se comprueba antes de avanzar en el EMA. Si el día cambió, el registro se reinicia a un borrador fresco sin heredar respuestas ni omisión, y un registro completado del día anterior deja de mostrarse como el de hoy. Se comprueba con la MISMA pantalla montada entregando el evento de reanudación (sin desmontar ni reabrir), tanto para un borrador incompleto como para uno completado de ayer. E2-02: desde la revisión de referencia, "Ir a Tu mapa de red" abre y permanece en el mapa (ya no termina en Inicio PCS). E2-03: acceso visible al mapa mínimo desde Inicio PCS y desde el cuestionario para cambiar la referencia activa, conservando la confirmación explícita. E2-04: pregunta del EMA en la serif de títulos (Lora, ~29/35), indicador de avance con hilos curvos (no puntos) y barra de estado ficticia "9:41" desactivada en móvil nativo (se usa la del sistema). Se añadieron pruebas puntuales (reanudación con cambio de día en pantalla montada, y navegación de la revisión al mapa) y se incorporó la verificación externa en `test/stage2/` conservando sus expectativas. Revisión manual en el emulador aparte.
- **Etapa 3, Wave 10 (3.1, 3.8, 3.13, 3.25): implementación terminada; verificación manual de 3.13 pendiente.** Implementación completa y en verde (lutter analyze limpio; 211 pruebas pasan, incluida la verificación externa de Wave 10 incorporada en 	est/stage3/ conservando sus expectativas). 3.1, 3.8 y 3.25 quedan verificados en su alcance. Para 3.13, la **implementación está terminada** pero la **verificación manual en Android del recorrido relato → editor sigue pendiente** (reproducción de video, pausa y detención de audio en un entorno Android estable). Hallazgos de implementación del informe corregidos: **E3-W10-01** entrada temporal y visible desde Inicio PCS al relato del plan ("Ir a mi plan para desenredar"), hasta el home real del PCS (3.4); **E3-W10-02** la navegación inferior del relato ya cabe al ancho del teléfono: ContigoButton envuelve su etiqueta (texto flexible, centrado, multilínea) y crece en alto en vez de recortar, conservando completas y legibles "Construir mi plan para desenredar" e "Ir a mi plan para desenredar" (revisados los usos existentes del botón, sin regresiones); **E3-W10-03** StoryVideo muestra el respaldo de inmediato cuando falla la creación nativa del reproductor, sin esperar un dispose() que podría no completar, conservando la limpieza de recursos en segundo plano y el control de errores asíncronos. **No corregido (incidencia del entorno, causa desconocida):** los cierres de QEMU (**E3-W10-04**) no se tratan como resueltos y no se cambió de forma permanente el motor gráfico; los MP4 del bundle se conservan idénticos a los del prototipo (mismo SHA-256). Queda repetir la comprobación manual relato → editor en Android.
- **Etapa 3, Wave 11 (3.3, 3.5, 3.6, 3.15, 3.20, 3.28): implementación terminada; verificación manual en Android pendiente.** Implementación completa y en verde (lutter analyze limpio; 249 pruebas pasan). 3.6: capa de autorización/gating compartida (CareGating + providers) derivada de canStrengthenRelationship, que deshabilita acciones y oculta contenido de cuidado tras revocación. 3.15: dominio de mensajes de cuidado (borrador de sesión, inserción aditiva, registro sin notas privadas ni preguntas, visibilidad por vínculo) y contenido educativo verbatim en lib/content. 3.3: onboarding del PCS (bienvenida, transiciones not-started/in-progress/deferred persistidas, ramificación) con pantalla y entrada temporal desde Inicio PCS. 3.5: inicio del cuidador con gating (tiles dependientes de asociación deshabilitados sin vínculo activo, selector de perfil y panel demo active/accepted-only/revoked); conserva el rótulo "Inicio Cuidador". 3.20: dominio de conexión (rotación cíclica
extConnectionStep, connectionLaunch con gating) y hub "Tejiendo vínculos" con paso destacado que rota sin completar y acciones dirigidas con gating. 3.28: notificaciones simuladas (tarjetas con contraste del tema ≥ 4.5:1, "Simular notificación", solo recordatorios sin red activa) y pantallas de modo crisis y respiración con texto verbatim y marcadores [[...]] de contenido pendiente conservados. Entradas temporales desde Inicio PCS (onboarding, Tejiendo vínculos, notificaciones, modo crisis) y home del Cuidador real hasta el home completo del PCS (3.4). **Pendiente:** verificación manual en Android de los nuevos recorridos (home del cuidador y su gating en vivo, Tejiendo vínculos, notificaciones simuladas, modo crisis y respiración). Las pantallas destino de algunas acciones (bandeja de recibidos, mensajes dirigidos, evaluación) llegan en Wave 12/13 (3.18, 3.19, 3.23).
- **Etapa 3, Wave 11 — correcciones de la revisión (conexiones de interacción).** Hallazgos corregidos sin ampliar el alcance: (1) las tarjetas de notificación abren su destino —los recordatorios (acción
elationships) navegan a "Tejiendo vínculos" (destino ya implementado); las acciones dirigidas reevalúan la autorización vigente antes de abrir y, como sus pantallas destino llegan en Waves 12–13, muestran una explicación temporal en lugar de un callback vacío. (2) El acceso del cuidador a "Aprendiendo a tejer vínculos" es funcional y conserva las opciones del prototipo ("Validación", "Habilidades interpersonales"); los tiles del cuidador cuyo destino sigue pendiente (plan de acompañamiento, registro de vínculo y evaluación, Wave 13: 3.19/3.23) muestran una explicación temporal en vez de no responder. (3) El bloqueo por asociación se aplica también a mensaje/contacto/encuentro en "Otros pasos" del hub de conexión (quedan deshabilitados sin vínculo activo), manteniendo disponibles recibidos, habilidades y la rotación de pasos. (4) El modo crisis completa el comportamiento del prototipo: "Elegir otra opción" y "No puedo ahora" avanzan el indicador de paso, hay confirmación de salida y apertura de opciones de contacto; se conservan textos verbatim y los marcadores [[...]] de contenido pendiente, sin inventar instrucciones clínicas ni realizar llamadas o envíos reales. Se incorporaron las 4 pruebas externas de la revisión a 	est/stage3/wave11_review_test.dart conservando sus expectativas, más pruebas puntuales de la reevaluación de notificaciones y del avance/confirmación del modo crisis. **Conexiones pendientes de Waves 12–13:** bandeja de recibidos del PCS (3.18), pantallas dirigidas de mensaje/contacto/encuentro y recorridos del cuidador (3.19), evaluación de la relación (3.23); hasta entonces, esas acciones muestran explicaciones temporales. lutter analyze limpio; 255 pruebas pasan. Verificación manual en Android pendiente.
- **Etapa 3, Wave 11 — correcciones de la verificación manual (E3-W11).** Sin avanzar a Wave 12: (1) Nuevo escenario de demostración "PCS nueva (onboarding no iniciado)" ([DemoScenario.freshPcsOnboarding]) accesible desde "Controles de demostración"; prepara el recorrido con onboardingStatus en
ot-started y sin mapa, y abre la bienvenida del PCS para comprobar "Construir mi mapa", "Hacerlo después" y la persistencia de la decisión. Conserva los escenarios con/sin vínculo. La construcción completa del mapa sigue siendo de la Wave 12 (no se adelanta). (2) "Línea ayuda" (modo crisis) abre una hoja de respuesta simulada coherente con la demo (el número lo configura el equipo clínico; no se realiza ninguna llamada) y "Contactar a alguien" (respiración) reutiliza las opciones de contacto simuladas (mensaje/llamar/ahora no); ya no son acciones vacías, sin inventar números ni enviar nada. (3) La animación de "Respiración pausada" ahora es perceptible: tanto el halo exterior como el círculo central escalan con la respiración (antes solo el halo), conservando el estilo y la cadencia de 4 s por sentido; el conmutador "Reducir movimiento"/"Activar animación" detiene y reanuda el controlador. Pruebas puntuales añadidas: escenario de dominio (onboarding sin iniciar), entrada del control de demostración que abre y aplaza la bienvenida, "Línea ayuda" y "Contactar a alguien" abren su hoja, y la animación cambia de tamaño entre fotogramas y se detiene al conmutar. **Pendiente:** la **confirmación visual de la animación en Android** queda pendiente hasta probarla en dispositivo (el test comprueba la ejecución, no la percepción en pantalla). lutter analyze limpio; 262 pruebas pasan.
- **Etapa 3, Wave 11 — verificación manual cerrada (satisfactoria).** El usuario confirmó en Android los recorridos anteriores y los 13 pasos que quedaban pendientes: bienvenida del PCS y conservación de las decisiones ("Construir mi mapa"/"Hacerlo después"), contactos simulados ("Línea ayuda", "Contactar a alguien") y el movimiento, pausa y reanudación de la animación de respiración. La comprobación corresponde a Android con los ajustes gráficos temporales ya documentados (SwiftShader, Vulkan desactivado, sin instantáneas; Impeller desactivado), que no se incorporan a la configuración del AVD ni del proyecto. Esto **no** marca como resuelta la causa de los cierres históricos de QEMU (E3-W10-04), que sigue como incidencia del entorno de causa desconocida.
- **Etapa 3, Wave 12 (3.4, 3.11, 3.18): implementación terminada; verificación manual en Android pendiente.** lutter analyze limpio; 275 pruebas pasan. **3.4 inicio real del PCS:** reemplaza el placeholder por el home con tiles reales (registro EMA "¿Cómo estoy hoy?", "¿En dónde tejer?"/mapa, "Tejiendo vínculos", "Mensajes de cuidado"/bandeja, "Necesito ayuda"/crisis, "Mi plan para desenredar"), avatares derivados de journey.people, ramificación por estado de onboarding (bienvenida embebida) y banner de notificación simulada in-app con indicador de simulación; conserva "Simular/Ver notificaciones" y los accesos de desarrollo (galería, controles de demostración). Las entradas temporales del placeholder quedaron integradas en estos tiles definitivos sin perder acceso a lo ya verificado (EMA, mapa, plan, onboarding, Tejiendo vínculos, notificaciones, crisis). **3.11 construcción del mapa:** dominio portado verbatim (NAME_QUESTIONS ×10, RELATIONSHIP_QUESTIONS ×18, SCALE ×6, generateResults, evaluación por persona) y pantalla "Construir mi mapa" (generador de nombres → agregar personas → evaluación de 18 ítems → generar) como Funcion_Simulada con indicador; alcanzable desde la bienvenida del PCS ("Construir mi mapa") y alimenta el dominio de métricas (3.8). **3.18 mensajes de cuidado:** CaringMessageRepository en memoria (sesión) cableado; pantalla del Cuidador para redactar un **mensaje para tejer cercanía** (guía con su video verbatim, ejemplos que se añaden de forma aditiva, preguntas con notas privadas, envío simulado) y **bandeja de recibidos del PCS** ("Mensajes de cuidado") que se abre **sin exigir** Asociacion_Activa y solo muestra mensajes de vínculo vigente; el registro excluye notas privadas y preguntas (Requirement 8.5) y se mantiene la distinción recibidos vs. tejer cercanía. **Pendiente de Waves posteriores:** el **mapa de red completo con gráficos y el flujo de invitaciones** (3.12, opcional) sigue representado por la entrada mínima de confirmación de referencia (2.15) más la construcción (3.11); los **recorridos del cuidador dependientes de asociación** (plan de acompañamiento, registro de vínculo, evaluación de encuentros, preguntas de conexión) y la **evaluación de la relación** llegan en la Wave 13 (3.19, 3.23) —hasta entonces esos tiles del cuidador muestran una explicación temporal—. Verificación manual en Android pendiente (se hará aparte). Sin Firebase (Etapa 4).
- **Etapa 3, Wave 12 — correcciones de la revisión.** Sin avanzar a Wave 13 ni Firebase: (1) Desde Inicio PCS, "¿En dónde tejer?" permite **empezar o retomar la construcción** del mapa (ruta a `networkBuilder`) cuando el mapa aún no está generado —p. ej. tras aplazar la bienvenida o salir del constructor—, conservando lo diligenciado; con el mapa ya generado abre "Tu mapa de red". Se conserva el acceso al mapa mínimo (confirmación de Referencia_EMA) por "Ver todos"/avatares. No se adelantan gráficos ni invitaciones (3.12). (2) Se corrigió el **ancho infinito** del pie "Salir del recurso" en la bienvenida y la confirmación de mensajes de cuidado (botón envuelto en Expanded); recorrido Inicio Cuidador → mensajes verificado a 412 px con las fuentes de la app. (3) La redacción **reevalúa el vínculo en vivo**: al revocarse, oculta el borrador y bloquea el envío; el borrador se **aísla por vínculo** (clave estable del cuidador en la demo); la bandeja del PCS sigue accesible **sin asociación activa** y oculta en vivo los mensajes del vínculo revocado. (4) Se restauró **"Cómo empezó todo"** con sus ilustraciones (historia de Motto), disponible **solo tras recorrer las seis partes** de la guía; se conserva el guion del video (expandible verbatim) y las expresiones del avatar (CompanionNote welcome/afecto). (5) Se habilitó un **conmutador de rol** en "Controles de demostración" (PCS ↔ Cuidador) para recorrer Cuidador → envío simulado → PCS → bandeja sin reiniciar la app; los mensajes simulados **no** se persisten. Se incorporaron las 4 pruebas externas de la revisión a 	est/stage3/wave12_review_test.dart conservando sus expectativas, más pruebas puntuales (orígenes gated y conmutador de rol). lutter analyze limpio; 281 pruebas pasan. 3.12 queda pendiente según el plan. Verificación manual en Android pendiente (se hará aparte).
- **Etapa 3, Wave 12 — correcciones de seguimiento de la revisión.** Sin avanzar a Wave 13 ni Firebase: (1) Inicio Cuidador tiene ahora un acceso visible a "Controles de demostración" (que incluye el conmutador de rol), de modo que el recorrido Cuidador → redactar → simular envío → volver al inicio → cambiar a PCS → ver el mensaje en la bandeja es ejercitable desde la interfaz, sin reiniciar ni persistir mensajes. (2) Los borradores de mensajes de cuidado se leen y editan por caringDraftKey del **contexto completo** (cuidador, PCS, persona, asociación): una asociación nueva del mismo cuidador **no hereda** el texto ni las notas del vínculo anterior. Para resolver la clave aunque el Stream del recorrido no haya emitido aún, el repositorio expone currentOrNull (valor síncrono) y se cae a un borrador provisional de sesión solo cuando no hay borrador bajo la clave del vínculo (sin provocar herencia entre asociaciones). Al **enviar** se verifica que el contexto siga vigente y coincida con la asociación que se estaba revisando (expectedAssociationId); si cambió o se revocó, el envío se rechaza. Se conserva el ocultamiento del borrador y el bloqueo de envío tras revocación, y la bandeja del PCS accesible sin asociación activa. (3) Se recuperó la tercera expresión del avatar de la guía, **thoughtful**: CompanionNote admite ahora CompanionExpression {welcome, thoughtful, affection} con la pose --thoughtful del prototipo; la guía usa thoughtful donde corresponde (nota de honestidad), conservando las tres expresiones acordadas. Se incorporaron las 2 pruebas externas a 	est/stage3/wave12_followup_review_test.dart conservando sus expectativas, más pruebas puntuales (tres expresiones del avatar y verificación de contexto al enviar). lutter analyze limpio; 285 pruebas pasan. 3.12 sigue pendiente según el plan. Verificación manual en Android pendiente (se hará aparte).
- **Etapa 3, Wave 12 — corrección de cambio de vínculo con la pantalla de mensajes abierta.** Sin avanzar a Wave 13: (1) La pantalla de redacción observa la clave completa del vínculo (caringDraftKey del contexto) en vivo; si cambia mientras está abierta, **reinicia el editor y la vista previa** (vuelve al inicio del recurso) y descarta la revisión capturada, de modo que el texto y las notas del vínculo anterior no quedan visibles ni pasan al nuevo borrador. (2) "Revisar mensaje" **captura** el contexto (clave completa) y el texto; si el vínculo cambia, esa revisión se invalida y se exige revisar de nuevo antes de enviar; al confirmar se compara contra el contexto capturado y, además, el envío verifica la asociación vigente (expectedAssociationId), por lo que un cambio de asociación entre revisión y envío lo bloquea. (3) El borrador provisional de sesión ("_") ya **no** respalda a un vínculo distinto: currentCaringDraftProvider resuelve por la clave completa del contexto y solo cae al provisional cuando el propio vínculo aún no tiene borrador; si el contexto no está resuelto, la pantalla no permite editar un borrador ajeno (el editor se reinicia al resolverse una clave distinta). Se conservan el conmutador de rol de la demo, las tres expresiones del avatar (welcome/thoughtful/affection) y el envío simulado en memoria (no persistente). Se incorporaron las 2 pruebas externas a 	est/stage3/wave12_live_context_review_test.dart conservando sus expectativas. lutter analyze limpio; 287 pruebas pasan. 3.12 sigue pendiente según el plan. Verificación manual en Android pendiente (se hará aparte).
- **Etapa 3, Wave 12 — eliminación del respaldo de borrador compartido.** Sin avanzar a Wave 13: se retiró la clave provisional compartida (drafts['_']). Ahora una escritura **sin vínculo válido** no se guarda (las ediciones son no-op si el contexto de cuidado no está resuelto) y, por tanto, **no puede atribuirse a una asociación posterior**. Una vez resuelto el contexto, el borrador se **lee y escribe solo con la clave completa del vínculo** (caringDraftKey); currentCaringDraftProvider ya no cae a ningún respaldo compartido. Las pruebas que preparan borradores cargan primero un vínculo válido (p. ej. loadJourney() para resolver el contexto antes de setText). Se conservan las demás correcciones de la ola (reinicio del editor/vista previa y revisión al cambiar de vínculo, verificación de contexto al enviar, conmutador de rol de la demo, tres expresiones del avatar y envío simulado en memoria). Se incorporó la prueba externa a 	est/stage3/wave12_unbound_draft_review_test.dart conservando sus expectativas. lutter analyze limpio; 288 pruebas pasan. 3.12 sigue pendiente según el plan. Verificación manual en Android pendiente (se hará aparte).
- **Etapa 3, Wave 12 — correcciones de interfaz de la verificación manual (E3-W12).** Sin avanzar a Wave 13 (3.12 sigue pendiente). (E3-W12-01) Al abrir "Consultar ejemplos" o "Preguntas para inspirarme" **desde el editor**, el pie de la guía ofrece ahora "Volver a mi mensaje", que regresa a la redacción conservando el texto original y las ideas añadidas (la inserción sigue siendo aditiva). Cuando la guía se abre **desde la bienvenida**, se mantiene la navegación normal (Anterior/Siguiente) sin ese atajo. (E3-W12-02) Las acciones de emergencia del modo crisis ("Mamá", "Línea ayuda", "Emergencias") se apilan a lo ancho completo en lugar de tres columnas estrechas, de modo que "Emergencias" se lee como una palabra completa al ancho del emulador, sin truncarla ni reducir la letra; la acción sigue siendo simulada (abre el diálogo de confirmación cuyo número configura el equipo clínico, sin realizar llamadas). Se añadieron pruebas puntuales: regreso desde ejemplos con conservación de texto/idea y navegación normal desde la bienvenida; y la etiqueta "Emergencias" completa y sin desbordes a 412 px con su acción simulada. lutter analyze limpio; 291 pruebas pasan. Verificación manual en Android pendiente (se hará aparte).
- **Etapa 3, Wave 12 — verificación manual cerrada (satisfactoria).** El usuario confirmó en Android los recorridos funcionales (inicio real del PCS y accesos, aplazar/agregar/retomar la construcción del mapa, guía de mensajes con sus tres expresiones del avatar y "Cómo empezó todo", borrador/envío simulado y bandeja del PCS con cambio de rol sin reiniciar, revocación y bloqueo). Las dos observaciones de interfaz quedaron resueltas y comprobadas: el regreso directo al borrador desde los ejemplos (E3-W12-01) y "Emergencias" legible como palabra completa en modo crisis (E3-W12-02). Además, el usuario unificó el fondo de las franjas superior e inferior de "Necesito ayuda" (modo crisis) con el del cuerpo (ContigoColors.canvas), coherente con el prototipo. **Wave 12 (3.4, 3.11, 3.18) queda cerrada.** 3.12 (mapa completo con gráficos e invitaciones) permanece pendiente según el plan; el mapa mínimo de confirmación de referencia (2.15) más la construcción (3.11) no lo reemplazan.
- **Etapa 3, Wave 13 (3.19, 3.23): implementación terminada; verificación manual en Android pendiente. No se avanza a Firebase (Etapa 4).** Implementación completa y en verde (flutter analyze limpio; 312 pruebas pasan, sin regresiones en las suites externas de Wave 12 incorporadas en test/stage3/). **3.19** — recorridos del cuidador dependientes de asociación: plan de acompañamiento (solo lectura), registro de vínculo, evaluación de encuentros y preguntas para conectar, todos gated por Asociacion_Activa (deshabilitados y con aviso "Necesitas un vínculo activo" sin tupla válida) y con adjuntos de audio/foto como Funcion_Simulada con indicador de simulación; los umbrales y la puntuación de las evaluaciones quedan marcados como Contenido_Validacion_Pendiente con marcadores verbatim [[...]], sin inventar contenido clínico. La entrada "Tejiendo vínculos" del inicio del cuidador conserva la navegación directa a la redacción de mensaje de cuidado (caringCompose), y las entradas "Preguntas para conectar" y "Registrar encuentro" viven en la vista de bienvenida de la redacción bajo "Otras formas de conectar". **3.23** — evaluación de relación y preguntas para conectar (portada de MobileScreen13 de social.tsx): recorrido persona → preguntas → orientación → invitación, avanzando solo cuando el paso actual está respondido (avance monótono, Property 19); la puntuación provisional invierte la polaridad en las preguntas negativas (7 - answer) y el umbral de orientación (>= 4) está marcado como Contenido_Validacion_Pendiente (orientación demostrativa, nunca bloquea ni decide); la invitación es una Funcion_Simulada (no contacta a nadie real). Nueva ruta PCS relationEvaluation (/evaluar-relacion) guardada por rol, accesible desde un tile del inicio del PCS ("Preguntas para conectar"). Pruebas añadidas (solo las necesarias): dominio de la evaluación (contenido verbatim, avance monótono, puntuación provisional con polaridad invertida, umbral >= 4) y recorrido de pantalla (exige nombre, bloqueo de avance sin respuesta, marcadores pendientes en la orientación, invitación simulada). **Pendiente:** verificación manual en Android de ambos recorridos (se hará aparte). **3.12** (mapa completo con gráficos e invitaciones) **no es opcional** en tasks.md y **sigue pendiente**; el mapa mínimo de confirmación de referencia (2.15) más la construcción (3.11) no lo reemplazan. Por eso **la Wave 13 no se declara completa**: 3.19 y 3.23 están implementadas (verificación manual en Android pendiente), pero 3.12 queda por entregar. **No se inicia Firebase (Etapa 4).**
- **Etapa 3, Wave 13 — correcciones de la revisión (E3-W13).** Sin avanzar a Firebase. (1) **"Preguntas para conectar" (cuidador)** ahora recorre las **seis** preguntas (el botón "Ver otra" avanza de una en una, antes saltaba de dos en dos y solo mostraba tres) y al cambiar de pregunta **limpia la respuesta visible** del campo de texto, no solo la variable interna (el campo comparte un TextEditingController que se vacía). (2) **Conservación de estado de los recorridos del cuidador ante revocación:** el registro de la relación en curso se guarda **por asociación** (clave = associationId, patrón de los borradores de mensajes) en un provider de sesión; al revocar el vínculo el contenido se **bloquea y oculta**, y al **reactivar la misma asociación** se **recupera lo diligenciado**. Como la clave es la asociación, el estado **no se traslada a una asociación distinta**. (3) **Evaluación de relación** completada conforme al prototipo (MobileScreen13): en la orientación no favorable aparecen **"Pensar en otra persona"** (reinicia el recorrido) y **"Ver recurso sobre relaciones"** (hoja simulada con contenido narrativo marcado `[[...]]` pendiente de validación); la invitación simulada exige el campo **"Número o correo"** antes de habilitar "Enviar invitación". (4) **Mensajes íntimos (parte de 3.19, distintos de los mensajes de cuidado):** nuevo recorrido gated `CaregiverIntimateMessageScreen` (ruta cuidador `/cuidador/mensaje-intimo`), portado de `MobileScreen10` con `messageKind == 'intimate'` (título "Mensaje íntimo para {PCS}", sugerencias, vista previa, orientaciones "Antes de guardar" verbatim marcadas como pendientes de validación, borrador de sesión simulado que no envía nada), accesible desde la bienvenida de la redacción ("Escribir un mensaje íntimo"). Se incorporó la suite externa de revisión `test/stage3/wave13_review_test.dart` conservando sus expectativas (recorrido de las seis preguntas, revocar/reactivar conserva el registro, "Ver otra" limpia la respuesta, invitación exige contacto) y se añadieron solo las pruebas necesarias (contacto requerido + reinicio en la evaluación; mensaje íntimo prepara borrador y queda bloqueado sin vínculo). flutter analyze limpio; 319 pruebas pasan. **3.19 y 3.23 implementadas (verificación manual en Android pendiente); 3.12 sigue pendiente, así que la Wave 13 no está completa.**
- **Etapa 3, Wave 13 — conservación de estado por contexto completo (E3-W13b).** Sin avanzar a Firebase. Se extendió la conservación de sesión (antes solo en el registro de la relación) a los **tres** recorridos del cuidador que faltaban: **mensaje íntimo**, **preguntas para conectar** y **evaluación de encuentros**. El estado en curso (texto, formato, adjuntos simulados, respuestas de escala, pregunta actual, "compartido") vive ahora en providers de sesión (Notifier) **aislados por contexto completo** (clave `caringDraftKey` = cuidador+PCS+persona+asociación), no en el `State` del widget. Efecto: **revocar** oculta y bloquea el recorrido **sin borrar** lo diligenciado; **reactivar la misma asociación** lo **recupera**; y una **asociación distinta arranca con su propio estado** (no hereda texto, notas, respuestas ni adjuntos). Los campos de texto usan un `TextEditingController` que se sincroniza con el estado (recupera al reactivar, limpia al cambiar de pregunta). Los datos siguen **solo en memoria de sesión** (no se persisten) y el contenido no cambió. Se incorporó la suite externa `test/stage3/wave13_state_review_test.dart` conservando sus expectativas (mensaje íntimo y preguntas para conectar conservan el texto al revocar/reactivar; el encuentro recupera sus cuatro respuestas) y se añadió una prueba de **aislamiento entre asociaciones** a nivel de controlador (la asociación B no hereda el estado de A). flutter analyze limpio; 324 pruebas pasan. **La Wave 13 sigue sin estar completa: 3.12 (mapa completo con gráficos e invitaciones) continúa pendiente; 3.19 y 3.23 quedan con verificación manual en Android pendiente.**
- **Etapa 3, Wave 13 — 3.12 mapa de red completo (E3-W13c). Implementación terminada; verificación manual en Android pendiente. No se avanza a Firebase.** Se completó la última tarea pendiente de la Wave 13. **Gráficos:** `ClosenessMapPainter` y `QualityGridPainter` en `lib/presentation/network/network_charts.dart` (`CustomPainter`), portados verbatim de los SVG del prototipo (`ClosenessMap`/`QualityGrid`/`SvgNode`/`Legend` de `src/screens/network.tsx`): mismos sectores por tipo de relación, anillos (42/77/112), cuadrantes de positividad/negatividad, formas (círculo/diamante/triángulo/cuadrado), tamaños por importancia y separación de marcadores solapados. Se alimentan de `NetworkMetricsCalculator.metricsFor` (fórmulas ya portadas en 3.8); los colores de marcador vienen de `metrics.colorValue` y los cortes/colores siguen siendo Contenido_Validacion_Pendiente. **Pantalla:** `NetworkMapScreen` pasó de la entrada mínima (2.15) al mapa completo con pestañas **Mapa de cercanía / Calidad relacional / Lista**, detalle por persona y acción "Gestionar invitaciones y vínculos". **Invitaciones (Funcion_Simulada):** `lib/domain/network/network_invitation.dart` con `invitationLabel`/`invitationVariant`/`canInvite`/`simulateInvite` verbatim; `simulateInvite` deja la invitación en `pending` sin crear ni activar asociación, y el flujo muestra el indicador de simulación y el borrador "pendiente de validación". **Integración conservada:** la construcción del mapa (3.11) sigue siendo el camino para generarlo (si no está generado, el mapa ofrece "Construir mi mapa"); la **selección/cambio de Referencia_EMA con confirmación explícita** (5.7/5.9) se conserva intacta —mismos rótulos "Seleccionar/Seleccionada para registro EMA" y diálogo "Confirmar selección/cambio para EMA", con regreso al flujo EMA tras confirmar—; y una **invitación aceptada por sí sola no habilita** acciones que requieren Asociacion_Activa (lo decide `canStrengthenRelationship`): el detalle de una persona sin asociación activa explica el gating y no ofrece seleccionarla como referencia. Envíos simulados y decisiones de persistencia (`JourneyRepository`) sin cambios. Pruebas añadidas (solo las necesarias): dominio de invitaciones y pantalla de resultados (gráficos dibujados, invitación simulada deja `pending` sin asociación, gating de referencia). Suites de Etapa 2 (mapa/EMA) y de la Wave 13 siguen verdes. flutter analyze limpio; 335 pruebas pasan. **Con 3.12 terminada, la Wave 13 queda implementada en su totalidad; resta la verificación manual en Android (3.12, 3.13, 3.19, 3.23) antes de darla por cerrada.**
- **Etapa 3, Wave 13 — correcciones de 3.12 de la revisión (E3-W13d). Sin avanzar a Firebase.** (1) **Acceso al mapa desacoplado del vínculo activo:** una red **generada** muestra gráficos, lista, detalles e invitaciones aunque no haya ninguna Asociacion_Activa; si **no está generada**, la pantalla ofrece `Construir mi mapa`. El requisito de vínculo activo se conserva **solo** donde corresponde: la selección/cambio de Referencia_EMA (con confirmación explícita) y las acciones dirigidas a persona. Cuando la red está generada pero no hay asociación activa, se muestra "Sin persona de referencia elegible" —distinto de "sin red"— y el mapa sigue disponible. (2) **Nodos pulsables en ambos gráficos:** nuevo `_ChartHitTarget` traduce un toque a la persona cuyo nodo está más cerca (usando las mismas coordenadas que dibuja el `CustomPainter`, expuestas vía `NetworkChartPainter.nodePositions`) y abre su detalle; además expone un nodo de semántica `button` por persona con la etiqueta del prototipo ("nombre, anillo, clasificación"), conservando la accesibilidad. (3) **Cancelar la selección de referencia desde el detalle** mantiene la hoja abierta y **no** muestra el mensaje de actualización; `confirmEmaReference` ahora devuelve si guardó y el detalle solo cierra y anuncia "Referencia EMA actualizada." tras confirmar y guardar. Se incorporó la suite externa `test/stage3/wave13_map_review_test.dart` conservando sus expectativas (mapa generado sin vínculos muestra resultados e invitaciones; mapa vacío ofrece construir; tocar un nodo abre el detalle; cancelar mantiene el detalle sin mensaje) y se **ajustaron** las pruebas del mapa mínimo para distinguir "sin referencia EMA elegible" (red generada, sin asociación activa) de "sin red" (sin mapa generado), sin eliminar la cobertura del EMA (selección y confirmación siguen probadas). flutter analyze limpio; 340 pruebas pasan. **La Wave 13 queda implementada; resta la verificación manual en Android (3.12, 3.13, 3.19, 3.23) antes de cerrarla.**
- **Etapa 3, Wave 13 — correcciones de navegación activa de la revisión manual (E3-W13-01 y E3-W13-02). Sin avanzar a Firebase.** La comprobación manual **aprobó los 26 pasos implementados**; el contraste con la navegación activa del prototipo detectó dos diferencias, ahora corregidas (pendientes de una revisión manual centrada en ambos recorridos). **E3-W13-01 — preguntas conversacionales del PCS (MobileScreen14, role pcs):** nueva pantalla `PcsConnectionQuestionsScreen` (ruta PCS `/preguntas-conectar`) y controlador de sesión que portan las **seis** preguntas conversacionales compartidas con una persona cercana **vinculada activa** (interlocutor = `journey.selectedPersonId` con asociación activa; si la seleccionada no está activa, cae a una vinculada activa; sin ninguna, exige vínculo con acceso al mapa). Respuesta en **texto/audio/foto simulados** (indicador de simulación), autorización por Asociacion_Activa y **aislamiento del estado por vínculo** (clave = id de la persona; solo en sesión). El tile "Preguntas para conectar" del inicio del PCS **abre este recorrido**; las notificaciones con acción `questions` lo abren fijando la persona de la notificación y posicionando su pregunta (`?q=`), conservando pregunta y persona. La **evaluación de nueve preguntas** (`RelationEvaluationScreen`) se **conserva separada** —ni se inserta en el constructor ni se elimina— y queda accesible desde un nuevo tile "Evaluar una relación". **E3-W13-02 — constructor guiado del mapa (network.tsx):** `NetworkBuilderScreen` se reescribió como recorrido por etapas: las **diez** preguntas del generador de nombres **una por pantalla** (con "Continuar", "No se me ocurre nadie" y "Omitir esta pregunta"), captura y **revisión** de personas (editar/eliminar), y **caracterización por persona** cuyo **paso 1 de 19** es "¿Quién es {nombre} para ti?" (selección de ámbito **sin preseleccionar "Familia"**) seguido de los **mismos 18 ítems** (pasos 2–19). El avance se **conserva y se reanuda** por persona (retoma en el primer ítem sin responder); no se duplican preguntas; generar con **al menos una relación completa** sigue siendo válido. Se reutilizaron el dominio (`nameGeneratorQuestions`/`relationshipQuestions`/`relationshipScale`/`generateResults`) y los componentes existentes; **métricas, Referencia_EMA (con confirmación explícita), contenido, resultados e invitaciones ya verificados se conservan**. Pruebas de navegación y conservación añadidas: recorrido conversacional del PCS (seis preguntas, adjuntos simulados, autorización, aislamiento por vínculo, pregunta inicial), lógica del interlocutor/`focusQuestion`, y constructor guiado (diez preguntas una por pantalla; paso 1 "¿Quién es {nombre}?" sin preselección; conservación/reanudación del avance). flutter analyze limpio; 353 pruebas pasan. **Pendiente:** revisión manual centrada en ambos recorridos en Android antes de cerrar la Etapa 3.
- **Etapa 3, Wave 13 — segunda tanda de correcciones de la revisión manual (E3-W13-01/02, seguimiento). Sin avanzar a Firebase; la comprobación manual de estos recorridos sigue pendiente.** Tres fallos reproducidos en pruebas, ya corregidos: (1) **Constructor — "Continuar" guarda el nombre escrito antes de avanzar** (como el prototipo `submitNameQuestion`), sin exigir pulsar "+": `_advanceName` añade el texto del campo (si lo hay) con `addNamedPerson` y luego avanza. (2) **Preguntas PCS — la pregunta inicial de una notificación se conserva y se muestra aunque no pertenezca al banco de seis**: el estado guarda una `extraQuestion` que se **antepone** a la lista efectiva (`MobileScreen14`); se muestra primero y luego "Ver otra" recorre las demás. (3) **Aislamiento por contexto completo del vínculo**: el estado de las preguntas PCS se indexa por `pcsLinkKey` = PCS + persona + **id de la asociación activa** (antes solo por `personId`). Así, una **asociación nueva con la misma persona empieza vacía** y **revocar/reactivar la misma** conserva su estado en sesión. Se incorporó la suite externa `test/stage3/wave13_guided_followup_test.dart` conservando sus expectativas (las tres pasan). Se reutilizaron dominio y componentes existentes; **métricas, Referencia_EMA con confirmación explícita, contenido, resultados e invitaciones se conservan**; la evaluación de nueve preguntas sigue separada. flutter analyze limpio; 358 pruebas pasan. **Pendiente:** revisión manual centrada en el constructor guiado y en las preguntas conversacionales del PCS en Android antes de cerrar la Etapa 3.
- **Etapa 3, Wave 13 — verificación manual cerrada (satisfactoria).** Según el informe actualizado, el usuario confirmó en Android los recorridos de la Wave 13 y de todas sus correcciones: **3.12** mapa de red completo (gráficos de cercanía y calidad alimentados por `metricsFor`, lista, detalle por persona, nodos pulsables en ambos gráficos, invitaciones simuladas que dejan `pending` sin crear asociación, acceso al mapa desacoplado del vínculo activo y conservación de la selección/cambio de Referencia_EMA con confirmación explícita); **3.19** recorridos del cuidador dependientes de asociación (plan de acompañamiento, registro de vínculo, evaluación de encuentros, preguntas para conectar y **mensajes íntimos**), con gating por Asociacion_Activa, adjuntos simulados y conservación del estado por contexto completo ante revocación/reactivación; y **3.23** evaluación de relación de nueve preguntas (avance monótono, orientación demostrativa con marcadores pendientes, invitación simulada que exige contacto). También quedaron confirmadas las correcciones de navegación activa (E3-W13-01: preguntas conversacionales del PCS portadas de `MobileScreen14` con persona vinculada activa, texto/audio/foto simulados, autorización, aislamiento por contexto completo del vínculo y conexión de las notificaciones `questions` conservando pregunta y persona —incluida una pregunta inicial ajena al banco de seis—; y E3-W13-02: constructor guiado con las diez preguntas del generador de nombres una por pantalla, captura/revisión y caracterización por persona cuyo paso 1 de 19 es "¿Quién es {nombre} para ti?" sin preseleccionar "Familia", con reanudación del avance y "Continuar" guardando el nombre escrito). **La Wave 13 (3.12, 3.19, 3.23) queda cerrada.** Se conservan métricas, Referencia_EMA, contenido, resultados e invitaciones ya verificados; los envíos, las invitaciones y las notificaciones mantienen su carácter simulado. **Firebase / Etapa 4 permanece pendiente por decisión del usuario; no se inicia.** Cierre documentado el 12 de noviembre de 2026, limitado a los recorridos acordados de Wave 13; no constituye una auditoría global de la Etapa 3. El caso de asociación nueva con la misma persona está cubierto por automatización, sin reproducción manual. Al reentrar al constructor, el generador vuelve a 1/10, conservando personas y respuestas. Las tareas opcionales `*` de propiedades PBT y de port de pruebas del prototipo siguen sin ejecutar, según el plan.
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

