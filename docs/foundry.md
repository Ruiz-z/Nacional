# Ruta de aprendizaje con Foundry

La ruta se genera con IA solo si hay un servicio de Azure AI Foundry configurado. Sin configuración, sin conexión o con una respuesta inválida, la app usa la ruta calculada por reglas y lo rotula **"Ruta calculada sin IA"**.

## Qué se envía y qué no
- **Se envía:** un identificador seudónimo del técnico, el dominio por competencia, el conteo de errores por tipo, si hay falta crítica y el catálogo de órdenes (id, título, dificultad, competencia).
- **No se envía:** alias, nombres ni texto libre.
- La IA no crea preguntas, valores técnicos ni dominio. Solo ordena los cuatro temas y explica cada uno; la app valida la respuesta y pone primero las competencias con falta crítica.
- El resultado se guarda en SQLite (tabla `ruta_generada`) y se reutiliza si el diagnóstico no cambia.

## Configuración (nunca en git)
Opción 1, variables de entorno antes de abrir la app:

```sh
export NACIONAL_FOUNDRY_ENDPOINT="https://<recurso>.services.ai.azure.com/<ruta de chat completions>?api-version=<versión>"
export NACIONAL_FOUNDRY_CLAVE="<clave>"
export NACIONAL_FOUNDRY_MODELO="<nombre del despliegue>"
# opcional: NACIONAL_FOUNDRY_AUTH=bearer para usar "Authorization: Bearer" en lugar de "api-key"
```

Opción 2, archivo `user://foundry.cfg` (en Linux: `~/.local/share/godot/app_userdata/<proyecto>/foundry.cfg`):

```ini
[foundry]
endpoint="https://..."
clave="..."
modelo="..."
```

El endpoint debe empezar con `https://`. Tiempo de espera: 8 s.

## Cómo probar
1. Configura una de las dos opciones y abre la app.
2. Entra con un alias, completa el diagnóstico y abre **Ruta de aprendizaje**.
3. Debe verse "Armando tu ruta…" y después el camino con "Ruta generada con IA". Si falla, aparece "Ruta calculada sin IA".

## Pendiente
- T-172: prueba con la clave real y revisión de que la ruta tenga sentido. La suite automática no llama a Foundry.
