"""Registra el agente de ruta en Foundry y prueba su respuesta con datos ficticios."""

import json
import logging
import os
from pathlib import Path


DEFINICION = Path(__file__).resolve().parents[2] / "foundry" / "agente-ruta.yaml"
COMPETENCIAS = {
    "seguridad-alto-voltaje": "Seguridad de alto voltaje",
    "diagnostico-fallas": "Diagnóstico de fallas",
    "electronica-conectividad": "Electrónica y conectividad",
    "sistema-electrico-bateria": "Sistema eléctrico y batería",
}
SEGURIDAD = "seguridad-alto-voltaje"
FORMATO = 'Devuelve {"pasos":[{"competencia":"id","motivo":"texto","practica":"texto","ordenes":["id"]}]}.'


def contexto_ejemplo():
    return {
        "tecnico": "T-00000000",
        "orden_base": list(COMPETENCIAS),
        "competencias": [
            {
                "id": id_competencia,
                "nombre": nombre,
                "dominio": 30 if id_competencia == SEGURIDAD else 70,
                "errores": {"falta-critica": 1} if id_competencia == SEGURIDAD else {},
                "falta_critica": id_competencia == SEGURIDAD,
            }
            for id_competencia, nombre in COMPETENCIAS.items()
        ],
        "ordenes": [
            {
                "id": "aislamiento",
                "titulo": "Aislamiento",
                "dificultad": "facil",
                "competencia": SEGURIDAD,
            }
        ],
    }


def validar_respuesta(respuesta, contexto):
    if not isinstance(respuesta, dict) or set(respuesta) != {"pasos"}:
        return False
    pasos = respuesta["pasos"]
    if not isinstance(pasos, list) or len(pasos) != len(contexto["orden_base"]):
        return False

    competencias = []
    ids_ordenes = [orden["id"] for orden in contexto["ordenes"]]
    for paso in pasos:
        if not isinstance(paso, dict) or set(paso) != {"competencia", "motivo", "practica", "ordenes"}:
            return False
        competencia = paso["competencia"]
        if competencia not in contexto["orden_base"] or competencia in competencias:
            return False
        for campo in ("motivo", "practica"):
            if not isinstance(paso[campo], str) or not 0 < len(paso[campo].strip()) <= 220:
                return False
        if not isinstance(paso["ordenes"], list) or any(id_orden not in ids_ordenes for id_orden in paso["ordenes"]):
            return False
        competencias.append(competencia)
    return competencias[0] == SEGURIDAD


def main():
    endpoint = os.getenv("PROJECT_ENDPOINT")
    despliegue = os.getenv("MODEL_DEPLOYMENT")
    if not endpoint or not despliegue:
        print("Prueba de humo fallida. Define PROJECT_ENDPOINT y MODEL_DEPLOYMENT.")
        return 1

    # Evita que los SDK registren datos de autenticación o de la solicitud.
    logging.disable(logging.CRITICAL)
    try:
        import yaml
        from azure.ai.projects import AIProjectClient
        from azure.ai.projects.models import PromptAgentDefinition
        from azure.identity import DefaultAzureCredential

        agente = yaml.safe_load(DEFINICION.read_text(encoding="utf-8"))
        definicion = PromptAgentDefinition(
            model=despliegue,
            instructions=agente["instructions"],
            tools=agente["tools"],
            **agente["model"]["options"],
        )
        contexto = contexto_ejemplo()
        with (
            DefaultAzureCredential() as credencial,
            AIProjectClient(endpoint=endpoint, credential=credencial, allow_preview=True) as proyecto,
        ):
            version = proyecto.agents.create_version(
                agent_name=agente["name"],
                definition=definicion,
                description=agente["description"],
                metadata={"tags": ", ".join(agente["metadata"]["tags"])},
            )
            with proyecto.get_openai_client(agent_name=version.name) as cliente:
                respuesta = cliente.responses.create(
                    input=f"{FORMATO}\n{json.dumps(contexto, ensure_ascii=False)}",
                    store=False,
                )
        paso = validar_respuesta(json.loads(respuesta.output_text), contexto)
    except json.JSONDecodeError:
        print("Prueba de humo fallida. El agente no devolvió JSON válido.")
        return 1
    except Exception:
        print("Prueba de humo fallida. Revisa las dependencias, la configuración y el acceso a Foundry.")
        return 1

    print("Prueba de humo superada." if paso else "Prueba de humo fallida. La ruta no cumple el formato esperado.")
    return 0 if paso else 1


if __name__ == "__main__":
    raise SystemExit(main())
