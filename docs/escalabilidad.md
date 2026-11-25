# Propuesta de escalabilidad e integración

## Fases
| Fase | Alcance |
|---|---|
| 1 (entregada) | Juego de escritorio, SQLite local, panel físico opcional, 4 competencias del autobús eléctrico, contenido `[MUESTRA]`. |
| 2 | Más escenarios y competencias (incluido diésel) agregados solo con JSON; el contenido oficial de Volvo sustituye al de muestra sin cambiar código. |
| 3 | Servidor central con sincronización cuando haya conexión (el modo sin conexión se mantiene), cuentas centralizadas y autenticación corporativa. |

## Punto de partida declarado por Volvo
Según la respuesta de un asesor de Volvo a los organizadores (24/11/2026): Volvo cuenta con un LMS limitado para sus empleados (referencia: Cornerstone OnDemand), **pero los entrenamientos de los técnicos no se gestionan en ese sistema y su seguimiento es manual**. Por eso el prototipo no sustituye un LMS existente: digitaliza el seguimiento que hoy se lleva a mano (diagnóstico, ruta, errores, brecha y retención).

## Integración
- Hoy: el tablero y la exportación CSV/JSON reemplazan el seguimiento manual y se pueden abrir en una hoja de cálculo.
- Fase 3: una API o una carga por lotes de esos CSV/JSON hacia el LMS de la empresa, si Volvo decide llevar allí el entrenamiento de técnicos; no se asume que el LMS actual ya lo gestione.
- Autenticación corporativa (SSO) en fase 3.
- Mejoras de interacción posteriores: giroscopio, VR, cámara y un asistente LLM más completo.

## Arquitectura
- **Actual:** una aplicación de escritorio con SQLite local y un panel por USB (ver `docs/arquitectura.md`).
- **Objetivo:** la misma aplicación como cliente offline que sincroniza con un servidor central; el contenido se versiona y se distribuye como paquetes JSON validados.

## Riesgos y requisitos
- **Protección de datos:** las cuentas, roles y hashes viven en SQLite local sin cifrar. La fase 3 requiere controles de acceso del servidor y protección de los datos sincronizados.
- **Validación de contenido:** los valores técnicos y procedimientos deben ser revisados por expertos de Volvo antes de usarse como capacitación oficial.
- **Mantenimiento del banco:** hace falta un responsable de contenido y un proceso de versionado.
- **Honestidad de los datos:** la retención se simula adelantando el reloj; la retención real exige tiempo real.
