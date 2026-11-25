# Fuentes públicas de Volvo Buses

Datos citables para los ítems y escenarios. Son especificaciones de producto, **no procedimientos de mantenimiento**: no contienen pares de apriete ni pasos de reparación, así que esos valores siguen siendo `[MUESTRA]` hasta recibir material oficial.

## Volvo BZR Low Entry Eléctrico (chasis)
- Fuente: Volvo Buses, "Chasis de autobús BZR Low Entry Eléctrico", https://www.volvobuses.com/es/city-and-intercity/chassis/volvo-bzr-le-electric.html (consultada el 24/11/2026).
- Sistema de almacenamiento de energía (ESS): iones de litio, 600 V, control automático de temperatura y recuperación de energía de frenado.
- Baterías: hasta siete unidades Volvo Cube de 90 kWh cada una, hasta 630 kWh en total (valor nominal).
- Sistema de gestión de batería (BMS): controla la carga y descarga y vigila el estado y el rendimiento de la batería.
- Cadena cinemática: uno o dos motores eléctricos; potencia máxima de 200 kW por motor (hasta 400 kW, 540 CV); par máximo de rueda de 20 900 Nm (33 500 Nm con dos motores).
- Transmisión automática de 2 velocidades, controlada por software; función de arranque en pendientes.
- Carga: en cochera con cable CCS (máx. 250 kW) y en ruta con OppCharge (máx. 450 kW).
- Dirección: Volvo Dynamic Steering (motor eléctrico de par alto que asiste la dirección).
- Cabina: cuadro de instrumentos digital con vista analógica o digital, volante multifunción.
- Seguridad: sistema de control de presión de neumáticos, alerta acústica AVAS y alerta de cansancio del conductor.

## Uso en el proyecto
- **Zona del motor** (`motor.json`): motor eléctrico, transmisión de 2 velocidades, control automático de temperatura, BMS y ESS de 600 V.
- **Cabina** (`comunicacion.json`): cuadro de instrumentos digital y estado del BMS.
- **Seguridad en alto voltaje:** el ESS de 600 V respalda la regla de bloquear, etiquetar y verificar antes de tocar cables naranja.
- Cualquier ítem que use estos datos cita la página como fuente y mantiene `muestra=true` si el valor numérico del escenario no proviene de aquí.

## Material entregado por Volvo en la asesoría (24/11/2026)
Fuente de prioridad máxima según la constitución (material oficial entregado por la empresa). Son presentaciones de la asesoría, no manuales: no traen valores de apriete ni pasos de reparación, así que esos siguen siendo `[MUESTRA]`.

### Grupos de función (FG 0 a FG 9)
Es la estructura con la que Volvo organiza la capacitación técnica y el catálogo de partes (plataforma IMPACT).

| FG | Tema | Enfoque del entrenamiento |
|---|---|---|
| 0 | General | Familiarización, operación segura y comprensión de los sistemas. |
| 1 | Servicio y mantenimiento | Inspección, mantenimiento preventivo y detección de desgaste o fallas. |
| 2 | Motor | Funcionamiento, emisiones y postratamiento (en eléctricos, el motor de tracción). |
| 3 | Sistema eléctrico | Interpretar circuitos, localizar fallas y trabajar con seguridad en alta tensión, baterías y carga. |
| 4 | Transmisión | Transmisión de potencia, control electrónico y servicio. |
| 5 | Frenos | Frenos neumáticos y electrónicos, ABS, desgaste. |
| 6 | Suspensión y dirección | Dirección, ejes y suspensión; identificar fallas. |
| 7 | Bastidor, resortes, amortiguadores y ruedas | Suspensión electrónica, control de altura; diagnosticar, ajustar y mantener el chasis. |
| 8 | Carrocería e interior | Puertas, climatización, accesibilidad y equipos interiores. |
| 9 | Temas diversos | Sistemas de seguridad contra incendios. |

### Estructura de cursos Volvo Buses 2023 (junio de 2023)
- **Módulo I:** familiarización y mantenimiento B13R y B8R; IMPACT enfocado a servicio; **BEA: interpretación de diagramas eléctricos**.
- **Módulo II:** overhaul de transmisión, motor y grupo cónico.
- **Módulo III:** sistema SCR; Tech Tool (diagnóstico guiado); BEA Body; aire acondicionado.
- **Módulo IV:** diagnóstico de motor y de transmisión I-Shift; **sistema electrónico de suspensión**; **sistema de frenos y Driver Support System (DSS)**.
- **Especialidades:** certificación Mecatrónico I a IV.
- Los cursos duran de 1 a 5 días (8 a 40 h). **Calificación mínima aprobatoria: 91** (80 en la certificación de Mecatrónico).
- Perfil de entrada del Mecatrónico: técnico con experiencia de al menos 4 años; el reto atiende desde recién graduados hasta técnicos con años de experiencia.

### Contexto operativo (asesoría)
- Mantienen los autobuses los técnicos de los WSI y PSV de Volvo o los técnicos del cliente en sus instalaciones; en clientes retail los PSV hacen el seguimiento.
- La demostración debe usar un caso anonimizado, sin información técnica confidencial y sin depender de documentación restringida.
- Los cursos de 2023 son del portafolio diésel; los de autobús eléctrico no aparecen en esa retícula.

## Cómo lo usamos
- Cada escenario declara su `grupo_funcion` (FG 3 para aislamiento, faros y banco de arnés; FG 7 y FG 6 para suspensión y ruedas; FG 5 para frenos; FG 8 para puertas y aire; FG 2 para el motor de tracción) y el catálogo se agrupa por FG.
- La línea de aprobación del tablero toma la de los cursos de Volvo: **91**.
- El banco de arnés cubre "interpretación de diagramas eléctricos" (BEA) y una herramienta de diagnóstico tipo Tech Tool se suma al taller como objeto del inventario, con códigos de falla genéricos.

## Preguntas nuevas del banco (T-176)

Las 20 preguntas de opción múltiple están marcadas como ejemplos didácticos y quedan pendientes de revisión por Volvo. Las referencias cuentan las páginas del PDF desde 1, incluidas las portadas y páginas en blanco.

| PDF usado | Páginas citadas | Preguntas |
| --- | --- | ---: |
| `Fact-sheet-Electric-Safety-EN-VolvoBuses-2024-Es-Mx.pdf` | 4, 5, 8 | 6 |
| `Data sheet BZL Electric ES-MX 2021.pdf` | 3 | 3 |
| `volvo_9700_manual_en_3.pdf` | 34 | 1 |
| `h3_operator_manual_en_0.pdf` | 17, 64, 71, 72, 132 | 8 |
| `PA1583-2 Literature.pdf` | 11 | 2 |

| Competencia | Fácil | Media | Difícil | Total |
| --- | ---: | ---: | ---: | ---: |
| Seguridad de alto voltaje | 1 | 2 | 1 | 4 |
| Sistema eléctrico y batería | 1 | 1 | 4 | 6 |
| Diagnóstico de fallas | 1 | 2 | 1 | 4 |
| Electrónica y conectividad | 1 | 1 | 4 | 6 |
| **Total** | **4** | **6** | **10** | **20** |
