# Materiales de estudio con IA (página web)

Página local donde se generan, con el agente de Azure AI Foundry y su búsqueda en los manuales de Volvo (RAG), materiales para aprender: **tarjetas**, **presentaciones**, **infografías** y cuatro **juegos** (quiz, pareo, ordenar pasos y ahorcado). Cada material se cataloga por **modelo de autobús**, **nivel** y **competencia**, y el catálogo abre en los **básicos** (Novato y Básico). Spec: [SPEC-materiales.md](../SPEC-materiales.md).
Página local donde se generan, con el agente de Azure AI Foundry y su búsqueda en los manuales de Volvo (RAG), materiales para aprender: **tarjetas**, **presentaciones**, **infografías** y siete **juegos**. Cada material se cataloga por **modelo de autobús**, **nivel** y **competencia**, y el catálogo abre en los **básicos** (Novato y Básico). Spec: [SPEC-materiales.md](../SPEC-materiales.md).

## Cómo abrirla
Desde la raíz del repositorio, con Python 3.10 o posterior (sin instalar nada más):

```sh
python web/servidor.py            # abre http://127.0.0.1:8765
```

- **Técnico:** ve solo los materiales revisados, filtra por modelo, nivel, competencia y formato, y estudia o juega.
- **Autor:** genera, actualiza con IA, edita a mano (JSON), marca como revisado o elimina. Ve también los borradores.
- Opciones: `--puerto 9000`, `--host` (por defecto solo `127.0.0.1`) y `--materiales <carpeta>` para trabajar sobre una copia.

## Quién puede generar, revisar y editar
La vista **Autor** (generar, actualizar con IA, editar, marcar como revisado, eliminar) solo existe para **jefe directo y admin**; el técnico solo ve los materiales revisados.
- Al abrir la página desde la tarjeta **Materiales de estudio** de la app, jefe directo y admin entran con un **permiso de autor**: el servidor lo guarda en `web/.token-autor` (se crea la primera vez, permisos `600`, fuera de git) y la app lo lee y abre `/acceso?token=…`. El servidor lo cambia por una cookie `HttpOnly` y `SameSite=Strict` y redirige a `/`, así que el token no queda en la barra de direcciones.
- La app también pasa tu **usuario** (`&usuario=`, cookie `HttpOnly`): al marcar un material como revisado, `revisado_por` es tu cuenta y no un texto libre; el servidor ignora cualquier otro nombre que llegue en la petición.
- Sin permiso, el servidor responde 403 a la vista de autor y a cualquier alta, edición, revisión o borrado, y no muestra borradores ni por su dirección directa. La página oculta el selector Técnico/Autor.
- Al ejecutar `python web/servidor.py` a mano, la vista de autor no se abre sola: se entra desde la app. Para trabajar solo sin la app, abre `http://127.0.0.1:8765/acceso?token=` con el contenido de `web/.token-autor`.
- Límite: el archivo del permiso lo puede leer quien tenga acceso a la sesión del sistema operativo, igual que la base de datos local. El control completo llega con el servidor central de la fase 3.

## Con IA y sin IA
- **Con IA:** usa la misma configuración que la ruta del juego ([foundry.md](foundry.md)): `.env` con `NACIONAL_FOUNDRY_ENDPOINT` y `az login`. La cabecera dice "IA conectada (Foundry)".
- **Agente:** se recomienda crear el agente `materiales` ([foundry/agente-materiales.yaml](../foundry/agente-materiales.yaml)) con la **misma base de conocimiento que Faro** y poner `NACIONAL_FOUNDRY_AGENTE_MATERIALES=materiales` en el `.env`. Si no existe, se usa `NACIONAL_FOUNDRY_AGENTE` (Faro); funciona porque la instrucción y el esquema viajan en el mensaje, pero las instrucciones fijas de Faro hablan de la ruta.
- **Sin IA** (sin `.env`, sin red o con `NACIONAL_SIN_NUBE=1`): tarjetas, quiz y ordenar pasos se arman con el banco (`contenido/banco.json`), con la fuente de cada ítem; prioriza el nivel, las palabras del tema y los PDF del modelo. Presentación, infografía, pareo y ahorcado necesitan la IA.
- **Sin IA** (sin `.env`, sin red o con `NACIONAL_SIN_NUBE=1`): tarjetas, quiz, ordenar pasos y verdadero o falso se arman con el banco (`contenido/banco.json`), con la fuente de cada ítem; prioriza el nivel, las palabras del tema y los PDF del modelo. Consulta la tabla de formatos para ver cuáles necesitan IA.
- Tiempo de espera de Foundry: 90 s (`NACIONAL_FOUNDRY_ESPERA_S`).
- Si tu cuenta pertenece a varios tenants, pon `NACIONAL_FOUNDRY_TENANT=<id>` (el del recurso de Foundry) y entra con `az login --tenant <id>`.

