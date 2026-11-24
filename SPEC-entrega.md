# Spec 006 — entrega

## Contexto y objetivo
Define los documentos, la propuesta de escalabilidad, el guion de demo, la prueba de usabilidad y el paquete final del proyecto. Cubre el entregable 6 del reto (escalabilidad, integración y documentación técnica) y asegura que los otros cinco sean demostrables.

## Usuarios / actores
- Jurado y personal de Volvo: evalúan y leen la documentación.
- Equipo: prepara, ensaya y presenta.
- Usuarios de prueba: personas ajenas al equipo que juegan el escenario.

## Historias de usuario
- H1: Como jurado quiero entender la arquitectura y cómo escalaría para evaluar la viabilidad.
- H2: Como equipo quiero un guion y un plan B para que la demo no dependa de un solo componente.
- H3: Como jurado quiero poder reproducir el proyecto con instrucciones simples.

## Documentos
- Documentación técnica: arquitectura (módulos y conexiones), modelo de datos SQLite, protocolo del panel, cómo ejecutar, cómo agregar contenido y escenarios en JSON.
- Propuesta de escalabilidad e integración.
- Nota de privacidad y contenido: alias, datos locales, fuentes y marcas `[MUESTRA]`.
- Guion de demo.
- README: instalación, comandos y estructura del repositorio.

## Propuesta de escalabilidad
- Fase 1 (entregada): juego de escritorio, SQLite local, panel opcional.
- Fase 2: más escenarios y competencias (diésel) solo con JSON; contenido oficial de Volvo sustituye el de muestra.
- Fase 3: servidor central, sincronización cuando haya conexión (mantiene offline), cuentas de técnico e instructor con contraseña.
- Integración: LMS o sistema de talento de la empresa; autenticación corporativa (SSO).
- Mejoras de interacción: giroscopio, VR, cámara y asistente LLM local más completo.
- Riesgos y requisitos: protección de datos, validación de contenido por expertos de Volvo, mantenimiento del banco.
- Diagrama de arquitectura actual y objetivo.

## Guion de demo (5 minutos)
1. Problema (30 s).
2. Diagnóstico del técnico ficticio, ya precargado: se muestra su resultado y su ruta (60 s).
3. Escenario de falla de aislamiento con recuperación y brecha (120 s).
4. Resumen y reintento con "¿qué harías distinto?" (30 s).
5. Tablero: ruta, ganancia, retención simulada (post-test y retest precargados con reloj adelantado) y fórmula de un indicador (60 s).
6. Cierre con escalabilidad (30 s).
- Plan B: panel virtual si falla el físico; teclado si falla el control.
- Ensayo completo al menos dos veces.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA incluye documentación técnica con arquitectura, modelo de datos, protocolo del panel, instrucciones de ejecución y guía para agregar contenido y escenarios.
- RF-2: EL SISTEMA incluye una propuesta de escalabilidad e integración con tres fases, riesgos y diagrama de arquitectura actual y objetivo.
- RF-3: EL SISTEMA incluye una nota de privacidad y contenido que declara el uso de alias, datos locales, fuentes y marcas `[MUESTRA]`.
- RF-4: EL SISTEMA incluye un guion de demo de 5 minutos con plan B.
- RF-5: EL SISTEMA incluye un README con instalación en 3 pasos, comandos y estructura del repositorio.
- RF-6: EL SISTEMA se exporta como ejecutable para Windows y Linux.
- RF-7: EL SISTEMA incluye la base SQLite con el técnico ficticio marcado `[DEMO]`.
- RF-8: EL SISTEMA incluye el banco de contenido JSON con sus fuentes y la lista de dependencias y versiones.
- RF-9: CUANDO se prepara la entrega, EL EQUIPO guarda el ejecutable y los datos de demostración en un USB de respaldo.
- RF-10: EL EQUIPO aplica una prueba de usabilidad a al menos 2 personas ajenas al equipo, registra hallazgos con severidad y corrige antes de la demo.
- RF-11: SI ninguna de las personas de prueba tiene conocimiento técnico de vehículos, ENTONCES la documentación lo declara.
- RF-12: ANTES de presentar, EL EQUIPO recorre una checklist de los 6 entregables del reto (diagnóstico, ruta, módulo práctico, evaluación en tres momentos, tablero, escalabilidad y documentación).
- RF-13: EL EQUIPO ensaya la demo completa al menos dos veces con el plan B incluido.

## Requisitos no funcionales
- Documentos en español, claros y breves.
- El repositorio es reproducible a partir del README.
- Todo funciona sin conexión a internet.

## Casos límite
- Falla el panel físico durante la demo: panel virtual.
- Falla el control: teclado y ratón.
- Falla la laptop: USB con ejecutable y datos de demostración en otra máquina.
- Contenido oficial de Volvo llega tarde: se mantiene el de muestra, claramente marcado.

## Fuera de alcance
- Código del juego, firmware y contenido (módulos anteriores).
- Sitio web, video promocional o presentación de marketing más allá del guion.
- Manuales de usuario extensos; basta el README y la ayuda en pantalla.
- Traducciones.
- Certificaciones, cumplimiento legal formal o auditorías de seguridad.
- Instalador con firma digital.

## Criterios de finalización
- Todos los RF cumplidos y la checklist de los 6 entregables sin pendientes.
- Dos ensayos completos de la demo con plan B.
- Prueba de usabilidad con 2 personas registrada y corregida.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Formato y fecha de entrega que exigen los organizadores.
- [NECESITA ACLARACIÓN] Tiempo y formato de la presentación (¿5 minutos?, ¿habrá preguntas?).
- [NECESITA ACLARACIÓN] Quién del equipo escribe cada documento.
