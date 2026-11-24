# Constitución del proyecto

1. **Stack:** Godot 4.7.2 para simulador y juego; firmware C++/Arduino para ESP32 o Arduino; puente Python solo si el plugin serial de Godot no sirve.
2. **Offline primero:** todo corre sin internet; datos locales (SQLite para resultados, JSON para contenido); asistente LLM local opcional.
3. **Contenido confiable:** cada pregunta, caso y paso cita su fuente; el contenido no oficial se marca `[MUESTRA]` hasta recibir material de Volvo.
4. **Seguridad primero:** una acción insegura se penaliza siempre más que un error de eficiencia; esas reglas se escriben a mano, no las genera un LLM.
5. **Todo es simulado:** no se toca un bus real ni alto voltaje; el panel físico es una maqueta.
6. **Entrada con respaldo:** funciona con teclado y ratón, sticks y botones del Pro Controller y panel físico; sin giroscopio.
7. **Contrato del panel:** una línea JSON por evento, versionada en `docs/protocolo-panel.md`; cambiarlo exige actualizar la spec primero.
8. **Honestidad en la demo:** la retención a largo plazo se simula adelantando el reloj y se declara; no se inventan métricas.
9. **Privacidad:** los técnicos se identifican con alias o ID, sin datos personales.
10. **Verificable:** cada RF tiene una prueba (automática o checklist manual) antes de marcarse hecho.
11. **Alcance:** primero el escenario eléctrico completo; el diésel solo si el eléctrico ya está validado.
12. **Dependencias:** no se añaden librerías o plugins sin preguntar. Aprobadas: plugin SQLite para Godot, runtime LLM local opcional (Ollama o similar) y búsqueda por palabras clave en GDScript para el RAG (el godot-sqlite incluido no trae FTS5), sin embeddings. Plugin serial o puente Python: se decide con la prueba de 30 minutos.
13. **Idioma:** código y commits en español claro; nombres técnicos en inglés si el motor lo exige.
