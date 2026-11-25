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

## Mapa de la ruta de aprendizaje

«Tu ruta» indica por qué competencia empezar, identifica el origen de la ruta y muestra una leyenda de cuatro estados. Los nodos numerados usan Poppins y muestran el estado, el porcentaje y una barra de dominio de 6 px. El relleno es ámbar para «Primero», turquesa para «Hoy», claro para «Después» y verde para «Hecho». El primer nodo lleva «Empieza aquí» y los nodos hechos llevan una marca de verificación.

El camino enlaza las competencias con una línea sólida y flechas descendentes. Los conectores en codo unen cada competencia con los errores a la izquierda y las prácticas a la derecha. Cada lado muestra hasta tres fichas de contenido. «+N más» abre el detalle de la competencia con la lista completa. Las faltas críticas tienen borde rojo. A la derecha aparecen primero los temas de la propuesta y luego las órdenes del taller. Las citas, las marcas didácticas y el refuerzo ampliado se consultan en el detalle.

«Continuar» y «Paso 2 de 6: tu ruta» quedan en el pie fijo. A 1920 × 1080 caben las cuatro competencias en la misma vista. A 1280 × 720, el mapa se desplaza sin mover el pie.

Cada tarjeta se activa con clic, Enter o Espacio. Al pasar el ratón se aclara el relleno y aparece el cursor de mano. Un borde blanco de 3 px marca el foco de teclado.

El panel se abre a la derecha y se desplaza por separado. Tiene fondo oscuro, un borde neutro de 1 px, un título de 22 px, el estado con texto y color, y texto de 16 px. «Cerrar» recibe el foco al abrir. Escape y «Cerrar» devuelven el foco a la tarjeta. Al elegir otra tarjeta visible, el panel actualiza su contenido. Los errores muestran los intentos disponibles. La acción de una competencia abre el catálogo filtrado y la de una orden abre su práctica. «Volver» retoma la ruta.


## Tablero de progreso

La cuenta de jefe directo abre la lista de técnicos. El usuario es el acceso a la ficha y el estado combina una marca de color con una palabra. Las cuatro barras usan un relleno neutro y muestran el nombre del nivel. La última columna indica la fecha del historial más reciente.

La ficha usa el título más grande para la recomendación. Debajo quedan sus evidencias y la frase que atribuye la decisión al jefe directo. Las competencias se leen en dos columnas, con separadores finos, texto breve y barras de 6 px sobre el fondo oscuro. Los tiempos, las brechas y el historial se pueden desplegar. «Volver a la lista» y «Exportar» están en la barra fija. Al volver, el foco regresa al alias abierto.

Las vistas admiten desplazamiento vertical a 1280 × 720 y 1920 × 1080. Los botones usan el foco visible del tema Poppins.


## Ingreso y menú

El formulario se centra en 420 px. Usa etiquetas visibles y Poppins sobre fondo oscuro. La acción principal va en turquesa con texto oscuro. La tarjeta de error se cierra con Aceptar o Escape. Si la cuenta queda bloqueada, el formulario muestra los segundos restantes junto a Entrar. La creación del primer administrador y el cambio obligatorio usan el mismo formulario.

El menú muestra el usuario, su rol y Cerrar sesión. Las acciones de formación se presentan en filas y la actividad recomendada usa el acento principal. El jefe directo abre Nuevo técnico desde su tablero.

## Administración y estado del taller

Administración presenta una tabla con usuario, rol, estado y acciones. Nueva cuenta abre un formulario. La contraseña temporal se muestra en una tarjeta con Copiar y se borra de la pantalla al cerrarla. Borrar abre una confirmación.

El tablero del administrador agrupa cuentas, contenido y servicios, y actividad de técnicos. Los estados se expresan con texto. Las otras vistas están disponibles para consulta. El botón Administración lleva a la gestión de cuentas.

Los controles de cuenta usan bordes de 1 px, radio de 3 px y foco de teclado de 3 px. Las listas pueden desplazarse a 1280 × 720 y 1920 × 1080.