## Qué valida la app (no confía en la IA)
- El JSON debe cumplir el esquema del formato: cantidades (por ejemplo, 4 a 12 tarjetas) y longitudes. Si no, no se guarda nada y el autor ve cada error.
- **Fuentes:** solo se aceptan PDF que la base de conocimiento devolvió en esa misma respuesta. Sin ninguna fuente válida, el material se rechaza.
- Todo lo generado o editado queda como **borrador**; el técnico solo ve lo que una persona marcó como **revisado** (con su alias).
- Material de **seguridad de alto voltaje** generado con IA muestra "Requiere revisión de ambos subequipos" (constitución 4).
- Al agente solo viajan formato, modelo, nivel, competencia, tema y, al actualizar, el material actual y la indicación del autor. Nunca alias ni datos de técnicos.

## Dónde se guarda
- `contenido/materiales/<id>.json`, un archivo por material, en git como el resto del contenido.
- Cada material tiene `version` e `historial` (hasta 10 versiones anteriores con su motivo). Actualizar o editar sube la versión y lo regresa a borrador.
- Catálogo de modelos, niveles y formatos: `contenido/catalogo-materiales.json`. Para agregar un modelo de autobús basta con añadirlo ahí con sus PDF; las competencias se leen del banco.

## Modelos y niveles
| Modelo | Tipo | PDF sugeridos al agente |
|---|---|---|
| Todos los autobuses | general | Fact sheet de seguridad eléctrica |
| Volvo BZL Eléctrico | eléctrico | Data sheet BZL, fact sheet de seguridad |
| Volvo BZR Low Entry Eléctrico | eléctrico | Fact sheet de seguridad |
| Volvo 9700 | diésel | Manual del 9700 |
| Prevost H3 | diésel | Manual de operador H3, literatura Allison (PA1583) |
| Volvo B8R, B13R | diésel | (sin PDF en la base todavía) |

| Nivel | Guía que recibe la IA |
|---|---|
| Novato | Vocabulario, para qué sirve cada parte y la regla de seguridad que nunca se salta. |
| Básico | Cómo funciona, revisiones de rutina y procedimientos sencillos paso a paso. |
| Competente | Lógica del diagnóstico: qué medir primero y cómo interpretar. |
| Experto | Varias causas posibles, fallas intermitentes. |

## Formatos

| Formato | Qué haces | Generación sin IA |
|---|---|---|
| Tarjetas | Voltea cada tarjeta para repasar términos. | Sí |
| Presentación | Avanza por diapositivas cortas. | No |
| Infografía | Revisa la idea central y los datos clave. | No |
| Quiz | Elige una respuesta y revisa su explicación. | Sí |
| Pareo | Une términos con sus definiciones. | No |
| Ordena los pasos | Coloca los pasos en el orden del procedimiento. | Sí |
| Verdadero o falso | Responde de 6 a 12 afirmaciones y revisa tu puntaje frente a la línea de 91 %. | Sí |
| Completa la frase | Completa de 5 a 10 frases con la opción que encaja. | No |
| Clasifica | Elige cada elemento y luego su categoría con el ratón o el teclado. | No |
| Caso de falla | Toma de 3 a 6 decisiones. Puedes reintentar una vez en cada paso. Al final, repasa el recorrido ideal. | No |

## Materiales de inicio
Hay diecisiete borradores de nivel básico para la demo. Seis se generaron con Faro en los formatos originales y cinco se generaron desde el banco. Los seis restantes se escribieron a mano, incluido un ejemplo de cada juego nuevo con referencias del banco o de [fuentes-volvo.md](fuentes-volvo.md). Ninguno está revisado: un instructor debe revisarlos antes de que los vea un técnico.

## Prueba real con Faro (25/11/2026)
- Los seis formatos se generaron con Faro en 5 a 15 s cada uno; las fuentes citadas (fact sheet de seguridad, data sheet del BZL, manual del 9700, manual del H3 y literatura Allison) coincidieron con las que devolvió la búsqueda.
- La primera vez, infografía, pareo y secuencia se pasaron de los límites de longitud. Ahora la app devuelve los errores a la IA y le pide corregir una vez; el campo «dato» de la infografía admite 60 caracteres.
- Permisos que hicieron falta para una cuenta del equipo: rol **Foundry User** (antes «Azure AI User») en el grupo de recursos. «Azure AI Developer» no alcanza: no incluye los agentes. El tenant del recurso es el de la suscripción «Azure for Students» (`NACIONAL_FOUNDRY_TENANT`).

## Pruebas
```sh
python -m unittest discover web/pruebas
```
Cubren formatos, catálogo, extracción de la respuesta de Foundry, fuentes, generación con un agente simulado, respaldo sin IA, almacén, la API completa y que todo material guardado sea válido. Nunca llaman a Foundry.

## Pendiente
- Revisar y publicar los materiales de inicio; crear el agente `materiales` en el portal (T-190).
- Confirmar con Volvo los modelos de autobús prioritarios y subir a la base los manuales de B8R y B13R.
