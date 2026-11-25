# Spec 007 — flujo

## Contexto y objetivo
Orquesta la aplicación: ingreso, cuentas y menú principal y el orden guiado diagnóstico → ruta → escenario → post-test → retest → tablero. No calcula nada: llama a `aprendizaje`, `simulador` y `tablero`.

## Usuarios / actores
- Técnico: entra con su usuario y contraseña, realiza las actividades y consulta su tablero.
- Jefe directo: consulta los resultados del equipo y crea cuentas de técnico.
- Administrador: consulta el estado del taller y gestiona cuentas.
- Equipo: usa el modo demo.
- Módulos: `aprendizaje`, `simulador`, `tablero`, `entrada`/`panel`.

## Historias de usuario
- H1: Como técnico quiero entrar con mi usuario y contraseña y que la app me diga qué sigue.
- H2: Como técnico quiero poder retomar donde me quedé.
- H3: Como equipo quiero cargar datos de demostración sin tocar datos reales.

## Pantallas
- Ingreso: Usuario, Contraseña, Entrar y Modo demo. En la primera apertura se crea la cuenta de administración.
- Menú principal: Diagnóstico, Ruta, Práctica, Evaluación, Repetir la evaluación y Tablero para el técnico. Tablero para el jefe directo. Tablero y Administración para el administrador.
- Administración: listado, alta, restablecimiento y borrado confirmado. El jefe directo abre Nuevo técnico desde su tablero.
- Modo demo: cargar `[DEMO]`, adelantar reloj, restablecer demo.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA identifica las cuentas por un usuario único de 3 a 24 caracteres. Se admiten letras minúsculas, números, punto, guion y guion bajo. El usuario comienza con letra o número y se elige sin datos personales.
- RF-2: CUANDO un técnico nuevo entra, EL SISTEMA lo lleva al diagnóstico antes de habilitar la ruta.
- RF-3: EL SISTEMA muestra en el menú el siguiente paso recomendado según el estado del técnico.
- RF-4: EL SISTEMA guarda el avance al terminar cada paso y permite retomar desde ahí.
- RF-5: SI la app se cierra a mitad de un paso, ENTONCES EL SISTEMA reanuda desde el último paso guardado, sin perder lo anterior.
- RF-6: CUANDO se elige Modo demo, EL SISTEMA carga el técnico ficticio `[DEMO]` en una base separada de los datos reales.
- RF-7: DONDE exista el modo demo, EL SISTEMA ofrece "Adelantar reloj" y "Restablecer demo".
- RF-8: EL SISTEMA muestra el estado de la entrada (panel físico, virtual o desconectado) en el menú.
- RF-9: EL SISTEMA funciona sin conexión a internet.
- RF-10: CUANDO existe una cuenta de administración, EL SISTEMA ofrece el ingreso con usuario y contraseña y el acceso a Modo demo sin credenciales.
- RF-11: SI falta una cuenta de administración, EL SISTEMA pide crear la primera con usuario, contraseña de al menos 8 caracteres y confirmación.
- RF-12: CUANDO la persona entra, EL SISTEMA presenta el menú de su rol, muestra su usuario y rol y permite cerrar sesión. Solo los técnicos pueden hacer la formación.
- RF-13: CUANDO una cuenta entra con contraseña temporal, EL SISTEMA pide cambiarla antes de habilitar el menú. El administrador puede crear cualquier rol y restablecer contraseñas. El jefe directo solo puede crear técnicos. Las contraseñas generadas se muestran una vez y pueden copiarse.
- RF-14: CUANDO se acumulan cinco intentos incorrectos seguidos para una cuenta, EL SISTEMA bloquea el ingreso durante 30 segundos. La espera crece con cada grupo adicional de cinco fallos. Un ingreso correcto reinicia el contador.
- RF-15: CUANDO falla un formulario de cuenta, EL SISTEMA muestra un mensaje en una tarjeta modal con Aceptar. Si la cuenta está bloqueada, informa los segundos y deshabilita Entrar durante la espera.

## Requisitos no funcionales
- Navegable con teclado, control y ratón.
- Español.
- Cada pantalla se alcanza en 2 acciones desde el menú.

## Casos límite
- Usuario inválido o repetido: se rechaza con un mensaje.
- Retest solicitado antes de adelantar el reloj: se avisa cuánto falta.
- Las cuentas heredadas quedan registradas sin acceso. El administrador puede borrarlas y crear cuentas nuevas.

## Fuera de alcance
- Cálculo de dominio y ruta (`aprendizaje`), escenarios (`simulador`), vistas (`tablero`).
- Sincronización de cuentas y credenciales entre equipos.

## Criterios de finalización
- RF con prueba (automática para guardado y reanudación; checklist manual para pantallas) en verde.
- Demo manual: crear administrador → crear técnico → entrar y cambiar contraseña → diagnóstico → ruta → práctica → cerrar sesión → modo demo.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Si un técnico puede repetir el diagnóstico.
