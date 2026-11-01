# Análisis del prototipo Contigo

Diagnóstico previo a la reimplementación en Flutter. Solo análisis; no se modificó el prototipo.

## Referencia revisada

- **Ruta del prototipo:** `C:\Users\Lex\Documents\contigo-prototype-main\Contigo`
- **Commit revisado:** `267ef91`. La carpeta local analizada **no es un repositorio git** (`git log` falla con *not a git repository*), pero una comparación externa confirmó que esta copia corresponde al código y las pruebas del commit `267ef91`. El análisis se hizo sobre esos archivos (fecha del documento: 2026-10-20).
- **Stack del prototipo:** React 19 + Vite 8 + TypeScript 5.7 + Tailwind CSS v4, generado con Figma Make. SPA sin router ni backend. `recharts` como única dependencia de UI de datos.
- **Pruebas:** 6 archivos `tests/*.test.mjs` ejecutados con `node --test` sobre los módulos de dominio transpilados en un `vm` (sin React ni DOM).

## Arquitectura observada

- SPA de una sola página: `src/App.tsx` es la **única fuente de verdad**. Mantiene todo el estado (`journey`, `emaReference`, `emaDraft`, `safetyPlan`, `caringDrafts`, `caringMessages`, `notifications`, `caregiverId`, etc.) y navega por un índice numérico `screen` (`useState`). Cada pantalla es un componente presentacional que recibe `navigate(n)` + datos + callbacks.
- **No hay router, no hay backend, no hay autenticación real.** El rol se decide en la pantalla de activación ficticia por una convención de código demo (código que empieza por "C" → cuidador; cualquier otro → PCS).
- Además de `App.tsx`, **las pantallas mantienen su propio estado local** (p. ej. el borrador del plan de seguridad en M5, el paso del relato, las etapas de invitación/respuesta en `social.tsx`). No todo el estado vive en `App.tsx`; esto habrá que reorganizarlo en la arquitectura Flutter.
- Separación clara entre **lógica de dominio** (`src/*.ts`, portable y con pruebas) y **pantallas** (`src/screens/*.tsx`, presentacionales, con muchas simulaciones).

## Roles

| Rol | Persona demo | Descripción |
|-----|-------------|-------------|
| **PCS** (persona con conducta suicida) | "Sofía" | Usuario principal: EMA diario, plan de seguridad, mapa de red, tejido de vínculos, bandeja de mensajes de cuidado. |
| **Cuidador** | "Marta" | Vinculado a un PCS mediante una asociación activa. Recorridos: plan de acompañamiento, registro de vínculo, evaluación de encuentros, redacción de mensajes de cuidado e íntimos, y preguntas de conexión. |
| **Admin / investigador (escritorio)** | "Dra. Ríos" | Panel de estudio (dashboard, detalle de participante, cuentas). Completamente simulado con datos sintéticos. |

## Pantallas y recorridos (resumen)

