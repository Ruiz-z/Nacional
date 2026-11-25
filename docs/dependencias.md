# Dependencias y versiones

| Componente | Versión | Uso | Obligatorio |
|---|---|---|---|
| Godot | 4.7.2 estable | Motor del juego y de las pruebas | Sí |
| godot-sqlite | 4.9 (en `godot/addons/`, sin FTS5) | Acceso a SQLite | Sí |
| Firmware ESP32 o Arduino | por definir | Panel físico | No (hay panel virtual) |
| Plugin serial de Godot o puente Python con pyserial | por decidir con la prueba de 30 min | Comunicación con el panel | No |
| Ollama y un modelo local | por definir | Asistente LLM | No |

| Azure AI Foundry (chat completions) | por definir | Ruta de aprendizaje generada con IA | No (hay ruta por reglas) |

El único servicio en la nube es Foundry y es opcional: sin configuración o sin conexión todo funciona con la ruta por reglas.
