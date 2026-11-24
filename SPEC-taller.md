# Spec 009 — taller, inventario y elevador

## Contexto y objetivo
Amplía la práctica en primera persona para que se parezca a trabajar en un taller: el técnico necesita **herramientas y piezas**, las busca en el taller, las **lleva consigo** con capacidad limitada y, si le falta algo, el sistema le **dice dónde está y se lo señala**. Añade un **elevador** para trabajar por debajo del autobús (ruedas, suspensión, frenos) y **más órdenes de servicio** de diferentes tipos, para no quedarnos con pocos casos.

## Usuarios / actores
- Técnico: toma herramientas y piezas, trabaja sobre y bajo el autobús.
- Autor de contenido: declara en el JSON qué requiere cada acción.
- Módulos: `simulador` (zonas, motor de estado, menú de pieza), `panel` (torque con la perilla), `competencias` (mapeo de competencias), `tablero` (errores).

## Historias de usuario
- H1: Como técnico quiero tomar la herramienta correcta de una caja y la pieza de una estantería para practicar el orden real de trabajo.
- H2: Como técnico quiero que el sistema me diga dónde está lo que me falta y me lo señale, para no perder tiempo buscando.
- H3: Como técnico quiero subir el autobús con un elevador y trabajar por debajo, siguiendo el procedimiento seguro.
- H4: Como equipo quiero muchas órdenes de servicio distintas para que la demo y el entrenamiento no se repitan.

## Taller
- **Mesa de trabajo:** superficie donde se pueden dejar y volver a tomar herramientas y piezas.
- **Caja roja de herramientas** (la que ya está junto al autobús, ahora funcional con cajones): llave ajustable, destornillador, multímetro, manómetro de presión de neumáticos, llave de torque, flexómetro, lámpara, calzas y Tech Tool.
- **Estantería de piezas:** foco, fusibles (correcto y equivocado), abrazadera, tuercas de rueda, bolsa de aire, amortiguador, neumático y pastillas de freno.
- **Carrito de herramientas:** amplía la capacidad de carga mientras se empuja o se tiene cerca.
- **Elevador:** consola con **Subir** y **Bajar** junto al autobús.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA incluye en el taller una mesa de trabajo, una caja roja de herramientas con cajones, una estantería de piezas y un carrito.
- RF-2: CUANDO el técnico pulsa sobre una herramienta o una pieza, EL SISTEMA ofrece "Tomar" en el menú de la pieza, y "Dejar" para lo que lleva consigo.
- RF-3: EL SISTEMA limita lo que el técnico lleva a 4 espacios en el cinturón y 4 más en el carrito, y SI no hay espacio, ENTONCES rechaza "Tomar" y lo explica.
- RF-4: EL SISTEMA muestra en pantalla lo que el técnico lleva, con nombre y espacio ocupado, y permite elegir qué tiene en la mano.
- RF-5: CADA acción de un escenario puede declarar `requiere` (herramientas y piezas); SI el técnico no lo lleva, ENTONCES EL SISTEMA rechaza la acción y nombra lo que falta.
- RF-6: CUANDO se ejecuta una acción, EL SISTEMA consume las piezas que requería y conserva las herramientas.
- RF-7: SI al rechazar por falta de algo existe en el taller, ENTONCES EL SISTEMA indica dónde está (nombre del mueble y la zona) y lo señala con una baliza visible y un indicador en pantalla.
- RF-8: CUANDO el técnico pulsa la tecla de guía, EL SISTEMA vuelve a señalar el siguiente requisito pendiente.
- RF-9: AL iniciar o reintentar una orden, EL SISTEMA vacía el inventario y devuelve piezas y herramientas a su lugar.
- RF-10: EL SISTEMA incluye un elevador cuya consola sube y baja el autobús y sus zonas con una animación.
- RF-11: ANTES de subir el autobús, EL SISTEMA exige las calzas colocadas, y SI faltan, ENTONCES rechaza **Subir** y explica por qué.
- RF-12: DESPUÉS de subir el autobús, EL SISTEMA exige trabar los soportes; SI el técnico trabaja bajo el autobús sin trabas, ENTONCES registra una falta crítica con explicación y fuente.
- RF-13: EL SISTEMA permite caminar bajo el autobús elevado, con colisiones coherentes, y trabajar en las zonas de ruedas, suspensión y frenos.
- RF-14: CUANDO se aprietan las tuercas de una rueda, EL SISTEMA compara el valor de la perilla del panel con el rango del escenario y registra `valor-fuera-de-rango` si no coincide.
- RF-15: EL SISTEMA incluye al menos 8 órdenes nuevas (neumático pinchado, tuercas de rueda flojas, fuga de suspensión neumática, amortiguador dañado, freno desgastado, carga CCS que no inicia, puerta de pasajeros que no cierra y luces interiores apagadas), cada una con sus acciones, requisitos y variante.
- RF-16: EL SISTEMA agrupa el catálogo de órdenes por zona o tema y permite desplazarse por él con teclado, ratón y control.
- RF-20: CADA escenario declara su `grupo_funcion` (FG 0 a FG 9, según la estructura de Volvo en `docs/fuentes-volvo.md`) y el catálogo de órdenes se agrupa por FG.
- RF-21: EL SISTEMA incluye en la caja de herramientas una herramienta de diagnóstico tipo Tech Tool que muestra códigos de falla genéricos `[MUESTRA]` de la orden activa.
- RF-22: EL SISTEMA incluye órdenes alineadas con los cursos de Volvo: sistema electrónico de suspensión (FG 7), frenos neumáticos (FG 5), puerta de pasajeros y aire acondicionado (FG 8).
- RF-23: EL SISTEMA permite dejar y guardar lo que lleva el técnico: en la mesa de trabajo y en el carrito puede dejar herramientas y piezas, y en la caja roja puede guardar las herramientas en sus cajones; el carrito y la mesa no se pueden tomar como objeto.
- RF-24: EL SISTEMA permite elegir el objeto en la mano con las teclas numéricas 1 a 4 (cinturón) y 5 a 8 (carrito, si está cerca) cuando no hay un menú abierto, y con rueda, flechas o L y R; el HUD muestra los ocho espacios numerados con su contenido y marca el elegido.
- RF-25: CADA acción de un escenario que implique trabajo sobre una pieza declara `requiere.herramienta` y EL SISTEMA exige que esa herramienta esté **en la mano**; SI el técnico la lleva pero no la tiene en la mano, ENTONCES lo avisa y le indica la tecla; SI tiene en la mano otra herramienta, ENTONCES muestra una tarjeta "Herramienta equivocada" con la que tiene y la que necesita y registra el error leve `herramienta-equivocada`.
- RF-26: AL terminar una orden, EL SISTEMA muestra las preguntas de diagnóstico ("¿Qué causó la falla?") y dice si la respuesta fue correcta o incorrecta, con la causa real, una explicación breve y la fuente, y registra el resultado para `aprendizaje` y `tablero`. El contenido vincula `causa_correcta` y `explicacion_causa` con las claves de `causas`. El intento final conserva la puntuación de práctica que aporta al dominio.
- RF-27: EL SISTEMA muestra el título completo de la orden en el HUD, en varias líneas si hace falta.
- RF-28: MIENTRAS el siguiente subpaso de la misión es tomar una herramienta o una pieza, EL SISTEMA marca ese objeto en azul con un contorno, muestra una flecha en pantalla hacia él cuando está fuera de cuadro y, si está dentro de un cajón cerrado, marca el cajón; y CUANDO el subpaso es tener la herramienta en la mano, resalta en azul su espacio en el inventario; todo sin pulsar la tecla de guía.
- RF-29: CADA subpaso de una misión que implique ir a un mueble o a una pieza dice **dónde está** con palabras que el jugador reconoce ("la caja roja de herramientas, junto a la mesa", "la estantería de repuestos", "la mesa de trabajo", "el carrito", "la consola del elevador") y los muebles llevan un rótulo visible en el taller; la tarjeta de orden incluye una leyenda "Dónde está todo".
- RF-17: EL SISTEMA mapea las órdenes nuevas a las cuatro competencias existentes (`diagnostico-fallas` para las mecánicas, `sistema-electrico-bateria` y `electronica-conectividad` para las eléctricas).
- RF-18: EL SISTEMA funciona con teclado y ratón, Pro Controller y panel virtual, y sin conexión a internet.
- RF-19: EL SISTEMA marca `[MUESTRA]` en todo valor técnico que no provenga de material oficial; los valores de las órdenes mecánicas son genéricos y no se inventan cifras.

