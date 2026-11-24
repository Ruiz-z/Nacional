# Verificación manual

Abrir `godot/` en Godot 4.7.2 y pulsar Ejecutar (abre el menú principal). Marcar cada punto al comprobarlo; si algo falla, anotar la tarea y qué se vio.

## Menú y flujo (T-73, T-74, T-85 a T-87)
- [ ] Se puede crear un alias `T-` más 2 a 8 dígitos; uno repetido o vacío se rechaza con mensaje.
- [ ] El menú se maneja con teclado, con ratón y con el control.
- [ ] El menú indica el siguiente paso recomendado y muestra el estado del panel (físico, virtual, desconectado).
- [ ] Diagnóstico: 8 preguntas y 2 tareas prácticas; al fallar la media aparece una fácil; termina con dominio, nivel y confianza.
- [ ] Ruta: sesión de 3 micro-lecciones, cada una con fuente visible; al terminar se recalcula la ruta.
- [ ] Post-test y retest: si no se adelantó el reloj, avisa cuánto falta.
- [ ] Modo demo: carga `[DEMO]` sin tocar datos reales; "Adelantar reloj" y "Restablecer demo" funcionan.

## Simulador (T-52, T-57 a T-60, T-91 a T-98, T-117 y T-118)

- [ ] En el ejecutable exportado, WASD y ratón permiten caminar y mirar desde el inicio de la orden. El personaje choca con el autobús y las paredes. Repetir con los sticks del Pro Controller si está disponible.
- [ ] A menos de 2,5 m, la mira resalta la compuerta y muestra su nombre. Clic izquierdo o A abre su menú. Elegir **Inspeccionar** abre la puerta de inmediato y muestra el resultado durante dos segundos.
- [ ] Tab libera y vuelve a capturar el cursor. Esc cancela la selección. Se puede ocultar el HUD izquierdo y el panel virtual derecho por separado.
- [ ] Escenario abre las órdenes de servicio con zona, dificultad y competencia. Al elegir una orden, las piezas que no intervienen indican «Sin falla en esta orden».
- [ ] Cada pieza muestra sus propias acciones y las lecturas aplicables. En comunicación, el monitor ofrece las acciones del caso.
- [ ] Se marca una causa y se confirma una acción distinta en el panel. El resumen registra la brecha.
- [ ] Panel virtual: los 2 interruptores, la perilla, los 2 botones y los 3 LEDs responden.
- [ ] En aislamiento, elegir **Forzar pieza** en el terminal. Aparecen el tornillo roto, la chispa y el LED rojo. Volver a apuntar al terminal y comprobar el costo, tiempo y riesgo de **Reponer pieza**. Confirmar la recuperación y verificar el tornillo intacto y el LED ámbar.
- [ ] Evaluar el indicio en el monitor. Verificar el LED verde y confirmar la solución en la batería. Revisar la línea de tiempo, guardar la reflexión y reintentar. Comprobar la variante y el estado del gabinete al reintentar.
- [ ] Una falta crítica detiene el escenario y explica la causa con fuente. Una leve resta puntos y permite continuar.
- [ ] Desconectar el panel a mitad del escenario pausa, avisa y deja continuar con el virtual.

- [ ] En el gabinete, faros y motor, abrir y cerrar la tapa desde su menú. Con la tapa cerrada, mover la mira sobre las piezas internas y comprobar que quedan fuera de alcance. Reabrir desde el menú o con **Inspeccionar** y comprobar que las piezas siguen ofreciendo sus acciones. Revisar que abrir y cerrar no aparezca en la línea de tiempo ni cambie el puntaje.
- [ ] En faros, inspeccionar la caja y medir continuidad. Intentar confirmar la solución desde el relé antes de reponer el foco. Al confirmar en el panel virtual, el aviso central muestra **Falta: Foco izquierdo repuesto**. Reponer el foco y confirmar desde el relé. Comprobar los cuatro indicios marcados en el HUD y el resumen de orden resuelta.
- [ ] Repetir faros con un fusible equivocado y luego uno correcto. En otro recorrido provocar una chispa y corregirla con el cambio de foco. Dejar una pausa entre confirmaciones del panel y verificar que ambos recorridos terminan con la falla resuelta.
- [ ] En aislamiento, comunicación, motor y el banco, comprobar que el HUD marca los pasos de la orden a medida que se completan.
- [ ] En el banco, toma el multímetro de la mesa. Mide TP1 y TP2 y comprueba la lectura en la mano, las pinzas y su indicador.
- [ ] Guarda las lecturas y la causa en la hoja. Reconecta el conductor y confirma en el panel. Reintenta y comprueba que el multímetro vuelve a la mesa.
- [ ] Abre una orden, comprueba la tarjeta inicial y ciérrala con OK. Vuelve a abrirla con O o Start.

