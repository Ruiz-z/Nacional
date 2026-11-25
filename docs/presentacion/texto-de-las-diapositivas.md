<!-- Slide number: 1 -->
![Autobús eléctrico dentro del taller virtual](foto-taller)
Técnicos del Mañana
Una plataforma para que los técnicos aprendan a diagnosticar fallas en autobuses eléctricos Volvo
HackaTec 2026 · Reto Volvo

### Notes:
Buenas tardes. Somos el equipo de Técnicos del Mañana. En los próximos minutos mostramos qué construimos para el reto de Volvo, cómo funciona y qué falta para llevarlo a un taller real.

<!-- Slide number: 2 -->
El error que se repite está en la lógica del procedimiento
Volvo nos confirmó que los técnicos fallan en la lógica de la solución de problemas, aunque tengan códigos de falla, diagnóstico guiado y el apoyo de BackOffice.
El seguimiento de la capacitación se lleva a mano.
El jefe directo decide cuándo un técnico sube de nivel, según su desempeño diario y los resultados de los cursos.
3 de 5
categorías de falla de Volvo se relacionan con nuestros escenarios de hoy: unidades de control, arneses y, en parte, la batería
Esto no equivale a cubrir el 60 % de las fallas.
2

### Notes:
La respuesta de Volvo cambió cómo planteamos el proyecto. El técnico suele tener la información y aun así se equivoca en el orden del procedimiento. Por eso evaluamos cómo diagnostica, además de qué concluye. Tres de las cinco categorías de falla que nos dieron se relacionan con nuestros escenarios. No decimos que cubrimos el 60 por ciento de las fallas.

<!-- Slide number: 3 -->
Cubrimos los seis entregables del reto
Diagnóstico
Ruta de aprendizaje
1
2
Diez preguntas sobre cuatro competencias, distintas para cada técnico
Un mapa ordenado según el resultado, armado con la IA de Foundry
Módulo práctico
Evaluación en tres momentos
3
4
Autobús eléctrico en 3D, con panel físico opcional
Diagnóstico, post-test y retest a los 7 días
Tablero
Escalabilidad
5
6
Gráficas y evidencia para el técnico, el jefe directo y el admin
Tres fases, documentación completa y 157 pruebas automáticas
3

### Notes:
Recorrimos la lista de entregables del reto y cada uno tiene algo funcionando. Los vamos a ver en el orden en que los usa un técnico.

<!-- Slide number: 4 -->
El diagnóstico arma una ruta distinta para cada técnico
![Mapa de la ruta de aprendizaje con cuatro competencias numeradas](captura-29)
Diez preguntas sobre seguridad de alto voltaje, sistema eléctrico, diagnóstico y conectividad.
La ruta pone primero la competencia donde hubo una falta crítica.
Al pulsar un nodo se ve qué falló, cómo evitarlo y qué practicar, con el manual de Volvo como fuente.
Ruta de un técnico con datos de ejemplo.
4

### Notes:
El técnico contesta diez preguntas y no todos reciben las mismas. Con el resultado se arma un mapa. Lo primero que aparece es la competencia donde tuvo una falta crítica, por ejemplo en seguridad. Cada nodo se puede abrir y dice qué falló, cómo evitarlo y qué practicar, con la fuente del manual.

<!-- Slide number: 5 -->
La IA propone la ruta y la aplicación decide si la acepta
1
2
3
La app envía el dominio y los errores con un seudónimo. No viaja el nombre ni el usuario.
Faro, el agente de Foundry, consulta 8 manuales de Volvo y responde con la ruta. Cada tema lleva su PDF.
La app revisa la respuesta: competencias, orden, órdenes del catálogo y fuentes. Si algo falla, usa una ruta por reglas y lo avisa.
10 s
3 de 3
aproximadamente por ruta
respuestas válidas en la última prueba con Faro
5

### Notes:
La IA no decide sola. Le mandamos datos sin nombre, ella consulta los manuales de Volvo y la aplicación revisa lo que devuelve. Si la respuesta no cumple el formato, o no hay conexión, se usa una ruta calculada por reglas y la pantalla lo dice. En la última prueba real las tres respuestas fueron válidas y tardaron unos diez segundos.

<!-- Slide number: 6 -->
En la práctica se registra cada paso que da el técnico
![Cabina del autobús con la misión Revisa los síntomas de la red](captura-42)
Autobús eléctrico en primera persona, con 10 órdenes de servicio de tres dificultades.
El motor anota el orden de los pasos, los que se omiten y las acciones innecesarias.
Una falta de seguridad se marca en el momento y queda en el historial.
El banco del arnés con ESP32 se conecta por UDP. Sin la placa, el panel virtual cumple la misma función.
![Banco de diagnóstico con multímetro y puntos TP1 y TP2](captura-44)
6

### Notes:
Aquí está la parte más pesada del proyecto. El técnico camina por el taller, toma herramientas y ejecuta la orden. El motor registra el orden de lo que hizo el técnico, lo que se saltó y lo que hizo de más, además de si llegó a la causa. Para el banco del arnés usamos una placa ESP32 que manda las tensiones por UDP. Si no la hay, el panel virtual hace lo mismo.

