# Diseño de la interfaz

Referencia visual: plantilla de Figma "Index Design for a Mechanical Watch and Car Repair Shop" (comunidad). Solo se pudo ver su miniatura pública, así que la paleta se tomó de ahí y la tipografía es una equivalente de uso libre.

## Paleta
| Uso | Color |
|---|---|
| Acento turquesa (botones primarios, títulos destacados, iconos) | `#1AA7A6` (hover `#21A4AA`, pulsado `#129B9A`) |
| Azul petróleo (tarjetas, cabeceras) | `#11507D` y `#185275` |
| Fondo oscuro (hero y paneles) | `#0E1A22` y `#1A2327` |
| Fondo claro de secciones | `#ECFAFA` |
| Blanco | `#FFFFFF` |
| Texto sobre claro / secundario | `#1A2327` / `#5B7480` |
| Estados (se conservan) | éxito `#3FAE6A`, advertencia `#F2B705`, peligro `#D64545` |

## Tipografía
**Poppins** (SIL Open Font License, `godot/assets/fuentes/`): SemiBold para títulos, Medium para botones y Regular para texto. Si el equipo conoce la fuente exacta de la plantilla, se sustituye cambiando los archivos y el tema.

## Catálogo de órdenes de servicio

El catálogo presenta Fácil, Media y Difícil en ese orden. Cada sección indica cuántas órdenes coinciden con el filtro. Las tarjetas se ordenan por número de FG y luego por título. La dificultad va en verde, ámbar o rojo, el FG en turquesa y la marca «Ejemplo didáctico» en azul. El contador de misiones corresponde a los indicios del escenario.

- **Fácil (2).** Comunicación tiene dos misiones de observación y diagnóstico. Tuercas flojas repite el mismo ajuste de torque, con una sola herramienta para el apriete y una secuencia guiada.
- **Media (4).** Faros, aislamiento, neumático pinchado y freno desgastado practican procedimientos habituales. Faros y freno introducen mediciones, aislamiento exige interpretar un indicio de seguridad y el neumático añade el cambio de rueda al patrón de apriete.
- **Difícil (4).** Motor combina medición de temperatura con bloqueo de seguridad. Módulo auxiliar exige medir, reportar e interpretar varios puntos. Fuga neumática y amortiguador combinan trabajo en los bajos con comprobaciones o apriete de componentes de la suspensión.

Estas asignaciones cubren los diez escenarios. Aislamiento requiere evaluar un riesgo crítico, aunque tenga pocas misiones.
