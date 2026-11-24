# Propuesta de escalabilidad e integración

## Fases
| Fase | Alcance |
|---|---|
| 1 (entregada) | Juego de escritorio, SQLite local, panel físico opcional, 4 competencias del autobús eléctrico, contenido `[MUESTRA]`. |
| 2 | Más escenarios y competencias (incluido diésel) agregados solo con JSON; el contenido oficial de Volvo sustituye al de muestra sin cambiar código. |
| 3 | Servidor central con sincronización cuando haya conexión (el modo sin conexión se mantiene), cuentas de técnico e instructor con contraseña. |

## Integración
- LMS o sistema de talento de la empresa mediante la exportación CSV/JSON ya existente y, en fase 3, una API.
- Autenticación corporativa (SSO) en fase 3.
- Mejoras de interacción posteriores: giroscopio, VR, cámara y un asistente LLM más completo.

## Arquitectura
- **Actual:** una aplicación de escritorio con SQLite local y un panel por USB (ver `docs/arquitectura.md`).
- **Objetivo:** la misma aplicación como cliente offline que sincroniza con un servidor central; el contenido se versiona y se distribuye como paquetes JSON validados.

## Riesgos y requisitos
- **Protección de datos:** hoy solo hay alias; con cuentas reales hará falta consentimiento, cifrado y control de acceso.
- **Validación de contenido:** los valores técnicos y procedimientos deben ser revisados por expertos de Volvo antes de usarse como capacitación oficial.
- **Mantenimiento del banco:** hace falta un responsable de contenido y un proceso de versionado.
- **Honestidad de los datos:** la retención se simula adelantando el reloj; la retención real exige tiempo real.
