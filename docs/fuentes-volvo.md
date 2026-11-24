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