<!-- Slide number: 7 -->
El tablero da la evidencia y el jefe directo decide
Tres momentos: el diagnóstico, el post-test y un retest a los 7 días. En la demo el reloj se adelanta, así que la retención es simulada.
El tablero muestra ganancia, retención, errores por tipo y faltas críticas con su fecha.
Volvo dijo que el paso de nivel lo decide el jefe directo. La plataforma le da la evidencia y una recomendación, y la decisión es de él.
![Tablero del jefe directo con mapa de calor del equipo y errores por tipo](captura-47)
Vista del jefe directo con datos de demostración.
7

### Notes:
Los tres momentos de evaluación son el diagnóstico inicial, un post-test y un retest a los siete días. Para la demostración adelantamos el reloj, así que lo que vean de retención es simulado y lo decimos siempre. Volvo nos dijo que el paso de nivel lo decide el jefe directo. Por eso el tablero no sube a nadie de nivel: le da la evidencia y una recomendación.

<!-- Slide number: 8 -->
Cada rol ve el tablero con su propio enfoque
![Técnico](icono-50)
![Jefe directo](icono-54)
![Admin](icono-58)
Técnico
Jefe directo
Admin
Su ruta, su dominio por competencia, sus errores y qué practicar.
El equipo completo, una recomendación con sus evidencias y la exportación a CSV o JSON.
Las cuentas, el estado del taller, las preguntas sin revisar, el respaldo y el estado de la IA.
Ingreso con usuario y contraseña. Los permisos se validan también en la lógica de los datos.
8

### Notes:
El ingreso es con usuario y contraseña, y la contraseña se guarda con un hash. El mismo tablero se adapta a quien lo abre. El técnico ve lo suyo. El jefe directo ve al equipo con la recomendación. El admin ve el estado del taller y las cuentas.

<!-- Slide number: 9 -->
Materiales de estudio con IA que una persona revisa antes de publicar
Once formatos: tarjetas, presentación, infografía, quiz, pareo, ordena los pasos, ahorcado, verdadero o falso, completa la frase, clasifica y caso de falla.
Cada material cita el PDF de donde sale.
Nacen como borrador. El técnico solo ve los que un jefe directo o un admin marcó como revisados, y queda registrado con su cuenta.
![Catálogo de materiales de estudio con filtros por nivel, modelo y formato](captura-63)
Catálogo con filtros por nivel, modelo, competencia y formato.
9

### Notes:
Además de la ruta hay una página de materiales de estudio. La IA los genera a partir de los manuales, pero siempre quedan como borrador. Un jefe directo o un admin los lee y los marca como revisados con su cuenta. Solo entonces los ve el técnico.

<!-- Slide number: 10 -->
Tres fases para llevarla a todo el taller
Fase 1 · Entregada
Fase 2
Fase 3
Aplicación de escritorio, base SQLite local, panel físico opcional y cuatro competencias del autobús eléctrico.
Más escenarios y competencias, también diésel, agregando solo archivos JSON. El contenido oficial de Volvo reemplaza al de muestra sin tocar código.
Servidor central con sincronización, cuentas centralizadas y acceso corporativo. Los resultados se pueden cargar al LMS que Volvo elija, por CSV o JSON.
Un asesor de Volvo indicó que su LMS actual es limitado y que no gestiona los entrenamientos de los técnicos. Por eso la fase 3 no lo da por hecho.
10

### Notes:
La fase uno es lo que entregamos hoy y funciona sin conexión. La dos es crecer en contenido: nuevos escenarios y competencias se agregan con archivos JSON, y el contenido oficial de Volvo sustituye al de muestra. La tres es un servidor central. Un asesor de Volvo nos dijo que su LMS actual es limitado, así que no asumimos que ahí se pueda gestionar este entrenamiento.

<!-- Slide number: 11 -->
El proyecto en números
45 h
157
57
de desarrollo
pruebas automáticas: 120 en Godot y 37 en Python
ítems en el banco de preguntas, con su fuente
11
8
4
formatos de material de estudio
manuales de Volvo en la base de conocimiento
competencias evaluadas
11

### Notes:
Algunos números del proyecto. Las 45 horas son de desarrollo de software. Las pruebas automáticas corren cada vez que se cambia el código. El banco tiene cincuenta y siete ítems y cada uno lleva su fuente.

<!-- Slide number: 12 -->
Lo que falta y lo que pedimos a Volvo
Pendiente
Pedimos
Las 57 preguntas y los materiales de ejemplo siguen marcados como muestra hasta que especialistas de Volvo los revisen.
La retención es simulada con el reloj adelantado.
La prueba en mesa con la placa ESP32 real.
La base de datos local no está cifrada.
Que sus especialistas validen los valores técnicos y los procedimientos.
Confirmar si sus manuales pueden usarse en la nube de Azure. Hoy están en un contenedor privado.
Un grupo de técnicos para un piloto con tiempo real.
12

### Notes:
Queremos ser claros con lo que falta. El contenido sigue marcado como muestra hasta que lo valide gente de Volvo, la retención de la demo es simulada y todavía no probamos en mesa con la placa física. De Volvo necesitamos tres cosas: que validen el contenido, que nos digan si sus manuales pueden vivir en la nube y un grupo de técnicos para un piloto.