### Capturas de primera persona

Con un servidor gráfico, ejecutar desde la raíz del repositorio. Las vistas se guardan en 1280×720 y 1920×1080 en `build/capturas/`.

```bash
mkdir -p build/capturas
for alto in 720 1080; do
  ancho=$((alto * 16 / 9))
  captura() {
    local vista=$1
    shift
    godot --path godot -s ../tools/captura.gd -- escenas/bus.tscn \
      "../build/capturas/${vista}-${alto}.png" "$ancho" "$alto" "$@"
  }
  captura entrada 6.75 0 0.12 90 0 entrada
  captura cerrado 3.10 0 0.08 90 -26 cerrado
  captura menu 3.10 0 0.08 90 -26 cerrado menu
  captura abierto 3.10 0 0.31 90 -19 abierto
  captura danado 3.10 0 0.31 90 -19 danado
done
```

Las coordenadas indican la posición de los pies en metros y los ángulos de giro e inclinación en grados. Los ojos quedan a 1,70 m. La entrada deja 5,50 m hasta el casco y despeja los paneles laterales para encuadrar el autobús completo. Las vistas del gabinete quedan a 1,60 m del frente del gabinete. Para comprobar el encuadre, la bisagra, el daño y el presupuesto de triángulos por consola, agrega `--headless` antes de `--path` y `--verificar` al final de los argumentos del script.

- [ ] En ambas resoluciones, comprobar el encuadre desde la entrada, la compuerta cerrada y el monitor con el gabinete abierto. En la captura de daño, comprobar también el tornillo roto y el LED rojo.

Para generar las vistas de faros y motor a 1280×720, ejecutar desde la raíz del repositorio con un servidor gráfico.

```bash
mkdir -p build/capturas
for zona in faros motor; do
  for vista in cerrado animacion abierto; do
    godot --path godot -s ../tools/captura.gd -- escenas/bus.tscn \
      "$PWD/build/capturas/${zona}-${vista}.png" 1280 720 "$zona" "$vista"
  done
done
```

`animacion` captura la tapa a los 0,21 s. `abierto` espera el final de la animación disparada por «Inspeccionar».

## Tablero (T-63 a T-65)
- [ ] Vista del técnico: dominio y nivel por competencia, ruta pendiente, errores repetidos, intento actual frente al anterior.
- [ ] Vista del instructor: lista de técnicos, detalle con línea de tiempo y brechas.
- [ ] Los 9 indicadores se ven; la ayuda de cada uno muestra su fórmula.
- [ ] El retest aparece etiquetado "simulado"; un indicador sin datos dice "pendiente", no cero.
- [ ] El color (rojo, ámbar, verde) siempre va con texto o icono.
- [ ] Exportar CSV y JSON funciona; borrar un técnico pide confirmación.
- [ ] Asistente: responde con cita de fuente, dice "no tengo esa información" cuando no hay respaldo y muestra "Asistente no disponible" si no hay modelo.

## Panel físico (T-05, T-54 a T-56)
- [ ] Cada control de la maqueta genera su evento y el simulador lo refleja.
- [ ] Los 3 LEDs responden al estado del simulador.
- [ ] Desconectar el USB activa el panel virtual.

## Contenido (T-17)
- [ ] Cada ítem de seguridad se comparó con su fuente; se cambió `revisado` a `true` solo en los comprobados.

## Entrega (T-82 a T-84)
- [ ] 2 personas ajenas al equipo juegan el escenario; hallazgos con severidad y corregidos.
- [ ] Checklist de los 6 entregables sin pendientes.
- [ ] Dos ensayos completos de la demo, con plan B y USB de respaldo.