## Requisitos no funcionales
- Escena ligera: menos de 120 000 triángulos en total con el elevador y los muebles.
- Español en rótulos, menús y avisos.
- Las balizas y el inventario no tapan el centro de la pantalla.

## Casos límite
- Tomar algo que ya llevas: se rechaza con mensaje.
- Dejar algo en la mesa y volver por ello: sigue ahí hasta reiniciar la orden.
- Bajar el elevador con las trabas puestas: se rechaza y se pide destrabar.
- Subir el elevador con el jugador debajo del autobús: se rechaza hasta despejar el área.
- Reintentar a mitad de una orden: inventario y elevador vuelven al estado inicial.
- Pieza requerida que ya se consumió: se pide otra de la estantería; si no hay existencias se informa.

## Fuera de alcance
- Física realista de piezas o de la carga, desmontaje real de ruedas y modelos 3D detallados de componentes.
- Quinta competencia de mecánica (queda para una iteración futura, con material oficial de Volvo).
- Procedimientos de mantenimiento certificados: los pasos son didácticos y se marcan `[MUESTRA]` hasta recibir la documentación de Volvo.

## Criterios de finalización
- Todos los RF con prueba (automática para inventario, requisitos, consumo, seguridad del elevador y escenarios; checklist manual para la escena, la guía y las balizas) en verde.
- Demo manual: tomar una pieza y una herramienta, que falte una y el sistema la señale, subir el autobús con el procedimiento, resolver una falla de rueda con la perilla de torque y bajar.
- Las ocho órdenes nuevas se completan por su ruta ideal y aparecen en el catálogo.

## Decisión sobre aprobación
La línea de aprobación del tablero es **91**, tomada de la "calificación mínima aprobatoria" de los cursos Volvo Buses 2023. Se muestra como referencia sin cambiar el cálculo de dominio de `aprendizaje`.

## Dudas abiertas
- [NECESITA ACLARACIÓN] La documentación técnica de Volvo, que ya fue entregada a los organizadores y se enviará al equipo: sustituirá valores `[MUESTRA]` y pasos genéricos.
- [NECESITA ACLARACIÓN] Si el material de Volvo se puede incluir en el repositorio o debe quedar fuera de git por confidencialidad.
