# Spec 007 — flujo

## Contexto y objetivo
Orquesta la aplicación: alta de técnico, menú principal y el orden guiado diagnóstico → ruta → escenario → post-test → retest → tablero. No calcula nada: llama a `aprendizaje`, `simulador` y `tablero`.

## Usuarios / actores
- Técnico: elige alias y avanza por el menú.
- Equipo: usa el modo demo.
- Módulos: `aprendizaje`, `simulador`, `tablero`, `entrada`/`panel`.

## Historias de usuario
- H1: Como técnico quiero entrar con un alias y que la app me diga qué sigue.
- H2: Como técnico quiero poder retomar donde me quedé.
- H3: Como equipo quiero cargar datos de demostración sin tocar datos reales.

## Pantallas
- Alias: crear o elegir técnico.
- Menú principal: Diagnóstico, Ruta, Escenario, Evaluación (post-test y retest), Tablero, Modo demo.
- Modo demo: cargar `[DEMO]`, adelantar reloj, restablecer demo.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA pide un alias al iniciar y no acepta nombres reales ni alias repetidos.
- RF-2: CUANDO un técnico nuevo entra, EL SISTEMA lo lleva al diagnóstico antes de habilitar la ruta.
- RF-3: EL SISTEMA muestra en el menú el siguiente paso recomendado según el estado del técnico.
- RF-4: EL SISTEMA guarda el avance al terminar cada paso y permite retomar desde ahí.
- RF-5: SI la app se cierra a mitad de un paso, ENTONCES EL SISTEMA reanuda desde el último paso guardado, sin perder lo anterior.
- RF-6: CUANDO el técnico elige Modo demo, EL SISTEMA carga el técnico ficticio `[DEMO]` en una base separada de los datos reales.
- RF-7: DONDE exista el modo demo, EL SISTEMA ofrece "Adelantar reloj" y "Restablecer demo".
- RF-8: EL SISTEMA muestra el estado de la entrada (panel físico, virtual o desconectado) en el menú.
- RF-9: EL SISTEMA funciona sin conexión a internet.

## Requisitos no funcionales
- Navegable con teclado, control y ratón.
- Español.
- Cada pantalla se alcanza en 2 acciones desde el menú.

## Casos límite
- Alias vacío o repetido: se rechaza con mensaje.
- Retest solicitado antes de adelantar el reloj: se avisa cuánto falta.
- Sin técnico seleccionado: solo alias y modo demo disponibles.

## Fuera de alcance
- Cálculo de dominio y ruta (`aprendizaje`), escenarios (`simulador`), vistas (`tablero`).
- Cuentas, contraseñas y sincronización.

## Criterios de finalización
- RF con prueba (automática para guardado y reanudación; checklist manual para pantallas) en verde.
- Demo manual: alias nuevo → diagnóstico → ruta → escenario → modo demo.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Si un técnico puede repetir el diagnóstico.
