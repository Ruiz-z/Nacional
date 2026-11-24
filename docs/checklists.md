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

## Simulador (T-52, T-57 a T-60)
- [ ] Se camina, se mira y se inspecciona el bus con teclado y ratón (y con el control si hay).
- [ ] Inspeccionar un componente muestra estado, lecturas y acciones.
- [ ] Se marca una causa en pantalla y se ejecuta la acción en el panel.
- [ ] Panel virtual: los 2 interruptores, la perilla, los 2 botones y los 3 LEDs responden.
- [ ] Apretar con torque excesivo rompe el tornillo y abre el menú de recuperación con costo, tiempo y riesgo.
- [ ] Una falta crítica detiene el escenario y explica con fuente; una leve resta puntos y sigue.
- [ ] Si la causa marcada y la acción no coinciden, se registra la brecha.
- [ ] Resumen: línea de tiempo, ruta ideal con fuente, "¿qué harías distinto?", comparación con el intento anterior y reintento con variante.
- [ ] Desconectar el panel a mitad del escenario pausa, avisa y deja continuar con el virtual.

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