- **Activación (`mobile.tsx` M1):** simulada. Solo valida `código.length >= 4`, finge verificación con `setTimeout`, enruta por rol. Sin validación ni red.
- **Inicio PCS (`home.tsx`):** mixto. Navegación real por tiles, avatares desde `journey.people`, ramificación de onboarding real. La "simular notificación" es un banner falso in-app; "Mensajes/actividad" y "Perfil" son placeholders.
- **EMA diario (`ema.tsx`):** **la funcionalidad más genuinamente implementada.** Banco de 9 ítems (3 binarios + 2 bloques de 3 rangos), slider 0–100 con accesibilidad por teclado, selección de persona de referencia condicionada a vínculo activo, omisión del bloque de relación sin vínculo (pasa a 6 ítems), cambio de día y reglas de completitud reales. **No hay puntuación clínica ni selección a partir de las respuestas.** (El `mobile.tsx` M3 es un EMA antiguo con texto placeholder `[[...]]`; la real es `ema.tsx`.)
- **Plan de seguridad (`mobile.tsx` M5):** editor real (títulos de pasos, contactos, actividades, entorno) sobre `SafetyPlanDraft`, pero **solo de sesión**. El importador de contactos del SO es un flujo de permisos **simulado**.
- **Relato "Las crisis también pasan" (`safety-plan-story.tsx`):** visor narrativo real de 7 páginas con videos; CTA al plan. Control demo para fingir plan vacío/lleno.
- **Hub de ayuda (`help-hub.tsx`):** solo navegación (plan, modo crisis, relato).
- **Modo crisis / respiración (`mobile.tsx` M6/M7):** pantallas de apoyo; acciones de contacto/llamada **sin handler** (puramente visuales; número de línea de ayuda "por confirmar").
- **Tejiendo vínculos (`connection-hub.tsx` + `connection-person.tsx`):** shell de flujo real sobre `connection.ts`. La **autorización por asociación activa** (`canStrengthenRelationship`) deshabilita realmente mensaje/contacto/encuentro. Mapa de "tejido" en SVG propio.
- **Conoce tu red / mapa (`network.tsx`):** la pantalla más grande, con **motor de métricas real** (`metricsFor`: puntuación POMP sobre 18 ítems → cercanía/positividad/negatividad/importancia, anillo Íntimo/Personal/Ocasional) y **dos gráficos SVG hechos a mano** (no recharts). El flujo de **invitaciones es simulado** (los estados pending/accepted/declined son solo datos; no se envía nada). `generateResults()` finge cómputo con un `setTimeout` de 550 ms.
- **Preguntas para conectar / evaluación de relación (`social.tsx` M13/M14):** simuladas. Umbrales "demostrativos" pendientes de validación; el "envío" de invitación solo avanza de etapa; audio y foto son adjuntos **falsos**; la respuesta de la otra persona se finge localmente.
- **Inicio cuidador (`caregiver-home.tsx`):** el **gating por vínculo activo es el núcleo**. Tiles deshabilitados salvo asociación activa válida. Panel demo (`onSimulate("active"|"accepted-only"|"revoked")`) + selector de perfil. Recursos de aprendizaje son placeholders.
- **Mensaje de cuidado (`caring-message.tsx`):** editor real sobre `caring-messages.ts` (guía de 6 páginas con video, seguimiento de lectura, preguntas de reflexión, inserción de ejemplos que **añaden, nunca sobrescriben**, borrador en sesión). **Envío simulado** (`onSimulateSend` → `createSimulatedCaringMessage`); la UI lo dice explícitamente.
- **Bandeja de mensajes de cuidado PCS (`caring-message-inbox.tsx`):** bandeja **simulada**; se borra al recargar.
- **Escritorio admin (`desktop.tsx` D13/D14/D15):** **todo simulado con datos sintéticos fijos.** Único lugar que usa **recharts** (AreaChart, LineChart, BarChart) sobre arrays hardcodeados, con descargos de "valores de demostración / escala pendiente de validación clínica". Modales, búsqueda y "activar protocolo de crisis" no funcionales.
- **Componentes compartidos:** `notification-card.tsx` (tarjeta presentacional de notificación demo) y `companion-note.tsx` (avatar + burbuja de "acompañante").

## Módulos de dominio a migrar (lógica real, con pruebas)

Estos módulos `src/*.ts` son la **lógica de negocio portable** y deben migrarse con fidelidad:

| Módulo | Qué hace | Regla crítica a preservar |
|--------|----------|---------------------------|
| `journey.ts` | Estado de la red, personas, asociaciones de cuidado; `canStrengthenRelationship`, `validCaregivers`. | **Autorización**: fortalecer una relación exige invitación `accepted` + asociación `active` con la tupla exacta (pcsId, caregiverId, personId). En el prototipo es solo un control de UI local; en la app final **debe respaldarse con autorización en el backend** (no confiar solo en el cliente). |
| `caregiver.ts` | `caregiverContext`, `simulateCaregiverLink`. | Acceso del cuidador exige la tupla activa exacta; simulaciones inmutables, sin asociaciones duplicadas. |
| `connection.ts` | `CONNECTION_STEPS`, `nextConnectionStep`, `connectionLaunch`. | Las acciones de conexión están gated por la misma regla de asociación activa. |
| `ema.ts` | Banco EMA, borrador, referencia, día, omisión, completitud. | **Contrato de persistencia** (ver abajo): nunca persistir respuestas EMA; referencia solo por IDs; reglas de día y de omisión. |
| `caring-messages.ts` | Contenido educativo, borradores, mensaje simulado, visibilidad. | El registro del mensaje **nunca** serializa notas privadas ni preguntas seleccionadas; visibilidad aislada por pcs/persona/asociación y oculta tras revocación. |
| `notifications.ts` | Plantillas y generación aleatoria de notificaciones demo. | Solo `reminder` cuando no hay red activa; sustituir `XXX` solo por persona vinculada activa; chequeo de contraste WCAG ≥ 4.5. |
| `safety-plan.ts` | `SafetyPlanDraft`, `safetyPlanHasInformation`, ejemplos demo. | Borrador de sesión; escenarios demo independientes, sin fuga de datos. |
| `safety-plan-story.ts` | Narrativa de 7 páginas + etiqueta de CTA. | Contenido narrativo clínico a preservar literal. |
| `network.ts` / `metricsFor` (en `network.tsx`) | Motor de puntuación POMP y clasificación de relaciones. | Portar el cálculo, pero sus cortes de anillo/clasificación quedan **pendientes de validación** (ver nota de contenidos). |

Además hay **contenido textual clínico** extenso que debe migrarse literal, pero **sin asumir que todo está validado**:

- **Confirmados por el equipo investigador:** banco EMA (`EMA_VERSION = "daily-nine-v2"`, provisto tras revisión del evaluador), relato del plan de seguridad y guion/ejemplos de mensajes de cuidado (textos narrativos suministrados).
- **Pendientes de validación (no tratar como lógica clínica definitiva):** los umbrales de la evaluación de relación en `social.tsx` (marcados "orientación demostrativa"), las escalas y reglas del dashboard de escritorio, y las **métricas de red** (`metricsFor`: puntuación POMP, anillos y clasificación) cuyos cortes no constan como validados. Varios bloques siguen marcados `[[... por validar con el equipo investigador]]`.

## Qué está implementado vs simulado (no confundir)

**Implementado de verdad (portar como funcionalidad):**
- Reglas de autorización por asociación activa (todo el gating PCS/cuidador).
- EMA diario completo (ítems, slider, referencia, omisión, día, completitud) — sin scoring clínico.
- Motor de métricas de red `metricsFor` y los gráficos SVG de cercanía/calidad.
- Editor del plan de seguridad y editor de mensajes de cuidado (estructura y validaciones).
- Visor narrativo del plan y guía de mensajes de cuidado.

**Simulado / placeholder (NO reimplementar como función real sin diseño nuevo):**
- Activación/login (no hay auth real).
- Envío de invitaciones, mensajes, llamadas y notificaciones (todo es fake/local).
- Bandeja de mensajes de cuidado (simulada, efímera).
- Importación de contactos del SO (flujo de permisos simulado).
- Panel de escritorio completo y todos sus gráficos recharts (datos sintéticos).
- Adjuntos de audio/foto en preguntas para conectar.
- Varios contenidos marcados `[[... por validar con el equipo investigador]]`.

## Persistencia

**Persistencia temporal del prototipo (lo que hace hoy, no una política):** única escritura en `window.localStorage`, en `App.tsx`.

- **Persistido:** `journey` (clave `contigo-demo-pcs-sofia`, o `...-testing` con `?demo=1`) y `emaReference` (solo IDs, clave `...-ema-reference`).
- **Solo de sesión (se pierde al recargar):** respuestas EMA (`emaDraft`), plan de seguridad, borradores y mensajes de cuidado, notificaciones, navegación, perfil de cuidador activo.
- `resetDemoState()` (solo en modo demo) borra las claves `-testing` y recarga.

Esto es un mecanismo de demostración: `localStorage` del navegador y una decisión deliberada de mantener el contenido clínico efímero **para el prototipo**.

**Política pendiente para la app final (decisión abierta):** la app Flutter tendrá otro sustrato (ver backend previsto). Queda por definir qué datos persisten, dónde (dispositivo vs. backend), con qué cifrado/consentimiento y por cuánto tiempo. No debe asumirse que la regla del prototipo —solo sobreviven el mapa de red y la referencia EMA, lo clínico es efímero— sea la política final; es el punto de partida a validar con el equipo clínico.

## Decisiones pendientes que afectan la implementación

1. **Autenticación y roles reales.** El prototipo no tiene auth. Definir el modelo real (identidad PCS/cuidador/investigador, códigos de activación, vinculación). Es el cimiento de toda la autorización por asociación, que **debe aplicarse en el backend**, no solo en el cliente.
2. **Backend previsto: Firebase / Google Cloud.** Es el sustrato planificado para la app final. Quedan pendientes el **modelo de datos** (cómo se representan `journey`/asociaciones/EMA/mensajes), el **esquema de permisos/reglas de seguridad** (que respalde la regla de asociación activa) y la **estrategia de sincronización** (online/offline). Esto define qué deja de ser simulado (invitaciones, mensajes, notificaciones).
3. **Política de persistencia de datos clínicos.** El prototipo mantiene EMA/plan/mensajes solo en memoria como mecanismo de demo. Confirmar con el equipo clínico qué debe persistir en la app final, dónde, con qué cifrado/consentimiento y retención.
4. **Notificaciones reales.** Las notificaciones son banners falsos. Definir si habrá push/locales reales y su copy; mantener las reglas de elegibilidad (solo persona vinculada activa) y de contraste WCAG.
5. **Envío real de mensajes de cuidado e invitaciones.** Hoy son simulaciones. Definir canal real (in-app, SMS, email) y el modelo de entrega/estado; preservar que el registro nunca incluya notas privadas.
6. **Validación clínica de contenidos pendientes.** Umbrales de la evaluación de relación, escalas del dashboard, cortes de las **métricas de red** (`metricsFor`) y varios textos marcados "por validar". No convertir umbrales ni cortes demostrativos en lógica clínica sin validación.
7. **Panel de investigador.** Decidir si entra en el alcance de la app Flutter (móvil) o es una herramienta aparte; hoy es un mockup de escritorio con datos sintéticos.
8. **Gráficos.** Elegir la librería Flutter para el mapa de red (los gráficos del prototipo son SVG a mano) y para el dashboard (hoy recharts). El motor `metricsFor` se porta igual, independiente del render.
9. **Contactos del dispositivo.** Definir si se integra el acceso real a contactos (permiso del SO) para el plan de seguridad o se mantiene entrada manual.
