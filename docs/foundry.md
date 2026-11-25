# Ruta de aprendizaje con Foundry

La ruta se genera con IA solo si hay un servicio de Azure AI Foundry configurado. Sin configuración, sin conexión o con una respuesta inválida, la app usa la ruta calculada por reglas y lo rotula **"Ruta calculada sin IA"**.

## Qué se envía y qué no
- **Se envía:** un identificador seudónimo del técnico, el dominio por competencia, el conteo de errores por tipo, si hay falta crítica y el catálogo de órdenes (id, título, dificultad, competencia).
- **No se envía:** alias, nombres ni texto libre.
- La IA no crea preguntas, valores técnicos ni dominio. Solo ordena los cuatro temas y explica cada uno; la app valida la respuesta y pone primero las competencias con falta crítica.
- El resultado se guarda en SQLite (tabla `ruta_generada`) y se reutiliza si el diagnóstico no cambia.

## Configuración (nunca en git)
La app llama al agente **Faro** de Azure AI Foundry (API Responses del agente, con búsqueda en los manuales de Volvo). No usa clave de API: usa un token de Microsoft Entra.

Archivo `.env` en la raíz del repositorio (ya está en `.gitignore`):

```sh
NACIONAL_FOUNDRY_ENDPOINT=https://<recurso>.services.ai.azure.com/api/projects/<proyecto>
NACIONAL_FOUNDRY_AGENTE=Faro
```

- El token sale de la CLI de Azure: haz `az login` antes de abrir la app. Se guarda en memoria unos 50 minutos.
- Opcional: `NACIONAL_FOUNDRY_TOKEN` para dar un token ya obtenido.
- También se puede usar el archivo `user://foundry.cfg` con la sección `[foundry]` (`endpoint`, `agente`, `token`) o variables de entorno con los mismos nombres.
- El endpoint debe empezar con `https://`. Tiempo de espera: 30 s (la búsqueda en los manuales tarda unos 9 s).
- La suite de pruebas pone `NACIONAL_SIN_NUBE=1` y nunca llama a Foundry.

## Cómo responde el agente
- Con un agente fijo la API no permite cambiar el formato de salida: el esquema viaja en el mensaje y la app lo valida.
- La app extrae el JSON del mensaje y los nombres de PDF que devolvió la base de conocimiento (`basefaro123`, origen `ks-docs-volvo`). Se muestran como "Basada en: …" en la intro de la ruta.
- Si el JSON no cumple el esquema, repite competencias, inventa ids de órdenes o pasa de 220 caracteres, se descarta y queda "Ruta calculada sin IA".
- Coste: cada consulta con búsqueda usa unos 16 000 tokens. Por eso el resultado se guarda en SQLite y se reutiliza mientras el diagnóstico no cambie.

## Temas del mapa
- Cada paso de la respuesta puede traer hasta tres `temas` (título de hasta 90 caracteres y `fuente`). Son conceptos a estudiar sacados de los manuales y se dibujan en la rama derecha del mapa de la ruta.
- Un tema solo se acepta si su fuente es uno de los PDF que la base devolvió en esa misma respuesta (se compara sin distinguir mayúsculas). Si no, se descarta ese tema y la ruta sigue.
- Un id en `ordenes` que no exista en el catálogo se ignora; el mapa completa con órdenes de esa competencia. El orden de las cuatro competencias y la falta crítica primero siguen siendo obligatorios.
- La clave de la caché lleva un prefijo de versión: al cambiar el formato de la respuesta no se reutilizan rutas guardadas sin temas.
- Pruebas reales: 3 de 3 respuestas válidas en unos 10 s cada una.

## Permisos de Azure que hicieron falta
- `volvo-resource` y la identidad de `volvo-srch-f54r`: Lector de datos de Storage Blob en `faroarchivos`.
- `volvo-resource` y el proyecto `volvo`: Lector de datos del índice de búsqueda y Colaborador de servicio de búsqueda en `volvo-srch-f54r`.
- Sin el rol del proyecto el agente fallaba con "A user error occurred while executing a tool call".

## Cómo probar
1. Crea el `.env`, haz `az login` y abre la app.
2. Entra con un alias, completa el diagnóstico y abre **Ruta de aprendizaje**.
3. Debe verse "Armando tu ruta…" y después el camino con "Ruta generada con IA". Si falla, aparece "Ruta calculada sin IA".

## Pendiente
- T-172: revisión humana de que la ruta tenga sentido. Hecha una corrida real: válida, con tres PDF de fuente, en unos 9 s. La suite automática no llama a Foundry.
- Confirmar con Volvo que sus documentos pueden estar en la nube de Azure.
