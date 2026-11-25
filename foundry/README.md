# Agente de ruta de aprendizaje

`ruta-aprendizaje` ordena las competencias según el diagnóstico y explica qué practicar. La fuente de las instrucciones es `RutaIA.INSTRUCCION`. [El YAML](agente-ruta.yaml) reproduce ese texto para el registro del agente y una prueba de Godot comprueba que coincidan.

## Desde el portal

1. Abre [Microsoft Foundry](https://ai.azure.com/) y selecciona el proyecto con un despliegue de `gpt-4.1-mini`.
2. En **Generar → Agentes → Crear**, elige un agente basado en prompt. Usa el nombre `ruta-aprendizaje`, la descripción del YAML y el despliegue del modelo.
3. Copia el contenido de `instructions` del YAML en **Instrucciones**. Configura la temperatura en **0.3**, deja **Top P** en **1** y conserva la lista de herramientas vacía.
4. En el **Área de pruebas**, pega el mensaje de ejemplo. Comprueba que la respuesta sea un objeto JSON con cuatro pasos, uno por competencia, con seguridad de alto voltaje primero. Cada paso debe tener `competencia`, `motivo`, `practica` y `ordenes`. El único id de orden permitido en este ejemplo es `aislamiento`.

```text
Devuelve {"pasos":[{"competencia":"id","motivo":"texto","practica":"texto","ordenes":["id"]}]}.
{
  "tecnico": "T-00000000",
  "orden_base": ["seguridad-alto-voltaje", "diagnostico-fallas", "electronica-conectividad", "sistema-electrico-bateria"],
  "competencias": [
    {"id": "seguridad-alto-voltaje", "nombre": "Seguridad de alto voltaje", "dominio": 30, "errores": {"falta-critica": 1}, "falta_critica": true},
    {"id": "diagnostico-fallas", "nombre": "Diagnóstico de fallas", "dominio": 70, "errores": {}, "falta_critica": false},
    {"id": "electronica-conectividad", "nombre": "Electrónica y conectividad", "dominio": 70, "errores": {}, "falta_critica": false},
    {"id": "sistema-electrico-bateria", "nombre": "Sistema eléctrico y batería", "dominio": 70, "errores": {}, "falta_critica": false}
  ],
  "ordenes": [{"id": "aislamiento", "titulo": "Aislamiento", "dificultad": "facil", "competencia": "seguridad-alto-voltaje"}]
}
```

Consulta el [inicio rápido de agentes basados en prompt](https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/prompt-agent).

## Desde el script

Desde la raíz del repositorio, con Azure CLI y una identidad autorizada para crear versiones e invocar el agente en el proyecto:

```sh
python -m venv .venv
source .venv/bin/activate
python -m pip install -r tools/foundry/requirements.txt
az login
export PROJECT_ENDPOINT='https://<recurso>.services.ai.azure.com/api/projects/<proyecto>'
export MODEL_DEPLOYMENT='<nombre del despliegue de gpt-4.1-mini>'
python tools/foundry/crear_agente.py
```

`MODEL_DEPLOYMENT` es el nombre asignado al despliegue en el proyecto. El script usa `DefaultAzureCredential`, crea una versión de `ruta-aprendizaje` y comprueba su respuesta con un diagnóstico ficticio. Cada ejecución registra una versión. El código de salida es **0** si pasa la prueba y **1** si falla. Para configurar el cliente del juego, consulta su [guía de Foundry](../docs/foundry.md).

## Seguridad

El agente tiene un único propósito y funciona sin herramientas. Envía solo un identificador seudónimo y los datos permitidos del diagnóstico y del catálogo de órdenes. Mantén las claves y los tokens fuera de Git y omite alias, nombres de personas y texto libre. La aprobación humana en el flujo (human-in-the-loop) no aplica porque el agente solo devuelve una propuesta de ruta y no ejecuta acciones.
