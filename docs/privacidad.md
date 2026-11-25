# Nota de privacidad y contenido

## Datos
- Cada cuenta usa un **usuario** (por ejemplo `tecnico01`). Elige un identificador sin nombres reales ni datos personales.
- Los datos viven **en el equipo** (SQLite local). Solo la generación opcional de la ruta con Foundry envía a la nube un identificador seudónimo, el dominio por competencia, los tipos de error y el catálogo de órdenes; nunca el usuario, nombres ni texto libre. Sin configuración o sin conexión no se envía nada.
- El asistente opcional usa un modelo local y solo recibe datos con alias.
- La contraseña se registra únicamente como hash PBKDF2 con sal. El usuario, el rol, la contraseña, su hash y la información de bloqueo se mantienen en el equipo.
- El archivo SQLite y sus respaldos locales se guardan sin cifrar. El ingreso protege contra el uso casual. Quien pueda editar el archivo puede modificar los datos y los permisos.
- El jefe directo puede exportar resultados desde la ficha de un técnico. El administrador puede borrar cuentas y su progreso desde Administración.

## Contenido
- Cada pregunta, caso y paso cita su fuente. Fuentes permitidas: documentación pública de Volvo Buses, NFPA 70E, NOM-029-STPS, NOM-001-SEDE, ISO 6469 y material oficial de la empresa.
- El contenido que no proviene de material oficial lleva la marca **`[MUESTRA]`**.
- Los datos de demostración llevan la marca **`[DEMO]`** y viven en una base separada.
- Todo es simulado: no se manipula un bus real ni alto voltaje; el panel físico es una maqueta de bajo voltaje por USB.
- Las reglas de seguridad están escritas a mano; ningún modelo de lenguaje las genera ni cambia el dominio. La ruta que propone la IA se valida contra el catálogo y las reglas de seguridad, y se registra como "Ruta generada con IA".
- La clave y el endpoint de Foundry viven en un archivo local fuera de git (`user://foundry.cfg`) o en variables de entorno.

## Modelos 3D
Si se usa un modelo de terceros, se declara aquí su autor y licencia. Un modelo con marca Volvo hecho por un aficionado es solo una referencia visual y no representa el vehículo del escenario.

## Pruebas de usabilidad
Se declara si las personas que probaron el sistema tenían o no conocimiento técnico de vehículos.

## Créditos de modelos 3D
- Autobús exterior: "3D Bus" de ajanhallinta, licencia CC0 (https://opengameart.org/content/3d-bus). Referencia visual genérica; no representa un modelo Volvo ni el vehículo del escenario.
- Props del taller: conos y señales de "LowPoly Public Transport" de Quaternius, licencia CC0 (https://opengameart.org/node/83020).
- Brazos de primera persona: "Low Poly Arms (Rigged)" de DevMops, CC0 (https://opengameart.org/node/156502).
- Herramientas: "Tool Pack 1", CC0 (https://opengameart.org/content/tool-pack-1).

- Fuente Poppins (SIL Open Font License), en godot/assets/fuentes/.
